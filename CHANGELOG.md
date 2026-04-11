# NC AI SDK — Changelog

All notable changes to the NC AI SDK are documented here.
Follows [Semantic Versioning](https://semver.org/) and [Keep a Changelog](https://keepachangelog.com/).

---

## [1.0.2] - 2026-04-11

### Bug fixes — Windows engine compatibility

This release picks up the NC engine v1.2.1 Windows fixes. No SDK API changes.

- **Engine: async/gather crash on Windows** — Coroutine runtime now calls
  `ConvertThreadToFiber()` before `GetCurrentFiber()`, preventing a crash that
  affected any SDK endpoint using `async`/`gather` on Windows hosts.
- **Engine: fiber handle leak** — `DeleteFiber()` is now called on coroutine free.
- **Engine: MSVC compilation** — Fixed unguarded `pthread.h`, `clock_gettime`, and
  `socklen_t` that caused build failures with MSVC. MinGW/MSYS2 builds unaffected.
- **Engine: select() on 64-bit Windows** — Fixed silent truncation of 64-bit `SOCKET`
  in the server accept loop fallback path.

---

## [1.0.1] - 2026-04-01

### Bug fixes (prod-ready patch)

- **chr() output fix** — `chr(34)` / `chr(10)` replaced with `"\""` / `"\n"` string literals.
  NC's JIT treated numeric literals as FLOAT at runtime, causing `chr()` to return `NC_NONE`
  ("nothing") — all generated code had corrupted quotes and newlines. All generation now
  produces clean, valid NC source.
- **Chatbot memory prompt** — Generated chatbot code now concatenates the `history` variable
  into the AI prompt string correctly (`str(history)`) instead of the `{{history}}` template
  placeholder which NC would evaluate to "nothing" at serve-time.

---

## [1.0.0] - 2026-03-31

### First stable release

This is the first production release of the NC AI SDK. The v1 release surface is
intentionally scoped to the stable, tested, and hardened components only.

### Stable API surface (v1 contract)

- **`sdk/nc_ai_api.nc`** — Unified HTTP API service on port 8092
  - `POST /generate` — template-first NC code generation from natural language
  - `POST /complete` — code completion from a prefix
  - `POST /explain` — plain-English explanation of NC code
  - `POST /fix` — error detection and auto-repair
  - `POST /reason` — multi-step reasoning with graph-based path scoring
  - `POST /plan` — structured multi-step plan generation
  - `POST /agent` — single autonomous agent execution
  - `POST /swarm` — multi-agent swarm with consensus voting
  - `POST /encode` — Hebbian vector encoding (64-dim)
  - `POST /similarity` — semantic similarity score (0.0–1.0)
  - `POST /train` — training submission (queues to NC engine)
  - `POST /train/example` — online single-example fine-tuning
  - `GET /health` — health check

- **`sdk/server.nc`** — Template-first generator service
  - Deterministic intent detection (no external model required)
  - 8 intent categories: `service`, `crud`, `chatbot`, `classifier`, `summarizer`, `pipeline`, `webhook`, `ncui`
  - 8 feature modifiers: `auth`, `ai`, `rate_limit`, `cache`, `search`, `upload`, `notification`, `test`

- **`cli/chat.nc`** — Interactive chat surface (HTTP + intent routing)
  - Routes to generate, fix, explain, or plan based on prompt classification
  - Short conversation history (last 5 exchanges)
  - `POST /chat` and `GET /history` endpoints

### Experimental modules (not part of v1 contract)

The following are included in the repository for development and experimentation.
They are **not** covered by v1 production-hardening or API stability guarantees:

- `sdk/inference/generate.nc` — Intent detection and template expansion internals
- `sdk/inference/errorfix.nc` — NC/NCUI validation and auto-fix logic
- `sdk/inference/recommend.nc` — Best-practice recommendations engine
- `sdk/ml/embeddings.nc` — Hebbian co-occurrence embeddings
- `sdk/ml/reasoning.nc` — Weighted multi-hop graph reasoning
- `sdk/ml/swarm.nc` — Ant-colony-inspired multi-agent path planning
- `sdk/ml/feedback.nc` — Feedback-based weight adjustment
- `sdk/ml/graph_brain.nc` — Knowledge graph with transitive inference
- `sdk/ml/pipeline.nc` — Orchestration pipeline for chaining ML modules

### Test suite

- `tests/run_tests.ps1` — Canonical Windows smoke runner (HTTP round-trips against live server)
- `tests/test_code_generation.nc` — Generation correctness tests
- `tests/test_embeddings.nc` — Embedding and similarity tests
- `tests/test_error_fixing.nc` — Validation and fix tests
- `tests/test_reasoning.nc` — Graph reasoning tests
- `tests/test_recommendations.nc` — Recommendation engine tests
- `tests/test_swarm.nc` — Multi-agent swarm tests

### Documentation

- `docs/ARCHITECTURE.md` — System architecture and component overview
- `docs/USER_MANUAL.md` — End-user guide with examples
- `docs/SECURITY.md` — Full threat model, OWASP compliance, hardening reference
- `docs/ENTERPRISE.md` — Enterprise deployment guide
- `docs/TESTING_GUIDE.md` — Testing strategy and how to run tests

### Dependencies

- NC engine v1.1.0 or higher (`nc` binary from nc-lang)
- No external runtime dependencies — all generation is local
- Optional: NC_AI_BRIDGE_URL for connecting to an external LLM (disabled by default)

---

## [0.9.0-beta] - 2026-03-15

### Beta release (internal)

- Initial implementation of `nc_ai_api.nc` with generate, fix, reason endpoints
- Template engine for CRUD, chatbot, classifier, summarizer, pipeline, webhook patterns
- Hebbian embeddings prototype
- Graph reasoning engine with BFS/DFS hybrid
- Multi-agent swarm with pheromone trails
- Internal smoke tests only
