# NC AI v1.0 — User Manual

> The world's first programming language with built-in AI.
> Everything runs locally. No cloud. No API keys.
> By DevHeal Labs AI.

## V1 Reality

The supported release surface for this repository is:

- `sdk/nc_ai_api.nc` for the stable public HTTP API
- `sdk/server.nc` for the stable template-first generator
- `tests/run_tests.ps1` for the canonical SDK smoke suite

Template-first generation is the supported public path in v1. The older `nc-ai/...` paths and many subsystem descriptions later in this document reflect historical or experimental work and should not be treated as the compatibility contract for this release.

---

## One Command

```bash
# Launch NC AI (builds automatically if needed)
bash nc-ai/launch.sh
```

That's it. This builds the engine and opens an interactive AI chat.

---

## Quick Start

```bash
# Interactive AI chat (the main way to use NC AI)
nc ai chat

# Ask a one-shot question
nc ai reason "Write an email about a project update"
nc ai reason "Why does my server crash under load?"
nc ai reason "Write a poem about technology"

# Run the demo (10 example questions)
bash nc-ai/launch.sh demo

# Run all tests (52 module + 17 security + performance)
bash nc-ai/launch.sh test

# Start as HTTP API
bash nc-ai/launch.sh serve
```

### What You Can Ask

| Category | Examples |
|----------|----------|
| Write emails | "Write an email about a meeting", "Email about resignation" |
| Creative writing | "Write a story about space", "Write a poem about nature" |
| Debug & fix | "Why does my API timeout?", "Fix the login crash" |
| Explain | "What is Kubernetes?", "Explain microservices" |
| Build code | "Build a task management API with users" |
| Compare | "Compare PostgreSQL vs MongoDB" |
| Decide | "Should I use canary deployment?" |
| Translate | "Translate hello to Japanese" (6 languages) |
| Math | "Calculate how long to travel 300km at 60km/h" |
| Plan | "How to deploy a microservice to production?" |

### Individual Modules

```bash
# Run individual AI modules directly
nc run nc-ai/reason-ai/reason.nc -b demo
nc run nc-ai/cortex/codegen.nc -b demo
nc run nc-ai/cortex/autonomous.nc -b start
nc run nc-ai/cortex/graph.nc -b demo
nc run nc-ai/cortex/decision.nc -b demo
nc run nc-ai/cortex/swarm.nc -b demo
nc run nc-ai/cortex/energy.nc -b demo
```

---

## Modules

NC AI has 7 modules. Each is a standalone NC service that can run independently or together.

### 1. Reason AI

Classifies questions and builds step-by-step reasoning chains.

**7 Reasoning Types:**

| Type | Example Question |
|------|-----------------|
| Mathematical | "If a train travels 60 km in 1 hour, how long for 180 km?" |
| Debugging | "Why does the server crash when memory exceeds 90%?" |
| Planning | "How to deploy a microservice to production?" |
| Code Generation | "Write a function that validates user input" |
| Comparison | "What is the difference between NC and Python?" |
| Causal | "Fix the bug where login fails after timeout" |
| General | "What is NC?" |

**Run:**
```bash
nc run nc-ai/reason-ai/reason.nc -b demo
```

**Serve as API:**
```bash
nc serve nc-ai/reason-ai/reason.nc
```

**API Endpoints:**
```
POST /reason     — Reason about a question
POST /classify   — Classify question type only
GET  /demo       — Run demo with 6 sample questions
GET  /health     — Health check
```

**Example API Call:**
```bash
curl -X POST http://localhost:8300/reason \
  -H "Content-Type: application/json" \
  -d '{"question": "Why does the API timeout under load?"}'
```

**Response includes:**
- `type` — reasoning type (mathematical, debugging, etc.)
- `steps` — step-by-step reasoning chain
- `confidence` — confidence score (0-1)
- `numbers` — count of numbers detected in question
- `words` — word count

---

### 2. Autonomous AI

Self-learning system that reads NC code, learns patterns, and answers questions.

**Capabilities:**
- Learns from NC source code files (behaviors, patterns, tokens)
- Detects query mode: explain, debug, generate, code, graph, general
- Hebbian learning — strengthens connections from every interaction

**Run:**
```bash
nc run nc-ai/cortex/autonomous.nc -b start
```

**API Endpoints:**
```
POST /start      — Initialize and learn from codebase
POST /learn      — Learn from a specific code file
POST /answer     — Answer a question using learned knowledge
GET  /capabilities — Show what the system can do
GET  /health     — Health check
```

---

### 3. Codegen

