# 🚀 HyperBEAM ARM64 一键部署工具 (v2.1.0)

**专为 Apple Silicon Mac 设计的 HyperBEAM 节点部署解决方案**

> 🎯 **最新更新 (v2.1.0)**: 优化部署流程，集成原生 Web 监控界面，移除冗余监控脚本，部署体验更加清晰高效！  
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

# 2. 运行环境诊断 (推荐)
./scripts/diagnose-deployment.sh

# 3. 运行部署测试 (可选)
./scripts/test-deployment.sh

# 4. 创建快捷方式 (可选)
./setup-links.sh

# 5. 运行一键部署
./scripts/deploy-hyperbeam-arm64.sh
# 或使用快捷方式: ./deploy-hyperbeam-arm64.sh

# 6. 验证部署 - 访问 Web 监控界面
# 节点信息: http://localhost:8734/~meta@1.0/info
# 监控面板: http://localhost:8734/~hyperbuddy@1.0/dashboard
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
│   ├── diagnose-deployment.sh        #     全面环境诊断工具 (新)
│   └── diagnose-build-environment.sh #     构建环境诊断工具
├── configs/                          # ⚙️  配置模板
│   ├── mainnet.flat                  #     主网配置模板
│   └── testnet.flat                  #     测试网配置模板
├── docs/                             # 📚  详细文档
│   ├── QUICK-START.md                #     快速开始指南
│   └── TROUBLESHOOTING.md            #     故障排除指南
├── setup-links.sh                   # 🔗  快捷方式设置
├── deploy-hyperbeam-arm64.sh         # ⚡  部署脚本快捷方式
├── .gitignore                        # 🚫  Git 忽略规则
├── DEPLOYMENT-IMPROVEMENTS.md        # 📈  改进说明 (新)
└── README.md                         # 📖  本文件
```

## 📖 详细文档

- [📋 快速开始指南](docs/QUICK-START.md) - 15分钟部署教程
- [🔧 故障排除指南](docs/TROUBLESHOOTING.md) - 常见问题解决
- [📈 改进说明](DEPLOYMENT-IMPROVEMENTS.md) - v2.1.0 改进详情

## 🛠️ 核心功能

### 自动化部署
- ✅ 自动检测和安装依赖（Erlang, Rebar3, CMake, Ninja）
- ✅ 自动修复 Apple Silicon 构建问题
- ✅ 自动配置主网/测试网参数
- ✅ 自动生成密钥和配置文件

### Web 监控界面
- 📊 原生 Web 监控面板 (http://localhost:8734/~hyperbuddy@1.0/dashboard)
- 📈 节点状态信息 (http://localhost:8734/~meta@1.0/info)
- 📋 实时性能指标
- 🔄 通过命令行管理节点

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

## 🔍 监控和管理

### Web 监控界面 (推荐)
- **节点信息**: http://localhost:8734/~meta@1.0/info
- **监控面板**: http://localhost:8734/~hyperbuddy@1.0/dashboard
- **实时状态**: 通过浏览器访问上述地址查看详细信息

### 命令行管理
```bash
# 查看节点日志
cd ~/hyperbeam-production/HyperBEAM/_build/default/rel/hb
./bin/hb logs

# 重启节点
./bin/hb restart

# 停止节点
./bin/hb stop

# 检查进程状态
pgrep -f "beam.*hb"

# 检查端口占用
lsof -i :8734
```

## 🚨 常见问题排除

### ⚡ 快速诊断

```bash
# 运行全面环境诊断 (推荐首选)
./scripts/diagnose-deployment.sh

# 运行部署测试
./scripts/test-deployment.sh
```

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
| MacBook Pro M4 | ✅ | macOS 15.5 |

## 🛠️ 便捷工具列表

| 工具 | 用途 | 命令 |
|------|------|------|
| 🔍 环境诊断 | 全面检查部署环境 | `./scripts/diagnose-deployment.sh` |
| 🧪 部署测试 | 验证部署脚本完整性 | `./scripts/test-deployment.sh` |
| 🚀 一键部署 | 自动部署 HyperBEAM | `./scripts/deploy-hyperbeam-arm64.sh` |
| 🔧 依赖安装 | 安装系统依赖 | `./scripts/setup-dependencies.sh` |
| 🍎 Apple Silicon修复 | 修复兼容性问题 | `./scripts/fix-apple-silicon.sh` |
| ✅ 配置验证 | 验证节点配置 | `./scripts/validate-config.sh` |
| 📊 节点监控 | 监控节点状态 | `./monitoring/monitor-node.sh --status` |
| 🔗 符号链接 | 创建快捷方式 | `./setup-links.sh` |

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
