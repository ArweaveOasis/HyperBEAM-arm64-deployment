#!/bin/bash

# =============================================================================
# HyperBEAM ARM64 一键部署脚本
# 专为 Apple Silicon Mac 设计
# =============================================================================

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为 Apple Silicon
check_apple_silicon() {
    log_info "检查系统架构..."
    
    if [[ $(uname -m) != "arm64" ]]; then
        log_error "此脚本专为 Apple Silicon (ARM64) 设计"
        log_error "当前架构: $(uname -m)"
        exit 1
    fi
    
    if [[ $(uname -s) != "Darwin" ]]; then
        log_error "此脚本专为 macOS 设计"
        exit 1
    fi
    
    log_success "检测到 Apple Silicon Mac"
}

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${BLUE}"
    echo "================================================================"
    echo "     🚀 HyperBEAM ARM64 一键部署工具"
    echo "================================================================"
    echo -e "${NC}"
    echo "此工具将自动为您的 Apple Silicon Mac 部署 HyperBEAM 节点"
    echo ""
    echo "部署内容："
    echo "  ✅ 自动安装所有依赖"
    echo "  ✅ 修复 Apple Silicon 兼容性问题"
    echo "  ✅ 构建 HyperBEAM 节点"
    echo "  ✅ 配置主网节点"
    echo "  ✅ 启动监控工具"
    echo ""
    echo -e "${YELLOW}预计部署时间: 30-60 分钟${NC}"
    echo ""
    read -p "按 Enter 继续，或 Ctrl+C 取消..."
    echo ""
}

# 创建工作目录
setup_workspace() {
    log_info "设置工作环境..."
    
    export HYPERBEAM_HOME="$HOME/hyperbeam-production"
    
    if [[ -d "$HYPERBEAM_HOME" ]]; then
        log_warning "发现现有安装目录: $HYPERBEAM_HOME"
        read -p "是否要备份现有安装并重新部署? (y/N): " choice
        if [[ $choice =~ ^[Yy]$ ]]; then
            mv "$HYPERBEAM_HOME" "$HYPERBEAM_HOME.backup.$(date +%Y%m%d_%H%M%S)"
            log_info "已备份现有安装"
        else
            log_info "取消部署"
            exit 0
        fi
    fi
    
    mkdir -p "$HYPERBEAM_HOME"
    cd "$HYPERBEAM_HOME"
    
    log_success "工作目录已设置: $HYPERBEAM_HOME"
}

# 安装依赖
install_dependencies() {
    log_info "安装系统依赖..."
    
    # 复制依赖安装脚本
    cp "${SCRIPT_DIR}/setup-dependencies.sh" .
    chmod +x setup-dependencies.sh
    
    # 运行依赖安装
    ./setup-dependencies.sh
    
    log_success "依赖安装完成"
}

# 克隆 HyperBEAM 源码
clone_hyperbeam() {
    log_info "克隆 HyperBEAM 源码..."
    
    if [[ ! -d "HyperBEAM" ]]; then
        git clone https://github.com/permaweb/HyperBEAM.git
        cd HyperBEAM
        git checkout beta  # 使用 beta 分支
    else
        cd HyperBEAM
        git pull origin beta
    fi
    
    log_success "HyperBEAM 源码已准备"
}

# 修复 Apple Silicon 兼容性
fix_apple_silicon() {
    log_info "修复 Apple Silicon 兼容性问题..."
    
    # 复制修复脚本
    cp "${SCRIPT_DIR}/fix-apple-silicon.sh" .
    chmod +x fix-apple-silicon.sh
    
    # 运行修复
    ./fix-apple-silicon.sh
    
    log_success "Apple Silicon 兼容性已修复"
}

# 构建 HyperBEAM
build_hyperbeam() {
    log_info "构建 HyperBEAM (这可能需要 20-30 分钟)..."
    
    # 设置构建环境变量
    export CMAKE_GENERATOR=Ninja
    export MAKEFLAGS="-j$(sysctl -n hw.ncpu)"
    
    # 构建
    rebar3 release
    
    if [[ $? -eq 0 ]]; then
        log_success "HyperBEAM 构建成功"
    else
        log_error "HyperBEAM 构建失败"
        exit 1
    fi
}

