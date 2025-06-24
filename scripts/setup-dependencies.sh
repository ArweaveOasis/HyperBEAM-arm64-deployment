#!/bin/bash

# HyperBEAM 依赖安装脚本
# 支持 Ubuntu/Debian, CentOS/RHEL/Rocky Linux, 和 macOS

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            source /etc/os-release
            OS=$ID
            VER=$VERSION_ID
        else
            log_error "无法检测 Linux 发行版"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        VER=$(sw_vers -productVersion)
    else
        log_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi
    
    log_info "检测到操作系统: $OS $VER"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 安装系统依赖
install_system_deps() {
    log_info "安装系统依赖..."
    
    case $OS in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y --no-install-recommends \
                build-essential \
                cmake \
                git \
                pkg-config \
                ncurses-dev \
                libssl-dev \
                curl \
                ca-certificates \
                wget
            ;;
        centos|rhel|rocky|almalinux)
            # 检查包管理器
            if command_exists dnf; then
                PKG_MANAGER="dnf"
            elif command_exists yum; then
                PKG_MANAGER="yum"
            else
                log_error "找不到包管理器 (dnf/yum)"
                exit 1
            fi
            
            sudo $PKG_MANAGER install -y epel-release || true
            sudo $PKG_MANAGER groupinstall -y "Development Tools"
            sudo $PKG_MANAGER install -y \
                cmake \
                git \
                pkgconfig \
                ncurses-devel \
                openssl-devel \
                curl \
                ca-certificates \
                wget
            ;;
        fedora)
            sudo dnf groupinstall -y "Development Tools"
            sudo dnf install -y \
                cmake \
                git \
                pkgconfig \
                ncurses-devel \
                openssl-devel \
                curl \
                ca-certificates \
                wget
            ;;
        macos)
            if ! command_exists brew; then
                log_info "安装 Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            brew install cmake git pkg-config openssl ncurses
            ;;
        *)
            log_error "不支持的操作系统: $OS"
            exit 1
            ;;
    esac
    
    log_info "系统依赖安装完成"
}

# 安装 Erlang/OTP
install_erlang() {
    if command_exists erl; then
        ERLANG_VERSION=$(erl -version 2>&1 | grep -o 'Erlang.*' || echo "未知")
        log_info "Erlang 已安装: $ERLANG_VERSION"
        return
    fi
    
    log_info "安装 Erlang/OTP..."
    
    case $OS in
        ubuntu|debian)
            sudo apt-get install -y erlang
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                sudo dnf install -y erlang
            else
                sudo yum install -y erlang
            fi
            ;;
        macos)
            brew install erlang
            ;;
    esac
    
    if command_exists erl; then
        log_info "Erlang/OTP 安装成功"
    else
        log_error "Erlang/OTP 安装失败"
        exit 1
    fi
}

# 安装 Rebar3
install_rebar3() {
    if command_exists rebar3; then
        REBAR3_VERSION=$(rebar3 version)
        log_info "Rebar3 已安装: $REBAR3_VERSION"
        return
    fi
    
    log_info "安装 Rebar3..."
    
    case $OS in
        macos)
            brew install rebar3
            ;;
        *)
            # 直接下载二进制文件
            wget https://s3.amazonaws.com/rebar3/rebar3
            chmod +x rebar3
            sudo mv rebar3 /usr/local/bin/
            ;;
    esac
    
    if command_exists rebar3; then
        log_info "Rebar3 安装成功"
    else
        log_error "Rebar3 安装失败"
        exit 1
    fi
}

# 安装 Rust
install_rust() {
    if command_exists rustc; then
        RUST_VERSION=$(rustc --version)
        log_info "Rust 已安装: $RUST_VERSION"
        return
    fi
    
    log_info "安装 Rust..."
    
    # 使用 rustup 安装
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    # 重新加载环境
    source ~/.cargo/env
    
    if command_exists rustc; then
        log_info "Rust 安装成功"
    else
        log_error "Rust 安装失败"
        exit 1
    fi
}

