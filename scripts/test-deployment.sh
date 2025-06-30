#!/bin/bash

# =============================================================================
# HyperBEAM ARM64 部署测试脚本
# 用于验证一键部署脚本的改进是否正常工作
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# 测试计数器
tests_passed=0
tests_failed=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    log_info "测试: $test_name"
    
    if eval "$test_command"; then
        log_success "$test_name"
        ((tests_passed++))
    else
        log_error "$test_name"
        ((tests_failed++))
    fi
    echo
}

# 主测试函数
main() {
    echo -e "${BLUE}🧪 HyperBEAM ARM64 部署测试${NC}"
    echo "=================================="
    echo
    
    # 检查脚本是否存在
    run_test "部署脚本存在检查" "test -f 'scripts/deploy-hyperbeam-arm64.sh'"
    
    # 检查修复脚本是否存在
    run_test "修复脚本存在检查" "test -f 'scripts/fix-apple-silicon.sh'"
    
    # 检查脚本权限
    run_test "部署脚本可执行权限" "test -x 'scripts/deploy-hyperbeam-arm64.sh'"
    
    # 检查脚本语法
    run_test "部署脚本语法检查" "bash -n 'scripts/deploy-hyperbeam-arm64.sh'"
    
    # 检查关键函数是否存在
    run_test "预检函数存在" "grep -q 'precheck_environment()' 'scripts/deploy-hyperbeam-arm64.sh'"
    run_test "Apple Silicon修复函数存在" "grep -q 'fix_apple_silicon()' 'scripts/deploy-hyperbeam-arm64.sh'"
    run_test "构建函数改进检查" "grep -q 'rebar3 clean' 'scripts/deploy-hyperbeam-arm64.sh'"
    run_test "端口冲突处理检查" "grep -q 'lsof.*10000' 'scripts/deploy-hyperbeam-arm64.sh'"
    
    # 检查错误处理
    run_test "错误处理函数存在" "grep -q 'handle_error()' 'scripts/deploy-hyperbeam-arm64.sh'"
    run_test "清理函数存在" "grep -q 'cleanup_on_failure()' 'scripts/deploy-hyperbeam-arm64.sh'"
    
    # 检查系统兼容性
    if [[ $(uname -m) == "arm64" && $(uname -s) == "Darwin" ]]; then
        run_test "系统兼容性" "true"
        
        # 检查必需工具
        for tool in git curl sed grep awk; do
            run_test "$tool 工具可用" "command -v $tool >/dev/null 2>&1"
        done
        
        # 检查 fix-apple-silicon.sh 是否包含关键修复
        run_test "Apple Silicon修复内容完整" "grep -q 'sed.*\.bak' 'scripts/fix-apple-silicon.sh'"
        
        # 检查磁盘空间
        local available_gb=$(df -g . | tail -1 | awk '{print $4}')
        run_test "磁盘空间充足 (${available_gb}GB)" "test $available_gb -gt 5"
        
    else
        log_warning "不在 Apple Silicon Mac 上，跳过部分测试"
    fi
    
    # 检查文档
    run_test "快速开始文档存在" "test -f 'docs/QUICK-START.md'"
    run_test "故障排除文档存在" "test -f 'docs/TROUBLESHOOTING.md'"
    
    # 检查监控脚本
    run_test "监控脚本存在" "test -f 'monitoring/monitor-node.sh'"
    
    # 显示测试结果
    echo "=================================="
    echo -e "${GREEN}通过测试: $tests_passed${NC}"
    echo -e "${RED}失败测试: $tests_failed${NC}"
    echo
    
    if [[ $tests_failed -eq 0 ]]; then
        echo -e "${GREEN}🎉 所有测试通过！一键部署脚本已准备就绪。${NC}"
        echo
        echo "现在可以运行："
        echo "  ./scripts/deploy-hyperbeam-arm64.sh"
        echo
        return 0
    else
        echo -e "${RED}❌ 有测试失败，请检查问题后重试。${NC}"
        echo
        return 1
    fi
}

# 运行测试
main "$@" 