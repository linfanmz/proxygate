# ProxyGate

[English](README_EN.md) | [简体中文](README.md)

> **Self-hosted proxy gateway** — aggregates public proxies and subscription nodes, validates them into one pool, and serves them through unified HTTP/SOCKS5 ports with session stickiness.

[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Go Version](https://img.shields.io/badge/Go-1.25-00ADD8?logo=go)](https://go.dev/)

---

## Server Deployment (Docker)

### Option A: Build locally → export → upload to server (recommended, no registry needed)

```bash
# 1. Build image on your local machine
docker compose -f docker-compose.yml -f docker-compose.build.yml build

# 2. Export to tar file
docker save proxygate:latest -o proxygate.tar

# 3. Upload to your server
scp proxygate.tar docker-compose.yml root@your-server:/opt/proxygate/

# 4. Load and start on server
ssh root@your-server
cd /opt/proxygate
docker load -i proxygate.tar
docker compose up -d

# 5. Open WebUI
# http://your-server-ip:7778 (default password: proxygate)
```

### Option B: Push to container registry → pull on server

```bash
docker compose -f docker-compose.yml -f docker-compose.build.yml build
docker tag proxygate:latest your-username/proxygate:latest
docker push your-username/proxygate:latest
# Then update docker-compose.yml image field and run on server
```

### Option C: Build directly on server

```bash
# Server needs Docker and source code
git clone <repo-url> && cd proxygate
docker compose -f docker-compose.yml -f docker-compose.build.yml up -d --build
```

### Post-deployment setup

1. Login at `http://your-server-ip:7778` with default password `proxygate`
2. Click gear icon → change admin password
3. Configure proxy auth, geo filtering, proxy sources — all via WebUI, no `.env` editing needed
4. For HTTPS, use nginx/caddy as reverse proxy in front of `:7778`

---

## Features

- **Dual pool**: Free pool (30+ public sources) + Subscription pool (Clash/V2ray import with built-in sing-box)
- **5 proxy modes**: Mixed (sub-first/free-first/equal), subscription-only, free-only
- **4 gateway ports**: HTTP random/latency + SOCKS5 random/latency
- **Full WebUI config**: All settings via admin panel — proxy auth, multi-user, sources, pool params, geo filter
- **Multi-user auth**: Multiple proxy credentials, independently managed
- **Session stickiness**: Username extensions for `region`/`st`/`sid`/`t` params
- **Auto operations**: Smart fetch, health checks, optimization, failure recovery, rate limiting
- **Security**: Brute force protection, audit logging, API key management

---

## Ports

| Port | Protocol | Mode | Use |
|------|----------|------|-----|
| 7776 | HTTP | Lowest latency | Stable connections |
| 7777 | HTTP | Random rotation | Crawling, IP diversity |
| 7779 | SOCKS5 | Random rotation | Browsers, SSH |
| 7780 | SOCKS5 | Lowest latency | Long-lived apps |
| 7778 | HTTP | WebUI | Dashboard |

---

## Proxy Usage

```bash
curl -x http://server-ip:7777 https://httpbin.org/ip
curl --socks5-hostname server-ip:7779 https://httpbin.org/ip

# With auth
curl -x http://user:pass@server-ip:7777 https://httpbin.org/ip

# Session stickiness + geo filter
curl -x http://proxy-region-US-sid-job001-t-30:pass@server-ip:7777 https://httpbin.org/ip
```

---

## WebUI Configuration

All settings managed via WebUI admin panel (gear icon). No `.env` editing needed:

| Section | Content |
|---------|---------|
| Proxy Mode | Mixed (sub-first/free-first/equal), sub-only, free-only |
| Free Pool | Capacity, HTTP ratio, latency thresholds, optimization |
| Subscription Pool | Probe interval, refresh interval |
| Validation | Concurrency, timeout, check interval, validate URL |
| Geo Filter | Allowed countries (whitelist) / Blocked countries (blacklist) |
| Proxy Auth | Enable toggle, username, password, local bypass |
| User Management | Add/remove multiple proxy auth users |
| Admin Password | Change WebUI login password |

Environment variables (`.env`) serve as initial defaults only. After first launch, use WebUI.

---

## Data Management

Docker deployment uses a named volume for persistence across restarts/upgrades.

```bash
# Backup
docker run --rm -v proxygate-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/proxygate-backup-$(date +%Y%m%d).tar.gz -C /data .

# Restore
docker compose down
docker run --rm -v proxygate-data:/data -v $(pwd):/backup \
  alpine sh -c "cd /data && tar xzf /backup/proxygate-backup-*.tar.gz"
docker compose up -d
```

---

## Docs

| Doc | Content |
|-----|---------|
| [Architecture](POOL_DESIGN.md) | State machine, data model, selection strategy |
| [Geo Filter](GEO_FILTER.md) | Country codes, whitelist/blacklist |
| [Data Directory](DATA_DIRECTORY.md) | Tables, config, backup |
| [Changelog](CHANGELOG.md) | Version history |

## License

[MIT](LICENSE) | Inspired by [isboyjc/GoProxy](https://github.com/isboyjc/GoProxy)
