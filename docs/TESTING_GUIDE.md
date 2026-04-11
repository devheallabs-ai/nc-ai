# NC AI — Testing Guide

> Stable v1 testing focuses on the public HTTP surface in `sdk/nc_ai_api.nc`.

---

## Supported V1 Runner

```powershell
powershell -ExecutionPolicy Bypass -File tests\run_tests.ps1
```

This runner is the canonical SDK smoke suite for v1. It:

- starts `sdk/nc_ai_api.nc` on port `8092`
- checks `health`, `intent`, `generate`, `recommend`, `fix`, `reason`, `plan`, `encode`, `similarity`, and `swarm`
- exits non-zero on failure

## Manual Smoke Checks

```powershell
nc run sdk\nc_ai_api.nc -b health_check
nc serve sdk\nc_ai_api.nc
```

```powershell
Invoke-RestMethod -Uri http://127.0.0.1:8092/health -Method Get
Invoke-RestMethod -Uri http://127.0.0.1:8092/intent -Method Post -ContentType application/json -Body '{"prompt":"Build a todo CRUD API"}'
```

## Legacy Note

Historical material below references older `nc-ai/...` layouts and experimental subsystems. Keep it as background context only; it is not the v1 release contract.

---

## Test Each Capability Manually

### 1. Greeting
```bash
nc ai reason "hello"
# Expected: "Hello! I am NC AI..."
```

### 2. Email Composition (15 templates)
```bash
nc ai reason "Write an email about a meeting"
nc ai reason "Write an email about a leave request"
nc ai reason "Email about resignation"
nc ai reason "Write an email about an outage"
nc ai reason "Write an email about a project update"
# Expected: Full email with subject, tone, body
```

### 3. Creative Writing
```bash
nc ai reason "Write a poem about technology"
nc ai reason "Write a story about space"
# Expected: Full poem or story with theme
```

### 4. Translation (6 languages)
```bash
nc ai reason "Translate hello to Spanish"
nc ai reason "Translate hello to Telugu"
nc ai reason "Translate hello to Japanese"
nc ai reason "Translate hello to French"
nc ai reason "Translate hello to Hindi"
nc ai reason "Translate hello to German"
# Expected: Common phrases in target language
```

### 5. Math Reasoning
```bash
nc ai reason "Calculate 300km at 60km per hour"
nc ai reason "How many seconds in a day"
# Expected: Type: mathematical, step-by-step approach
```

### 6. Debug Reasoning
```bash
nc ai reason "Why does my server crash under load?"
nc ai reason "Why does my API timeout?"
# Expected: Type: debugging or causal, diagnostic steps
```

### 7. Planning
```bash
nc ai reason "How to deploy a microservice to production?"
# Expected: Type: planning, phased approach
```

### 8. Comparison
```bash
nc ai reason "Compare Docker vs Kubernetes"
nc ai reason "Compare PostgreSQL vs MongoDB"
# Expected: Type: comparison, evaluation criteria
```

### 9. Code Generation
```bash
nc ai reason "Build a task management API with users"
# Expected: Codegen output with entities, routes, CRUD
```

### 10. Decision Making
```bash
nc ai reason "Should I use canary deployment?"
# Expected: Decision with recommendation and reasoning
```

### 11. Code Review (NEW)
```bash
# In chat
nc ai reason "review my code"
nc ai reason "security review"
nc ai reason "find bugs"
nc ai reason "code quality"

# Automated file scan
nc ai review nc-ai/chat.nc
nc ai review nc-ai/
nc ai review .
# Expected: Issues, warnings, health score
```

### 12. Help
```bash
nc ai reason "what can you do"
# Expected: List of all capabilities
```

---

## Interactive Chat Test

```bash
nc ai chat
```

Type these in order:
1. `hello` — greeting
2. `Write an email about a project update` — email
3. `Write a poem about nature` — creative
4. `Translate hello to Telugu` — translation
5. `Why does my server crash?` — debug
6. `Build a task management API` — codegen
7. `review my code` — code review
8. `help` — capabilities list
9. `exit` — quit

