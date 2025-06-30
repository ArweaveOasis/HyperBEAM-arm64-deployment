# 📋 HyperBEAM ARM64 快速开始指南

## 🎯 概述

这是一个15分钟的快速部署指南，专为 Apple Silicon Mac 用户设计。

## 🚀 一键部署

### 步骤 1: 下载部署工具包

```bash
git clone https://github.com/ArweaveOasis/HyperBEAM-arm64-deployment.git
cd hyperbeam-arm64-deployment
```

### 步骤 2: 运行部署前测试 (推荐)

```bash
./scripts/test-deployment.sh
```

这个测试会验证：
- ✅ 系统兼容性
- ✅ 必需工具可用性
- ✅ 磁盘空间充足
- ✅ 脚本完整性

### 步骤 3: 运行一键部署

```bash
./scripts/deploy-hyperbeam-arm64.sh
```

这个脚本会自动：
- ✅ 检查系统兼容性和环境
- ✅ 预检系统资源和依赖
- ✅ 处理端口冲突和进程管理
- ✅ 安装所有必需依赖
- ✅ 修复 Apple Silicon 构建问题
- ✅ 构建 HyperBEAM 并生成配置
- ✅ 配置主网节点和密钥
- ✅ 启动节点和监控工具
- ✅ 提供详细的使用指南

### 步骤 4: 验证部署

```bash
# 检查节点状态
./monitoring/monitor-node.sh --status

# 查看 Web 界面 (端口可能不同)
open http://localhost:10000

# 验证进程和端口
pgrep -f 'beam.*hb'
lsof -i :10000
```

## 🔧 手动部署（高级用户）

如果您希望更细粒度的控制，可以分步骤执行：

### 1. 安装依赖

```bash
./scripts/setup-dependencies.sh
```

### 2. 修复 Apple Silicon 兼容性

```bash
./scripts/fix-apple-silicon.sh
```

### 3. 构建 HyperBEAM

```bash
git clone https://github.com/permaweb/HyperBEAM.git
cd HyperBEAM
git checkout beta
rebar3 release
```

### 4. 配置节点

```bash
cd _build/default/rel/hb
cp ../../../../../configs/mainnet.flat config.flat
./bin/hb eval 'ar_wallet:to_file(ar_wallet:new(), "hyperbeam-key.json").'
```

### 5. 启动节点

```bash
./bin/hb daemon
```

## 📊 监控和管理

### 检查节点状态

```bash
./monitoring/monitor-node.sh --status
```

### 查看实时日志

```bash
./monitoring/monitor-node.sh --logs
```

### 监控系统资源

```bash
./monitoring/monitor-node.sh --resources
```

### 网络连接监控

```bash
./monitoring/monitor-node.sh --network
```

## ⚙️ 配置选项

### 更改端口

编辑 `config.flat` 文件：

```erlang
[
  {"port", "YOUR_PORT"},
  {"mode", "mainnet"},
  {"priv_key_location", "hyperbeam-key.json"}
].
```

### 切换到测试网

```bash
cp configs/testnet.flat _build/default/rel/hb/config.flat
```

## 🔍 故障排除

### 常见问题

1. **构建失败**
   ```bash
   # 重新运行 Apple Silicon 修复
   ./scripts/fix-apple-silicon.sh
   ```

2. **端口冲突**
   ```bash
   # 检查端口占用
   lsof -i :8734
   ```

3. **节点启动失败**
   ```bash
   # 检查配置
   ./scripts/validate-config.sh
   ```

### 获取帮助

详细的故障排除指南请参阅：[TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## 🔄 更新节点

```bash
cd HyperBEAM
git pull origin beta
rebar3 release
./bin/hb restart
```

## 🛑 停止节点

```bash
./bin/hb stop
```

## 📈 性能优化

### 构建优化

```bash
export CMAKE_GENERATOR=Ninja
export MAKEFLAGS="-j$(sysctl -n hw.ncpu)"
```

### 运行时优化

```bash
export ERL_FLAGS="+sbwt very_short +swt very_low"
```

## 🔐 安全建议

1. **备份密钥文件**
   ```bash
   cp hyperbeam-key.json ~/Desktop/hyperbeam-key-backup.json
   ```

2. **定期更新**
   ```bash
   # 每周检查更新
   git pull origin beta
   ```

3. **监控日志**
   ```bash
   # 设置日志监控
   ./monitoring/monitor-node.sh --logs > hyperbeam.log &
   ```

## 📞 支持

- 🐛 问题报告：[GitHub Issues](https://github.com/ArweaveOasis/HyperBEAM-arm64-deployment/issues)
- 💬 社区讨论：[Discord](https://discord.gg/arweave)
- 📚 官方文档：[HyperBEAM Docs](https://docs.hyperbeam.com) 