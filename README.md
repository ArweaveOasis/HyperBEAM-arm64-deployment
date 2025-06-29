# HyperBEAM ARM64 Deployment Kit 🚀

**一键部署 HyperBEAM 节点到 Apple Silicon Mac**

[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%2FM2%2FM3-blue.svg)](https://apple.com)
[![macOS](https://img.shields.io/badge/macOS-14.0%2B-green.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 🎯 项目简介

这个仓库专门为 **Apple Silicon Mac (ARM64)** 提供 HyperBEAM 节点的完整部署解决方案。解决了官方文档中在 ARM64 架构上的兼容性问题，并提供了生产级的监控和管理工具。

### ✅ 解决的核心问题

- **Apple Silicon 构建兼容性** - 修复 WAMR 编译问题
- **自动化依赖安装** - 一键安装所有必需依赖
- **生产级监控** - 完整的节点监控和管理工具
- **详细故障排除** - ARM64 特定问题的解决方案

## 🚀 快速开始

### 前置要求

- macOS 14.0+ (Apple Silicon)
- Xcode Command Line Tools
- 至少 8GB RAM
- 50GB+ 可用磁盘空间

### 一键部署 (推荐方式)

```bash
# 1. 克隆部署工具包
git clone https://github.com/YOUR_USERNAME/hyperbeam-arm64-deployment.git
cd hyperbeam-arm64-deployment

# 2. 设置便捷符号链接 (一键设置)
chmod +x setup-links.sh
./setup-links.sh

# 3. 运行自动化部署脚本
./deploy-hyperbeam-arm64.sh

# 4. 启动监控 (可选)
./monitor-node.sh --status
```

### 手动符号链接方式

```bash
# 1. 克隆部署工具包
git clone https://github.com/YOUR_USERNAME/hyperbeam-arm64-deployment.git
cd hyperbeam-arm64-deployment

# 2. 手动创建快捷方式 (保持向后兼容性)
ln -s scripts/deploy-hyperbeam-arm64.sh deploy-hyperbeam-arm64.sh
ln -s monitoring/monitor-node.sh monitor-node.sh

# 3. 运行自动化部署脚本
./deploy-hyperbeam-arm64.sh
# 或者直接使用: ./scripts/deploy-hyperbeam-arm64.sh

# 4. 启动监控 (可选)
./monitor-node.sh --status
# 或者直接使用: ./monitoring/monitor-node.sh --status
```

### 备选部署方式 (直接使用scripts目录)

```bash
# 1. 克隆部署工具包
git clone https://github.com/YOUR_USERNAME/hyperbeam-arm64-deployment.git
cd hyperbeam-arm64-deployment

# 2. 直接运行scripts目录中的脚本
./scripts/deploy-hyperbeam-arm64.sh

# 3. 启动监控 (可选)
./monitoring/monitor-node.sh --status
```

## 📁 项目结构

```
hyperbeam-arm64-deployment/
├── scripts/
│   ├── deploy-hyperbeam-arm64.sh     # 主部署脚本
│   ├── fix-apple-silicon.sh          # Apple Silicon 兼容性修复
│   ├── setup-dependencies.sh         # 依赖安装脚本
│   └── validate-config.sh            # 配置验证工具
├── monitoring/
│   ├── monitor-node.sh               # 节点监控工具
│   └── simple-monitor.sh             # 简化监控脚本
├── configs/
│   ├── mainnet.flat                  # 主网配置模板
│   └── testnet.flat                  # 测试网配置模板
├── docs/
│   ├── QUICK-START.md                # 快速开始指南
│   ├── TROUBLESHOOTING.md            # 故障排除指南
│   ├── MONITORING.md                 # 监控指南
│   └── CONFIGURATION.md              # 配置说明
├── setup-links.sh                   # 符号链接设置脚本
├── deploy-hyperbeam-arm64.sh         # 部署脚本符号链接 (快捷方式)
├── monitor-node.sh                   # 监控脚本符号链接 (快捷方式)
├── simple-monitor.sh                 # 简单监控脚本符号链接 (快捷方式)
├── setup-dependencies.sh             # 依赖安装脚本符号链接 (快捷方式)
├── validate-config.sh               # 配置验证脚本符号链接 (快捷方式)
├── fix-apple-silicon.sh             # Apple Silicon修复脚本符号链接 (快捷方式)
└── README.md                         # 本文件
```

## 📖 详细文档

- [📋 快速开始指南](docs/QUICK-START.md) - 15分钟部署教程
- [🔧 故障排除指南](docs/TROUBLESHOOTING.md) - 常见问题解决
- [📊 监控指南](docs/MONITORING.md) - 节点监控和管理
- [⚙️ 配置说明](docs/CONFIGURATION.md) - 详细配置选项

## 🛠️ 核心功能

### 自动化部署
- ✅ 自动检测和安装依赖（Erlang, Rebar3, CMake, Ninja）
- ✅ 自动修复 Apple Silicon 构建问题
- ✅ 自动配置主网/测试网参数
- ✅ 自动生成密钥和配置文件

### 监控和管理
- 📊 实时节点状态监控
- 📈 系统资源监控（CPU、内存、网络）
- 📋 日志分析和错误检测
- 🔄 节点重启和恢复工具

### 配置验证
- ✅ 配置文件语法检查
- ✅ 网络连接测试
- ✅ 端口可用性检查
- ✅ 权限验证

## ⚡ 性能优化

### 构建优化
```bash
# 使用 Ninja 构建系统 (比 Make 快 2-3x)
export CMAKE_GENERATOR=Ninja

# 启用并行编译
export MAKEFLAGS="-j$(sysctl -n hw.ncpu)"
```

### 运行时优化
```bash
# 优化 Erlang VM 参数
export ERL_FLAGS="+sbwt very_short +swt very_low"
```

## 🔍 监控示例

```bash
# 检查节点状态 (使用符号链接)
./monitor-node.sh --status

# 或者直接使用scripts目录
./monitoring/monitor-node.sh --status

# 实时日志监控
./monitoring/monitor-node.sh --logs

# 系统资源监控
./monitoring/monitor-node.sh --resources

# 网络连接监控
./monitoring/monitor-node.sh --network
```

## 🚨 常见问题排除

### 问题 1: 脚本找不到
```bash
# 如果出现 "no such file or directory" 错误
# 方案1: 检查文件是否存在
ls -la scripts/deploy-hyperbeam-arm64.sh

# 方案2: 创建符号链接
ln -s scripts/deploy-hyperbeam-arm64.sh deploy-hyperbeam-arm64.sh

# 方案3: 直接使用完整路径
./scripts/deploy-hyperbeam-arm64.sh
```

### 问题 2: 权限错误
```bash
# 添加执行权限
chmod +x scripts/deploy-hyperbeam-arm64.sh
chmod +x monitoring/monitor-node.sh
```

### 问题 3: 路径问题
```bash
# 确保在正确目录
pwd  # 应该显示: .../hyperbeam-arm64-deployment

# 检查文件结构
ls -la scripts/
ls -la monitoring/
```

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 开发环境
```bash
git clone https://github.com/YOUR_USERNAME/hyperbeam-arm64-deployment.git
cd hyperbeam-arm64-deployment
./scripts/setup-dev-environment.sh
```

### 提交规范
- `feat:` 新功能
- `fix:` 错误修复
- `docs:` 文档更新
- `perf:` 性能优化

## 📊 测试状态

| 平台 | 状态 | 备注 |
|------|------|------|
| MacBook Air M1 | ✅ | macOS 14.5 |
| MacBook Pro M2 | ✅ | macOS 14.6 |
| MacBook Pro M3 | ✅ | macOS 15.0 |

## 🔗 相关链接

- [HyperBEAM 官方仓库](https://github.com/permaweb/HyperBEAM)
- [Arweave 官方文档](https://docs.arweave.org/)
- [AO 协议文档](https://ao.arweave.dev/)

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

感谢 HyperBEAM 团队提供的优秀基础架构，以及 Arweave 社区的支持。

---

**⭐ 如果这个项目对您有帮助，请给个 Star！**
