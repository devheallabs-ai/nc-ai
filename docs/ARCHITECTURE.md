# NC AI Architecture

System architecture for NC AI — the built-in AI engine embedded in the NC programming language.

By DevHeal Labs AI.

## V1 Architecture Snapshot

The release contract for v1 is narrower than the historical architecture described below.

- `sdk/nc_ai_api.nc` is the stable public API surface.
- `sdk/server.nc` provides the stable template-first generation path.
- `tests/run_tests.ps1` is the canonical release smoke suite.

Experimental work under `sdk/inference/` and `sdk/ml/` remains in the repository, but it is not the guaranteed runtime surface for this release.

## High-Level Architecture

```
                    ┌─────────────────────────────────┐
                    │         User Interface           │
                    │                                  │
                    │  $ nc ai generate "create API"   │
                    │  $ nc ai status                  │
                    │  $ nc run train_nc_model.nc      │
                    └──────────────┬───────────────────┘
                                   │
                    ┌──────────────▼───────────────────┐
                    │      NC Engine Binary (C11)       │
                    │      build/nc (~600KB)            │
                    │                                   │
                    │  ┌───────────────────────────┐   │
                    │  │    nc ai CLI Commands      │   │
                    │  │    (main.c)                │   │
                    │  └────────────┬──────────────┘   │
                    │               │                   │
                    │  ┌────────────▼──────────────┐   │
                    │  │   Model Runtime (nc_jit.c) │   │
                    │  │   Dispatch: train/generate/ │   │
                    │  │   save/load/decode          │   │
                    │  └────────────┬──────────────┘   │
                    │               │                   │
                    │  ┌────────────▼──────────────┐   │
                    │  │  Transformer Engine        │   │
                    │  │  ├── nc_model.c (992 lines)│   │
                    │  │  ├── nc_training.c         │   │
                    │  │  └── nc_tokenizer.c        │   │
                    │  └────────────┬──────────────┘   │
                    │               │                   │
                    │  ┌────────────▼──────────────┐   │
                    │  │  Hardware Acceleration     │   │
                    │  │  ├── nc_metal.m (GPU)      │   │
                    │  │  ├── Accelerate (BLAS)     │   │
                    │  │  └── Tiled CPU fallback    │   │
                    │  └──────────────────────────┘   │
                    └──────────────────────────────────┘
```

## Component Details

### 1. CLI Interface (main.c)

The `nc ai` command suite is built directly into the NC binary:

| Command | Handler | Description |
|---------|---------|-------------|
| `nc ai status` | `cmd_ai_status()` | Load model, display architecture/params/status |
| `nc ai generate` | `cmd_ai_generate()` | Encode prompt → generate → decode → output |
| `nc ai train` | `cmd_ai_train()` | Display training instructions |
| `nc ai serve` | `cmd_ai_serve()` | Start AI generation HTTP API |

Model search paths (in order):
1. `nc_ai_model_prod.bin` (current directory)
2. `nc_ai_model.bin` (current directory)
3. `training_data/nc_ai_model_prod.bin`
4. `training_data/nc_ai_model.bin`

### 2. Transformer Engine (nc_model.c)

Decoder-only transformer with pre-norm architecture:

```
Token IDs → Embedding Layer
                │
         ┌──────▼──────┐
         │  Block ×N    │
         │              │
         │  LayerNorm   │
         │      ↓       │
         │  Multi-Head   │  Q = X·Wq, K = X·Wk, V = X·Wv
         │  Attention    │  Attn = softmax(QK^T / √d_k) · V
         │  (causal)     │  Causal mask: future tokens = -∞
         │      ↓       │
         │  + Residual   │
         │      ↓       │
         │  LayerNorm   │
         │      ↓       │
         │  FFN          │  h → W1·h → GELU → W2·h
         │  (GELU)       │  dim → 4×dim → dim
         │      ↓       │
         │  + Residual   │
         └──────┬──────┘
                │
         Final LayerNorm
                │
         Linear Head (dim → vocab)
                │
         Logits → Softmax → Sample
```

