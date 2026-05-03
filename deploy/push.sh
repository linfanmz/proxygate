#!/bin/bash
# 构建并推送到自建 Registry
# 用法: ./deploy/push.sh registry.你的域名.com
set -e

REGISTRY="${1:-${REGISTRY_HOST}}"
if [ -z "$REGISTRY" ]; then
    echo "用法: ./deploy/push.sh registry.你的域名.com"
    exit 1
fi

IMAGE="${REGISTRY}:5000/proxygate:latest"

echo ">>> ${IMAGE}"
docker compose -f docker-compose.yml -f docker-compose.build.yml build
docker tag proxygate:local "${IMAGE}"
docker push "${IMAGE}"
echo ">>> 完成: docker pull ${IMAGE}"
