# ProxyGate Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-05-03

## Active Technologies

- Go 1.25.0 + Go standard library, `github.com/mattn/go-sqlite3`, `gopkg.in/yaml.v3`, `golang.org/x/net`, `golang.org/x/time`
- Embedded HTML/CSS/JavaScript in Go source (webui/dashboard.go)
- SQLite with WAL mode for persistence
- sing-box binary for encrypted subscription protocol conversion

## Project Structure

```text
config/          — Configuration (env vars + config.json persistence)
storage/         — SQLite persistence (proxies, subscriptions, source_status, proxy_sources, proxy_users, pool_history, api_keys, audit_events)
fetcher/         — Multi-source proxy fetching with circuit breaker, now DB-backed
validator/       — Proxy validation (connect + exit IP + geo + latency + HTTPS tunnel)
pool/            — Slot-based pool admission with mutex-guarded concurrent safety
checker/         — Health check (free deletion / custom soft-disable)
optimizer/       — Quality optimization for free pool
custom/          — Subscription management (parser, sing-box process, refresh/probe/cleanup)
proxy/           — HTTP + SOCKS5 proxy servers with multi-user auth, rate limiting, session stickiness
webui/           — Embedded dashboard with REST API, session auth, business theme
logger/          — In-memory ring buffer log collector
```

## Commands

```bash
go test ./...                    # Run all tests
go test -race ./...              # Run with race detector
go test -v -count=1 ./...        # Verbose, no cache
go test ./proxy/...              # Single package
go test -run TestCandidateBudget ./...
go build -o proxygate .          # Build binary
go vet ./...                     # Static analysis
```

## Code Style

Go 1.25.0: Follow standard conventions. Use `config.Get()` for runtime config reads (atomic pointer snapshot). Use `s.gobg()` for WebUI background goroutines (WaitGroup-tracked). Use `storage.XXX()` for DB operations with parameterized queries.

## Key Architectural Patterns

### Config System
- `config.Get()` returns `atomic.Pointer[Config]` snapshot — thread-safe, never mutate
- `config.Save()` persists to `config.json` and publishes new snapshot
- ENV vars provide initial defaults; config.json takes priority after first WebUI save
- All runtime-configurable fields live in `savedConfig` struct

### Proxy Selection
- `storage.getSelectionSnapshot()` builds in-memory cache of eligible proxies
- Cached for 2+ seconds with dirty-flag checking
- `SelectProxy()` uses reservoir sampling for random, sequential scan for lowest-latency

### Multi-User Auth
- `proxy_users` table stores username + SHA256 password hash
- HTTP/SOCKS5 auth checks DB first, falls back to config single-user
- Username supports extended parameters: `username-region-US-sid-SessionID-t-TTL`

### Background Goroutine Safety
- WebUI fire-and-forget goroutines use `s.gobg(fn)` which tracks via WaitGroup + atomic closed flag
- Pool Manager uses `sync.Mutex` to serialize slot-check-and-insert operations
- Tunnel relay connections have 5-minute idle deadline to prevent goroutine leaks

### Database Migrations
- All tables use `CREATE TABLE IF NOT EXISTS`
- Column additions use `pragma_table_info` checks for idempotent migration
- Default sources seeded via `seedDefaultSources()` on first run

## Database Tables

| Table | Purpose |
|-------|---------|
| `proxies` | All proxy nodes (free + custom) with quality/status metadata |
| `subscriptions` | Subscription sources (URL/file) with refresh config |
| `source_status` | Circuit breaker state for fetcher sources |
| `proxy_sources` | Configurable proxy list source URLs (DB-backed, replaces hardcoded) |
| `proxy_users` | Multi-user proxy authentication credentials |
| `pool_history` | Periodic pool state snapshots (every 5 min) |
| `api_keys` | API keys for external programmatic access |
| `audit_events` | Admin action audit trail |

## Recent Changes

- **v0.5.0** (2026-05-03): Full WebUI configuration management, multi-user proxy auth, DB-backed proxy sources, API key management, audit logging, pool history, rate limiting, business theme, critical bug fixes (race condition, goroutine leak, timer leak, body size limits)

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