# 安装 Node.js（可选）
install_nodejs() {
    if command_exists node; then
        NODE_VERSION=$(node --version)
        log_info "Node.js 已安装: $NODE_VERSION"
        return
    fi
    
    log_info "安装 Node.js..."
    
    case $OS in
        ubuntu|debian)
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        centos|rhel|rocky|almalinux|fedora)
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            if command_exists dnf; then
                sudo dnf install -y nodejs npm
            else
                sudo yum install -y nodejs npm
            fi
            ;;
        macos)
            brew install node
            ;;
    esac
    
    if command_exists node; then
        log_info "Node.js 安装成功"
    else
        log_warn "Node.js 安装失败（可选依赖）"
    fi
}

# 验证安装
verify_installation() {
    log_info "验证安装..."
    
    local failed=0
    
    # 必需依赖
    for cmd in git cmake erl rebar3 rustc; do
        if command_exists $cmd; then
            log_info "✓ $cmd 已安装"
        else
            log_error "✗ $cmd 未安装"
            failed=1
        fi
    done
    
    # 可选依赖
    if command_exists node; then
        log_info "✓ node (可选) 已安装"
    else
        log_warn "⚠ node (可选) 未安装"
    fi
    
    if [ $failed -eq 1 ]; then
        log_error "某些必需依赖安装失败"
        exit 1
    fi
    
    log_info "所有依赖验证通过！"
}

# 修复平台特定问题
fix_platform_issues() {
    log_info "检查平台特定问题..."
    
    if [[ "$OS" == "macos" ]]; then
        log_info "检测到 macOS，检查系统架构和 Makefile 兼容性..."
        
        # 检查架构
        ARCH=$(arch)
        log_info "系统架构: $ARCH"
        
        if [[ "$ARCH" == "arm64" ]]; then
            log_info "检测到 Apple Silicon (ARM64)"
            
            # 确保使用原生 ARM64 版本的工具
            if command_exists brew; then
                log_info "优化 Homebrew 包为原生 ARM64 版本..."
                brew install --force-bottle erlang 2>/dev/null || true
                brew install --force-bottle cmake 2>/dev/null || true
            fi
        fi
        
        # 检查当前目录是否有 Makefile
        if [ -f "Makefile" ]; then
            # 检查是否已经修复
            if grep -q "sed -i '.bak'" Makefile; then
                log_info "Makefile 已经修复过了"
            else
                log_warn "发现 Makefile sed 兼容性问题，尝试自动修复..."
                
                # 尝试自动修复
                if sed -i '.bak' 's/sed -i '\''742a tbl_inst->is_table64 = 1;'\''/sed -i '\''.bak'\'' -e '\''742a\\'\'' -e '\''tbl_inst->is_table64 = 1;'\''/' Makefile 2>/dev/null; then
                    log_info "✓ Makefile 自动修复成功"
                else
                    log_warn "自动修复失败，请手动修复"
                    log_info "请参考 docs/run/troubleshooting/build-issues.md"
                fi
            fi
        else
            log_info "当前目录没有 Makefile，克隆 HyperBEAM 后再运行此脚本以修复兼容性问题"
        fi
        
        # 检查 OpenSSL 路径
        if command_exists brew; then
            OPENSSL_PATH=$(brew --prefix openssl 2>/dev/null)
            if [ -n "$OPENSSL_PATH" ]; then
                log_info "OpenSSL 路径: $OPENSSL_PATH"
                log_info "如果遇到 OpenSSL 相关编译错误，请运行:"
                echo "  export LDFLAGS=\"-L$OPENSSL_PATH/lib\""
                echo "  export CPPFLAGS=\"-I$OPENSSL_PATH/include\""
            fi
        fi
    fi
}

# 显示下一步操作
show_next_steps() {
    log_info "依赖安装完成！"
    echo
    echo "下一步操作："
    echo "1. 获取 Arweave 钱包文件并保存为 hyperbeam-key.json"
    echo "2. 克隆 HyperBEAM 仓库:"
    echo "   git clone https://github.com/permaweb/HyperBEAM.git"
    echo "3. 进入目录并构建:"
    echo "   cd HyperBEAM"
    echo "   rebar3 release"
    echo "4. 参考快速开始指南完成配置:"
    echo "   docs/run/quick-start/linux-amd64.md"
    echo
}

# 主函数
main() {
    echo "HyperBEAM 依赖安装脚本"
    echo "========================="
    
    detect_os
    install_system_deps
    install_erlang
    install_rebar3
    install_rust
    install_nodejs
    verify_installation
    fix_platform_issues
    show_next_steps
}

# 运行主函数
main "$@" 