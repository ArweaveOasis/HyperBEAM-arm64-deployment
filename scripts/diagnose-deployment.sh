#!/bin/bash

# =============================================================================
# HyperBEAM 一键部署环境诊断工具
# 全面检查部署环境，诊断并提供解决方案
# =============================================================================

# 注意：不使用 set -e，因为我们需要处理命令失败的情况

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 统计变量
checks_passed=0
checks_failed=0
checks_warning=0

echo -e "${CYAN}🔍 HyperBEAM 一键部署环境诊断工具${NC}"
echo "========================================================"
echo "此工具将全面检查部署环境，帮您诊断和解决问题"
echo ""

# 检查函数
check_pass() {
    echo -e "${GREEN}✅ $1${NC}"
    ((checks_passed++))
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
    ((checks_failed++))
}

check_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((checks_warning++))
}

check_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 1. 系统兼容性检查
echo -e "${PURPLE}📱 1. 系统兼容性检查${NC}"
echo "----------------------------------------"

# 操作系统检查
if [[ "$OSTYPE" == "darwin"* ]]; then
    check_pass "运行在 macOS 系统"
    
    # macOS 版本检查
    macos_version=$(sw_vers -productVersion 2>/dev/null || echo "未知")
    if [[ "$macos_version" != "未知" ]]; then
        major_version=$(echo "$macos_version" | cut -d. -f1)
        if [[ "$major_version" -ge 14 ]] 2>/dev/null; then
            check_pass "macOS 版本 $macos_version (支持)"
        else
            check_warn "macOS 版本 $macos_version (建议升级到 14.0+)"
        fi
    else
        check_warn "无法获取 macOS 版本信息"
    fi
else
    check_fail "不在 macOS 系统 (当前: $OSTYPE)"
fi

# 架构检查
arch=$(uname -m)
if [[ "$arch" == "arm64" ]]; then
    check_pass "Apple Silicon (ARM64) 架构"
else
    check_fail "非 Apple Silicon 架构 (当前: $arch)"
fi

echo ""

# 2. 项目结构检查
echo -e "${PURPLE}📁 2. 项目结构检查${NC}"
echo "----------------------------------------"

# 检查是否在正确目录
if [[ -d "scripts" && -f "README.md" ]]; then
    check_pass "在正确的项目根目录"
else
    check_fail "不在项目根目录或项目结构不完整"
    check_info "请确保在 hyperbeam-arm64-deployment 目录下运行"
fi

# 检查关键脚本
scripts_to_check=(
    "scripts/deploy-hyperbeam-arm64.sh"
    "scripts/fix-apple-silicon.sh"
    "scripts/setup-dependencies.sh"
    "scripts/test-deployment.sh"
    "scripts/validate-config.sh"
    "scripts/diagnose-deployment.sh"
)

for script in "${scripts_to_check[@]}"; do
    if [[ -f "$script" && -x "$script" ]]; then
        check_pass "$(basename "$script") 存在且可执行"
    elif [[ -f "$script" ]]; then
        check_warn "$(basename "$script") 存在但不可执行"
        check_info "运行: chmod +x $script"
    else
        check_fail "$(basename "$script") 不存在"
    fi
done

echo ""

# 3. 系统工具检查
echo -e "${PURPLE}🛠️  3. 系统工具检查${NC}"
echo "----------------------------------------"

required_tools=("git" "curl" "sed" "grep" "awk" "readlink" "lsof")
for tool in "${required_tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        check_pass "$tool 可用"
    else
        check_fail "$tool 不可用"
    fi
done

# 检查 Xcode Command Line Tools
if xcode-select -p >/dev/null 2>&1; then
    check_pass "Xcode Command Line Tools 已安装"
else
    check_fail "Xcode Command Line Tools 未安装"
    check_info "运行: xcode-select --install"
fi

echo ""

# 4. 开发依赖检查
echo -e "${PURPLE}⚙️  4. 开发依赖检查${NC}"
echo "----------------------------------------"

# Homebrew
if command -v brew >/dev/null 2>&1; then
    check_pass "Homebrew 已安装"
    
    # 检查 Homebrew 位置
    brew_prefix=$(brew --prefix 2>/dev/null || echo "")
    if [[ "$brew_prefix" == "/opt/homebrew" ]]; then
        check_pass "使用 ARM64 原生 Homebrew"
    elif [[ -n "$brew_prefix" ]]; then
        check_warn "使用 Intel Homebrew ($brew_prefix)"
        check_info "建议重新安装 ARM64 版本"
    else
        check_warn "无法获取 Homebrew 路径"
    fi