# 配置节点
configure_node() {
    log_info "配置 HyperBEAM 节点..."
    
    cd "_build/default/rel/hb"
    
    # 创建配置文件
    cat > config.flat << 'EOF'
[
  {"port", "10000"},
  {"mode", "mainnet"},
  {"priv_key_location", "hyperbeam-key.json"}
].
EOF
    
    # 生成密钥（如果不存在）
    if [[ ! -f "hyperbeam-key.json" ]]; then
        log_info "生成节点密钥..."
        ./bin/hb eval 'ar_wallet:to_file(ar_wallet:new(), "hyperbeam-key.json").'
    fi
    
    # 修改 vm.args 避免节点名冲突
    sed -i '.bak' 's/-name hb/-name hb_mainnet/' releases/*/vm.args
    
    log_success "节点配置完成"
}

# 启动节点
start_node() {
    log_info "启动 HyperBEAM 节点..."
    
    # 启动节点
    ./bin/hb daemon
    
    # 等待启动
    sleep 10
    
    # 检查节点状态
    if pgrep -f "beam.*hb_mainnet" > /dev/null; then
        log_success "HyperBEAM 节点启动成功"
        
        # 获取节点信息
        local pid=$(pgrep -f "beam.*hb_mainnet")
        local port=$(lsof -Pan -i TCP -F | grep -A1 "p$pid" | grep ":.*->.*LISTEN" | head -1 | sed 's/.*:\([0-9]*\).*/\1/')
        
        echo ""
        echo -e "${GREEN}🎉 部署成功！${NC}"
        echo "节点信息："
        echo "  PID: $pid"
        echo "  端口: $port"
        echo "  Web界面: http://localhost:$port"
        echo ""
    else
        log_error "节点启动失败，请检查日志"
        exit 1
    fi
}

# 设置监控工具
setup_monitoring() {
    log_info "设置监控工具..."
    
    # 复制监控脚本
    cp "${SCRIPT_DIR}/../monitoring/"*.sh .
    chmod +x *.sh
    
    # 复制配置验证脚本
    cp "${SCRIPT_DIR}/validate-config.sh" .
    chmod +x validate-config.sh
    
    log_success "监控工具已设置"
}

# 显示完成信息
show_completion() {
    echo ""
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}     🎉 HyperBEAM ARM64 部署完成！${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo ""
    echo "部署信息："
    echo "  📁 安装目录: $HYPERBEAM_HOME/HyperBEAM/_build/default/rel/hb"
    echo "  🔧 配置文件: config.flat"
    echo "  🔑 节点密钥: hyperbeam-key.json"
    echo ""
    echo "常用命令："
    echo "  📊 检查状态: ./monitor-node.sh --status"
    echo "  📋 查看日志: ./monitor-node.sh --logs"
    echo "  🔄 重启节点: ./bin/hb restart"
    echo "  🛑 停止节点: ./bin/hb stop"
    echo ""
    echo "接下来的步骤："
    echo "  1. 配置路由器端口转发（如需外网访问）"
    echo "  2. 设置防火墙规则"
    echo "  3. 配置自动启动（可选）"
    echo ""
    echo -e "${YELLOW}💡 更多信息请参阅文档: docs/QUICK-START.md${NC}"
    echo ""
}

# 主函数
main() {
    # 获取脚本目录
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # 执行部署步骤
    check_apple_silicon
    show_welcome
    setup_workspace
    install_dependencies
    clone_hyperbeam
    fix_apple_silicon
    build_hyperbeam
    configure_node
    start_node
    setup_monitoring
    show_completion
}

# 错误处理
trap 'log_error "部署过程中发生错误，请检查上方的错误信息"' ERR

# 运行主函数
main "$@" 