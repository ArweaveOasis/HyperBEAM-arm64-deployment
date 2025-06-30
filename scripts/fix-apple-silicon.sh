#!/bin/bash

# Apple Silicon Mac HyperBEAM 兼容性修复脚本
# 自动修复 macOS Apple Silicon 上的已知问题

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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查是否在 Apple Silicon Mac 上运行
check_apple_silicon() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "此脚本仅适用于 macOS"
        exit 1
    fi
    
    ARCH=$(arch)
    if [[ "$ARCH" != "arm64" ]]; then
        log_error "此脚本专为 Apple Silicon (ARM64) Mac 设计"
        log_error "当前架构: $ARCH"
        exit 1
    fi
    
    log_info "确认运行在 Apple Silicon Mac 上 (架构: $ARCH)"
}

# 检查并安装 Homebrew
setup_homebrew() {
    log_step "检查 Homebrew..."
    
    if ! command -v brew >/dev/null 2>&1; then
        log_info "安装 Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # 添加到 PATH
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        log_info "✓ Homebrew 已安装"
        
        # 确保使用 ARM64 版本
        BREW_PREFIX=$(brew --prefix)
        if [[ "$BREW_PREFIX" != "/opt/homebrew" ]]; then
            log_warn "检测到非 ARM64 版本的 Homebrew，路径: $BREW_PREFIX"
            log_info "建议重新安装 ARM64 版本的 Homebrew"
        else
            log_info "✓ 使用 ARM64 原生版本的 Homebrew"
        fi
    fi
}

# 修复 Makefile sed 命令
fix_makefile() {
    log_step "修复 Makefile sed 兼容性..."
    
    if [ ! -f "Makefile" ]; then
        log_warn "当前目录没有 Makefile"
        log_info "请在 HyperBEAM 项目根目录运行此脚本"
        return 1
    fi
    
    # 检查是否已经修复
    if grep -q "sed -i '.bak'" Makefile; then
        log_info "✓ Makefile 已经修复过了"
        return 0
    fi
    
    # 备份原始文件
    cp Makefile Makefile.original
    log_info "已备份原始 Makefile 为 Makefile.original"
    
    # 创建可靠的文件修复脚本，替代有问题的 sed 命令
    log_info "修复 WAMR 文件修改兼容性..."
    
         # 创建修复脚本
    cat > temp_sed_fix.sh << 'EOF'
#!/bin/bash
# 修复 WAMR 文件，使用 awk 代替有问题的 sed 命令

file="./_build/wamr/core/iwasm/aot/aot_runtime.c"
if [ -f "$file" ]; then
    # 备份原文件
    cp "$file" "$file.bak"
    
    # 在第742行后插入内容，使用 awk 确保兼容性
    awk 'NR==742{print; print "tbl_inst->is_table64 = 1;"} NR!=742' "$file.bak" > "$file"
    
    echo "✓ 已修复 $file"
else
    echo "文件 $file 不存在，将在构建时创建后修复"
fi
EOF
    chmod +x temp_sed_fix.sh
    
    # 检查并修复 Makefile 中的 sed 命令
    if grep -q "sed -i.*742a.*tbl_inst" Makefile; then
        log_info "发现需要修复的 sed 命令，替换为兼容的方案..."
        
        # 找到包含有问题的 sed 命令的行号
        local sed_line=$(grep -n "sed -i.*742a.*tbl_inst" Makefile | cut -d: -f1)
        
        if [[ -n "$sed_line" ]]; then
            # 替换为我们的修复脚本
            head -n $((sed_line-1)) Makefile > Makefile.tmp
            echo -e "\t\t./temp_sed_fix.sh; \\" >> Makefile.tmp
            tail -n +$((sed_line+1)) Makefile >> Makefile.tmp
            mv Makefile.tmp Makefile
            
            log_info "✓ 已将第 $sed_line 行的 sed 命令替换为兼容的修复脚本"
        fi
    fi
    
    # 修复 make 命令为 ninja（因为 CMAKE_GENERATOR=Ninja）
    if grep -q "make -C.*wamr.*lib" Makefile; then
        log_info "修复构建命令：make -> ninja..."
        sed -i '.bak' 's/make -C \$(WAMR_DIR)\/lib/ninja -C $(WAMR_DIR)\/lib/' Makefile
        log_info "✓ 已修复构建命令为 ninja"
    fi
    
    log_info "✓ WAMR 兼容性修复完成"
    
    # 同时添加 CMake 策略修复
    log_info "添加 CMake 策略版本修复..."
    if ! grep -q "DCMAKE_POLICY_VERSION_MINIMUM" Makefile; then
        sed -i '.bak2' 's/cmake \\/cmake \\\
\t\t-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \\/' Makefile
        log_info "✓ CMake 策略修复已添加"
    fi
}

