#!/bin/bash
# 验证配置和环境的脚本

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════╗"
echo "║   OpenClaw Manager 配置验证            ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}\n"

# 检查文件结构
echo -e "${YELLOW}[1/4] 检查文件结构...${NC}"

FILES=(
    ".env.example"
    ".gitignore"
    "README.md"
    "docker-compose.yml"
    "config/repos.json"
    "dockerfiles/traffic-ai.Dockerfile"
    "dockerfiles/plugin-manager.Dockerfile"
    "dockerfiles/credential-manager.Dockerfile"
    "scripts/init.sh"
    "scripts/start.sh"
    "scripts/stop.sh"
    "scripts/rebuild.sh"
    "scripts/logs.sh"
)

ALL_OK=true
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file (缺失)"
        ALL_OK=false
    fi
done

if [ "$ALL_OK" = false ]; then
    echo -e "\n${RED}部分文件缺失，请检查！${NC}"
    exit 1
fi

# 检查脚本权限
echo -e "\n${YELLOW}[2/4] 检查脚本权限...${NC}"

for script in scripts/*.sh; do
    if [ -x "$script" ]; then
        echo -e "  ${GREEN}✓${NC} $(basename $script) 可执行"
    else
        echo -e "  ${YELLOW}⚠${NC}  $(basename $script) 无执行权限，正在修复..."
        chmod +x "$script"
    fi
done

# 检查 .env 配置
echo -e "\n${YELLOW}[3/4] 检查配置文件...${NC}"

if [ -f .env ]; then
    source .env
    echo -e "  ${GREEN}✓${NC} .env 文件存在"

    # 检查必要的配置
    if [[ -z "$TRAFFIC_AI_REPO" ]] || [[ "$TRAFFIC_AI_REPO" == *"YOUR_ORG"* ]]; then
        echo -e "  ${RED}✗${NC} TRAFFIC_AI_REPO 未配置"
        ALL_OK=false
    else
        echo -e "  ${GREEN}✓${NC} TRAFFIC_AI_REPO 已配置"
    fi

    if [[ -z "$PLUGIN_MANAGER_REPO" ]] || [[ "$PLUGIN_MANAGER_REPO" == *"YOUR_ORG"* ]]; then
        echo -e "  ${RED}✗${NC} PLUGIN_MANAGER_REPO 未配置"
        ALL_OK=false
    else
        echo -e "  ${GREEN}✓${NC} PLUGIN_MANAGER_REPO 已配置"
    fi

    if [[ -z "$CREDENTIAL_MANAGER_REPO" ]] || [[ "$CREDENTIAL_MANAGER_REPO" == *"YOUR_ORG"* ]]; then
        echo -e "  ${RED}✗${NC} CREDENTIAL_MANAGER_REPO 未配置"
        ALL_OK=false
    else
        echo -e "  ${GREEN}✓${NC} CREDENTIAL_MANAGER_REPO 已配置"
    fi

else
    echo -e "  ${YELLOW}⚠${NC}  .env 文件不存在（首次运行请执行 ./scripts/init.sh）"
fi

# 检查系统依赖
echo -e "\n${YELLOW}[4/4] 检查系统依赖...${NC}"

DEPS=("podman" "git" "curl")
for dep in "${DEPS[@]}"; do
    if command -v "$dep" &> /dev/null; then
        VERSION=$(podman --version 2>/dev/null || git --version 2>/dev/null || curl --version 2>/dev/null | head -1)
        echo -e "  ${GREEN}✓${NC} $dep (${VERSION})"
    else
        echo -e "  ${RED}✗${NC} $dep 未安装"
        ALL_OK=false
    fi
done

# 总结
echo ""
if [ "$ALL_OK" = true ]; then
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════╗"
    echo "║        ✓ 验证通过！                    ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}\n"

    if [ ! -f .env ]; then
        echo -e "${BLUE}下一步：运行初始化脚本${NC}"
        echo "  ./scripts/init.sh"
    else
        echo -e "${BLUE}下一步：启动服务${NC}"
        echo "  ./scripts/start.sh"
    fi
else
    echo -e "${RED}"
    echo "╔════════════════════════════════════════╗"
    echo "║        ✗ 验证失败！                    ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}\n"
    echo "请根据上述提示修复问题后重试"
    exit 1
fi
