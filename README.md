# ProxyGate

[简体中文](README.md) | [English](README_EN.md)

> **自托管代理网关** — 聚合公开代理与订阅节点，统一验证入池，通过 HTTP/SOCKS5 网关输出，支持会话粘性与地域筛选

[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Go Version](https://img.shields.io/badge/Go-1.25-00ADD8?logo=go)](https://go.dev/)

---

## 服务器部署（Docker）

### 方式一：本地构建镜像 → 导出 → 上传服务器（推荐，无需注册仓库）

```bash
# 1. 在本地机器上构建镜像
docker compose -f docker-compose.yml -f docker-compose.build.yml build

# 2. 导出为 tar 文件
docker save proxygate:local -o proxygate.tar

# 3. 上传到服务器（任选一种）
scp proxygate.tar docker-compose.yml root@你的服务器IP:/opt/proxygate/

# 4. 在服务器上加载并启动
ssh root@你的服务器IP
cd /opt/proxygate
docker load -i proxygate.tar
docker compose up -d

# 5. 访问 WebUI
# http://你的服务器IP:7778（默认密码：proxygate）
```

### 方式二：推送到容器仓库 → 服务器拉取

```bash
# 1. 构建并打标签
docker compose -f docker-compose.yml -f docker-compose.build.yml build
docker tag proxygate:local 你的用户名/proxygate:latest

# 2. 推送到 Docker Hub 或 GHCR
docker push 你的用户名/proxygate:latest

# 3. 在服务器上拉取运行
# 先修改 docker-compose.yml 中的 image 为 你的用户名/proxygate:latest
docker compose up -d
```

### 方式三：服务器上直接构建

```bash
# 服务器上需要安装 Docker
git clone <repo-url> && cd proxygate
docker compose -f docker-compose.yml -f docker-compose.build.yml up -d --build
```

### 部署后首次配置

1. 浏览器访问 `http://你的服务器IP:7778`，用默认密码 `proxygate` 登录
2. 点击右上角齿轮 → **修改管理密码**
3. 在设置面板中配置：代理认证、地理过滤、代理源等（**全部在 WebUI 完成，无需编辑 .env**）
4. 若需配置 HTTPS，建议在服务器上用 nginx/caddy 反代 `:7778` 端口

### 方式四：推送到 GitHub Container Registry（自动构建+分享）

项目自带 GitHub Actions 工作流，推送代码到 GitHub 后自动构建多架构镜像并发布到 GHCR。

```bash
# 1. Fork 本仓库到你的 GitHub 账号
# 2. 推送你的代码
git push origin main

# 3. GitHub Actions 自动构建 amd64 + arm64 镜像，发布到
#    ghcr.io/你的用户名/proxygate:latest

# 4. 在 .env 中设置（或直接修改 docker-compose.yml）
echo 'PROXYGATE_IMAGE=ghcr.io/你的用户名/proxygate:latest' >> .env
echo 'PROXYGATE_PULL_POLICY=always' >> .env

# 5. 服务器上直接拉取运行
docker compose up -d
```

镜像默认 **公开**。要设为私有：GitHub → 你的 fork → Packages → 选择 proxygate → Package Settings → Change visibility。

### 方式五：自建 Docker Registry（完全自主，不依赖第三方）

域名解析到服务器后，一个命令启动仓库，然后本地推送即可。

```bash
# 1. 域名添加 A 记录: registry.你的域名.com → 服务器IP

# 2. 服务器上启动 Registry
scp deploy/registry.yml root@服务器:/opt/registry/
ssh root@服务器 "cd /opt/registry && docker compose -f registry.yml up -d"

# 3. 本地构建并推送
docker compose -f docker-compose.yml -f docker-compose.build.yml build
docker tag proxygate:local registry.你的域名.com:5000/proxygate:latest
docker push registry.你的域名.com:5000/proxygate:latest

# 4. 任何人拉取
docker pull registry.你的域名.com:5000/proxygate:latest
```

---

## 核心特性

- **双池架构**：免费代理池（30+ 公开源自动抓取）+ 订阅代理池（Clash/V2ray 导入，sing-box 自动转换加密协议）
- **5 种代理模式**：混合（订阅优先/免费优先/平等）、仅订阅、仅免费
- **4 端口输出**：HTTP 随机(:7777) / HTTP 低延迟(:7776) / SOCKS5 随机(:7779) / SOCKS5 低延迟(:7780)
- **全配置 WebUI 化**：所有设置（代理认证、多用户、代理源、池子参数、地理过滤）在面板中完成
- **多用户代理认证**：支持创建多个用户名/密码，各自独立管理
- **会话粘性**：认证用户名支持 `region`/`st`/`sid`/`t` 扩展参数
- **自动运维**：智能抓取、健康检查、延迟优化、故障自愈、速率保护
- **企业级安全**：登录暴力破解保护、审计日志、API Key 管理

---

## 端口一览

| 端口 | 协议 | 模式 | 用途 |
|------|------|------|------|
| 7776 | HTTP | 最低延迟 | 长连接、流媒体 |
| 7777 | HTTP | 随机轮换 | 爬虫、IP 多样性 |
| 7779 | SOCKS5 | 随机轮换 | 浏览器、SSH |
| 7780 | SOCKS5 | 最低延迟 | 稳定连接 |
| 7778 | HTTP | WebUI | 管理面板 |

---

## 使用代理

```bash
# HTTP 代理
curl -x http://服务器IP:7777 https://httpbin.org/ip

# SOCKS5 代理（远程 DNS 解析）
curl --socks5-hostname 服务器IP:7779 https://httpbin.org/ip

# 带认证
curl -x http://用户名:密码@服务器IP:7777 https://httpbin.org/ip

# 会话粘性 + 地域筛选
curl -x http://proxy-region-US-sid-job001-t-30:密码@服务器IP:7777 https://httpbin.org/ip
```

认证用户名扩展参数：`<username>-region-<国家码>-st-<城市>-sid-<会话ID>-t-<TTL分钟>`

---

## 订阅导入

管理员登录后通过 WebUI 管理订阅：
- **订阅 URL** — 填入 Clash/V2ray 地址，自动识别格式
- **上传文件** — 拖拽 Clash YAML / V2ray 配置文件
- 支持的加密协议：vmess、vless、trojan、shadowsocks、hysteria2、anytls（Docker 内置 sing-box 自动转换）
- 新节点先验证后激活，失败节点保留并定时探测恢复

---

## WebUI 系统设置

管理员登录后，点击右上角齿轮进入设置面板，所有配置**无需编辑 .env 文件**：

| 设置区块 | 内容 |
|---------|------|
| 代理模式 | 混合（订阅优先/免费优先/平等）、仅订阅、仅免费 |
| 免费代理池 | 容量、HTTP 占比、延迟阈值、优化间隔 |
| 订阅代理池 | 探测间隔、默认刷新间隔 |
| 验证与检查 | 并发数、超时、检查间隔、验证 URL |
| 地理过滤 | 允许国家（白名单）/ 屏蔽国家（黑名单） |
| 代理认证 | 启用开关、用户名、密码、本地绕行 |
| 用户管理 | 添加多个代理认证用户 |
| 管理密码 | WebUI 登录密码修改 |

环境变量（`.env`）仅作为初始默认值，首次启动后全部通过 WebUI 管理并持久化到 `config.json`。

---

## 环境变量参考

以下变量可在首次启动时通过 `.env` 或 `docker run -e` 设置，之后建议在 WebUI 中管理：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `WEBUI_PASSWORD` | `proxygate` | WebUI 登录密码 |
| `PROXY_AUTH_ENABLED` | `false` | 代理认证开关 |
| `PROXY_AUTH_USERNAME` | `proxy` | 单用户认证用户名 |
| `PROXY_AUTH_PASSWORD` | 空 | 单用户认证密码 |
| `BLOCKED_COUNTRIES` | `CN` | 屏蔽国家（逗号分隔） |
| `ALLOWED_COUNTRIES` | 空 | 允许国家白名单 |
| `CUSTOM_PROXY_MODE` | `mixed` | 代理模式 |
| `DATA_DIR` | 空 | 数据目录 |
| `TZ` | `Asia/Shanghai` | 时区 |

---

## 数据管理

Docker 部署使用 Named Volume 持久化数据，容器重启/更新不丢失。

```bash
# 备份
docker run --rm -v proxygate-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/proxygate-backup-$(date +%Y%m%d).tar.gz -C /data .

# 恢复
docker compose down
docker run --rm -v proxygate-data:/data -v $(pwd):/backup \
  alpine sh -c "cd /data && tar xzf /backup/proxygate-backup-*.tar.gz"
docker compose up -d

# 也可通过 WebUI 管理员访问 /api/backup 下载数据库
```

---

## 本地开发

```bash
# 需要 Go 1.25 + CGO（gcc）
cp .env.example .env
go mod download
go run .
```

---

## 扩展文档

| 文档 | 内容 |
|------|------|
| [架构设计](POOL_DESIGN.md) | 状态机、数据模型、选择策略 |
| [地理过滤](GEO_FILTER.md) | 国家代码、白名单/黑名单 |
| [数据目录](DATA_DIRECTORY.md) | 数据库表结构、备份恢复 |
| [更新日志](CHANGELOG.md) | 版本历史 |

---

## 免责声明

本项目仅供学习交流和技术研究使用。代理来自互联网公开资源，不保证可用性。请遵守当地法律法规。

## License

[MIT](LICENSE) | 灵感来源 [isboyjc/GoProxy](https://github.com/isboyjc/GoProxy)
