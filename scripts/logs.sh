#!/bin/bash
# OpenClaw Manager 日志查看脚本

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

if [ -z "$1" ]; then
    echo "查看所有服务日志..."
    podman-compose logs -f --tail=100
else
    echo "查看 $1 服务日志..."
    podman-compose logs -f --tail=100 "$1"
fi
