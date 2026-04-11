# NC AI Enterprise Readiness

Enterprise deployment, scalability, compliance, and support documentation for NC AI.

By DevHeal Labs AI.

## V1 Reality

For this release, enterprise support applies to the stable public surface only:

- `sdk/nc_ai_api.nc`
- `sdk/server.nc`
- `tests/run_tests.ps1`

The deterministic template-first path is the default supported operating mode. Experimental modules under `sdk/inference/` and `sdk/ml/` are not part of the v1 SLA or compatibility promise.

## Deployment Options

### 1. Static Binary

The simplest deployment — a single compiled binary with no runtime dependencies.

```
$ make release
$ ./nc-ai generate "build a REST API for users"
```

- **Size**: ~2MB (stripped)
- **Dependencies**: None
- **Platforms**: Linux (x86-64, ARM64), macOS (x86-64, ARM64), Windows (x86-64)
- **Best for**: Developer workstations, CI/CD pipelines, embedded systems

### 2. Docker Container

Alpine-based container for containerized environments.

```
$ docker build -t nc-ai .
$ docker run --rm nc-ai generate "build a REST API for users"
```

- **Image size**: ~15MB (Alpine-based)
- **Base image**: `alpine:3.19` (minimal attack surface)
- **Non-root**: Runs as non-root user by default
- **Health check**: Built-in health endpoint for orchestrators

### 3. Kubernetes

Helm chart provided in `k8s/` directory.

```
$ helm install nc-ai ./k8s/nc-ai-chart
```

- **Horizontal scaling**: StatelessSet, scales via HPA
- **Resource limits**: CPU/memory limits configured by default
- **Secrets**: Kubernetes Secrets for API keys (bridge mode)
- **Probes**: Liveness and readiness probes included
- **Service mesh**: Compatible with Istio, Linkerd

## Scalability

### Model Size Options

| Tier   | Parameters | RAM Usage | Inference Time | Use Case                    |
|--------|-----------|-----------|----------------|-----------------------------|
| Tiny   | ~500K     | ~5MB      | < 50ms         | Edge devices, IoT, embedded |
| Small  | ~5M       | ~25MB     | < 200ms        | Desktop, CI/CD pipelines    |
| Medium | ~25M      | ~100MB    | < 500ms        | Servers, quality-critical   |

### Throughput

Template-based generation (no model):
- **Single instance**: ~10,000 generations/second
- **Bottleneck**: CPU-bound string operations

Neural model inference:
- **Single instance**: 2-20 generations/second (varies by model size)
- **Bottleneck**: Matrix multiplication in transformer layers

Ant Colony solve:
- **Single instance**: 1-10 solutions/second (depends on colony size)
- **Bottleneck**: Validation passes per ant agent

### Scaling Strategy

1. **Horizontal**: Deploy multiple NC AI instances behind a load balancer. Each instance is stateless (memory is per-request unless persistence is configured).
2. **Vertical**: Use the Medium model tier on machines with more RAM for higher quality output.
3. **Hybrid**: Use template generation for latency-sensitive requests, neural model for quality-sensitive requests.

## High Availability

### Stateless Design

NC AI instances are stateless by default. The colony memory and cognitive memory systems operate in-memory per-process. This means:

- Any instance can serve any request
- No shared state between instances
- No database dependency
- Instant startup (< 100ms with model pre-loading)

### Failure Modes

| Failure                | Impact       | Recovery                                |
|-----------------------|-------------|----------------------------------------|
| Instance crash         | Single request lost | Load balancer routes to healthy instance |
| Model file corruption  | Neural generation unavailable | Falls back to template engine |
| LLM bridge timeout     | External generation unavailable | Falls back to local model     |
| Memory exhaustion      | Process killed by OOM | Auto-restart via container orchestrator  |

### Recommended HA Setup

- Minimum 2 instances across availability zones
- Health check endpoint with 5-second interval
- Circuit breaker on LLM bridge (3 failures = open)
- Template engine as fallback (always available, no model needed)