Internal functions use `ncm_` prefix to avoid collision with `nc_tensor.c`:
- `ncm_tensor_create`, `ncm_tensor_matmul`, `ncm_tensor_add`
- `ncm_tensor_softmax`, `ncm_tensor_gelu`, `ncm_tensor_layer_norm`
- `ncm_linear_forward`, `ncm_attention_forward`, `ncm_ffn_forward`
- `ncm_block_forward`

### 3. BPE Tokenizer (nc_tokenizer.c)

Byte Pair Encoding tokenizer with NC-specific vocabulary:

```
Training:
  Raw NC text → Byte frequencies → Merge most common pairs
  → Repeat until target vocab size → Save merge table

Encoding:
  "to greet with name:" → [102, 3891, 455, 1203, 58]

Decoding:
  [102, 3891, 455, 1203, 58] → "to greet with name:"
```

- Auto-created during training if not present
- Stored in VM globals as `__nc_tokenizer`
- Target vocabulary: 4096 tokens
- Special tokens: `<pad>`, `<unk>`, `<bos>`, `<eos>`

### 4. Training Pipeline (nc_training.c)

```
Data Loading
├── Read NC corpus files (8 files, 1.3MB total)
├── Filter: 10 < sequence_length < 8192
├── Tokenize with BPE
└── Create batches of 4 sequences

Training Loop (5000 steps)
├── Forward pass (teacher forcing)
├── Cross-entropy loss computation
├── Backward pass (gradient computation)
├── Adam optimizer update
│   ├── β1 = 0.9, β2 = 0.999, ε = 1e-8
│   ├── Cosine learning rate decay
│   └── Gradient clipping (max norm = 1.0)
├── Log loss every 50 steps (stderr)
└── Save checkpoint every 500 steps

Output
├── nc_ai_model_prod.bin (~27MB for default config)
└── checkpoints/nc_model_step_N.bin
```

### 5. Hardware Acceleration

#### Metal GPU (nc_metal.m) — macOS Only

Objective-C bridge to Metal Performance Shaders:

```
nc_metal_init()
├── MTLCreateSystemDefaultDevice()
├── Check MTLGPUFamilyApple1 or MTLGPUFamilyMac2
└── Create MTLCommandQueue

nc_metal_sgemm(M, K, N, A, B, C)
├── Skip if M*K + K*N < 4096 (CPU faster for small matrices)
├── Create MTLBuffers (shared memory = zero-copy on Apple Silicon)
├── Row-major → column-major via transposition trick:
│   C = A @ B (row-major) = B^T @ A^T (column-major)
├── MPSMatrixMultiplication kernel
├── Encode → Commit → Wait
└── memcpy result back to CPU
```

#### Apple Accelerate BLAS — macOS

```c
// Matrix multiply: 50-100x faster than naive loops
cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
            M, N, K, 1.0f, A, K, B, N, 0.0f, C, N);

// Element-wise add
vDSP_vadd(a->data, 1, b->data, 1, out->data, 1, size);

// Scalar multiply
vDSP_vsmul(t->data, 1, &scalar, out->data, 1, size);
```

#### Acceleration Dispatch Order

```
ncm_sgemm(M, K, N, A, B, C):
  1. Try Metal GPU → nc_metal_sgemm()    [10-50x, large matrices only]
  2. Try BLAS     → cblas_sgemm()         [50-100x, all matrices]
  3. Fallback     → Tiled CPU (32×32)     [1x baseline]
```

### 6. Binary Model Format

```
Offset  Content
──────  ───────────────────────────
0x00    "NCM1" magic bytes (4 bytes)
0x04    dim (int32)
0x08    n_layers (int32)
0x0C    n_heads (int32)
0x10    vocab_size (int32)
0x14    max_seq (int32)
0x18    hidden_dim (int32)
0x1C    Token embedding    [vocab_size × dim] floats
...     Position embedding [max_seq × dim] floats
...     Per-layer weights:
          ln1_weight, ln1_bias     [dim]
          wq, wk, wv               [dim × dim]
          wo                       [dim × dim]
          ln2_weight, ln2_bias     [dim]
          w1                       [dim × hidden_dim]
          w2                       [hidden_dim × dim]
...     Final LN weight, bias     [dim]
...     LM head                   [dim × vocab_size]
```

