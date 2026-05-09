# 更新代码指南

## 快速更新所有服务

从 Git 拉取最新代码并重启所有服务：

```bash
./update.sh
```

## 更新指定服务

```bash
./rebuild-all.sh <service-name>
```

### 示例

```bash
# 更新 traffic-ai-gateway
./rebuild-all.sh traffic-ai-gateway

# 更新 plugin-manager
./rebuild-all.sh claw-plugin-manager

# 更新 credential-manager
./rebuild-all.sh claw-credential-manager
```

## 完全重建（清除缓存）

如果遇到构建问题：

```bash
./rebuild-all.sh --no-cache
```

## 手动更新步骤

如果你想手动控制每一步：

```bash
# 1. 停止服务
podman-compose down <service-name>

# 2. 重建镜像（从 Git 拉取最新代码）
podman-compose build --build-arg CACHEBUST=$(date +%s) <service-name>

# 3. 启动服务
podman-compose up -d <service-name>

# 4. 查看日志
podman logs -f <service-name>
```

## 更新工作原理

### CACHEBUST 机制

每次构建时，我们使用时间戳作为 `CACHEBUST` 参数：

```dockerfile
ARG CACHEBUST=1
RUN git clone ...
```

这样可以强制 Docker/Podman 重新执行 git clone，拉取最新代码。

### 构建流程

```
1. 停止运行中的容器
   ↓
2. 构建新镜像
   ├─ 安装基础依赖
   ├─ 从 Git 克隆最新代码 (使用 CACHEBUST)
   ├─ 安装项目依赖
   └─ 编译 (Go) / 准备运行环境 (Node.js)
   ↓
3. 启动新容器
   ↓
4. 服务就绪
```

## 服务列表

可更新的服务：

- `traffic-ai-control` - Traffic AI 控制台
- `traffic-ai-gateway` - Traffic AI 网关
- `claw-plugin-manager` - MCP 插件管理器
- `claw-credential-manager` - 凭证管理器

## 检查更新结果

### 查看服务状态

```bash
podman-compose ps
```

### 查看日志

```bash
# 实时日志
podman logs -f <service-name>

# 最近 50 行
podman logs --tail 50 <service-name>
```

### 验证服务

```bash
# Traffic AI Gateway
curl http://localhost:8081/v1/models

# Plugin Manager (Web UI)
curl http://localhost:8001

# Plugin Manager (MCP HTTP)
curl http://localhost:8090/health

# Credential Manager
curl http://localhost:8002/health
```

## 常见问题

### Q: 更新需要多长时间？

- **Node.js 项目**（plugin-manager）：约 30-60 秒
- **Go 项目**（traffic-ai, credential-manager）：约 2-5 分钟

### Q: 更新会丢失数据吗？

不会。配置文件和数据卷都是持久化的：

- 配置文件：`~/openclaw-data/`
- 数据卷：`credential-vault`（凭证数据）

### Q: 更新失败怎么办？

1. 查看构建日志找到错误原因
2. 尝试完全重建：`./rebuild-all.sh --no-cache`
3. 检查 Git 仓库是否可访问
4. 检查 `.env` 中的配置是否正确

### Q: 如何回滚到之前的版本？

```bash
# 1. 修改 .env 中的分支
vim .env
# 将 BRANCH 改为具体的 tag 或 commit

# 2. 重建
./rebuild-all.sh
```

### Q: 开发模式下如何更新？

如果启用了 `DEV_MODE=true`：

- **Node.js 项目**：直接修改本地代码，重启容器即可
- **Go 项目**：仍需提交到 Git 并重建

详见 [README-DEV.md](README-DEV.md)

## 更新计划建议

### 日常开发

使用开发模式 + 重启容器

### 测试新功能

```bash
# 提交到 Git
git commit -am "feat: new feature"
git push

# 更新指定服务测试
./rebuild-all.sh <service-name>
```

### 生产部署

```bash
# 1. 确保代码已合并到 main 分支
# 2. 更新所有服务
./update.sh

# 3. 验证服务
podman-compose ps
podman logs -f <service-name>
```
