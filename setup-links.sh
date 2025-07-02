#!/bin/bash

# =============================================================================
# HyperBEAM ARM64 部署工具 - 简化符号链接设置
# 只创建核心的快捷方式
# =============================================================================

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔗 设置 HyperBEAM ARM64 核心快捷方式${NC}"
echo "======================================="

# 检查是否在正确的目录
if [[ ! -d "scripts" ]]; then
    echo -e "${YELLOW}⚠️  请在 hyperbeam-arm64-deployment 根目录下运行此脚本${NC}"
    exit 1
fi

# 创建主要的快捷方式
echo -e "${GREEN}创建核心快捷方式...${NC}"

# 1. 主部署脚本快捷方式
if [[ -f "scripts/deploy-hyperbeam-arm64.sh" ]]; then
    ln -sf scripts/deploy-hyperbeam-arm64.sh deploy-hyperbeam-arm64.sh
    echo -e "${GREEN}✅ ./deploy-hyperbeam-arm64.sh${NC} → scripts/deploy-hyperbeam-arm64.sh"
else
    echo -e "${YELLOW}⚠️  未找到部署脚本${NC}"
fi



echo ""
echo -e "${GREEN}🎉 设置完成！${NC}"
echo ""
echo "现在您可以使用："
echo -e "  ${GREEN}./deploy-hyperbeam-arm64.sh${NC}  # 一键部署"
echo ""
echo "其他工具可直接使用完整路径："
echo "  ./scripts/diagnose-deployment.sh  # 环境诊断"
echo "  ./scripts/test-deployment.sh      # 测试部署环境"
echo "  ./scripts/setup-dependencies.sh   # 安装依赖"
echo "  ./scripts/validate-config.sh      # 验证配置"
echo "  ./scripts/fix-apple-silicon.sh    # Apple Silicon 修复"
echo ""
echo "部署完成后访问 Web 监控界面："
echo "  http://localhost:8734/~meta@1.0/info        # 节点信息"
echo "  http://localhost:8734/~hyperbuddy@1.0/dashboard  # 监控面板"
echo "" 