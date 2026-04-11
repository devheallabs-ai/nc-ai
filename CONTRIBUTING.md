# Contributing to NC AI SDK

Thank you for your interest in contributing. This document covers how to set up
the development environment, run tests, and submit changes.

## Prerequisites

- `nc` binary v1.0.0 or higher ([install from NC repo](https://github.com/devheallabs-ai/nc) or download a [release](https://github.com/devheallabs-ai/nc/releases))
- Git
- PowerShell (Windows) or Bash (macOS/Linux) for the test suite

## Getting Started

```bash
# Clone the repo
git clone https://github.com/devheallabs-ai/nc-ai.git
cd nc-ai

# Verify nc is available and is the right version
nc version
# Expected: nc v1.1.0 or higher

# Start the SDK server
nc serve sdk/nc_ai_api.nc

# In another terminal, hit the health endpoint
curl http://localhost:8092/health
# Expected: {"status":"ok","service":"nc-ai-sdk","version":"1.0.0",...}
```

## Running Tests

### Canonical smoke suite (Windows)
```powershell
powershell -ExecutionPolicy Bypass -File tests\run_tests.ps1
```

### NC unit tests (all platforms)
```bash
# Ensure nc is in your PATH (install from https://github.com/devheallabs-ai/nc)
nc version

# Run individual test modules
nc tests/test_code_generation.nc
nc tests/test_embeddings.nc
nc tests/test_error_fixing.nc
nc tests/test_reasoning.nc
nc tests/test_recommendations.nc
nc tests/test_swarm.nc
```

### Run all NC tests in one go
```bash
PASS=0; FAIL=0
for f in tests/*.nc; do
  echo "── $f"
  nc "$f" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
done
echo "Results: $PASS passed, $FAIL failed"
```

## Project Structure

```text
nc-ai-sdk/
  sdk/
    nc_ai_api.nc        ← STABLE: public HTTP API (edit with care)
    server.nc           ← STABLE: template-first generator (edit with care)
    export.nc           ← ancillary export utilities
    inference/          ← EXPERIMENTAL: intent detection and fix engine
    ml/                 ← EXPERIMENTAL: embeddings, reasoning, swarm
  cli/
    chat.nc             ← interactive chat surface
  tests/
    run_tests.ps1       ← canonical Windows smoke runner
    test_*.nc           ← NC unit tests (one per module)
  docs/
    ARCHITECTURE.md
    USER_MANUAL.md
    SECURITY.md
    ENTERPRISE.md
    TESTING_GUIDE.md
  examples/
    *.md                ← spec examples for common use cases
```

## What to Contribute

### High-value contributions

- **New test cases** — the `tests/test_*.nc` files cover the stable API surface.
  Adding tests for edge cases (empty inputs, special characters, long prompts) is
  the highest-value contribution you can make.

- **Bug fixes in stable modules** — `sdk/nc_ai_api.nc` and `sdk/server.nc` are the
  production surface. Fixes here are reviewed quickly.

- **Documentation improvements** — examples, clearer explanations, additional
  languages in the user manual.

- **New intent patterns** in `sdk/nc_ai_api.nc` — if the intent detector misses
  a common class of prompt, open an issue with examples and we can add patterns.

### Experimental modules (`sdk/inference/`, `sdk/ml/`)

These are explicitly marked experimental. Contributions welcome, but they will
not be merged into the stable API surface without a separate RFC discussion.

## Submitting Changes

1. **Fork** the repository
2. **Create a branch**: `git checkout -b fix/describe-the-fix`
3. **Make your change** and add or update tests
4. **Run the test suite** (see above) and verify it passes
5. **Open a Pull Request** against `main`

### PR checklist

- [ ] Tests pass locally
- [ ] New behavior is covered by a test
- [ ] Existing tests still pass
- [ ] CHANGELOG.md updated if this is a user-visible change
- [ ] No secrets, API keys, or private data in the diff

## Commit Style

Use short, imperative commit messages:

```
fix: handle empty prompt in ai_generate
feat: add POST /similarity endpoint
docs: clarify experimental module status
test: add edge case for empty input in test_embeddings
```

## Code Style

NC code in this SDK follows these conventions:

- `service` and `version` declaration at the top of every file
- `purpose:` string on every function
- Input validation with early `respond with {error: ...}` at the top of functions
- Functions named `verb_noun` (e.g., `detect_intent`, `generate_from_template`)
- Comments above each logical section with `// ──` divider style

## Reporting Bugs

Open a GitHub Issue with:
- NC version (`nc version`)
- Platform (OS + architecture)
- The exact prompt or input that triggered the bug
- Expected vs. actual response
- The full error message or unexpected output

For security issues, see [SECURITY.md](SECURITY.md).

## License

By contributing, you agree that your contributions will be licensed under
the [Apache License 2.0](LICENSE).
