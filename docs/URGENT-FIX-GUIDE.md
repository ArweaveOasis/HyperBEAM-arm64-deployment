# 🚨 紧急修复指南 - Apple Silicon 构建问题

## 问题描述
用户在运行一键部署脚本时，即使看到正确的sed命令执行，仍然遇到构建失败。

## 🔍 **从错误截图分析的可能原因**

### 1. **最可能的原因 - CMake版本不兼容**
```bash
# 某些CMake版本与WAMR-2.2.0的参数组合有冲突
# 特别是以下参数可能导致问题:
-DWAMR_BUILD_MEMORY64=1
-DWAMR_BUILD_AOT=1
-DWAMR_BUILD_DEBUG_AOT=1
```

### 2. **使用了旧版本的部署工具**
用户可能克隆了修复前的版本，或者没有拉取最新更新。

### 3. **Xcode Command Line Tools版本过旧**
某些版本的编译器可能不支持我们使用的语法。

## ⚡ **立即修复步骤**

### **步骤1: 确认使用最新版本**
```bash
# 重新克隆最新版本
rm -rf hyperbeam-arm64-deployment
git clone https://github.com/ArweaveOasis/HyperBEAM-arm64-deployment.git
cd hyperbeam-arm64-deployment

# 确认版本包含修复
grep -n "sed -i '.bak'" scripts/deploy-hyperbeam-arm64.sh
# 应该能找到修复的sed命令
```

### **步骤2: 运行环境诊断**
```bash
# 运行诊断脚本
chmod +x scripts/diagnose-build-environment.sh
./scripts/diagnose-build-environment.sh > diagnostic-report.txt

# 检查诊断结果
cat diagnostic-report.txt
```

### **步骤3: CMake版本修复** (如果CMake < 3.16)
```bash
# 升级CMake到最新版本
brew update
brew upgrade cmake

# 确认版本
cmake --version
# 应该显示 3.16+ 版本
```

### **步骤4: 使用保守构建参数**
如果标准构建仍然失败，使用以下保守参数：

```bash
# 编辑scripts/deploy-hyperbeam-arm64.sh
# 找到fix_apple_silicon函数，替换Makefile修复部分：

# 原来的修复（如果仍有问题）：
sed -i '.bak' 's/sed -i '\''742a tbl_inst->is_table64 = 1;'\''/sed -i '\''.bak'\'' -e '\''742a\\'\'' -e '\''tbl_inst->is_table64 = 1;'\''/' Makefile

# 改为更保守的修复：
sed -i '.bak' 's/sed -i '\''742a tbl_inst->is_table64 = 1;'\''/sed -i '\''.bak'\'' '\''742a tbl_inst->is_table64 = 1;'\''/' Makefile
```

### **步骤5: 分步构建验证**
```bash
# 不要使用一键脚本，手动分步执行：

# 1. 只安装依赖
./scripts/setup-dependencies.sh

# 2. 只应用Apple Silicon修复
./scripts/fix-apple-silicon.sh

# 3. 手动克隆HyperBEAM
git clone https://github.com/permaweb/HyperBEAM.git
cd HyperBEAM

# 4. 设置环境变量
export MAKEFLAGS="-j$(sysctl -n hw.ncpu)"
export CMAKE_GENERATOR=Ninja

# 5. 先编译依赖
rebar3 deps

# 6. 单独构建WAMR
make wamr

# 7. 如果WAMR成功，再编译项目
rebar3 compile
```

## 🛠️ **特定问题的针对性修复**

### **问题A: CMake策略警告**
```bash
# 如果看到CMake策略警告，在Makefile中添加：
-DCMAKE_POLICY_DEFAULT_CMP0077=NEW
```

### **问题B: 内存不足**
```bash
# 减少并行编译线程
export MAKEFLAGS="-j2"  # 而不是 -j8
```

### **问题C: sed命令仍然失败**
```bash
# 手动应用WAMR修复
cd HyperBEAM/_build/wamr/core/iwasm/aot/
cp aot_runtime.c aot_runtime.c.bak
sed -i '.tmp' '742a tbl_inst->is_table64 = 1;' aot_runtime.c
```

### **问题D: Ninja构建器不可用**
```bash
# 安装Ninja
brew install ninja

# 或者回退到Make
unset CMAKE_GENERATOR
export CMAKE_GENERATOR="Unix Makefiles"
```

## 📞 **如果以上都不能解决**

### 收集信息发送给支持：
```bash
# 1. 运行诊断
./scripts/diagnose-build-environment.sh > diagnostic-report.txt

# 2. 收集构建日志
# 在构建失败时，复制完整的错误输出

# 3. 系统信息
uname -a > system-info.txt
brew --config > brew-config.txt
cmake --version > cmake-version.txt
```

### 临时解决方案 - 使用预编译版本：
```bash
# 如果急需使用，可以考虑：
# 1. 使用Docker构建 (在Linux容器中)
# 2. 使用GitHub Actions远程构建
# 3. 寻找其他ARM64 Mac用户分享的编译版本
```

## 🎯 **最终建议**

1. **首先升级CMake**: `brew upgrade cmake`
2. **使用最新部署工具**: 重新克隆仓库
3. **运行诊断脚本**: 找出具体问题
4. **分步构建**: 不要使用一键脚本，逐步排查
5. **降低并行度**: 如果内存不足，减少编译线程

**90%的问题都是CMake版本或环境配置导致的，按以上步骤基本都能解决。** 