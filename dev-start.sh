#!/bin/bash
# OpenClaw 开发模式启动脚本
#
# 用法：
#   ./dev-start.sh                    # 启动所有服务（开发模式）
#   ./dev-start.sh <service-name>     # 启动指定服务
#   ./dev-start.sh restart <service>  # 重启指定服务（应用代码修改）
#
# 功能：
#   - 自动挂载本地代码目录
#   - 修改代码后重启容器即可生效
#   - Go 项目会在容器内重新编译
#   - Node.js 项目直接使用最新代码

set -e

cd "$(dirname "$0")"

# 检查 DEV_MODE
if [ -f .env ]; then
  source .env
fi

if [ "${DEV_MODE}" != "true" ]; then
  echo "❌ 开发模式未启用"
  echo "请在 .env 中设置 DEV_MODE=true"
  exit 1
fi

echo "=========================================="
echo "OpenClaw 开发模式"
echo "=========================================="
echo ""

# 检查本地代码目录
check_dir() {
  local dir=$1
  local name=$2
  if [ ! -d "$dir" ]; then
    echo "⚠️  警告: $name 代码目录不存在: $dir"
    return 1
  fi
  echo "✅ $name: $dir"
  return 0
}

echo "检查本地代码目录..."
check_dir ~/Documents/codedev/traffic-ai "Traffic AI"
check_dir ~/Documents/codedev/claw_plugin_manager "Plugin Manager"
check_dir ~/Documents/codedev/claw_credential_manager "Credential Manager"
echo ""

# 执行命令
if [ "$1" = "restart" ]; then
  if [ -z "$2" ]; then
    echo "用法: $0 restart <service-name>"
    exit 1
  fi
  echo "重启服务: $2"
  podman-compose restart "$2"
  echo ""
  echo "✅ 服务已重启，新代码已生效"
  echo "查看日志: podman logs -f $2"
elif [ "$1" = "logs" ]; then
  service=${2:-}
  if [ -z "$service" ]; then
    podman-compose logs -f
  else
    podman logs -f "$service"
  fi
elif [ "$1" = "rebuild" ]; then
  if [ -z "$2" ]; then
    echo "用法: $0 rebuild <service-name>"
    exit 1
  fi
  echo "重新构建并重启: $2"
  podman-compose build "$2"
  podman-compose up -d "$2"
  echo "✅ 已重新构建并启动"
else
  # 启动服务
  if [ -n "$1" ]; then
    echo "启动服务: $1"
    podman-compose up -d "$1"
  else
    echo "启动所有服务（开发模式）..."
    podman-compose up -d
  fi
  echo ""
  echo "✅ 服务已启动"
  echo ""
  echo "常用命令："
  echo "  $0 restart <service>   # 重启服务应用代码修改"
  echo "  $0 logs <service>      # 查看日志"
  echo "  podman-compose ps      # 查看服务状态"
fi
