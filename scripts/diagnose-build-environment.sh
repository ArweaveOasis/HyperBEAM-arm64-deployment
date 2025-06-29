#!/bin/bash

# HyperBEAM Apple Silicon 构建环境诊断脚本
# 用于排查构建失败问题

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "${BLUE}[SECTION]${NC} $1"
    echo "================================"
}

echo "🔍 HyperBEAM Apple Silicon 构建环境诊断"
echo "========================================"
echo

# 1. 系统信息
log_section "1. 系统架构检查"
ARCH=$(arch)
echo "架构: $ARCH"
if [[ "$ARCH" != "arm64" ]]; then
    log_error "不是 ARM64 架构！"
    exit 1
else
    log_info "✓ ARM64 架构确认"
fi

MACOS_VERSION=$(sw_vers -productVersion)
echo "macOS 版本: $MACOS_VERSION"

# 2. 开发工具版本
log_section "2. 开发工具版本检查"

# Xcode Command Line Tools
if xcode-select -p >/dev/null 2>&1; then
    XCODE_PATH=$(xcode-select -p)
    echo "Xcode Command Line Tools: $XCODE_PATH"
    
    # 检查版本
    if command -v clang >/dev/null 2>&1; then
        CLANG_VERSION=$(clang --version | head -1)
        echo "Clang: $CLANG_VERSION"
    fi
else
    log_error "✗ Xcode Command Line Tools 未安装"
    echo "请运行: xcode-select --install"
fi

# CMake
if command -v cmake >/dev/null 2>&1; then
    CMAKE_VERSION=$(cmake --version | head -1)
    echo "CMake: $CMAKE_VERSION"
    
    # 检查CMake版本是否足够新
    CMAKE_VERSION_NUM=$(cmake --version | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    if [[ "$CMAKE_VERSION_NUM" < "3.16.0" ]]; then
        log_warn "⚠ CMake版本可能过旧，建议升级到3.16+: brew upgrade cmake"
    else
        log_info "✓ CMake版本合适"
    fi
else
    log_error "✗ CMake 未安装"
fi

# Git
if command -v git >/dev/null 2>&1; then
    GIT_VERSION=$(git --version)
    echo "Git: $GIT_VERSION"
    log_info "✓ Git 可用"
else
    log_error "✗ Git 未安装"
fi

# 3. Homebrew检查
log_section "3. Homebrew 环境检查"
if command -v brew >/dev/null 2>&1; then
    BREW_PREFIX=$(brew --prefix)
    echo "Homebrew 路径: $BREW_PREFIX"
    
    if [[ "$BREW_PREFIX" == "/opt/homebrew" ]]; then
        log_info "✓ 使用ARM64原生Homebrew"
    else
        log_warn "⚠ 可能使用Intel版本Homebrew: $BREW_PREFIX"
        log_warn "建议重新安装ARM64版本的Homebrew"
    fi
    
    # 检查关键包
    echo
    echo "关键包版本检查:"
    for pkg in erlang rebar3 cmake openssl; do
        if brew list "$pkg" >/dev/null 2>&1; then
            VERSION=$(brew list --versions "$pkg" | head -1)
            echo "  $pkg: $VERSION"
        else
            echo "  $pkg: 未安装"
        fi
    done
else
    log_error "✗ Homebrew 未安装"
fi

# 4. Erlang/OTP检查
log_section "4. Erlang/OTP 环境检查"
if command -v erl >/dev/null 2>&1; then
    ERL_VERSION=$(erl -version 2>&1 | head -1)
    echo "Erlang: $ERL_VERSION"
    log_info "✓ Erlang 可用"
    
    # 检查架构
    ERL_ARCH=$(erl -eval 'io:format("~s~n", [erlang:system_info(system_architecture)]), halt().' -noshell)
    echo "Erlang 架构: $ERL_ARCH"
    if [[ "$ERL_ARCH" == *"aarch64"* ]]; then
        log_info "✓ Erlang ARM64原生版本"
    else
        log_warn "⚠ Erlang可能不是ARM64原生版本"
    fi
else
    log_error "✗ Erlang 未安装"
fi

if command -v rebar3 >/dev/null 2>&1; then
    REBAR3_VERSION=$(rebar3 version)
    echo "Rebar3: $REBAR3_VERSION"
    log_info "✓ Rebar3 可用"
else
    log_error "✗ Rebar3 未安装"
fi

# 5. Rust环境检查
log_section "5. Rust 环境检查"
if command -v rustc >/dev/null 2>&1; then
    RUST_VERSION=$(rustc --version)
    echo "Rust: $RUST_VERSION"
    
    RUST_TARGET=$(rustc -vV | grep host | cut -d' ' -f2)
    echo "Rust目标: $RUST_TARGET"
    if [[ "$RUST_TARGET" == *"aarch64-apple-darwin"* ]]; then
        log_info "✓ Rust ARM64原生版本"
    else
        log_warn "⚠ Rust可能不是ARM64原生版本"
    fi
else
    log_warn "⚠ Rust 未安装 (某些功能需要)"
fi

# 6. 环境变量检查
log_section "6. 构建环境变量检查"
echo "PATH: $PATH"
echo "MAKEFLAGS: ${MAKEFLAGS:-未设置}"
echo "CMAKE_GENERATOR: ${CMAKE_GENERATOR:-未设置}"
echo "LDFLAGS: ${LDFLAGS:-未设置}"
echo "CPPFLAGS: ${CPPFLAGS:-未设置}"

# 7. 部署工具版本检查
log_section "7. 部署工具版本检查"
if [[ -f "scripts/deploy-hyperbeam-arm64.sh" ]]; then
    log_info "✓ 在正确的部署工具目录"
    
    # 检查是否有最新的修复
    if grep -q "sed -i '.bak'" ../Makefile 2>/dev/null || grep -q "sed -i '.bak'" Makefile 2>/dev/null; then
        log_info "✓ 包含Apple Silicon修复"
    else
        log_warn "⚠ 可能缺少最新的Apple Silicon修复"
        log_warn "建议重新克隆最新版本:"
        echo "  git clone https://github.com/ArweaveOasis/HyperBEAM-arm64-deployment.git"
    fi
else
    log_warn "⚠ 不在部署工具目录或文件缺失"
fi

# 8. 磁盘空间检查
log_section "8. 系统资源检查"
DISK_AVAILABLE=$(df -h . | tail -1 | awk '{print $4}')
echo "可用磁盘空间: $DISK_AVAILABLE"

MEMORY_GB=$(echo "$(sysctl -n hw.memsize) / 1073741824" | bc)
echo "系统内存: ${MEMORY_GB}GB"

CPU_CORES=$(sysctl -n hw.ncpu)
echo "CPU核心数: $CPU_CORES"

if [[ $MEMORY_GB -lt 8 ]]; then
    log_warn "⚠ 内存可能不足，建议8GB+用于构建"
fi

echo
echo "🎯 诊断完成!"
echo "========================================"
echo "如果发现问题，请参考以下解决方案："
echo
echo "1. 更新部署工具:"
echo "   git clone https://github.com/ArweaveOasis/HyperBEAM-arm64-deployment.git"
echo 
echo "2. 升级开发工具:"
echo "   brew update && brew upgrade cmake"
echo "   xcode-select --install"
echo
echo "3. 设置构建优化:"
echo "   export MAKEFLAGS=\"-j$CPU_CORES\""
echo "   export CMAKE_GENERATOR=Ninja"
echo
echo "4. 如果仍有问题，请将此诊断报告发送给技术支持" 