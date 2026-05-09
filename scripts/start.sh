#!/bin/bash
# OpenClaw Manager 启动脚本

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
echo "║   启动 OpenClaw 服务                   ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

# 检查是否已初始化
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  未找到 .env 文件${NC}"
    echo "请先运行初始化脚本:"
    echo "  ./scripts/init.sh"
    exit 1
fi

# 加载环境变量
source .env

echo -e "${YELLOW}[1/4] 检查服务状态...${NC}"

# 检查端口占用
check_port() {
    local port=$1
    local service=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  端口 $port ($service) 已被占用${NC}"
        lsof -Pi :$port -sTCP:LISTEN
        return 1
    fi
    return 0
}

PORTS_OK=true
check_port ${CREDENTIAL_MANAGER_PORT:-8002} "Credential Manager" || PORTS_OK=false
check_port ${TRAFFIC_AI_CONSOLE_PORT:-3001} "Traffic AI Console" || PORTS_OK=false
check_port ${TRAFFIC_AI_ADMIN_PORT:-3002} "Traffic AI Admin" || PORTS_OK=false
check_port ${PLUGIN_MANAGER_PORT:-8001} "Plugin Manager" || PORTS_OK=false

if [ "$PORTS_OK" = false ]; then
    echo ""
    read -p "是否停止占用端口的进程？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        lsof -ti:${CREDENTIAL_MANAGER_PORT:-8002},${TRAFFIC_AI_CONSOLE_PORT:-3001},${TRAFFIC_AI_ADMIN_PORT:-3002},${PLUGIN_MANAGER_PORT:-8001} | xargs kill -9 2>/dev/null || true
        echo -e "${GREEN}✓ 已释放端口${NC}"
        sleep 2
    else
        echo -e "${YELLOW}请手动处理端口占用后重试${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ 端口检查通过${NC}"

# 启动服务
echo -e "\n${YELLOW}[2/4] 启动服务...${NC}"
echo "按启动顺序依次启动服务..."

# 1. 凭证管理器（最底层）
echo -e "\n  ${BLUE}→ 启动凭证管理器...${NC}"
podman-compose up -d claw-credential-manager

echo "     等待凭证管理器就绪..."
for i in {1..30}; do
    if curl -sf http://localhost:${CREDENTIAL_MANAGER_PORT:-8002}/health > /dev/null 2>&1; then
        echo -e "     ${GREEN}✓ 凭证管理器已就绪${NC}"
        break
    fi
    sleep 1
    if [ $i -eq 30 ]; then
        echo -e "     ${YELLOW}⚠️  凭证管理器启动超时，继续...${NC}"
    fi
done

# 2. Traffic AI
echo -e "\n  ${BLUE}→ 启动 Traffic AI 服务...${NC}"
podman-compose up -d traffic-ai-console traffic-ai-admin

echo "     等待 Traffic AI 就绪..."
sleep 5

# 3. 插件管理器
echo -e "\n  ${BLUE}→ 启动插件管理器...${NC}"
podman-compose up -d claw-plugin-manager

sleep 3

echo -e "${GREEN}✓ 所有服务已启动${NC}"

# 健康检查
echo -e "\n${YELLOW}[3/4] 健康检查...${NC}"

check_health() {
    local url=$1
    local name=$2
    echo -n "  检查 $name... "
    if curl -sf "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  (可能仍在启动中)${NC}"
        return 1
    fi
}

sleep 2
check_health "http://localhost:${CREDENTIAL_MANAGER_PORT:-8002}/health" "Credential Manager"
check_health "http://localhost:${TRAFFIC_AI_CONSOLE_PORT:-3001}/health" "Traffic AI Console"
check_health "http://localhost:${TRAFFIC_AI_ADMIN_PORT:-3002}/health" "Traffic AI Admin"
check_health "http://localhost:${PLUGIN_MANAGER_PORT:-8001}/health" "Plugin Manager"

# 显示服务信息
echo -e "\n${YELLOW}[4/4] 服务信息${NC}"
echo ""
podman-compose ps

echo ""
echo -e "${GREEN}"
echo "╔════════════════════════════════════════╗"
echo "║        ✓ 启动完成！                    ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo -e "${BLUE}🌐 服务地址：${NC}"
echo "  • Traffic AI Console:    ${GREEN}http://localhost:${TRAFFIC_AI_CONSOLE_PORT:-3001}${NC}"
echo "  • Traffic AI Admin:      ${GREEN}http://localhost:${TRAFFIC_AI_ADMIN_PORT:-3002}${NC}"
echo "  • Plugin Manager:        ${GREEN}http://localhost:${PLUGIN_MANAGER_PORT:-8001}${NC}"
echo "  • Credential Manager:    ${GREEN}http://localhost:${CREDENTIAL_MANAGER_PORT:-8002}${NC}"

echo ""
echo -e "${BLUE}📊 常用命令：${NC}"
echo "  • 查看状态:   ${GREEN}podman-compose ps${NC}"
echo "  • 查看日志:   ${GREEN}podman-compose logs -f [service-name]${NC}"
echo "  • 停止服务:   ${GREEN}./scripts/stop.sh${NC}"
echo "  • 重启服务:   ${GREEN}./scripts/restart.sh${NC}"
echo "  • 重新构建:   ${GREEN}./scripts/rebuild.sh${NC}"
echo ""
