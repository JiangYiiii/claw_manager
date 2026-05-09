#!/bin/bash
# OpenClaw Manager 初始化脚本
# 用途：首次运行，初始化环境和配置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔════════════════════════════════════════╗"
echo "║   OpenClaw Manager 初始化向导          ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

# ============================================
# 1. 检查依赖
# ============================================
echo -e "${YELLOW}[1/6] 检查系统依赖...${NC}"

REQUIRED_CMDS=("podman" "git" "curl")
MISSING_CMDS=()

for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING_CMDS+=("$cmd")
    fi
done

if [ ${#MISSING_CMDS[@]} -ne 0 ]; then
    echo -e "${RED}✗ 缺少必要命令: ${MISSING_CMDS[*]}${NC}"
    echo "请先安装缺失的命令"
    exit 1
fi

echo -e "${GREEN}✓ 系统依赖检查通过${NC}"

# ============================================
# 2. 检查 .env 文件
# ============================================
echo -e "\n${YELLOW}[2/6] 配置环境变量...${NC}"

if [ ! -f .env ]; then
    echo "创建 .env 文件..."
    cp .env.example .env

    # 生成随机 token
    ADMIN_TOKEN=$(openssl rand -hex 32)
    CRED_TOKEN=$(openssl rand -hex 32)

    # 更新 .env 文件
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/ADMIN_TOKEN=.*/ADMIN_TOKEN=${ADMIN_TOKEN}/" .env
        sed -i '' "s/CRED_TOKEN=.*/CRED_TOKEN=${CRED_TOKEN}/" .env
    else
        sed -i "s/ADMIN_TOKEN=.*/ADMIN_TOKEN=${ADMIN_TOKEN}/" .env
        sed -i "s/CRED_TOKEN=.*/CRED_TOKEN=${CRED_TOKEN}/" .env
    fi

    echo -e "${GREEN}✓ 已生成 .env 文件${NC}"
    echo -e "${YELLOW}⚠️  请编辑 .env 文件，配置 Git 仓库地址！${NC}"
    echo ""

    # 提示用户配置 Git 仓库
    echo "需要配置以下 Git 仓库地址："
    echo "  - TRAFFIC_AI_REPO"
    echo "  - PLUGIN_MANAGER_REPO"
    echo "  - CREDENTIAL_MANAGER_REPO"
    echo ""
    read -p "是否现在编辑 .env 文件？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ${EDITOR:-nano} .env
    else
        echo -e "${YELLOW}请稍后手动编辑 .env 文件${NC}"
        exit 0
    fi
else
    echo -e "${GREEN}✓ .env 文件已存在${NC}"
fi

# 加载环境变量
source .env

# 验证关键配置
if [[ -z "$TRAFFIC_AI_REPO" ]] || [[ "$TRAFFIC_AI_REPO" == *"YOUR_ORG"* ]]; then
    echo -e "${RED}✗ 请先在 .env 中配置正确的 Git 仓库地址${NC}"
    exit 1
fi

# ============================================
# 3. 创建 Podman 网络
# ============================================
echo -e "\n${YELLOW}[3/6] 创建 Podman 网络...${NC}"

if podman network exists openclaw 2>/dev/null; then
    echo -e "${GREEN}✓ 网络 openclaw 已存在${NC}"
else
    podman network create openclaw
    echo -e "${GREEN}✓ 已创建网络 openclaw${NC}"
fi

# ============================================
# 4. 测试 Git 仓库访问
# ============================================
echo -e "\n${YELLOW}[4/6] 测试 Git 仓库访问...${NC}"

test_git_access() {
    local repo=$1
    local name=$2

    echo -n "  测试 $name... "
    if git ls-remote "$repo" &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

REPOS_OK=true
test_git_access "$TRAFFIC_AI_REPO" "Traffic AI" || REPOS_OK=false
test_git_access "$PLUGIN_MANAGER_REPO" "Plugin Manager" || REPOS_OK=false
test_git_access "$CREDENTIAL_MANAGER_REPO" "Credential Manager" || REPOS_OK=false

if [ "$REPOS_OK" = false ]; then
    echo -e "\n${YELLOW}⚠️  部分仓库无法访问${NC}"
    echo "如果是私有仓库，请配置 GIT_TOKEN 或 SSH Key"
    read -p "是否继续？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# ============================================
# 5. 构建镜像
# ============================================
echo -e "\n${YELLOW}[5/6] 构建 Docker 镜像...${NC}"
echo "这可能需要几分钟，请耐心等待..."
echo ""

read -p "是否现在构建镜像？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    podman-compose build
    echo -e "${GREEN}✓ 镜像构建完成${NC}"
else
    echo -e "${YELLOW}跳过镜像构建，稍后可运行: podman-compose build${NC}"
fi

# ============================================
# 6. 生成摘要
# ============================================
echo -e "\n${YELLOW}[6/6] 生成配置摘要...${NC}"

cat > .init-summary.txt <<EOF
OpenClaw Manager 初始化完成
初始化时间: $(date)

配置信息:
- 管理员 Token: ${ADMIN_TOKEN}
- 凭证 Token:   ${CRED_TOKEN}

服务端口:
- Traffic AI Console:    http://localhost:${TRAFFIC_AI_CONSOLE_PORT:-3001}
- Traffic AI Admin:      http://localhost:${TRAFFIC_AI_ADMIN_PORT:-3002}
- Plugin Manager:        http://localhost:${PLUGIN_MANAGER_PORT:-8001}
- Credential Manager:    http://localhost:${CREDENTIAL_MANAGER_PORT:-8002}

下一步:
1. 启动服务: ./scripts/start.sh
2. 查看状态: podman-compose ps
3. 查看日志: podman-compose logs -f

注意: 请妥善保管 Token，避免泄露！
EOF

echo -e "${GREEN}✓ 配置摘要已保存到 .init-summary.txt${NC}"

# ============================================
# 完成
# ============================================
echo ""
echo -e "${GREEN}"
echo "╔════════════════════════════════════════╗"
echo "║        ✓ 初始化完成！                  ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo -e "${BLUE}📋 下一步操作：${NC}"
echo "  1. 启动所有服务:"
echo -e "     ${GREEN}./scripts/start.sh${NC}"
echo ""
echo "  2. 查看服务状态:"
echo -e "     ${GREEN}podman-compose ps${NC}"
echo ""
echo "  3. 查看配置摘要:"
echo -e "     ${GREEN}cat .init-summary.txt${NC}"
echo ""

echo -e "${YELLOW}🔐 重要提醒：${NC}"
echo "  Token 信息已保存在 .env 和 .init-summary.txt 中"
echo "  请妥善保管这些文件，不要提交到 Git 仓库！"
echo ""