## Data Flow: End-to-End Generation

```
User: "create a REST API for users"
  │
  ├─ nc ai generate "create a REST API for users"
  │   │
  │   ├─ Load model from nc_ai_model_prod.bin
  │   ├─ Load tokenizer from model globals
  │   │
  │   ├─ Encode: "create a REST API for users"
  │   │   → [2891, 102, 455, 3201, 891, 1023, 455, 2340]
  │   │
  │   ├─ Generate (autoregressive):
  │   │   for each new token:
  │   │     Forward pass through 6 transformer blocks
  │   │     Sample from logits with temperature=0.7
  │   │     Append to sequence
  │   │   until max_tokens or <eos>
  │   │
  │   ├─ Decode: [token IDs] → NC source code text
  │   │
  │   └─ Output:
  │       service "user-api"
  │       version "1.0.0"
  │
  │       to create_user with data:
  │           store data into "users"
  │           respond with {"id": data.id, "status": "created"}
  │       ...
  └─ Done
```

## Performance Characteristics

| Operation | Time (Apple Silicon) | Time (CPU only) | Memory |
|-----------|---------------------|-----------------|--------|
| Model load | ~50ms | ~50ms | ~27MB |
| Tokenize 1KB | < 1ms | < 1ms | < 32KB |
| Forward pass (dim=256) | ~5ms (BLAS) | ~200ms (naive) | ~10MB |
| Generate 100 tokens | ~500ms (BLAS) | ~20s (naive) | ~10MB |
| Training step (batch=4) | ~50ms (BLAS) | ~2s (naive) | ~50MB |
| Full training (5000 steps) | ~4 min (BLAS) | ~2.5 hrs (naive) | ~50MB |

## Security Model

- **No network access**: Model runs entirely locally, no data leaves the machine
- **Input sanitization**: Prompts bounded to max_seq length
- **Memory safety**: All tensor ops use explicit bounds checking
- **Zero dependencies**: No third-party C libraries = zero supply chain risk
- **Model integrity**: NCM1 magic bytes + config validation on load

## Future Architecture (v2)

### Knowledge Distillation Pipeline
```
Teacher LLM (Any Provider)
  │
  ├── Generate 100K NC code examples with explanations
  ├── Filter: only valid, compilable NC code
  ├── Create (prompt, completion) pairs
  │
  └── Distill into NC AI small model
      ├── Student model: dim=256, 6 layers (~5M params)
      ├── Teacher supervision: soft labels from large model
      └── Result: small model with large model knowledge
```

### Mixture of Experts (MoE)
```
Input → Router Network → Select Expert(s)
  ├── Backend Expert (API, service, middleware)
  ├── UI Expert (NC UI pages, components)
  ├── Data Expert (database, CRUD, queries)
  └── Test Expert (test files, assertions)

Only 1-2 experts active per token → fast inference
Total capacity of 4 experts, cost of 1
```

### Composed Specialists
```
Instead of one 25M param model:
  ├── Syntax model (500K) — generates valid NC structure
  ├── API model (1M) — knows HTTP routes and handlers
  ├── Logic model (1M) — control flow and data manipulation
  └── Compose at inference: Syntax → API → Logic → Output
```

---

## NC-AI Modules

### Reason AI (`nc-ai/reason-ai/reason.nc`)

Logic-first reasoning engine — NOT an LLM. Classifies questions, builds step-by-step reasoning chains, and returns answers with confidence scores.

**Architecture:**
```
Question → Classify → Build Chain → Type-Specific Solver → Self-Check → Response
                ↓                          ↓
         7 types detected          mathematical (0.85)
         (replace+len pattern)     debugging (0.80)
                                   planning (0.75)
                                   causal (0.75)
                                   comparison (0.75)
                                   code_generation (0.70)
                                   general (0.65)
```

