#!/bin/bash
# 快速更新：从 Git 拉取最新代码、重建镜像并重启
#
# 用法：
#   ./update.sh                       # 更新所有服务
#   ./update.sh claw-plugin-manager   # 只更新指定服务（可多个）
#
# 说明：
# - 使用 CACHEBUST=$(date +%s) 强制 Dockerfile 中的 git clone 步骤失效缓存。
# - 通过 --build-arg http_proxy= 等清空构建期代理，避免 podman machine 中
#   遗留的 HTTP_PROXY=host.containers.internal:7890 在宿主机未起代理时拖死 git clone。
# - 重启使用 --no-deps --force-recreate，只动目标服务，不连带其他容器。

set -e
cd "$(dirname "$0")"

SERVICES=("$@")
CACHEBUST=$(date +%s)

PROXY_ARGS=(
  --build-arg "http_proxy="
  --build-arg "https_proxy="
  --build-arg "HTTP_PROXY="
  --build-arg "HTTPS_PROXY="
  --build-arg "CACHEBUST=$CACHEBUST"
)

if [ ${#SERVICES[@]} -eq 0 ]; then
  echo "🔄 更新所有服务（CACHEBUST=$CACHEBUST）..."
  echo ""
  podman-compose build "${PROXY_ARGS[@]}"
  podman-compose down
  podman-compose up -d
else
  echo "🔄 更新服务: ${SERVICES[*]}（CACHEBUST=$CACHEBUST）..."
  echo ""
  podman-compose build "${PROXY_ARGS[@]}" "${SERVICES[@]}"
  podman-compose up -d --no-deps --force-recreate "${SERVICES[@]}"
fi

echo ""
echo "✅ 更新完成！"
echo ""
echo "查看状态: podman-compose ps"
echo "查看日志: podman logs -f <service-name>"
