# OpenClaw Manager 快速上手指南

## 🎯 核心理念

**完全理解你的需求：**
- ✅ **不移动原项目代码** - 保持 `traffic-ai`, `claw-plugin-manager`, `claw-credential-manager` 在原位置
- ✅ **从 Git 构建镜像** - 构建时 `git clone` 拉取稳定版代码，不挂载本地目录
- ✅ **一键管理** - 通过 `claw_manager` 统一管理所有服务
- ✅ **本地开发 → Git → 容器** - 本地开发提交到 Git，重启容器自动拉取最新代码

## 📂 目录说明

```
/Users/jiangyi/Documents/codedev/
├── traffic-ai/                 # 原项目（本地开发）
├── claw-plugin-manager/        # 原项目（本地开发）
├── claw-credential-manager/    # 原项目（本地开发）
└── claw_manager/               # ✨ 新建管理项目
    ├── dockerfiles/            # 各服务的 Dockerfile（从 Git 构建）
    ├── scripts/                # 管理脚本（一键启动/停止/重建）
    └── docker-compose.yml      # 服务编排配置
```

## 🚀 第一次使用（2 步）

### 步骤 1: 自动配置（✨ 新增）

```bash
cd /Users/jiangyi/Documents/codedev/claw_manager

# 自动从本地项目读取 Git 地址
./scripts/auto-config.sh
```

**自动配置会做什么：**
- ✅ 自动检测 `../traffic-ai` 的 Git 远程地址
- ✅ 自动检测 `../claw_plugin_manager` 的 Git 远程地址
- ✅ 自动检测 `../claw_credential_manager` 的 Git 远程地址
- ✅ 自动生成 `.env` 文件
- ✅ 自动生成安全 Token

**如果是私有仓库，补充配置：**

```bash
vim .env  # 添加 GIT_TOKEN=your_personal_access_token
```

### 步骤 2: 运行初始化

```bash
./scripts/init.sh
```

初始化脚本会：
1. ✅ 检查系统依赖（podman, git, curl）
2. ✅ 生成安全 Token（ADMIN_TOKEN, CRED_TOKEN）
3. ✅ 创建 Podman 网络
4. ✅ 测试 Git 仓库访问
5. ✅ 从 Git 拉取代码并构建镜像

### 步骤 3: 启动服务

```bash
./scripts/start.sh
```

🎉 完成！访问服务：
- Traffic AI Console: http://localhost:3001
- Traffic AI Admin: http://localhost:3002
- Plugin Manager: http://localhost:8001
- Credential Manager: http://localhost:8002

---

## 🔄 日常开发工作流

### 场景 1: 修改代码并更新容器

```bash
# 1. 在原项目目录开发
cd ~/Documents/codedev/traffic-ai
vim src/api/handler.js

# 2. 提交到 Git
git add .
git commit -m "feat: 优化 API 性能"
git push origin main

# 3. 在 claw_manager 重新构建
cd ~/Documents/codedev/claw_manager
./scripts/rebuild.sh

# 完成！容器已使用最新代码重启
```

**关键点：** 不需要手动挂载代码目录，`rebuild.sh` 会从 Git 拉取最新代码重新构建镜像。

### 场景 2: 只重启特定服务

```bash
# 只重建 Traffic AI Console
podman-compose build --no-cache traffic-ai-console
podman-compose up -d traffic-ai-console

# 查看日志确认
podman-compose logs -f traffic-ai-console
```

### 场景 3: 切换到特定版本

编辑 `.env` 文件：

```bash
# 切换到特定分支
TRAFFIC_AI_BRANCH=develop

# 或切换到特定 tag
TRAFFIC_AI_BRANCH=v1.2.3
```

然后重新构建：

```bash
./scripts/rebuild.sh
```

---

## 📋 常用命令速查

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

# 进入容器调试
podman exec -it traffic-ai-console sh

# 验证配置
./scripts/validate.sh
```

---

## 🔍 工作原理

### Dockerfile 构建流程

以 `traffic-ai.Dockerfile` 为例：

```dockerfile
# 1. 克隆 Git 仓库
RUN git clone --depth 1 --branch ${GIT_BRANCH} ${GIT_REPO} .

# 2. 显示版本信息
RUN echo "Git commit: $(git rev-parse HEAD)"

# 3. 安装依赖
RUN npm ci --production

# 4. 构建（如果需要）
RUN npm run build

