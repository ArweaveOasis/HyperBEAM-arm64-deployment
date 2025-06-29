#!/bin/bash

# =============================================================================
# HyperBEAM ARM64 部署工具符号链接设置脚本
# 创建便捷的符号链接以保持向后兼容性
# =============================================================================

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔗 设置 HyperBEAM ARM64 部署工具符号链接${NC}"
echo "============================================"

# 检查是否在正确的目录
if [[ ! -d "scripts" ]] || [[ ! -d "monitoring" ]]; then
    echo -e "${YELLOW}⚠️  请在 hyperbeam-arm64-deployment 根目录下运行此脚本${NC}"
    exit 1
fi

# 创建部署脚本符号链接
if [[ -f "scripts/deploy-hyperbeam-arm64.sh" ]]; then
    ln -sf scripts/deploy-hyperbeam-arm64.sh deploy-hyperbeam-arm64.sh
    echo -e "${GREEN}✅ 创建部署脚本符号链接: deploy-hyperbeam-arm64.sh${NC}"
else
    echo -e "${YELLOW}⚠️  未找到 scripts/deploy-hyperbeam-arm64.sh${NC}"
fi

# 创建监控脚本符号链接
if [[ -f "monitoring/monitor-node.sh" ]]; then
    ln -sf monitoring/monitor-node.sh monitor-node.sh
    echo -e "${GREEN}✅ 创建监控脚本符号链接: monitor-node.sh${NC}"
else
    echo -e "${YELLOW}⚠️  未找到 monitoring/monitor-node.sh${NC}"
fi

# 创建简单监控脚本符号链接
if [[ -f "monitoring/simple-monitor.sh" ]]; then
    ln -sf monitoring/simple-monitor.sh simple-monitor.sh
    echo -e "${GREEN}✅ 创建简单监控脚本符号链接: simple-monitor.sh${NC}"
fi

# 创建其他实用工具符号链接
if [[ -f "scripts/setup-dependencies.sh" ]]; then
    ln -sf scripts/setup-dependencies.sh setup-dependencies.sh
    echo -e "${GREEN}✅ 创建依赖安装脚本符号链接: setup-dependencies.sh${NC}"
fi

if [[ -f "scripts/validate-config.sh" ]]; then
    ln -sf scripts/validate-config.sh validate-config.sh
    echo -e "${GREEN}✅ 创建配置验证脚本符号链接: validate-config.sh${NC}"
fi

if [[ -f "scripts/fix-apple-silicon.sh" ]]; then
    ln -sf scripts/fix-apple-silicon.sh fix-apple-silicon.sh
    echo -e "${GREEN}✅ 创建Apple Silicon修复脚本符号链接: fix-apple-silicon.sh${NC}"
fi

# 设置执行权限
chmod +x scripts/*.sh 2>/dev/null || true
chmod +x monitoring/*.sh 2>/dev/null || true

echo ""
echo -e "${GREEN}🎉 符号链接设置完成！${NC}"
echo ""
echo "现在您可以直接使用以下命令："
echo "  ./deploy-hyperbeam-arm64.sh      # 一键部署"
echo "  ./monitor-node.sh --status       # 节点监控"
echo "  ./simple-monitor.sh              # 简单监控"
echo "  ./setup-dependencies.sh          # 依赖安装"
echo "  ./validate-config.sh             # 配置验证"
echo "  ./fix-apple-silicon.sh           # Apple Silicon修复"
echo ""
echo -e "${BLUE}或者您也可以直接使用原始路径：${NC}"
echo "  ./scripts/deploy-hyperbeam-arm64.sh"
echo "  ./monitoring/monitor-node.sh"
echo "" 