AI-powered code generator. Describe an app in plain English, get working NC code.

**Detects:**
- App type: API, CLI, data pipeline, ML model
- Entities: user, task, product, order, post, comment, etc.
- Requirements: authentication, validation, CRUD

**Run:**
```bash
nc run nc-ai/cortex/codegen.nc -b demo
```

**API Endpoints:**
```
POST /generate   — Generate a full NC application from a prompt
POST /analyze    — Analyze a prompt without generating code
GET  /demo       — Generate 3 sample applications
GET  /health     — Health check
```

**Example:**
```bash
curl -X POST http://localhost:8000/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt": "build a task management API with user assignments"}'
```

**Generates:**
- Service header with configuration
- CRUD operations for each entity (create, list, get, update, delete)
- Input validation
- API routes
- Health check endpoint

---

### 4. Knowledge Graph

Graph-based knowledge system that connects concepts, traverses relationships, and learns.

**Features:**
- Typed nodes: keywords, patterns, AI concepts, DevOps concepts
- Weighted directed edges with relationship types
- BFS traversal (2-hop)
- Path scoring: `Score = Sum(weights) - 0.1 * path_length`
- Hebbian learning: edges strengthen when co-activated

**Run:**
```bash
nc run nc-ai/cortex/graph.nc -b demo
```

**API Endpoints:**
```
POST /build      — Build knowledge graph from NC concepts
POST /query      — Query the graph with a question
POST /add_node   — Add a concept node
POST /add_edge   — Add a relationship edge
POST /learn      — Hebbian: strengthen a connection
GET  /traverse   — BFS traversal from a node
GET  /neighbors  — Get direct neighbors
GET  /stats      — Graph statistics
GET  /demo       — Full demo
GET  /health     — Health check
```

---

### 5. Decision Engine

Q-learning based decision maker. Evaluates actions by reward, cost, and risk.

**How it works:**
1. Classify system state (normal, degraded, critical, deployment, security)
2. Generate candidate actions
3. Score each: `Score = R - C - Risk + Q(s,a)`
4. Pick best action
5. Learn from outcome: `Q(s,a) = Q + alpha * (reward - Q)`

**Run:**
```bash
nc run nc-ai/cortex/decision.nc -b demo
```

**API Endpoints:**
```
POST /decide     — Make a decision for a given situation
POST /feedback   — Provide feedback on a decision (for learning)
GET  /q_table    — View learned Q-values
GET  /demo       — Run 4 demo scenarios
GET  /health     — Health check
```

---

### 6. Swarm Intelligence

Multi-agent voting system. 5 agents with different strategies compete to find the best action.

**5 Agent Strategies:**

| Agent | Strategy | Behavior |
|-------|----------|----------|
| Conservative | Minimize risk | Prefers safe, low-risk actions |
| Aggressive | Maximize reward | Picks highest-reward regardless of risk |
| Balanced | Optimize R-C-Risk | Weighs all factors equally |
| Explorer | Random exploration | Tries novel actions to discover better options |
| Memory | Past experience | Uses history of what worked before |

**How voting works:**
1. Each agent scores every candidate action using its strategy
2. Scores are weighted by agent's track record (wins/losses)
3. Final score = weighted sum of all agent scores
4. Best action = highest weighted score
5. Winning agent's weight increases; losers decay slightly

**Run:**
```bash
nc run nc-ai/cortex/swarm.nc -b demo
```

**API Endpoints:**
```
POST /decide     — Swarm vote on a situation
POST /feedback   — Provide outcome feedback (agents evolve)
GET  /agents     — View agent weights and win rates
GET  /demo       — Run 4 demo scenarios
GET  /health     — Health check
```

---

### 7. Energy Scoring

Physics-inspired scoring system. Uses energy minimization and entropy for decision making.

**Key concepts:**
- **Action Energy:** `E = -(Reward - Cost - Risk)` — lower energy = better action
- **System Energy:** Computed from CPU, memory, error rate, latency
- **Boltzmann Selection:** `P(action) = e^(-E/T) / Z` — probabilistic action selection
- **Entropy:** Measures uncertainty — high entropy = explore, low entropy = exploit

**Run:**
```bash
nc run nc-ai/cortex/energy.nc -b demo
```

**API Endpoints:**
```
POST /score      — Score actions for a system state
POST /feedback   — Record outcome for learning
GET  /trend      — View energy trend (improving/worsening/stable)
GET  /demo       — Run 4 scenarios (healthy → critical)
GET  /health     — Health check
```

---

## Running as Services

Each module can run as an HTTP server:

