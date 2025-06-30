# 🚀 HyperBEAM ARM64 一键部署工具 (改进版 v2.0.0)

**专为 Apple Silicon Mac 设计的 HyperBEAM 节点部署解决方案**

> 🎯 **重大更新 (v2.0.0)**: 基于实际手动部署验证，集成了所有 Apple Silicon 兼容性修复，大幅提升部署成功率！  
> 📊 **改进总结**: [查看详细改进内容](DEPLOYMENT-IMPROVEMENTS.md)

## ✨ 新版本亮点

- 🔧 **智能修复**: 自动应用所有 Apple Silicon 兼容性修复
- 🛡️ **冲突处理**: 自动检测和解决端口冲突问题  
- 🧪 **环境预检**: 部署前全面检查系统环境
- 🎯 **错误恢复**: 详细的故障诊断和恢复指导
- ✅ **验证机制**: 完整的部署成功验证流程

## 🚀 快速开始

[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%2FM2%2FM3-blue.svg)](https://apple.com)
[![macOS](https://img.shields.io/badge/macOS-14.0%2B-green.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

### 前置要求

* macOS 14.0+ (Apple Silicon)
* Xcode Command Line Tools
* 至少 8GB RAM
* 50GB+ 可用磁盘空间

### 一键部署

```bash
# 1. 克隆部署工具包
git clone https://github.com/ArweaveOasis/HyperBEAM-arm64-deployment.git
cd hyperbeam-arm64-deployment

# 2. 运行部署测试 (可选但推荐)
./scripts/test-deployment.sh

# 3. 创建快捷方式 (可选)
./setup-links.sh

# 4. 运行一键部署
./scripts/deploy-hyperbeam-arm64.sh
# 或使用快捷方式: ./deploy-hyperbeam-arm64.sh

# 5. 验证部署
./monitoring/monitor-node.sh --status
# 或使用快捷方式: ./monitor-node.sh --status
```

## 📁 项目结构

```
hyperbeam-arm64-deployment/
├── scripts/                          # 🛠️  部署和管理脚本
│   ├── deploy-hyperbeam-arm64.sh     #     主部署脚本
│   ├── fix-apple-silicon.sh          #     Apple Silicon 兼容性修复
│   ├── setup-dependencies.sh         #     依赖安装脚本
│   ├── test-deployment.sh            #     部署测试脚本 (新)
│   ├── validate-config.sh            #     配置验证工具
│   └── diagnose-build-environment.sh #     环境诊断工具
├── monitoring/                       # 📊  节点监控
│   └── monitor-node.sh               #     节点监控工具
├── configs/                          # ⚙️  配置模板
│   ├── mainnet.flat                  #     主网配置模板
│   └── testnet.flat                  #     测试网配置模板
├── docs/                             # 📚  详细文档
│   ├── QUICK-START.md                #     快速开始指南
│   ├── TROUBLESHOOTING.md            #     故障排除指南
│   └── MONITORING.md                 #     监控指南
├── setup-links.sh                   # 🔗  快捷方式设置
├── deploy-hyperbeam-arm64.sh         # ⚡  部署脚本快捷方式
├── monitor-node.sh                   # 📊  监控脚本快捷方式
├── .gitignore                        # 🚫  Git 忽略规则
├── DEPLOYMENT-IMPROVEMENTS.md        # 📈  改进说明 (新)
└── README.md                         # 📖  本文件
```

## 📖 详细文档

- [📋 快速开始指南](docs/QUICK-START.md) - 15分钟部署教程
- [🔧 故障排除指南](docs/TROUBLESHOOTING.md) - 常见问题解决
- [📊 监控指南](docs/MONITORING.md) - 节点监控和管理
- [📈 改进说明](DEPLOYMENT-IMPROVEMENTS.md) - v2.0.0 改进详情

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
# 检查节点状态 (使用快捷方式)
./monitor-node.sh --status

# 或者直接使用完整路径
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

# 方案2: 创建快捷方式
./setup-links.sh

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
git clone https://github.com/ArweaveOasis/HyperBEAM-arm64-deployment.git
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
