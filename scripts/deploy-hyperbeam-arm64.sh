#!/bin/bash

# =============================================================================
# HyperBEAM ARM64 一键部署脚本 (改进版)
# 专为 Apple Silicon Mac 设计
# 版本: v2.0.0 - 包含手动测试验证的所有修复
# =============================================================================
#
# 🚀 主要改进:
#   ✅ 集成 Apple Silicon 兼容性修复
#   ✅ 智能端口冲突处理
#   ✅ 系统环境预检
#   ✅ 改进的错误处理和恢复
#   ✅ 详细的部署验证
#   ✅ 更好的用户指导
#
# 🎯 基于手动部署成功经验优化
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

# 预检系统环境
precheck_environment() {
    log_info "执行系统环境预检..."
    
    local issues=0
    
    # 检查必需工具
    local required_tools=("git" "curl" "sed" "grep" "awk")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log_error "缺少必需工具: $tool"
            ((issues++))
        fi
    done
    
    # 检查磁盘空间 (至少需要 10GB)
    local available_space=$(df -g . | tail -1 | awk '{print $4}')
    if [[ $available_space -lt 10 ]]; then
        log_warning "磁盘可用空间不足: ${available_space}GB (建议至少10GB)"
        ((issues++))
    fi
    
    # 检查内存 (建议至少 8GB)
    local memory_gb=$(echo "$(sysctl -n hw.memsize) / 1073741824" | bc 2>/dev/null || echo "0")
    if [[ $memory_gb -lt 8 ]]; then
        log_warning "系统内存较少: ${memory_gb}GB (建议至少8GB)"
    fi
    
    # 检查网络连接
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        log_warning "网络连接可能有问题，请确保网络正常"
    fi
    
    # 检查是否已有旧的 HyperBEAM 进程
    if pgrep -f "beam.*hb" >/dev/null 2>&1; then
        log_warning "发现运行中的 HyperBEAM 进程，可能会导致冲突"
        log_info "运行中的进程: $(pgrep -f 'beam.*hb' | tr '\n' ' ')"
        
        read -p "是否要停止现有进程并继续? (y/N): " choice
        if [[ $choice =~ ^[Yy]$ ]]; then
            pkill -f "beam.*hb" 2>/dev/null || true
            sleep 3
            log_info "已停止现有进程"
        else
            log_info "用户选择保留现有进程，退出部署"
            exit 0
        fi
    fi
    
    if [[ $issues -gt 0 ]]; then
        log_error "预检发现 $issues 个问题，请解决后重试"
        exit 1
    fi
    
    log_success "系统环境预检通过"
}

# 清理函数
cleanup_on_failure() {
    log_info "执行清理操作..."
    
    # 停止可能启动失败的进程
    pkill -f "beam.*hb" 2>/dev/null || true
    
    # 清理临时文件
    rm -f /tmp/hyperbeam-*.tmp 2>/dev/null || true
    
    log_info "清理完成"
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
    
    # 确保在正确的工作目录
    cd "$HYPERBEAM_HOME"
    
    # 复制修复脚本
    cp "${SCRIPT_DIR}/fix-apple-silicon.sh" .
    chmod +x fix-apple-silicon.sh
    
    # 运行修复（在 HyperBEAM 目录内）
    cd HyperBEAM
    ../fix-apple-silicon.sh
    
    log_success "Apple Silicon 兼容性已修复"
}

# 构建 HyperBEAM
build_hyperbeam() {
    log_info "构建 HyperBEAM (这可能需要 20-30 分钟)..."
    
    # 确保在正确的工作目录，然后进入 HyperBEAM 目录
    cd "$HYPERBEAM_HOME"
    cd HyperBEAM
    
    # 设置构建环境变量
    export CMAKE_GENERATOR=Ninja
    export MAKEFLAGS="-j$(sysctl -n hw.ncpu)"
    
    # 重新加载环境变量
    source ~/.zshrc 2>/dev/null || true
    
    # 清理之前的构建 (可选)
    log_info "清理之前的构建缓存..."
    rebar3 clean || true
    
    # 开始构建
    log_info "开始编译 HyperBEAM..."
    if rebar3 release; then
        log_success "HyperBEAM 构建成功"
    else
        log_error "HyperBEAM 构建失败"
        log_error "常见解决方案:"
        log_error "1. 检查是否有旧进程占用端口: lsof -i :8734"
        log_error "2. 重新运行 Apple Silicon 修复: ../fix-apple-silicon.sh"
        log_error "3. 检查系统依赖: brew doctor"
        exit 1
    fi
}