else
    check_fail "Homebrew 未安装"
    check_info "运行: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
fi

# Erlang/OTP
if command -v erl >/dev/null 2>&1; then
    erlang_version=$(erl -version 2>&1 | head -1 || echo "版本获取失败")
    check_pass "Erlang/OTP 已安装 ($erlang_version)"
else
    check_fail "Erlang/OTP 未安装"
    check_info "运行: brew install erlang"
fi

# Rebar3
if command -v rebar3 >/dev/null 2>&1; then
    rebar3_version=$(rebar3 version 2>/dev/null || echo "版本获取失败")
    check_pass "Rebar3 已安装 ($rebar3_version)"
else
    check_fail "Rebar3 未安装"
    check_info "运行: brew install rebar3"
fi

# CMake
if command -v cmake >/dev/null 2>&1; then
    cmake_version=$(cmake --version 2>/dev/null | head -1 || echo "版本获取失败")
    check_pass "CMake 已安装 ($cmake_version)"
else
    check_fail "CMake 未安装"
    check_info "运行: brew install cmake"
fi

# Ninja
if command -v ninja >/dev/null 2>&1; then
    ninja_version=$(ninja --version 2>/dev/null || echo "版本获取失败")
    check_pass "Ninja 已安装 (v$ninja_version)"
else
    check_warn "Ninja 未安装 (建议安装以提升构建速度)"
    check_info "运行: brew install ninja"
fi

# Rust
if command -v rustc >/dev/null 2>&1; then
    rust_version=$(rustc --version 2>/dev/null || echo "版本获取失败")
    check_pass "Rust 已安装 ($rust_version)"
else
    check_warn "Rust 未安装 (可选，某些组件需要)"
    check_info "运行: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
fi

echo ""

# 5. 系统资源检查
echo -e "${PURPLE}💻 5. 系统资源检查${NC}"
echo "----------------------------------------"

# 内存检查
if command -v bc >/dev/null 2>&1; then
    memory_gb=$(echo "$(sysctl -n hw.memsize) / 1073741824" | bc 2>/dev/null || echo "0")
else
    # 使用 awk 作为 bc 的替代
    memory_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
    memory_gb=$(echo "$memory_bytes" | awk '{print int($1/1073741824)}')
fi
if [[ "$memory_gb" -ge 8 ]]; then
    check_pass "系统内存: ${memory_gb}GB (充足)"
elif [[ "$memory_gb" -ge 4 ]]; then
    check_warn "系统内存: ${memory_gb}GB (勉强够用，建议8GB+)"
else
    check_fail "系统内存: ${memory_gb}GB (不足，需要至少4GB)"
fi

# 磁盘空间检查
available_gb=$(df -g . | tail -1 | awk '{print $4}')
if [[ "$available_gb" -ge 50 ]]; then
    check_pass "可用磁盘空间: ${available_gb}GB (充足)"
elif [[ "$available_gb" -ge 20 ]]; then
    check_warn "可用磁盘空间: ${available_gb}GB (勉强够用，建议50GB+)"
else
    check_fail "可用磁盘空间: ${available_gb}GB (不足，需要至少20GB)"
fi

# CPU 检查
cpu_count=$(sysctl -n hw.ncpu)
check_pass "CPU 核心数: $cpu_count"

echo ""

# 6. 网络连接检查
echo -e "${PURPLE}🌐 6. 网络连接检查${NC}"
echo "----------------------------------------"

# 基本网络连接
if ping -c 1 -W 3000 google.com >/dev/null 2>&1; then
    check_pass "基本网络连接正常"
elif curl -s --connect-timeout 5 --max-time 10 https://www.google.com >/dev/null 2>&1; then
    check_pass "基本网络连接正常 (HTTP)"
else
    check_warn "网络连接可能异常 (ping/curl 均失败)"
fi

# GitHub 连接
if ping -c 1 -W 3000 github.com >/dev/null 2>&1; then
    check_pass "GitHub 连接正常"
elif curl -s --connect-timeout 5 --max-time 10 https://github.com >/dev/null 2>&1; then
    check_pass "GitHub 连接正常 (HTTP)"
else
    check_warn "GitHub 连接异常，可能影响代码下载"
fi

