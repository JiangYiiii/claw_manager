# OpenClaw 开发模式使用指南

## 概述

开发模式允许你直接挂载本地代码到容器中，修改代码后重启容器即可生效，无需重新构建镜像。

## 启用开发模式

### 1. 编辑 .env 文件

```bash
# 设置开发模式
DEV_MODE=true
```

### 2. 启动服务

```bash
# 方式一：使用开发脚本（推荐）
./dev-start.sh

# 方式二：直接使用 podman-compose
podman-compose up -d
```

## 开发工作流

### 修改代码后应用更改

#### Node.js 项目（Plugin Manager）
```bash
# 1. 修改代码
vim ~/Documents/codedev/claw_plugin_manager/src/index.js

# 2. 重启容器（秒级生效）
./dev-start.sh restart claw-plugin-manager

# 3. 查看日志
./dev-start.sh logs claw-plugin-manager
```

#### Go 项目（Traffic AI）
```bash
# 1. 修改代码
vim ~/Documents/codedev/traffic-ai/cmd/gateway/main.go

# 2. 重启容器（会自动重新编译，约 5-10 秒）
./dev-start.sh restart traffic-ai-gateway

# 3. 查看编译和启动日志
./dev-start.sh logs traffic-ai-gateway
```

### 常用命令

```bash
# 查看所有服务状态
podman-compose ps

# 重启指定服务
./dev-start.sh restart <service-name>

# 查看日志
./dev-start.sh logs <service-name>

# 停止所有服务
podman-compose down

# 重新启动所有服务
./dev-start.sh
```

## 各服务的开发模式说明

| 服务 | 语言 | 重启后编译时间 | 说明 |
|------|------|---------------|------|
| traffic-ai-control | Go | ~5-10 秒 | 每次重启会在容器内重新编译 |
| traffic-ai-gateway | Go | ~5-10 秒 | 每次重启会在容器内重新编译 |
| claw-plugin-manager | Node.js | 秒级 | 直接使用最新代码，无需编译 |
| claw-credential-manager | Go + Node.js | ~5-10 秒 | Go 部分需要编译，Web 部分直接生效 |

## 代码挂载路径

开发模式下，以下本地目录会被挂载到容器：

```
~/Documents/codedev/traffic-ai              → traffic-ai-* 容器
~/Documents/codedev/claw_plugin_manager     → claw-plugin-manager 容器
~/Documents/codedev/claw_credential_manager → claw-credential-manager 容器
```

## 优势

✅ **快速迭代**：修改代码后重启即可，无需重建镜像  
✅ **真实环境**：在容器环境中运行，与生产环境一致  
✅ **保留依赖**：使用容器内的依赖，避免本地环境差异  
✅ **只读挂载**：容器内编译产生的文件不会污染宿主机  

## 注意事项

### Go 项目编译注意
- 容器内会自动下载依赖（`go mod download`）
- 如果依赖变更，首次编译可能需要更长时间
- 编译产物存放在 `/tmp`，不会影响宿主机代码

### Node.js 项目注意
- `node_modules` 使用容器内的版本
- 如果 `package.json` 有变更，需要重建镜像

### 配置文件
- 配置文件仍从 `~/openclaw-data/` 挂载
- 修改配置后需要重启服务

## 切换回生产模式

```bash
# 1. 编辑 .env
DEV_MODE=false

# 2. 停止服务
podman-compose down

# 3. 重建镜像（从 Git 拉取最新代码）
podman-compose build --no-cache

# 4. 启动服务
podman-compose up -d
```

或者直接重命名/删除 `docker-compose.override.yml`：

```bash
mv docker-compose.override.yml docker-compose.override.yml.disabled
podman-compose down
podman-compose up -d
```

## 示例：修改 Traffic AI Gateway 日志级别

```bash
# 1. 编辑代码
vim ~/Documents/codedev/traffic-ai/cmd/gateway/main.go

# 修改日志级别从 info 改为 debug
# logger := log.New(log.LevelInfo)
# 改为：
# logger := log.New(log.LevelDebug)

# 2. 重启服务（自动重新编译）
./dev-start.sh restart traffic-ai-gateway

# 3. 查看日志验证
./dev-start.sh logs traffic-ai-gateway | grep DEBUG
```

## 故障排查

### 编译失败
```bash
# 查看完整编译日志
podman logs traffic-ai-gateway

# 检查 Go 版本和依赖
podman exec traffic-ai-gateway go version
```

### Node.js 代码未生效
```bash
# 确认挂载正确
podman inspect claw-plugin-manager | grep -A5 Mounts

# 检查容器内代码
podman exec claw-plugin-manager cat /app/src/index.js | head
```

### 端口冲突
```bash
# 检查端口占用
lsof -i :8081
lsof -i :8090

# 重启 podman 网络
podman-compose down
podman machine restart
```