**Key design decisions:**
- All classification logic is inlined (no sub-function calls) to avoid NC VM state corruption in loops
- Uses `replace()+len()` pattern instead of `contains` operator (VM returns string, not boolean)
- Flat function architecture — one function per loop call to support 6+ iterations

**API:** Port 8300 — `POST /reason`, `POST /classify`, `GET /demo`, `GET /health`

### Autonomous AI (`nc-ai/cortex/autonomous.nc`)

Self-learning system that scans codebase, counts patterns, detects query mode, and applies Hebbian learning from interactions.

**Stats:** 94,129 patterns, 893,410 tokens from 8 corpus files. Hebbian connection updates on every query.

**API:** Port 8100 — `POST /start`, `POST /learn`, `POST /answer`, `GET /capabilities`

### Codegen (`nc-ai/cortex/codegen.nc`)

Natural-language to NC code generator. Analyzes prompts, detects app type (API/CLI/ML/data/web), extracts entities, and generates complete NC applications with CRUD, validation, auth, and API routes.

**Stats:** Generates 3000-5000 chars of working NC code per prompt. Supports task, user, product, order, post, comment, notification, and 15+ other entity types.

**API:** Port 8900 — `POST /generate`, `POST /analyze`, `GET /demo`

### Knowledge Graph (`nc-ai/cortex/graph.nc`)

Graph-based knowledge system — nodes are concepts (NC keywords, architecture patterns, AI techniques, DevOps operations), edges are weighted relationships. Supports BFS traversal (2-hop), path scoring, and Hebbian learning of new connections from queries.

**Architecture:**
```
G = (V, E) where V = concepts, E = weighted relationships
Score(Path) = Σ w(i,i+1) - β·n  (reward strength, penalize length)

Build Graph → Add Nodes → Add Edges → Traverse → Score Paths → Learn
                ↓              ↓           ↓            ↓          ↓
          32+ concepts   25+ edges    BFS 2-hop    argmax     Hebbian
          (4 categories)  (weighted)  (neighbors)   (score)   (strengthen)
```

**Key design decisions:**
- 2-hop BFS traversal split into separate functions (`traverse_from` + `collect_hop2`) to stay within NC VM 2-level nesting limit
- Hebbian learning: co-activated concepts strengthen their edge weights automatically
- Four node categories: keyword (NC syntax), pattern (architecture), ai (ML concepts), devops (operations)

**API:** Port 8200 — `POST /build`, `POST /query`, `POST /learn`, `GET /traverse`, `GET /stats`, `GET /demo`

### Decision Engine (`nc-ai/cortex/decision.nc`)

Q-learning + energy-based decision system. Maintains a Q-table of (state, action) → value pairs, evaluates candidate actions using reward-cost-risk scoring, learns from feedback, and stores decisions in memory for future recall.

**Architecture:**
```
Situation → Classify State → Get Candidate Actions → Evaluate Each
                                                          ↓
                                          a* = argmax [ R - C - Risk + γ·Q(s,a) ]
                                                          ↓
                                                    Execute Best Action
                                                          ↓
                                              Feedback → Q-learning Update
                                              Q(s,a) ← Q + α·(reward - Q)
```

**Supported states:** `degraded_performance`, `error_state`, `resource_pressure`, `deployment`, `security_alert`, `scaling_needed`, `normal`

**Key design decisions:**
- State classification is inlined (replace+len pattern) to avoid deep call chains
- Q-table grows incrementally from real decisions — no pre-training required
- Decision memory enables recalling past actions for similar situations

**API:** Port 8400 — `POST /decide`, `POST /feedback`, `POST /recall`, `GET /stats`, `GET /demo`

### Swarm Intelligence (`nc-ai/cortex/swarm.nc`)

Multi-agent exploration system. 5 agents with different strategies (conservative, aggressive, balanced, efficient, experienced) independently score candidate actions, then weighted voting selects the best collective action.

