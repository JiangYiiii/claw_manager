# OpenClaw Manager

统一管理 OpenClaw 相关服务的容器化解决方案。

## 🎯 功能特性

- **一键启动** - 通过 `./scripts/start.sh` 启动所有服务
- **从 Git 构建** - 镜像构建时从 Git 仓库拉取最新稳定代码
- **版本管理** - 支持指定分支/标签构建特定版本
- **服务编排** - 自动处理服务依赖和启动顺序
- **健康检查** - 内置健康检查和状态监控

## 📦 包含服务

| 服务 | 端口 | 说明 |
|------|------|------|
| **Traffic AI Console** | 3001 | 模型代理服务 - 用户端 |
| **Traffic AI Admin** | 3002 | 模型代理服务 - 管理端 |
| **Plugin Manager** | 8001 | OpenClaw MCP 插件管理器 |
| **Credential Manager** | 8002 | 凭证管理服务 |

## 🚀 快速开始

### 1. 自动配置（推荐）

```bash
cd /Users/jiangyi/Documents/codedev/claw_manager

# 自动从本地项目读取 Git 地址并生成 .env
./scripts/auto-config.sh
```

自动配置会：
- 自动检测本地项目的 Git 远程地址
- 生成 `.env` 配置文件
- 自动生成安全 Token

如果是私有仓库，编辑 `.env` 添加访问凭证：

```bash
vim .env  # 添加 GIT_TOKEN=your_github_token
```

### 2. 运行初始化

```bash
./scripts/init.sh
```

初始化脚本会：
- 检查系统依赖（podman, git, curl）
- 测试 Git 仓库访问
- 创建 Podman 网络
- 从 Git 拉取代码并构建镜像

### 3. 启动服务

```bash
./scripts/start.sh
```

### 4. 访问服务

- Traffic AI Console: http://localhost:3001
- Traffic AI Admin: http://localhost:3002
- Plugin Manager: http://localhost:8001
- Credential Manager: http://localhost:8002

## 📋 常用命令

```bash
# 启动所有服务
./scripts/start.sh

# 停止所有服务
./scripts/stop.sh

# 查看服务状态
podman-compose ps

# 查看所有日志
./scripts/logs.sh

# 查看特定服务日志
./scripts/logs.sh traffic-ai-console

# 重新构建镜像（拉取最新代码）
./scripts/rebuild.sh
```

## 🔄 更新服务

当 Git 仓库有新代码时：

```bash
# 方式1: 重新构建所有镜像
./scripts/rebuild.sh

# 方式2: 重新构建特定服务
podman-compose build --no-cache traffic-ai-console
podman-compose up -d traffic-ai-console
```

## 🏗️ 架构说明

### 构建流程

```
Git Repository (main 分支)
        ↓
   git clone (Dockerfile)
        ↓
   安装依赖 & 构建
        ↓
   Docker 镜像
        ↓
   Podman 容器
```

### 服务依赖

```
Credential Manager (底层)
    ↓
Traffic AI + Plugin Manager
    ↓
OpenClaw Gateway
```

### 网络架构

所有服务运行在 `openclaw` bridge 网络中，可以通过服务名互相访问。

## 📂 目录结构

```
claw_manager/
├── .env                          # 环境变量配置
├── .env.example                  # 配置模板
├── docker-compose.yml            # 服务编排配置
├── dockerfiles/                  # Dockerfile 文件
│   ├── traffic-ai.Dockerfile
│   ├── plugin-manager.Dockerfile
│   ├── credential-manager.Dockerfile
│   └── dashboard.Dockerfile
├── scripts/                      # 管理脚本
│   ├── init.sh                  # 初始化
│   ├── start.sh                 # 启动
│   ├── stop.sh                  # 停止
│   ├── rebuild.sh               # 重建
│   └── logs.sh                  # 日志
├── config/                       # 配置文件
│   └── repos.json               # 仓库配置
└── dashboard/                    # Dashboard 前端（待开发）
```

## 🔧 配置说明

### 环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `VERSION` | 镜像版本标签 | `latest` |
| `*_REPO` | Git 仓库地址 | - |
| `*_BRANCH` | Git 分支 | `main` |
| `*_PORT` | 服务端口 | 见上表 |
| `GIT_TOKEN` | Git 访问凭证 | - |
| `ADMIN_TOKEN` | 管理员 Token | 自动生成 |
| `CRED_TOKEN` | 凭证服务 Token | 自动生成 |

### Dockerfile 构建参数

```dockerfile
ARG GIT_REPO        # Git 仓库地址
ARG GIT_BRANCH      # Git 分支
ARG GIT_TOKEN       # Git 访问凭证（可选）
ARG BUILD_TARGET    # 构建目标（traffic-ai 特有）
```

## 🐛 故障排除

### 问题1: 端口被占用

```bash
# 查看端口占用
lsof -i :3001

# 释放端口（会提示）
./scripts/start.sh
```

### 问题2: Git 仓库无法访问

```bash
# 测试仓库访问
git ls-remote https://github.com/YOUR_ORG/traffic-ai.git

# 配置 Git Token（私有仓库）
# 编辑 .env，添加 GIT_TOKEN=your_token
```

### 问题3: 镜像构建失败

```bash
# 查看构建日志
podman-compose build traffic-ai-console

# 清理缓存重新构建
podman-compose build --no-cache traffic-ai-console
```

### 问题4: 服务启动失败

```bash
# 查看服务日志
podman-compose logs -f traffic-ai-console

# 查看容器状态
podman ps -a

# 进入容器调试
podman exec -it traffic-ai-console sh
```

## 🔐 安全建议

1. **不要将 .env 文件提交到 Git**
2. **定期更换 Token**
3. **使用 SSH Key 而非 Token 访问 Git**
4. **限制容器网络访问**
5. **定期更新镜像和依赖**

## 📝 开发说明

### 本地开发流程

1. 在原项目目录开发代码（不动）
2. 提交并推送到 Git
3. 运行 `./scripts/rebuild.sh` 拉取最新代码

### 添加新服务

1. 创建 Dockerfile: `dockerfiles/new-service.Dockerfile`
2. 在 `docker-compose.yml` 添加服务定义
3. 更新 `.env.example` 添加配置
4. 运行 `./scripts/rebuild.sh`

## 📄 License

MIT

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！
