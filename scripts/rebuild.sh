#!/bin/bash
# OpenClaw Manager 重新构建脚本
# 从 Git 拉取最新代码并重新构建镜像

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════╗"
echo "║   重新构建 OpenClaw 服务镜像           ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

# 加载环境变量
if [ -f .env ]; then
    source .env
fi

echo -e "${YELLOW}此操作将：${NC}"
echo "  1. 从 Git 拉取最新代码"
echo "  2. 重新构建所有镜像（不使用缓存）"
echo "  3. 重启服务使用新镜像"
echo ""

read -p "是否继续？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

# 停止现有服务
echo -e "\n${YELLOW}[1/4] 停止现有服务...${NC}"
podman-compose down

# 清理旧镜像（可选）
read -p "是否清理旧镜像以释放空间？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "清理未使用的镜像..."
    podman image prune -f
fi

# 重新构建镜像
echo -e "\n${YELLOW}[2/4] 重新构建镜像...${NC}"
echo "从 Git 拉取最新代码并构建（不使用缓存）..."
podman-compose build --no-cache

echo -e "${GREEN}✓ 镜像构建完成${NC}"

# 启动服务
echo -e "\n${YELLOW}[3/4] 启动服务...${NC}"
./scripts/start.sh

# 验证
echo -e "\n${YELLOW}[4/4] 验证服务版本...${NC}"

echo "检查各服务的 Git commit..."
podman exec claw-credential-manager sh -c "cat /app/.git/refs/heads/main 2>/dev/null || echo 'N/A'" | head -c 8
echo " - Credential Manager"

podman exec traffic-ai-console sh -c "cat /app/.git/refs/heads/main 2>/dev/null || echo 'N/A'" | head -c 8
echo " - Traffic AI Console"

podman exec claw-plugin-manager sh -c "cat /app/.git/refs/heads/main 2>/dev/null || echo 'N/A'" | head -c 8
echo " - Plugin Manager"

echo ""
echo -e "${GREEN}"
echo "╔════════════════════════════════════════╗"
echo "║        ✓ 重新构建完成！                ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"
