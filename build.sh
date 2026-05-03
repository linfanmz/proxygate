#!/bin/bash
# ProxyGate Docker 构建并导出脚本
# 用法: ./build.sh
# 输出: proxygate.tar (可直接上传到服务器)

set -e

IMAGE_NAME="${PROXYGATE_IMAGE:-proxygate}"
IMAGE_TAG="${PROXYGATE_TAG:-latest}"

echo "=== ProxyGate Docker 构建 ==="
echo "镜像: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""

# 构建镜像
echo "[1/3] 构建 Docker 镜像..."
docker compose -f docker-compose.yml -f docker-compose.build.yml build

# 统一标签（build compose 输出 proxygate:local，重命名为 latest）
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
echo "[2/3] 导出镜像到 proxygate.tar ..."
docker tag proxygate:local "${FULL_IMAGE}" 2>/dev/null || true
docker save "${FULL_IMAGE}" -o proxygate.tar

# 显示文件大小
SIZE=$(du -h proxygate.tar | cut -f1)
echo "[3/3] 完成!"
echo ""
echo "=== 导出文件 ==="
echo "  proxygate.tar (${SIZE})"
echo ""
echo "=== 上传到服务器 ==="
echo "  scp proxygate.tar docker-compose.yml root@你的服务器:/opt/proxygate/"
echo ""
echo "=== 服务器上执行 ==="
echo "  cd /opt/proxygate"
echo "  docker load -i proxygate.tar"
echo "  docker compose up -d"
echo ""
echo "=== 可选：推送到容器仓库 ==="
echo "  docker tag ${FULL_IMAGE} docker.io/你的用户名/proxygate:latest"
echo "  docker push docker.io/你的用户名/proxygate:latest"