# 配置节点
configure_node() {
    log_info "配置 HyperBEAM 节点..."
    
    # 确保在正确的工作目录，然后进入构建目录
    cd "$HYPERBEAM_HOME/HyperBEAM"
    cd "_build/default/rel/hb"
    
    # 检查并停止冲突的进程
    log_info "检查端口冲突..."
    local conflicting_pid=$(lsof -ti :10000 2>/dev/null || true)
    if [[ -n "$conflicting_pid" ]]; then
        log_warning "发现端口 10000 被进程 $conflicting_pid 占用，正在停止..."
        kill -9 "$conflicting_pid" 2>/dev/null || true
        sleep 2
    fi
    
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
        # 先验证 HyperBEAM 可以启动
        if ! timeout 10 ./bin/hb eval 'ar_wallet:to_file(ar_wallet:new(), "hyperbeam-key.json").' 2>/dev/null; then
            log_warning "自动生成密钥失败，使用备用方法..."
            # 创建一个基本的密钥文件作为占位符
            echo '{"kty":"RSA"}' > hyperbeam-key.json.tmp
            mv hyperbeam-key.json.tmp hyperbeam-key.json
            log_warning "已创建临时密钥文件，建议稍后手动更新"
        fi
    fi
    
    # 修改 vm.args 避免节点名冲突
    if [[ -f "releases/0.0.1/vm.args" ]]; then
        sed -i '.bak' 's/-name hb/-name hb_mainnet/' releases/*/vm.args
        log_info "已修改节点名避免冲突"
    fi
    
    log_success "节点配置完成"
}

# 启动节点 (改进版)
start_node() {
    log_info "启动 HyperBEAM 节点..."
    
    # 确保在正确目录
    if [[ ! -f "bin/hb" ]]; then
        log_error "未找到 HyperBEAM 可执行文件"
        exit 1
    fi
    
    # 检查端口是否空闲
    local port=$(grep -o '"port"[^"]*"[^"]*"[0-9]*"' config.flat | grep -o '[0-9]*' || echo "10000")
    if lsof -i ":$port" >/dev/null 2>&1; then
        log_warning "端口 $port 仍被占用，等待释放..."
        sleep 5
        
        if lsof -i ":$port" >/dev/null 2>&1; then
            log_error "端口 $port 持续被占用，请手动处理"
            log_error "运行: lsof -i :$port"
            exit 1
        fi
    fi
    
    # 启动节点
    log_info "启动节点守护进程..."
    ./bin/hb daemon
    
    # 等待启动完成
    log_info "等待节点启动..."
    local max_attempts=30
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if pgrep -f "beam.*hb" > /dev/null 2>&1; then
            sleep 2  # 额外等待确保完全启动
            
            # 验证端口监听
            if lsof -i ":$port" >/dev/null 2>&1; then
                log_success "HyperBEAM 节点启动成功"
                
                # 获取节点信息
                local pid=$(pgrep -f "beam.*hb" | head -1)
                
                echo ""
                echo -e "${GREEN}🎉 部署成功！${NC}"
                echo "节点信息："
                echo "  PID: $pid"
                echo "  端口: $port"
                echo "  Web界面: http://localhost:$port"
                echo "  配置文件: $(pwd)/config.flat"
                echo "  密钥文件: $(pwd)/hyperbeam-key.json"
                echo ""
                return 0
            fi
        fi
        
        ((attempt++))
        sleep 2
    done
    
    log_error "节点启动超时或失败"
    log_error "请检查日志: ./bin/hb logs"
    exit 1
}

# 设置监控工具
setup_monitoring() {
    log_info "设置监控工具..."
    
    # 确保在正确的工作目录
    cd "$HYPERBEAM_HOME"
    
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
    echo "  🌐 Web界面: http://localhost:$(grep -o '[0-9]*' $HYPERBEAM_HOME/HyperBEAM/_build/default/rel/hb/config.flat || echo "10000")"
    echo ""
    echo "常用命令："
    echo "  📊 检查状态: cd $HYPERBEAM_HOME && ./monitor-node.sh --status"
    echo "  📋 查看日志: cd $HYPERBEAM_HOME/HyperBEAM/_build/default/rel/hb && ./bin/hb logs"
    echo "  🔄 重启节点: cd $HYPERBEAM_HOME/HyperBEAM/_build/default/rel/hb && ./bin/hb restart"
    echo "  🛑 停止节点: cd $HYPERBEAM_HOME/HyperBEAM/_build/default/rel/hb && ./bin/hb stop"
    echo ""
    echo "验证部署："
    echo "  1. 检查进程: pgrep -f 'beam.*hb'"
    echo "  2. 检查端口: lsof -i :$(grep -o '[0-9]*' $HYPERBEAM_HOME/HyperBEAM/_build/default/rel/hb/config.flat || echo "10000")"
    echo "  3. 访问 Web 界面确认节点运行状态"
    echo ""
    echo "接下来的步骤："
    echo "  1. 📊 监控节点性能和日志"
    echo "  2. 🔧 根据需要调整配置文件"
    echo "  3. 🔄 设置自动启动（可选）"
    echo "  4. 🔐 备份节点密钥文件"
    echo ""
    echo -e "${YELLOW}💡 重要提醒：${NC}"
    echo "  • 定期备份密钥文件: cp hyperbeam-key.json ~/Desktop/hyperbeam-backup.json"
    echo "  • 监控系统资源使用情况"
    echo "  • 关注 HyperBEAM 更新公告"
    echo ""
    echo -e "${YELLOW}📚 更多信息请参阅：${NC}"
    echo "  • 快速指南: docs/QUICK-START.md"
    echo "  • 故障排除: docs/TROUBLESHOOTING.md" 
    echo "  • 监控指南: docs/MONITORING.md"
    echo ""
    
    # 最终验证
    local node_pid=$(pgrep -f "beam.*hb" | head -1)
    local node_port=$(grep -o '[0-9]*' $HYPERBEAM_HOME/HyperBEAM/_build/default/rel/hb/config.flat || echo "10000")
    
    if [[ -n "$node_pid" ]] && lsof -i ":$node_port" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 部署验证：节点正在正常运行 (PID: $node_pid, 端口: $node_port)${NC}"
    else
        echo -e "${YELLOW}⚠️  部署验证：请手动确认节点状态${NC}"
    fi
    echo ""
}

# 主函数
main() {
    # 获取脚本目录
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # 执行部署步骤
    check_apple_silicon
    precheck_environment
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
handle_error() {
    local exit_code=$?
    local line_number=$1
    
    log_error "部署失败 (退出码: $exit_code, 行: $line_number)"
    log_error "请检查上方的错误信息"
    
    # 提供调试信息
    echo ""
    echo "🔍 调试信息:"
    echo "  脚本目录: ${SCRIPT_DIR:-未设置}"
    echo "  工作目录: $(pwd)"
    echo "  当前用户: $(whoami)"
    echo "  系统架构: $(uname -m)"
    echo ""
    echo "📞 获取帮助:"
    echo "  1. 查看故障排除指南: docs/TROUBLESHOOTING.md"
    echo "  2. 运行诊断工具: scripts/diagnose-build-environment.sh"
    echo "  3. 检查日志文件"
    echo ""
    
    # 如果是在构建阶段失败，提供恢复建议
    if [[ -d "HyperBEAM" ]]; then
        echo "💡 恢复建议:"
        echo "  cd HyperBEAM"
        echo "  ../fix-apple-silicon.sh"
        echo "  rebar3 clean && rebar3 release"
        echo ""
    fi
    
    cleanup_on_failure
    exit $exit_code
}

# 设置错误处理
trap 'handle_error $LINENO' ERR

# 运行主函数
main "$@" 