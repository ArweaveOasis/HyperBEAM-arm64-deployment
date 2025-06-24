# 🔧 HyperBEAM ARM64 故障排除指南

## 🚨 常见问题

### 1. 构建相关问题

#### 问题：WAMR 构建失败
```
error: invalid command 'a\', expecting 'a', 'c', 'd', 'i', 'q', or 'r'
```

**解决方案：**
```bash
# 运行 Apple Silicon 修复脚本
./scripts/fix-apple-silicon.sh

# 或手动修复
cd _build/default/lib/wamr/c_src/deps/WAMR/core/iwasm/interpreter
sed -i '.bak' -e '742a\' -e 'tbl_inst->is_table64 = 1;' int_table.c
```

#### 问题：CMake 版本警告
```
CMake Warning (dev) at CMakeLists.txt:1 (cmake_minimum_required)
```

**解决方案：**
```bash
# 设置 CMake 策略版本
export CMAKE_FLAGS="-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
```

#### 问题：编译器找不到 Ninja
```
Could not find a package configuration file provided by "ninja"
```

**解决方案：**
```bash
# 安装 Ninja
brew install ninja

# 设置构建系统
export CMAKE_GENERATOR=Ninja
```

### 2. 启动相关问题

#### 问题：节点名冲突
```
{error,{already_started,hb}}
```

**解决方案：**
```bash
# 修改节点名
cd _build/default/rel/hb
sed -i '.bak' 's/-name hb/-name hb_mainnet/' releases/*/vm.args

# 或杀死现有进程
pkill -f "beam.*hb"
```

#### 问题：端口被占用
```
{error,{shutdown,{failed_to_start_child,hb_http_server,{listen_error,eaddrinuse}}}}
```

**解决方案：**
```bash
# 检查端口占用
lsof -i :8734

# 更改配置端口
echo '[{"port", "10000"}, {"mode", "mainnet"}, {"priv_key_location", "hyperbeam-key.json"}].' > config.flat
```

#### 问题：权限错误
```
Permission denied (publickey)
```

**解决方案：**
```bash
# 检查密钥文件权限
chmod 600 hyperbeam-key.json

# 重新生成密钥
./bin/hb eval 'ar_wallet:to_file(ar_wallet:new(), "hyperbeam-key.json").'
```

### 3. 依赖相关问题

#### 问题：Erlang 版本不兼容
```
unsupported Erlang/OTP version
```

**解决方案：**
```bash
# 卸载旧版本
brew uninstall erlang

# 安装兼容版本
brew install erlang@26

# 设置路径
export PATH="/opt/homebrew/opt/erlang@26/bin:$PATH"
```

#### 问题：Rebar3 找不到
```
command not found: rebar3
```

**解决方案：**
```bash
# 安装 Rebar3
brew install rebar3

# 或使用脚本安装
curl -s https://s3.amazonaws.com/rebar3/rebar3 > rebar3
chmod +x rebar3
sudo mv rebar3 /usr/local/bin/
```

#### 问题：Git 克隆失败
```
fatal: could not read from remote repository
```

**解决方案：**
```bash
# 使用 HTTPS 克隆
git clone https://github.com/permaweb/HyperBEAM.git

# 检查网络连接
ping github.com
```

### 4. 运行时问题

#### 问题：Web 界面无法访问
```
This site can't be reached
```

**解决方案：**
```bash
# 检查节点是否运行
./monitoring/monitor-node.sh --status

# 检查端口监听
lsof -i :8734

# 检查配置
./scripts/validate-config.sh
```

#### 问题：内存不足
```
beam.smp killed (out of memory)
```

**解决方案：**
```bash
# 增加 Erlang VM 内存限制
export ERL_FLAGS="+MBas aobf +MBlmbcs 32 +MBmbcgs 16"

# 监控内存使用
./monitoring/monitor-node.sh --resources
```

#### 问题：磁盘空间不足
```
no space left on device
```

**解决方案：**
```bash
# 检查磁盘空间
df -h

# 清理构建缓存
rm -rf _build/default/lib/*/ebin/*.beam
rm -rf ~/.cache/rebar3

# 清理日志
find log/ -name "*.log" -mtime +7 -delete
```

### 5. 网络相关问题

#### 问题：外网无法访问节点
```
Connection timeout
```

**解决方案：**
```bash
# 检查防火墙状态
sudo pfctl -sr

# 检查节点绑定
netstat -an | grep LISTEN

# 配置路由器端口转发
# 转发外部端口到内部 IP:PORT
```

#### 问题：同步速度慢
```
sync progress: 0.1%
```

**解决方案：**
```bash
# 检查网络连接质量
ping 8.8.8.8

# 更换 DNS 服务器
sudo networksetup -setdnsservers Wi-Fi 8.8.8.8 1.1.1.1

# 检查带宽限制
```

## 🔍 诊断工具

### 全面健康检查

```bash
# 运行诊断脚本
./scripts/validate-config.sh

# 检查所有服务状态
./monitoring/monitor-node.sh --status --verbose
```

### 日志分析

```bash
# 查看错误日志
grep -i error log/erlang.log.*

# 实时监控日志
tail -f log/erlang.log.1

# 分析特定时间段日志
sed -n '/2024-06-24 20:00/,/2024-06-24 21:00/p' log/erlang.log.1
```

### 性能分析

```bash
# CPU 使用率
top -pid $(pgrep -f beam)

# 内存使用详情
ps -p $(pgrep -f beam) -o pid,vsz,rss,comm

# 网络连接状态
lsof -p $(pgrep -f beam) -a -i
```

## 🔧 高级故障排除

### 完全重置

```bash
# 停止所有相关进程
pkill -f beam
pkill -f epmd

# 清理所有构建文件
rm -rf _build/
rm -rf deps/

# 重新构建
rebar3 clean
rebar3 release
```

### 调试模式

```bash
# 启用详细日志
export HB_DEBUG=true

# 启动调试模式
./bin/hb console

# 在 Erlang shell 中：
% hb_logger:set_level(debug).
```

### 备份和恢复

```bash
# 备份重要文件
tar -czf hyperbeam-backup-$(date +%Y%m%d).tar.gz config.flat hyperbeam-key.json log/

# 恢复配置
tar -xzf hyperbeam-backup-*.tar.gz
```

## 📞 获取帮助

### 日志收集

在报告问题时，请提供以下信息：

```bash
# 系统信息
system_profiler SPSoftwareDataType SPHardwareDataType

# 构建环境
erlang -version
rebar3 version
cmake --version

# 节点状态
./monitoring/monitor-node.sh --status

# 最近的错误日志
tail -100 log/erlang.log.1 | grep -i error
```

### 支持渠道

- 🐛 **Bug 报告**：[GitHub Issues](https://github.com/YOUR_USERNAME/hyperbeam-arm64-deployment/issues)
- 💬 **社区讨论**：[Discord](https://discord.gg/arweave)
- 📚 **官方文档**：[HyperBEAM Docs](https://docs.hyperbeam.com)
- 📧 **直接联系**：support@hyperbeam.com

### 问题报告模板

```markdown
## 问题描述
[简要描述问题]

## 系统环境
- macOS 版本：
- 芯片类型：
- 内存大小：

## 重现步骤
1. [第一步]
2. [第二步]
3. [第三步]

## 期望结果
[描述期望的行为]

## 实际结果
[描述实际发生的情况]

## 错误日志
```
[粘贴相关的错误日志]
```

## 已尝试的解决方案
[列出已经尝试过的解决方法]
``` 