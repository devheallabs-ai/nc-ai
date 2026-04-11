# NC AI Security Documentation

Security model, threat analysis, and compliance documentation for NC AI.

By DevHeal Labs AI.

## V1 Security Scope

The security claims in this document apply to the stable release surface only:

- `sdk/nc_ai_api.nc`
- `sdk/server.nc`
- the template-first generation path exercised by `tests/run_tests.ps1`

Experimental modules under `sdk/inference/` and `sdk/ml/` are not part of the v1 production-hardening claim.

## Threat Model

### Assets

| Asset                  | Sensitivity | Description                                    |
|-----------------------|-------------|------------------------------------------------|
| User prompts           | Medium      | Natural language descriptions of desired code  |
| Generated code         | Medium      | NC source code produced by the engine          |
| Model weights          | Low         | Trained transformer parameters                 |
| API keys (bridge)      | High        | External LLM API credentials                   |
| Training data          | Low         | NC code corpus (public examples)               |

### Threat Actors

1. **Malicious user input** — Injection attacks via prompts (SQL, XSS, command injection)
2. **Supply chain attacks** — Compromised dependencies (mitigated: zero dependencies)
3. **Model poisoning** — Corrupted training data or model files
4. **Network interception** — Man-in-the-middle on LLM bridge API calls
5. **Local privilege escalation** — Malicious code execution from generated output

### Attack Surface

| Surface                    | Risk   | Mitigation                                              |
|---------------------------|--------|--------------------------------------------------------|
| User prompt input          | Medium | Input sanitization, injection pattern detection         |
| Generated code output      | Medium | OWASP security scan on all generated code               |
| LLM Bridge HTTP calls      | Medium | TLS enforcement, API key rotation, timeout limits       |
| Model file loading         | Low    | Magic number validation, size bounds checking           |
| File system access         | Low    | Path traversal prevention, sandboxed file operations    |

## OWASP Top 10 Compliance Checklist

NC AI implements checks and mitigations for all OWASP Top 10 (2021) categories:

| # | Category                               | Status      | Implementation                              |
|---|---------------------------------------|-------------|---------------------------------------------|
| A01 | Broken Access Control                | Implemented | JWT validation, CSRF tokens, rate limiting  |
| A02 | Cryptographic Failures               | Implemented | Crypto-random tokens, no plaintext secrets  |
| A03 | Injection                            | Implemented | SQL/NoSQL/XSS pattern detection in scanner  |
| A04 | Insecure Design                      | Implemented | Secure-by-default templates, threat model   |
| A05 | Security Misconfiguration            | Implemented | Strict CSP headers, no debug defaults       |
| A06 | Vulnerable/Outdated Components       | Implemented | Zero external dependencies                  |
| A07 | Identification/Authentication Failures | Implemented | JWT auth templates, OAuth 2.0 PKCE          |
| A08 | Software/Data Integrity Failures     | Implemented | Model file validation, code signing support |
| A09 | Security Logging/Monitoring          | Implemented | Audit logging, security event tracking      |
| A10 | Server-Side Request Forgery          | Implemented | URL validation, protocol allowlisting       |

### Scanner Functions

The security scanner (`nc_ai_security.h`) provides dedicated checks:

- `nc_security_check_injection()` — SQL, NoSQL, command injection
- `nc_security_check_xss()` — Cross-site scripting patterns
- `nc_security_check_auth()` — Authentication configuration
- `nc_security_check_ssrf()` — Server-side request forgery
- `nc_security_check_secrets()` — Hardcoded secrets detection
- `nc_security_check_rate_limit()` — Rate limiting presence
- `nc_security_check_cors()` — CORS configuration
- `nc_security_check_csrf()` — CSRF protection
- `nc_security_check_headers()` — Security headers
- `nc_security_check_input_validation()` — Input validation

## SOC 2 Relevant Controls

| Principle       | Control | Description                          | Status      |
|----------------|---------|--------------------------------------|-------------|
| Security        | CC6.1   | Logical access controls              | Implemented |
| Security        | CC6.2   | Credential management                | Implemented |
| Security        | CC6.3   | Access removal                       | Implemented |
| Security        | CC6.6   | Boundary protection                  | Implemented |
| Security        | CC6.7   | Encrypted transmission               | Implemented |
| Security        | CC6.8   | Unauthorized software prevention     | Implemented |
| Availability    | A1.1    | Capacity management                  | Implemented |
| Confidentiality | C1.1    | Data classification                  | Implemented |
| Confidentiality | C1.2    | Data disposal                        | Implemented |

## Data Handling

### Default Behavior (No User Data Stored)

- NC AI does **not** store user prompts by default
- Generated code is returned to the caller and not persisted
- The memory system stores learned **patterns**, not user data
- Training data consists only of public NC code examples
- No telemetry, analytics, or usage tracking

### When External LLMs Are Used (Bridge Mode)

- Prompts are sent to the configured LLM provider over TLS
- API keys are read from environment variables or config files (never hardcoded)
- Responses are not cached unless explicitly configured
- Bridge timeout defaults to 30 seconds

### GDPR Considerations

- No personal data processing in default (local) mode
- Bridge mode: user is responsible for LLM provider data processing agreements
- No cookies, tracking, or user profiling
- Data deletion: `nc_memory_free()` destroys all in-memory state

## Input Sanitization

All inputs pass through multiple sanitization layers:

1. **Length validation** — Maximum input length enforced (configurable, default 1MB)
2. **Pattern detection** — SQL, NoSQL, XSS, command injection patterns flagged
3. **Character filtering** — Control characters stripped (except newlines/tabs)
4. **Path validation** — File paths checked for traversal (`../`, `..\\`, null bytes)
5. **Header sanitization** — HTTP headers stripped of CRLF injection

## Memory Safety Guarantees

NC AI is written in C11 with strict memory safety practices:

- **Bounds checking**: All array accesses use explicit index validation
- **NULL checks**: Every pointer is checked before dereference
- **Buffer limits**: Fixed-size buffers with `NC_TOK_MAX_TOKEN_LEN`, `NC_SWARM_MAX_PATTERNS`, etc.
- **Lifecycle management**: Clear `create`/`free` pairs for all allocated structures
- **No dynamic format strings**: `printf` and friends use compile-time format strings only
- **Integer overflow protection**: Dimension products checked before allocation

## Dependency Audit

NC AI has **zero external dependencies**. The entire engine is built using only the C11 standard library:

- `stdio.h` — File I/O
- `stdlib.h` — Memory allocation
- `string.h` — String operations
- `math.h` — Mathematical functions
- `time.h` — Timestamps
- `stdbool.h` — Boolean type
- `float.h` — Float limits

**Supply chain risk: None.** No package manager, no third-party libraries, no network dependencies at build time.
