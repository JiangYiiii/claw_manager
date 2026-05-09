#!/bin/bash
# OpenClaw Manager 停止脚本

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════╗"
echo "║   停止 OpenClaw 服务                   ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

echo "停止所有服务..."
podman-compose down

echo ""
echo -e "${GREEN}✓ 所有服务已停止${NC}"
echo ""
echo "提示: 重新启动请运行 ./scripts/start.sh"
