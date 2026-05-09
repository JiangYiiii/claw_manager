# 开发模式快速开始

## ✅ 已启用开发模式

当前配置：
- **DEV_MODE=true** (在 .env 中)
- 所有服务已挂载本地代码目录
- 修改代码后重启容器即可生效

## 🚀 快速开始

### 1. 修改代码并应用

```bash
# 方式一：使用开发脚本（推荐）
./dev-start.sh restart <service-name>

# 方式二：直接使用 podman-compose
podman-compose restart <service-name>
```

### 2. 示例：修改 Plugin Manager

```bash
# 1. 编辑代码
vim ~/Documents/codedev/claw_plugin_manager/src/index.js

# 2. 重启服务（秒级生效）
./dev-start.sh restart claw-plugin-manager

# 3. 查看日志验证
podman logs -f claw-plugin-manager
```

## 📋 服务列表

| 服务名 | 代码路径 | 语言 | 重启生效时间 |
|--------|---------|------|-------------|
| **claw-plugin-manager** | `~/Documents/codedev/claw_plugin_manager` | Node.js | 秒级 |
| **traffic-ai-control** | `~/Documents/codedev/traffic-ai` | Go | 5-10秒（重新编译） |
| **traffic-ai-gateway** | `~/Documents/codedev/traffic-ai` | Go | 5-10秒（重新编译） |
| **claw-credential-manager** | `~/Documents/codedev/claw_credential_manager` | Go + Node.js | 5-10秒（重新编译） |

## 🔍 验证开发模式

### 检查代码挂载

```bash
# Plugin Manager (Node.js)
podman exec claw-plugin-manager ls -la /app/src/

# Traffic AI Gateway (Go)
podman exec traffic-ai-gateway ls -la /app/src/cmd/gateway/

# Credential Manager (Go)
podman exec claw-credential-manager ls -la /app/src/cmd/server/
```

### 查看挂载配置

```bash
podman inspect claw-plugin-manager --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}'
```

应该看到类似：
```
/Users/jiangyi/Documents/codedev/claw_plugin_manager/src -> /app/src
```

## 💡 工作流示例

### 场景 1: 修改 Node.js 代码（Plugin Manager）

```bash
# 1. 修改代码
vim ~/Documents/codedev/claw_plugin_manager/src/mcp-http-server.js

# 2. 重启容器（秒级）
./dev-start.sh restart claw-plugin-manager

# 3. 测试新功能
curl http://localhost:8090/health
```

### 场景 2: 修改 Go 代码（Traffic AI）

```bash
# 1. 修改代码
vim ~/Documents/codedev/traffic-ai/cmd/gateway/main.go

# 2. 重启容器（会自动编译，约 5-10 秒）
./dev-start.sh restart traffic-ai-gateway

# 3. 查看编译日志
podman logs traffic-ai-gateway 2>&1 | grep "Building gateway"

# 4. 测试新功能
curl http://localhost:8081/v1/models
```

### 场景 3: 同时修改多个文件

```bash
# 1. 批量修改代码
vim ~/Documents/codedev/claw_plugin_manager/src/index.js
vim ~/Documents/codedev/claw_plugin_manager/src/mcp-http-server.js

# 2. 一次重启即可应用所有修改
./dev-start.sh restart claw-plugin-manager
```

## 🛠️ 常用命令

```bash
# 查看所有服务状态
podman-compose ps

# 重启指定服务
./dev-start.sh restart <service-name>

# 查看日志
./dev-start.sh logs <service-name>

# 查看实时日志
podman logs -f <service-name>

# 停止所有服务
podman-compose down

# 启动所有服务
./dev-start.sh
```

## ⚠️ 注意事项

### Go 项目
- ✅ 每次重启会在容器内重新编译
- ✅ 依赖会自动下载（首次可能较慢）
- ✅ 编译产物在 `/tmp`，不污染宿主机
- ⚠️ 如果 go.mod 有变更，首次编译较慢

### Node.js 项目
- ✅ 直接使用最新代码，秒级生效
- ✅ `node_modules` 使用容器内版本
- ⚠️ 如果 package.json 变更，需要重建镜像

### 配置文件
- ✅ 配置文件在 `~/openclaw-data/` 目录
- ⚠️ 修改配置后需要重启服务

## 🔄 切换回生产模式

```bash
# 1. 修改 .env
sed -i '' 's/DEV_MODE=true/DEV_MODE=false/' .env

# 2. 停止服务
podman-compose down

# 3. 重建镜像（从 Git 拉取代码）
podman-compose build --no-cache

# 4. 启动生产模式
podman-compose up -d
```

## 🐛 故障排查

### 问题 1: 代码修改不生效

```bash
# 检查挂载
podman inspect <service-name> | grep -A10 Mounts

# 检查容器内代码时间戳
podman exec <service-name> ls -la /app/src/
```

### 问题 2: Go 编译失败

```bash
# 查看完整编译日志
podman logs <service-name> 2>&1 | less

# 进入容器手动编译测试
podman exec -it <service-name> sh
cd /app/src
go build ./cmd/gateway/
```

### 问题 3: 容器启动慢

```bash
# Go 项目第一次启动需要编译，这是正常的
# 查看编译进度
podman logs -f <service-name>
```

## 📊 性能对比

| 操作 | 生产模式 | 开发模式 |
|------|---------|---------|
| 代码修改后 | 重建镜像 (3-5分钟) | 重启容器 (5-10秒) |
| Node.js 生效 | 重建镜像 | 秒级 |
| Go 生效 | 重建镜像 | 容器内编译 (5-10秒) |
| 依赖更新 | 重建镜像 | 重建镜像 |

## ✨ 最佳实践

1. **频繁修改时使用开发模式**：节省大量构建时间
2. **提交前验证生产模式**：确保 Git 代码完整
3. **使用 git stash**：在开发和生产模式间切换
4. **定期 pull 更新**：保持本地代码最新

## 🎯 总结

开发模式已启用！现在你可以：
- ✅ 直接修改本地代码
- ✅ 重启容器立即生效
- ✅ 在真实容器环境中调试
- ✅ 大幅提升开发效率

需要帮助？查看 `README-DEV.md` 获取更多详细信息。