# 优化 Homebrew 包
optimize_homebrew_packages() {
    log_step "优化 Homebrew 包为 ARM64 原生版本..."
    
    # 核心依赖包列表
    packages=("erlang" "cmake" "openssl" "pkg-config" "ncurses" "rebar3")
    
    for package in "${packages[@]}"; do
        log_info "优化 $package..."
        
        if brew list "$package" >/dev/null 2>&1; then
            # 强制重新安装为 ARM64 版本
            brew reinstall --force-bottle "$package" 2>/dev/null || {
                log_warn "$package 优化失败，但可能不影响构建"
            }
        else
            log_info "$package 未安装，跳过"
        fi
    done
    
    log_info "✓ Homebrew 包优化完成"
}

# 设置环境变量
setup_environment() {
    log_step "设置编译环境变量..."
    
    # OpenSSL 路径
    OPENSSL_PATH=$(brew --prefix openssl 2>/dev/null)
    if [ -n "$OPENSSL_PATH" ]; then
        echo "export LDFLAGS=\"-L$OPENSSL_PATH/lib\"" >> ~/.zshrc
        echo "export CPPFLAGS=\"-I$OPENSSL_PATH/include\"" >> ~/.zshrc
        log_info "✓ OpenSSL 环境变量已添加到 ~/.zshrc"
        
        # 为当前会话设置
        export LDFLAGS="-L$OPENSSL_PATH/lib"
        export CPPFLAGS="-I$OPENSSL_PATH/include"
        log_info "✓ 当前会话环境变量已设置"
    fi
    
    # 优化构建参数
    echo "export MAKEFLAGS=\"-j$(sysctl -n hw.ncpu)\"" >> ~/.zshrc
    export MAKEFLAGS="-j$(sysctl -n hw.ncpu)"
    log_info "✓ 并行构建优化已设置"
    
    # Rust 环境
    if [ -f ~/.cargo/env ]; then
        source ~/.cargo/env
        log_info "✓ Rust 环境已加载"
    fi
}

# 验证修复
verify_fixes() {
    log_step "验证修复结果..."
    
    local failed=0
    
    # 检查架构
    if [[ "$(arch)" == "arm64" ]]; then
        log_info "✓ 运行在 ARM64 架构"
    else
        log_error "✗ 未运行在 ARM64 架构"
        failed=1
    fi
    
    # 检查必需工具
    for cmd in brew git cmake erl rebar3 rustc; do
        if command -v "$cmd" >/dev/null 2>&1; then
            log_info "✓ $cmd 可用"
        else
            log_error "✗ $cmd 不可用"
            failed=1
        fi
    done
    
    # 检查 Makefile 修复
    if [ -f "Makefile" ] && grep -q "sed -i '.bak'" Makefile; then
        log_info "✓ Makefile sed 修复已应用"
    else
        log_warn "⚠ Makefile 修复未应用或不在项目目录"
    fi
    
    # 检查环境变量
    if [ -n "$LDFLAGS" ] && [ -n "$CPPFLAGS" ]; then
        log_info "✓ 编译环境变量已设置"
    else
        log_warn "⚠ 编译环境变量未设置"
    fi
    
    if [ $failed -eq 1 ]; then
        log_error "某些验证失败，可能需要手动处理"
        return 1
    else
        log_info "✅ 所有验证通过！"
        return 0
    fi
}

# 显示构建指南
show_build_guide() {
    echo
    echo "🎉 Apple Silicon 兼容性修复完成！"
    echo "================================================"
    echo
    echo "下一步构建指南："
    echo "1. 如果还没有克隆 HyperBEAM："
    echo "   git clone https://github.com/permaweb/HyperBEAM.git"
    echo "   cd HyperBEAM"
    echo
    echo "2. 如果已在项目目录，直接构建："
    echo "   rebar3 release"
    echo
    echo "3. 如果遇到问题："
    echo "   - 重新加载 shell: exec zsh"
    echo "   - 清理后重试: rebar3 clean && rebar3 release"
    echo "   - 查看故障排除: docs/run/troubleshooting/build-issues.md"
    echo
    echo "4. 构建成功后："
    echo "   - 准备钱包文件: cp /path/to/wallet.json hyperbeam-key.json"
    echo "   - 创建配置: 参考 docs/run/quick-start/macos-apple-silicon.md"
    echo "   - 启动节点: cd _build/default/rel/hb && ./bin/hb daemon"
    echo
    echo "完整指南: docs/run/quick-start/macos-apple-silicon.md"
    echo "================================================"
}

# 主函数
main() {
    echo "🍎 Apple Silicon Mac HyperBEAM 兼容性修复工具"
    echo "=============================================="
    
    check_apple_silicon
    setup_homebrew
    optimize_homebrew_packages
    setup_environment
    
    # 如果在 HyperBEAM 项目目录，修复 Makefile
    if [ -f "Makefile" ] && [ -f "rebar.config" ]; then
        fix_makefile
    else
        log_info "不在 HyperBEAM 项目目录，跳过 Makefile 修复"
        log_info "请在项目目录再次运行此脚本以修复 Makefile"
    fi
    
    verify_fixes
    show_build_guide
    
    echo
    log_info "修复完成！请重新加载 shell 或运行 'source ~/.zshrc'"
}

# 运行主函数
main "$@" 