```bash
# Start the unified chat API (recommended)
nc serve nc-ai/chat.nc

# Or start individual services
nc serve nc-ai/reason-ai/reason.nc
nc serve nc-ai/cortex/autonomous.nc
nc serve nc-ai/cortex/codegen.nc
nc serve nc-ai/cortex/graph.nc
nc serve nc-ai/cortex/decision.nc
nc serve nc-ai/cortex/swarm.nc
nc serve nc-ai/cortex/energy.nc
```

---

## Testing

Run the complete test suite (52 module + 17 security + performance):

```bash
bash nc-ai/tests/test_all.sh
```

Or run individual test categories:

```bash
# Module tests (52 tests across 7 AI modules)
bash nc-ai/tests/run_tests.sh

# Security & penetration tests (17 tests)
bash nc-ai/tests/test_security.sh

# Performance benchmarks
bash nc-ai/tests/test_performance.sh

# Individual module tests
nc run nc-ai/tests/test_all_ai.nc -b test_reason
nc run nc-ai/tests/test_all_ai.nc -b test_autonomous
nc run nc-ai/tests/test_all_ai.nc -b test_codegen
nc run nc-ai/tests/test_all_ai.nc -b test_graph
nc run nc-ai/tests/test_all_ai.nc -b test_decision
nc run nc-ai/tests/test_all_ai.nc -b test_swarm
nc run nc-ai/tests/test_all_ai.nc -b test_energy
```

---

## NC AI Model

NC AI (Neural Optimized Vector Architecture) is the ML model that powers NC AI.

**Architecture:** SSM + Knowledge Graph + Hebbian Learning

**Training data:** Corpus files in `training_data/nc_corpus/`

**Model artifacts:** Stored as binary model files (`.bin`)

| Artifact | Description |
|----------|-------------|
| `nc_ai_model.bin` | Trained model weights |
| `nc_ai_tokenizer.bin` | Vocabulary and tokenizer state |
| `metadata.json` | Model version, stats, config |

**Retrain the model:**
```bash
nc ai learn training_data/nc_corpus/
nc ai learn training_data/nc_corpus/ --gpu   # with GPU acceleration
```

The NC engine handles all training and inference natively in C — no external dependencies required.

---

## Architecture

```
User writes NC code
        ↓
NC Runtime (C engine)
        ↓
    ┌───┴────────────────────────────┐
    │         NC AI Modules          │
    ├────────────────────────────────┤
    │  Reason AI    → Classification │
    │  Autonomous   → Learning       │
    │  Codegen      → Generation     │
    │  Graph        → Knowledge      │
    │  Decision     → Q-Learning     │
    │  Swarm        → Multi-Agent    │
    │  Energy       → Scoring        │
    └────────────────────────────────┘
        ↓
NC AI Model (trained artifacts)
        ↓
Results returned to user
```

**Key design principle:** Everything the user touches is NC. The AI is built into the language — not bolted on.

---

## Performance

| Metric | Value |
|--------|-------|
| Average latency | ~11ms per query |
| Throughput | ~92 queries/sec |
| Binary size | 0.8MB |
| Peak memory | ~4MB |
| Chat module | 53KB |
| Cold start | <50ms |

---

## FAQ

**Is this an LLM?**
No. NC AI is a neuro-symbolic reasoning engine. It uses knowledge graphs, Q-learning, swarm intelligence, and energy-based scoring — not transformer-based token prediction.

**Does it need a GPU?**
No. Everything runs on CPU. Training takes ~20 seconds. Inference is sub-second.

**Does it need Python at runtime?**
No. Everything runs natively through NC + the C engine. No external dependencies required.

**Can it write emails and stories?**
Yes. `nc ai chat` can compose emails (15+ templates), write stories and poems, translate to 6 languages, and more. Try: `nc ai reason "Write an email about a project update"`

**Can it replace Cloud AI assistants?**
No. It solves a different problem: operational intelligence for DevOps, debugging, code generation, and system reasoning — not general-purpose text generation. But it can write emails, debug errors, and generate code entirely offline.

**What makes it unique?**
It's the only programming language with built-in AI that runs entirely locally on CPU with no external API dependencies. One binary, no cloud, no API keys.

**Does it work on Windows?**
Yes. Build with MSYS2/MinGW. The REPL uses basic input (fgets) on Windows — no readline required.

**Does it work with Docker?**
Yes. See [NC Dockerfile](https://github.com/devheallabs-ai/nc) for container builds.

---

Copyright 2026 DevHeal Labs AI. All rights reserved.
