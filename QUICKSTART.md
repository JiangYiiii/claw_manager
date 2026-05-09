# 🚀 OpenClaw Manager 快速启动指南

## ✨ 已自动配置完成

你的 Git 仓库地址已自动从本地项目读取并配置：

```
✓ Traffic AI:          https://github.com/JiangYiiii/traffic-ai.git
✓ Plugin Manager:      https://github.com/JiangYiiii/claw_plugin_manager.git
✓ Credential Manager:  https://github.com/JiangYiiii/claw_credential_manager.git
```

`.env` 文件已自动生成，包含：
- ✅ Git 仓库地址
- ✅ 安全 Token（ADMIN_TOKEN, CRED_TOKEN）
- ✅ 服务端口配置

---

## 🎯 现在只需 2 步启动

### 第 1 步：初始化（首次运行）

```bash
cd /Users/jiangyi/Documents/codedev/claw_manager
./scripts/init.sh
```

初始化会：
- 检查系统依赖（podman, git, curl）
- 测试 Git 仓库访问
- 创建 Podman 网络
- **从 Git 拉取最新代码并构建镜像**（约 3-5 分钟）

### 第 2 步：启动服务

```bash
./scripts/start.sh
```

---

## 🌐 访问服务

启动成功后，访问以下地址：

| 服务 | 地址 | 说明 |
|------|------|------|
| **Traffic AI Console** | http://localhost:3001 | 模型代理 - 用户端 |
| **Traffic AI Admin** | http://localhost:3002 | 模型代理 - 管理端 |
| **Plugin Manager** | http://localhost:8001 | MCP 插件管理 |
| **Credential Manager** | http://localhost:8002 | 凭证管理 |

---

## 🔄 日常使用

### 更新代码

当你在原项目（traffic-ai, claw_plugin_manager, claw_credential_manager）修改代码后：

```bash
# 1. 在原项目提交代码
cd ~/Documents/codedev/traffic-ai
git add .
git commit -m "feat: 新功能"
git push origin main

# 2. 重新构建容器（自动拉取最新代码）
cd ~/Documents/codedev/claw_manager
./scripts/rebuild.sh

# ✅ 完成！容器已使用最新代码运行
```

### 查看日志

```bash
# 查看所有服务日志
./scripts/logs.sh

# 查看特定服务日志
./scripts/logs.sh traffic-ai-console
```

### 停止服务

```bash
./scripts/stop.sh
```

### 重启服务

```bash
./scripts/stop.sh && ./scripts/start.sh
```

---

## 🔐 私有仓库配置

如果你的 Git 仓库是私有的，需要配置访问凭证：

```bash
# 编辑 .env 文件
vim .env

# 添加 GitHub Personal Access Token
GIT_TOKEN=ghp_xxxxxxxxxxxxx
```

**获取 Token：**
1. 访问 GitHub Settings → Developer settings → Personal access tokens
2. 生成新 Token，权限勾选 `repo`
3. 复制 Token 并配置到 `.env`

---

## 📊 服务状态检查

```bash
# 查看容器状态
podman-compose ps

# 健康检查
curl http://localhost:3001/health
curl http://localhost:3002/health
curl http://localhost:8001/health
curl http://localhost:8002/health
```

---

## 🐛 常见问题

### Q1: 端口被占用？

```bash
# start.sh 会自动检测并提示处理
# 或手动释放端口
lsof -ti :3001,:3002,:8001,:8002 | xargs kill -9
```

### Q2: Git 仓库访问失败？

```bash
# 测试访问
git ls-remote https://github.com/JiangYiiii/traffic-ai.git

# 如果是私有仓库，配置 GIT_TOKEN
vim .env
```

### Q3: 镜像构建失败？

```bash
# 查看构建日志
podman-compose build traffic-ai-console

# 清理缓存重新构建
podman-compose build --no-cache traffic-ai-console
```

### Q4: 服务启动失败？

```bash
# 查看日志
./scripts/logs.sh traffic-ai-console

# 进入容器调试
podman exec -it traffic-ai-console sh
```

---

## 📚 更多文档

- **README.md** - 完整功能说明和配置
- **GETTING_STARTED.md** - 详细使用指南
- **scripts/validate.sh** - 配置验证工具

---

## 💡 工作原理

```
本地开发              Git 仓库              容器镜像
   ↓                    ↓                    ↓
traffic-ai/  →  git push  →  GitHub  →  git clone  →  Docker Image
   ↓                                           ↓
修改代码                                   podman run
   ↓                                           ↓
git commit                                运行最新代码
```

**核心特点：**
- ✅ 不挂载本地代码，容器内是独立副本
- ✅ 从 Git 构建，版本明确可追溯
- ✅ 一键重建，自动拉取最新代码

---

**祝使用愉快！** 🦞

如有问题，查看完整文档：
- [README.md](./README.md)
- [GETTING_STARTED.md](./GETTING_STARTED.md)