# 5. 启动服务
CMD ["npm", "run", "start:console"]
```

### 为什么这样设计？

| 传统方式 | 我们的方式 | 优势 |
|----------|-----------|------|
| 挂载本地代码 | 从 Git 构建 | ✅ 版本明确，可追溯 |
| 开发和生产不一致 | 完全一致 | ✅ 避免"我电脑上能跑" |
| 手动构建推送镜像 | 一键重建 | ✅ 简化流程 |
| 运行时 git pull | 构建时 clone | ✅ 容器不可变 |

---

## 🐛 常见问题

### Q1: 构建时提示 Git 仓库无法访问？

**A:** 私有仓库需要配置访问凭证。

**方式 1：使用 Personal Access Token**

```bash
# 在 GitHub 创建 Token: Settings → Developer settings → Personal access tokens
# 编辑 .env
GIT_TOKEN=ghp_xxxxxxxxxxxxx
```

**方式 2：使用 SSH Key（推荐）**

```bash
# 确保 ~/.ssh/id_rsa 存在且添加到 GitHub
# 将 .env 中的 HTTPS 地址改为 SSH 地址
TRAFFIC_AI_REPO=git@github.com:YOUR_ORG/traffic-ai.git
```

### Q2: 端口被占用怎么办？

**A:** `start.sh` 会自动检测并提示处理。或手动释放：

```bash
# 查看占用进程
lsof -i :3001

# 停止进程
kill -9 <PID>
```

### Q3: 如何查看容器内的 Git 版本？

**A:** 进入容器查看：

```bash
podman exec -it traffic-ai-console sh
cat /app/.git/refs/heads/main  # 查看 commit hash
```

### Q4: 如何回滚到之前的版本？

**A:** 修改 `.env` 中的分支/标签，然后重新构建：

```bash
# 编辑 .env
TRAFFIC_AI_BRANCH=v1.1.0  # 之前的稳定版本

# 重新构建
./scripts/rebuild.sh
```

### Q5: 容器启动失败怎么调试？

```bash
# 1. 查看日志
podman-compose logs traffic-ai-console

# 2. 查看容器状态
podman ps -a

# 3. 进入容器调试
podman exec -it traffic-ai-console sh

# 4. 手动运行服务看详细错误
npm run start:console
```

---

## 🔐 安全最佳实践

### 保护敏感信息

```bash
# .env 文件不要提交到 Git
echo ".env" >> .gitignore

# Token 文件也不要提交
echo ".init-summary.txt" >> .gitignore
```

### 定期更换 Token

```bash
# 重新生成 Token
openssl rand -hex 32

# 更新 .env
vim .env

# 重启服务
./scripts/stop.sh && ./scripts/start.sh
```

### 使用 SSH Key 而非 Token

```bash
# 生成 SSH Key（如果没有）
ssh-keygen -t ed25519 -C "your_email@example.com"

# 添加到 GitHub
cat ~/.ssh/id_ed25519.pub
# 复制到 GitHub Settings → SSH Keys

# 修改 .env 使用 SSH 地址
TRAFFIC_AI_REPO=git@github.com:YOUR_ORG/traffic-ai.git
```

---

## 📊 服务依赖关系

```
┌─────────────────────────────────┐
│  Credential Manager (底层)      │
│  端口: 8002                     │
└────────────┬────────────────────┘
             │
     ┌───────┴────────┐
     ▼                ▼
┌──────────┐    ┌──────────────┐
│Traffic AI│    │Plugin Manager│
│3001,3002 │    │    8001      │
└────┬─────┘    └──────┬───────┘
     │                 │
     └────────┬────────┘
              ▼
     ┌────────────────┐
     │OpenClaw Gateway│
     │   (宿主机)      │
     └────────────────┘
```

**启动顺序：**
1. Credential Manager 先启动（提供凭证）
2. Traffic AI 和 Plugin Manager（依赖凭证）
3. OpenClaw Gateway（使用上述服务）

---

## 🎯 下一步

### 添加 Dashboard（可选）

未来可以添加统一管理界面：

```bash
# 1. 开发 Dashboard 前端
cd dashboard/
npm create vite@latest . -- --template react-ts

# 2. 创建 Dashboard Dockerfile
# 见 dockerfiles/dashboard.Dockerfile

# 3. 在 docker-compose.yml 取消注释 Dashboard 服务

# 4. 启动
./scripts/start.sh
```

### 集成到 OpenClaw

```bash
# 配置 OpenClaw 使用 Traffic AI
cat > ~/.openclaw/providers.d/traffic-ai.json <<EOF
{
  "traffic-ai": {
    "type": "openai-compatible",
    "baseURL": "http://localhost:3001/v1",
    "enabled": true
  }
}
EOF

# 重启 OpenClaw Gateway
openclaw gateway restart
```

---

## 💡 设计哲学

1. **不可变基础设施** - 镜像构建后不变，通过重建更新
2. **版本可追溯** - 每个镜像对应明确的 Git commit
3. **本地开发分离** - 不影响原项目开发体验
4. **一键操作** - 简化运维，降低出错概率
5. **从 Git 为源头** - Git 是唯一真相来源

---

## 📞 获取帮助

遇到问题？

1. 查看 [README.md](./README.md) 完整文档
2. 运行 `./scripts/validate.sh` 检查配置
3. 查看日志 `./scripts/logs.sh [service-name]`
4. 提交 Issue 到 Git 仓库

---

**祝使用愉快！** 🦞