# 端口可用性检查
common_ports=(8734 10000 1984)
for port in "${common_ports[@]}"; do
    if command -v lsof >/dev/null 2>&1; then
        if lsof -i ":$port" >/dev/null 2>&1; then
            check_warn "端口 $port 被占用"
            local process_id=$(lsof -i ":$port" -t 2>/dev/null | head -1 || echo "未知")
            check_info "占用进程: $process_id"
        else
            check_pass "端口 $port 可用"
        fi
    else
        check_info "端口 $port (无法检查，lsof 不可用)"
    fi
done

echo ""

# 7. 脚本路径解析检查
echo -e "${PURPLE}🔗 7. 脚本路径解析检查${NC}"
echo "----------------------------------------"

# 检查当前脚本路径解析
current_script="${BASH_SOURCE[0]}"
if [[ -L "$current_script" ]]; then
    link_target=$(readlink "$current_script" 2>/dev/null || echo "无法解析")
    check_info "当前脚本是符号链接，目标: $link_target"
else
    check_info "当前脚本不是符号链接"
fi

# 检查主部署脚本
if [[ -L "deploy-hyperbeam-arm64.sh" ]]; then
    deploy_target=$(readlink "deploy-hyperbeam-arm64.sh" 2>/dev/null || echo "无法解析")
    if [[ "$deploy_target" == "scripts/deploy-hyperbeam-arm64.sh" ]]; then
        check_pass "部署脚本符号链接正确"
    else
        check_warn "部署脚本符号链接目标异常: $deploy_target"
    fi
else
    check_warn "部署脚本符号链接不存在"
    check_info "运行: ./setup-links.sh"
fi

echo ""

# 8. 环境变量检查
echo -e "${PURPLE}🌍 8. 环境变量检查${NC}"
echo "----------------------------------------"

# PATH 检查
if echo "$PATH" | grep -q "/opt/homebrew/bin"; then
    check_pass "PATH 包含 Homebrew 路径"
else
    check_warn "PATH 不包含 Homebrew 路径"
    check_info "添加到 ~/.zshrc: export PATH=\"/opt/homebrew/bin:\$PATH\""
fi

# SHELL 检查
if [[ "$SHELL" =~ zsh ]]; then
    check_pass "使用 zsh shell"
else
    check_info "当前 shell: $SHELL"
fi

echo ""

# 总结报告
echo -e "${CYAN}📊 诊断总结${NC}"
echo "========================================================"
echo -e "${GREEN}✅ 通过检查: $checks_passed${NC}"
echo -e "${YELLOW}⚠️  警告项目: $checks_warning${NC}"
echo -e "${RED}❌ 失败项目: $checks_failed${NC}"
echo ""

if [[ $checks_failed -eq 0 ]]; then
    if [[ $checks_warning -eq 0 ]]; then
        echo -e "${GREEN}🎉 环境完美！可以开始部署了${NC}"
        echo ""
        echo "建议的部署步骤："
        echo "1. ./scripts/test-deployment.sh      # 运行部署测试"
        echo "2. ./scripts/deploy-hyperbeam-arm64.sh  # 开始一键部署"
    else
        echo -e "${YELLOW}⚠️  环境基本就绪，但有一些警告项目${NC}"
        echo "可以继续部署，但建议先解决警告项目以获得最佳体验"
        echo ""
        echo "快速修复警告的命令："
        if ! command -v ninja >/dev/null 2>&1; then
            echo "brew install ninja"
        fi
        if [[ -w "." ]]; then
            echo "./setup-links.sh"
        fi
    fi
else
    echo -e "${RED}❌ 环境存在问题，建议先解决失败项目再进行部署${NC}"
    echo ""
    echo "快速修复命令："
    
    if ! command -v brew >/dev/null 2>&1; then
        echo "# 安装 Homebrew"
        echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    fi
    
    if ! command -v erl >/dev/null 2>&1 || ! command -v rebar3 >/dev/null 2>&1 || ! command -v cmake >/dev/null 2>&1; then
        echo "# 安装开发依赖"
        echo "./scripts/setup-dependencies.sh"
    fi
    
    if ! xcode-select -p >/dev/null 2>&1; then
        echo "# 安装 Xcode Command Line Tools"
        echo "xcode-select --install"
    fi
fi

echo ""
echo -e "${BLUE}🔧 其他有用命令:${NC}"
echo "• 完整依赖安装: ./scripts/setup-dependencies.sh"
echo "• Apple Silicon修复: ./scripts/fix-apple-silicon.sh"
echo "• 配置验证: ./scripts/validate-config.sh"
echo "• 创建符号链接: ./setup-links.sh"
echo ""
echo -e "${GREEN}诊断完成！${NC}" 