---

## Automated Test Suites

### Module Tests (52 tests)
```bash
# All 7 AI modules
bash tests/run_tests.sh

# Force a specific NC binary if needed
NC_BIN=$(which nc) bash tests/run_tests.sh

# Plain log-friendly output
NO_COLOR=1 bash tests/run_tests.sh

# Individual modules
nc run nc-ai/tests/test_all_ai.nc -b test_reason
nc run nc-ai/tests/test_all_ai.nc -b test_autonomous
nc run nc-ai/tests/test_all_ai.nc -b test_codegen
nc run nc-ai/tests/test_all_ai.nc -b test_graph
nc run nc-ai/tests/test_all_ai.nc -b test_decision
nc run nc-ai/tests/test_all_ai.nc -b test_swarm
nc run nc-ai/tests/test_all_ai.nc -b test_energy
```

### Security Tests (17 tests)
```bash
bash nc-ai/tests/test_security.sh
```

Tests: newline injection, quote injection, null bytes, path traversal, DoS, unicode stress, etc.

### Performance Benchmarks
```bash
bash nc-ai/tests/test_performance.sh
```

Measures: cold/warm start, intent routing latency, throughput, input size impact, memory usage.

**Targets:**
| Metric | Target | Typical |
|--------|--------|---------|
| Avg latency | < 50ms | ~12ms |
| Throughput | > 50 qps | ~77 qps |
| Binary size | < 2MB | 0.8MB |
| Peak RAM | < 10MB | ~4MB |
| Cold start | < 100ms | ~15ms |

---

## Windows Testing

### Setup (one-time)
```powershell
# Install MSYS2 from https://www.msys2.org/
# Open MSYS2 MinGW64 terminal
pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-curl make
```

### Build
```bash
# Install the NC binary from https://github.com/devheallabs-ai/nc/releases
# Or build from source — see the NC repo README
```

### Test
```bash
./build/nc.exe ai reason "hello"
./build/nc.exe ai reason "Write an email about a meeting"
./build/nc.exe ai reason "review my code"
./build/nc.exe ai review somefile.py
./build/nc.exe ai chat
```

### Windows Notes
- REPL uses basic fgets input (no readline)
- No Metal/Accelerate (CPU only, same as all platforms)
- `nc ai review <dir>` directory scan requires `find` in PATH (MSYS2 provides this)
- Shell test runners default to `nc` on your PATH and also accept `NC_BIN` overrides.
- For CI and Windows log capture, use `NO_COLOR=1` or `NC_NO_ANIM=1` with the shell launchers.

---

## Retrain NC AI Model

If you add new training data:
```bash
# Add corpus files to training_data/nc_corpus/
# Then retrain using the NC engine:
nc ai learn training_data/nc_corpus/

# Or retrain with GPU acceleration:
nc ai learn training_data/nc_corpus/ --gpu
```

Current model stats:
| Metric | Value |
|--------|-------|
| Corpus files | 65 |
| Total lines | 2.8M |
| Total chars | 103M |
| Vocabulary | 111,145 |
| Triplets | 53,450 |
| Entities | 7,104 |
| Embeddings | 36,367 x 64 |
| 5-grams | 4M+ |
| Training time | ~139s |

---

## Troubleshooting

**Build fails on macOS?**
- Need: Xcode Command Line Tools (`xcode-select --install`)
- Requires: curl, pthread (system-provided)

**Build fails on Windows?**
- Need: MSYS2 with mingw-w64-x86_64-gcc and mingw-w64-x86_64-curl
- Run from MSYS2 MinGW64 terminal, not CMD

**Tests fail?**
- Run `bash launch.sh build` to rebuild
- Check that `nc` is available on your PATH

**AI gives wrong response?**
- Check intent routing: `nc ai reason "your question"` — look at Type field
- If wrong type, the keyword may not match — file an issue

---

Copyright 2026 DevHeal Labs AI. All rights reserved.