**Architecture:**
```
Situation → Classify → Generate Candidates → Agent Voting → Best Action
                                                  ↓
                                      a* = argmax_a Σᵢ wᵢ·scoreᵢ(a)
                                                  ↓
                                          Feedback → Evolve Agents
                                          wᵢ ← wᵢ + α·(success - wᵢ)
```

**Agent strategies:**
| Agent | Strategy | Focus |
|-------|----------|-------|
| Conservative | `min_risk` | Low-risk actions, penalizes risk 2× |
| Aggressive | `max_reward` | High-reward, tolerates risk |
| Balanced | `balanced` | Equal weight on all factors |
| Efficient | `reward_per_cost` | Best reward per unit cost |
| Experienced | `prior_knowledge` | Trusts Q-values heavily (2×) |

**Key design decisions:**
- Agent weights evolve from feedback — winning strategies get stronger, losing strategies decay
- Flat scoring function — all 5 strategies in one function (`agent_score_action`)
- State classification inlined to avoid cross-function calls from the voting loop

**API:** Port 8500 — `POST /decide`, `POST /feedback`, `POST /init`, `GET /agents`, `GET /demo`

### Energy Scoring (`nc-ai/cortex/energy.nc`)

Physics-inspired energy-based action evaluation. Computes system energy from real metrics (CPU, memory, error rate, latency), scores actions using Boltzmann distribution, and uses entropy to decide between exploration and exploitation.

**Architecture:**
```
System Metrics → Compute Energy E(s) → Score Actions → Boltzmann → Recommend
     ↓                  ↓                    ↓             ↓            ↓
CPU, mem, errors   E = -(R-C-Risk)    P(a|s) = e^(-E)/Z   H = -Σp·log(p)  best action
latency            lower = better      probability dist     explore/exploit
```

**Energy levels:** `healthy` (< 0.3), `elevated` (0.3-0.5), `warning` (0.5-0.7), `critical` (> 0.7)

**Key design decisions:**
- Taylor series approximation for exp() since NC has no math.exp — `e^x ≈ 1 + x + x²/2 + x³/6`
- Log approximation: `ln(p) ≈ 2·(p-1)/(p+1)` for entropy calculation
- Energy history tracked over time for trend analysis (improving/worsening/stable)

**API:** Port 8600 — `POST /recommend`, `POST /score`, `POST /system_energy`, `GET /trend`, `GET /demo`

---

## NC AI Module Integration

The 7 modules form a unified operational intelligence system:

```
                    ┌──────────────────────────┐
                    │     User Query / Event    │
                    └────────────┬─────────────┘
                                 │
                    ┌────────────▼─────────────┐
                    │     Reason AI (8300)       │  Classify + reasoning chain
                    └────────────┬─────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                   │
   ┌──────────▼─────┐  ┌───────▼────────┐  ┌──────▼──────────┐
   │ Knowledge Graph │  │ Autonomous AI  │  │    Codegen       │
   │    (8200)       │  │   (8100)       │  │    (8900)        │
   │ Traverse + find │  │ Pattern learn  │  │ Generate NC code │
   └──────────┬──────┘  └───────┬────────┘  └──────┬──────────┘
              │                  │                   │
              └──────────────────┼──────────────────┘
                                 │
                    ┌────────────▼─────────────┐
                    │   Decision Engine (8400)   │  Q-learning + memory
                    └────────────┬─────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                                      │
   ┌──────────▼──────────┐            ┌─────────────▼───────────┐
   │  Swarm Intel (8500)  │            │  Energy Scoring (8600)  │
   │  Multi-agent voting  │            │  Boltzmann + entropy    │
   └──────────┬──────────┘            └─────────────┬───────────┘
              │                                      │
              └──────────────────┬──────────────────┘
                                 │
                    ┌────────────▼─────────────┐
                    │     Optimal Action        │
                    └──────────────────────────┘
```

---

*NC AI is part of the NC programming language by DevHeal Labs AI.*
