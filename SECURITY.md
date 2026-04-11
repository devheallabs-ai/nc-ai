# Security Policy — NC AI SDK

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x     | ✅ Active security fixes |
| < 1.0   | ❌ Not supported |

The security claims in this document apply to the stable release surface:

- `sdk/nc_ai_api.nc` — stable public HTTP API
- `sdk/server.nc` — stable template-first generator
- `tests/run_tests.ps1` — canonical smoke runner

Experimental modules (`sdk/inference/`, `sdk/ml/`) are not covered by v1 production-hardening claims.

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Report privately to: **security@devheallabs.in**

Include in your report:
- Description of the vulnerability and its potential impact
- Steps to reproduce (proof-of-concept code, curl commands, etc.)
- NC AI SDK version and platform (OS, NC engine version)
- Any suggested mitigations

### Response timeline

| Stage | Target |
|-------|--------|
| Acknowledgement | 72 hours |
| Severity assessment | 7 days |
| Fix or mitigation plan | 30 days |
| Public disclosure | After fix is released |

We follow coordinated responsible disclosure. We will credit reporters in release notes unless you request anonymity.

## Security Model

### What the SDK does

The NC AI SDK is a **template-first code generation service**. It:
- Accepts natural language prompts via HTTP POST
- Classifies intent using deterministic string matching (no neural network on the request path)
- Returns generated NC source code using pre-defined templates

### Trust boundary

```
User prompt (untrusted)
        │
        ▼
  nc_ai_api.nc  ─── intent detection (string matching)
        │             template selection
        ▼
  Generated NC code (output — review before executing)
```

- The SDK does **not** execute generated code
- The SDK does **not** make outbound network calls during generation
- The SDK does **not** store prompts or generated code to disk

### Input handling

- All prompt inputs are treated as untrusted strings
- Intent detection uses `lower()`, `contains()`, `split()` — no `eval()` or shell execution
- Generated code is returned as a plain string — never executed by the SDK itself

### Running as a network service

When started with `nc serve sdk/nc_ai_api.nc`:

- Binds to `127.0.0.1:8092` by default — not exposed to the network
- To expose externally, put behind a reverse proxy (nginx, Caddy) with TLS
- Rate limiting is configurable via the `configure:` block
- No authentication is built in — add your own proxy-layer auth for production

### What the SDK does NOT protect against

- Prompt injection in the generated code (review generated output before running it)
- SSRF if the generated NC service is run without sandboxing
- Denial-of-service from extremely large prompts (set `NC_MAX_BODY` env var)

## Detailed Security Documentation

See [docs/SECURITY.md](docs/SECURITY.md) for the full threat model, OWASP compliance
matrix, and hardening configuration reference.