## Monitoring and Logging

### Metrics

NC AI exposes the following operational metrics:

| Metric                         | Type    | Description                        |
|-------------------------------|---------|-----------------------------------|
| `nc_ai_generations_total`      | Counter | Total code generations             |
| `nc_ai_generation_duration_ms` | Histogram | Generation latency               |
| `nc_ai_template_type`          | Counter | Generations per template type      |
| `nc_ai_security_issues_found`  | Counter | Security issues detected in output |
| `nc_ai_bridge_requests`        | Counter | External LLM API calls             |
| `nc_ai_bridge_errors`          | Counter | Failed external LLM calls          |
| `nc_ai_memory_entries`         | Gauge   | Current cognitive memory entries    |
| `nc_ai_colony_pheromone_avg`   | Gauge   | Average pheromone strength         |

### Logging

Structured logging with severity levels:

- **ERROR**: Generation failures, model load errors, security violations
- **WARN**: Fallback to template engine, bridge timeout, rate limit triggered
- **INFO**: Generation completed, model loaded, bridge connected
- **DEBUG**: Token sequences, intent parsing details, pheromone updates

### Alerting Recommendations

| Alert                           | Threshold            | Action                      |
|--------------------------------|---------------------|-----------------------------|
| Generation error rate           | > 5% over 5 minutes | Investigate model/input     |
| Bridge error rate               | > 10% over 1 minute | Check LLM provider status   |
| Security issues in output       | Any critical         | Review generated code       |
| Memory usage                    | > 80% of limit       | Scale up or reduce model    |
| Latency P99                     | > 2 seconds          | Check model size / scaling  |

## Compliance

### OWASP Top 10

All generated code is scanned against OWASP Top 10 (2021). See [SECURITY.md](SECURITY.md) for the full checklist. The `nc_security_scan()` function returns a detailed report with severity levels and remediation recommendations.

### SOC 2

NC AI supports SOC 2 Type II readiness through:

- Access controls (JWT, OAuth, RBAC in generated code)
- Audit logging (security events, access patterns)
- Data handling (no user data stored by default)
- Change management (version-controlled model files)
- Incident response (security scan on all output)

### GDPR

- **Data minimization**: No user data collected or stored in local mode
- **Right to erasure**: `nc_memory_free()` destroys all in-memory state
- **Data portability**: All output is plain text NC code
- **Privacy by design**: No telemetry, no tracking, no analytics

### PCI DSS

- **No cardholder data processing**: NC AI does not handle payment data
- **Secure code generation**: Generated code includes input validation and injection prevention
- **Access controls**: JWT and OAuth templates enforce authentication

## SLA Targets

| Metric             | Target (Small model) | Target (Template only) |
|-------------------|---------------------|----------------------|
| Availability       | 99.9%               | 99.99%               |
| Generation latency (P50) | < 200ms        | < 5ms                |
| Generation latency (P99) | < 1000ms       | < 50ms               |
| Error rate         | < 1%                | < 0.1%               |
| Security scan coverage | 100%            | 100%                 |

Template-only mode achieves higher availability because it has no model loading step and no external dependencies.

## Support Model

### Tiers

| Tier        | Response Time | Channels           | Includes                          |
|------------|--------------|--------------------|------------------------------------|
| Community   | Best effort  | GitHub Issues      | Bug reports, feature requests      |
| Professional | 24 hours    | Email, GitHub      | Priority bug fixes, guidance       |
| Enterprise  | 4 hours      | Dedicated Slack    | Custom models, on-site support     |

### Versioning

NC AI follows semantic versioning (SemVer):

- **Major**: Breaking API changes
- **Minor**: New features, backward compatible
- **Patch**: Bug fixes, security patches

### Upgrade Path

1. Download new binary / pull new Docker image
2. Model files are backward-compatible within major versions
3. Configuration files are backward-compatible within major versions
4. Zero-downtime upgrades via rolling deployment in Kubernetes
