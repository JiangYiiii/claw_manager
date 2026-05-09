#!/bin/bash
# OpenClaw - 重建所有服务并从 Git 拉取最新代码
#
# 用法：
#   ./rebuild-all.sh                    # 重建所有服务
#   ./rebuild-all.sh <service-name>     # 仅重建指定服务
#   ./rebuild-all.sh --no-cache         # 完全重建（不使用缓存）
#
# 功能：
#   - 从 Git 仓库拉取最新代码
#   - 重新构建 Docker 镜像
#   - 重启服务应用最新代码

set -e

cd "$(dirname "$0")"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "OpenClaw - 重建服务并更新代码"
echo "=========================================="
echo ""

# 检查是否在开发模式
if [ -f .env ]; then
  source .env
fi

if [ "${DEV_MODE}" = "true" ]; then
  echo -e "${YELLOW}⚠️  警告：当前处于开发模式 (DEV_MODE=true)${NC}"
  echo "开发模式下会挂载本地代码，重建镜像仍会从 Git 拉取但本地代码优先"
  echo ""
  read -p "是否继续？(y/N) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
  fi
fi

# 解析参数
NO_CACHE=""
SERVICE=""

for arg in "$@"; do
  case $arg in
    --no-cache)
      NO_CACHE="--no-cache"
      shift
      ;;
    *)
      SERVICE="$arg"
      ;;
  esac
done

# 需要重建的服务列表
if [ -n "$SERVICE" ]; then
  SERVICES=("$SERVICE")
else
  SERVICES=(
    "traffic-ai-control"
    "traffic-ai-gateway"
    "claw-plugin-manager"
    "claw-credential-manager"
  )
fi

# 生成新的 CACHEBUST 值强制重新克隆
CACHEBUST=$(date +%s)

echo -e "${BLUE}=== 重建配置 ===${NC}"
echo "服务: ${SERVICES[*]}"
echo "CACHEBUST: $CACHEBUST"
[ -n "$NO_CACHE" ] && echo "模式: 完全重建（不使用缓存）" || echo "模式: 增量构建"
echo ""

# 停止服务
echo -e "${YELLOW}=== 停止服务 ===${NC}"
for service in "${SERVICES[@]}"; do
  echo "停止 $service..."
  podman-compose down "$service" 2>/dev/null || true
done
echo ""

# 重建镜像
echo -e "${BLUE}=== 重建镜像（从 Git 拉取最新代码）===${NC}"
for service in "${SERVICES[@]}"; do
  echo ""
  echo -e "${GREEN}>>> 重建 $service${NC}"
  podman-compose build $NO_CACHE \
    --build-arg CACHEBUST=$CACHEBUST \
    "$service"

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ $service 构建成功${NC}"
  else
    echo -e "${RED}❌ $service 构建失败${NC}"
    exit 1
  fi
done

echo ""
echo -e "${BLUE}=== 启动服务 ===${NC}"
for service in "${SERVICES[@]}"; do
  echo "启动 $service..."
  podman-compose up -d "$service"
done

echo ""
echo -e "${GREEN}=========================================="
echo "✅ 所有服务已重建并启动"
echo "==========================================${NC}"
echo ""
echo "查看服务状态："
echo "  podman-compose ps"
echo ""
echo "查看日志："
echo "  podman logs -f <service-name>"
echo ""
echo "服务列表："
for service in "${SERVICES[@]}"; do
  echo "  - $service"
done
