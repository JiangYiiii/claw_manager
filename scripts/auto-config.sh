#!/bin/bash
# 自动从本地项目读取 Git 远程地址并生成 .env 文件

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
CODEDEV_DIR="$( cd "$PROJECT_ROOT/.." && pwd )"

cd "$PROJECT_ROOT"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════╗"
echo "║   自动配置 Git 仓库地址                ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}\n"

# 检测项目目录和 Git 远程地址
echo -e "${YELLOW}[1/3] 检测本地项目...${NC}"

# Traffic AI
if [ -d "${CODEDEV_DIR}/traffic-ai" ]; then
    TRAFFIC_AI_REPO=$(cd "${CODEDEV_DIR}/traffic-ai" && git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$TRAFFIC_AI_REPO" ]; then
        echo -e "  ${GREEN}✓${NC} Traffic AI: $TRAFFIC_AI_REPO"
    else
        echo -e "  ${YELLOW}⚠${NC}  Traffic AI: 未找到 Git 远程地址"
    fi
else
    echo -e "  ${YELLOW}⚠${NC}  Traffic AI: 目录不存在"
fi

# Plugin Manager
if [ -d "${CODEDEV_DIR}/claw_plugin_manager" ]; then
    PLUGIN_MANAGER_REPO=$(cd "${CODEDEV_DIR}/claw_plugin_manager" && git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$PLUGIN_MANAGER_REPO" ]; then
        echo -e "  ${GREEN}✓${NC} Plugin Manager: $PLUGIN_MANAGER_REPO"
    else
        echo -e "  ${YELLOW}⚠${NC}  Plugin Manager: 未找到 Git 远程地址"
    fi
else
    echo -e "  ${YELLOW}⚠${NC}  Plugin Manager: 目录不存在"
fi

# Credential Manager
if [ -d "${CODEDEV_DIR}/claw_credential_manager" ]; then
    CREDENTIAL_MANAGER_REPO=$(cd "${CODEDEV_DIR}/claw_credential_manager" && git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$CREDENTIAL_MANAGER_REPO" ]; then
        echo -e "  ${GREEN}✓${NC} Credential Manager: $CREDENTIAL_MANAGER_REPO"
    else
        echo -e "  ${YELLOW}⚠${NC}  Credential Manager: 未找到 Git 远程地址"
    fi
else
    echo -e "  ${YELLOW}⚠${NC}  Credential Manager: 目录不存在"
fi

# 检查是否都找到了
if [ -z "$TRAFFIC_AI_REPO" ] || [ -z "$PLUGIN_MANAGER_REPO" ] || [ -z "$CREDENTIAL_MANAGER_REPO" ]; then
    echo ""
    echo -e "${YELLOW}部分项目未找到 Git 远程地址${NC}"
    echo "请确保以下目录存在且已初始化 Git："
    [ -z "$TRAFFIC_AI_REPO" ] && echo "  - ${CODEDEV_DIR}/traffic-ai"
    [ -z "$PLUGIN_MANAGER_REPO" ] && echo "  - ${CODEDEV_DIR}/claw_plugin_manager"
    [ -z "$CREDENTIAL_MANAGER_REPO" ] && echo "  - ${CODEDEV_DIR}/claw_credential_manager"
    exit 1
fi

# 生成 .env 文件
echo -e "\n${YELLOW}[2/3] 生成 .env 文件...${NC}"

if [ -f .env ]; then
    echo -e "  ${YELLOW}⚠${NC}  .env 文件已存在"
    read -p "是否覆盖？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "已取消"
        exit 0
    fi
    # 备份现有文件
    cp .env .env.backup-$(date +%Y%m%d-%H%M%S)
    echo "  已备份到 .env.backup-$(date +%Y%m%d-%H%M%S)"
fi

# 生成随机 Token
ADMIN_TOKEN=$(openssl rand -hex 32)
CRED_TOKEN=$(openssl rand -hex 32)

# 创建 .env 文件
cat > .env <<EOF
# OpenClaw Manager 环境变量配置
# 自动生成时间: $(date)

# ============ 版本管理 ============
VERSION=latest

# ============ Git 仓库配置 ============
# Traffic AI
TRAFFIC_AI_REPO=${TRAFFIC_AI_REPO}
TRAFFIC_AI_BRANCH=main

# Plugin Manager
PLUGIN_MANAGER_REPO=${PLUGIN_MANAGER_REPO}
PLUGIN_MANAGER_BRANCH=main

# Credential Manager
CREDENTIAL_MANAGER_REPO=${CREDENTIAL_MANAGER_REPO}
CREDENTIAL_MANAGER_BRANCH=main

# ============ 服务端口 ============
TRAFFIC_AI_CONSOLE_PORT=3001
TRAFFIC_AI_ADMIN_PORT=3002
PLUGIN_MANAGER_PORT=18091
PLUGIN_MANAGER_WEB_PORT=19000
CREDENTIAL_MANAGER_PORT=8002
DASHBOARD_PORT=9000

# ============ OpenClaw 配置 ============
OPENCLAW_HOME=\${HOME}/.openclaw

# ============ 安全凭证 ============
# 自动生成的 Token（请妥善保管）
ADMIN_TOKEN=${ADMIN_TOKEN}
CRED_TOKEN=${CRED_TOKEN}

# ============ 构建参数 ============
DOCKER_BUILDKIT=1

# Git 凭证（私有仓库需要）
# 如果是公开仓库，留空即可
GIT_TOKEN=
EOF

echo -e "  ${GREEN}✓${NC} .env 文件已生成"

# 显示摘要
echo -e "\n${YELLOW}[3/3] 配置摘要${NC}"
echo ""
echo -e "${BLUE}Git 仓库配置:${NC}"
echo "  Traffic AI:          ${TRAFFIC_AI_REPO}"
echo "  Plugin Manager:      ${PLUGIN_MANAGER_REPO}"
echo "  Credential Manager:  ${CREDENTIAL_MANAGER_REPO}"
echo ""
echo -e "${BLUE}生成的安全凭证:${NC}"
echo "  ADMIN_TOKEN: ${ADMIN_TOKEN}"
echo "  CRED_TOKEN:  ${CRED_TOKEN}"
echo ""
echo -e "${YELLOW}⚠️  重要提示:${NC}"
echo "  1. Token 已保存在 .env 文件中，请妥善保管"
echo "  2. 如果是私有仓库，请在 .env 中配置 GIT_TOKEN"
echo "  3. .env 文件已被 .gitignore 忽略，不会提交到 Git"
echo ""

# 检查是否是私有仓库（简单判断）
if [[ "$TRAFFIC_AI_REPO" =~ ^git@github\.com:.*\.git$ ]] || [[ "$TRAFFIC_AI_REPO" =~ ^https://github\.com/.*/.*/.*\.git$ ]]; then
    echo -e "${BLUE}下一步:${NC}"
    echo "  1. 如果是私有仓库，配置 Git 访问凭证:"
    echo "     vim .env  # 添加 GIT_TOKEN=your_token"
    echo ""
    echo "  2. 运行初始化脚本:"
    echo "     ./scripts/init.sh"
else
    echo -e "${GREEN}✓ 配置完成！${NC}"
    echo ""
    echo -e "${BLUE}下一步: 运行初始化脚本${NC}"
    echo "  ./scripts/init.sh"
fi
