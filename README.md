# NC AI SDK

Stable v1 of the public NC AI SDK.

## V1 Scope

The supported release surface is intentionally small:

- `sdk/nc_ai_api.nc` — stable public HTTP API
- `sdk/server.nc` — stable template-first generator service
- `tests/run_tests.ps1` — canonical Windows smoke runner for the public API

What v1 supports today:

- Template-first NC and NCUI generation
- Deterministic local intent detection
- Deterministic local recommendation, fixing, planning, reasoning, and similarity helpers
- HTTP-first integration via `nc serve`

What is not part of the v1 contract:

- Direct package imports using path separators in NC source
- The older `sdk/inference/` and `sdk/ml/` module tree as a runtime-stable API
- Neural generation as the default public path

Those directories remain in the repository as experimental work, but the release contract is the stable surface above.

## Quick Start

Start the public API:

```bash
nc serve sdk/nc_ai_api.nc
```

Smoke-check the service:

```bash
nc run sdk/nc_ai_api.nc -b health_check
```

Example HTTP calls:

```bash
curl -X POST http://127.0.0.1:8092/intent \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Build a todo CRUD API"}'

curl -X POST http://127.0.0.1:8092/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Build an orders CRUD service","options":{}}'
```

## Testing

The canonical SDK smoke suite is:

```powershell
powershell -ExecutionPolicy Bypass -File tests\run_tests.ps1
```

That runner starts `sdk/nc_ai_api.nc`, exercises the public HTTP routes, and exits non-zero on failure.

## Repository Layout

```text
nc-ai-sdk/
  sdk/
    nc_ai_api.nc    stable public API
    server.nc       stable template-first generator
    export.nc       ancillary export work
    inference/      experimental
    ml/             experimental
  cli/
    chat.nc         interactive chat surface
  tests/
    run_tests.ps1   canonical smoke runner
  docs/
    ARCHITECTURE.md
    ENTERPRISE.md
    SECURITY.md
    TESTING_GUIDE.md
    USER_MANUAL.md
```

## Notes

The current NC module loader only accepts module names without path separators. Because of that, the supported v1 integration story is to run the SDK as a service rather than import `sdk/nc_ai_api.nc` directly from another NC file.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [User Manual](docs/USER_MANUAL.md)
- [Security](docs/SECURITY.md)
- [Testing Guide](docs/TESTING_GUIDE.md)

## License

See [LICENSE](LICENSE).
