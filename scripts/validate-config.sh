#!/bin/bash

# HyperBEAM 配置验证工具
# 帮助用户验证和诊断配置问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 HyperBEAM 配置验证工具${NC}"
echo "========================================"

# 检查配置文件是否存在
if [[ -f "config.flat" ]]; then
    echo -e "${GREEN}✅ 配置文件存在: config.flat${NC}"
else
    echo -e "${RED}❌ 配置文件不存在: config.flat${NC}"
    echo "请创建配置文件或确保在正确的目录中运行此脚本"
    exit 1
fi

echo ""
echo -e "${YELLOW}📋 配置文件内容:${NC}"
echo "----------------------------------------"
cat config.flat
echo "----------------------------------------"

echo ""
echo -e "${YELLOW}🔍 配置验证:${NC}"

# 检查配置文件语法
echo -n "语法检查: "
if cat config.flat | sed 's/%.*//' | grep -E '^\s*\[.*\]\s*\.\s*$' >/dev/null; then
    echo -e "${GREEN}✅ 语法正确${NC}"
else
    echo -e "${RED}❌ 语法错误 - 确保配置以 ]. 结尾${NC}"
fi

# 提取配置项
port=$(grep -o '"port"[[:space:]]*,[[:space:]]*"[^"]*"' config.flat | cut -d'"' -f4 2>/dev/null || echo "")
mode=$(grep -o '"mode"[[:space:]]*,[[:space:]]*"[^"]*"' config.flat | cut -d'"' -f4 2>/dev/null || echo "")
key_location=$(grep -o '"priv_key_location"[[:space:]]*,[[:space:]]*"[^"]*"' config.flat | cut -d'"' -f4 2>/dev/null || echo "")

echo ""
echo -e "${YELLOW}📊 配置项分析:${NC}"

# 端口配置
if [[ -n "$port" ]]; then
    echo -e "端口配置: ${GREEN}$port${NC}"
    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1024 ] && [ "$port" -le 65535 ]; then
        echo -e "  ${GREEN}✅ 端口号有效${NC}"
    else
        echo -e "  ${RED}❌ 端口号无效 (应为 1024-65535)${NC}"
    fi
else
    echo -e "端口配置: ${YELLOW}未设置 (将使用默认值 8734)${NC}"
    port="8734"
fi

# 模式配置
if [[ -n "$mode" ]]; then
    echo -e "运行模式: ${GREEN}$mode${NC}"
    case "$mode" in
        "mainnet"|"debug"|"testnet")
            echo -e "  ${GREEN}✅ 模式有效${NC}"
            ;;
        *)
            echo -e "  ${YELLOW}⚠️ 未知模式，建议使用: mainnet, debug, 或 testnet${NC}"
            ;;
    esac
else
    echo -e "运行模式: ${YELLOW}未设置${NC}"
fi

# 钱包文件
if [[ -n "$key_location" ]]; then
    echo -e "钱包文件: ${GREEN}$key_location${NC}"
    if [[ -f "$key_location" ]]; then
        echo -e "  ${GREEN}✅ 钱包文件存在${NC}"
        # 检查 JSON 格式
        if jq empty "$key_location" 2>/dev/null; then
            echo -e "  ${GREEN}✅ JSON 格式有效${NC}"
        else
            echo -e "  ${RED}❌ JSON 格式无效${NC}"
        fi
    else
        echo -e "  ${RED}❌ 钱包文件不存在${NC}"
    fi
else
    echo -e "钱包文件: ${RED}❌ 未配置${NC}"
fi

echo ""
echo -e "${YELLOW}🌐 网络配置检查:${NC}"

# 检查端口是否被占用
if lsof -i ":$port" >/dev/null 2>&1; then
    echo -e "端口 $port: ${YELLOW}⚠️ 已被占用${NC}"
    echo "占用进程:"
    lsof -i ":$port" | grep -v COMMAND
else
    echo -e "端口 $port: ${GREEN}✅ 可用${NC}"
fi

# 检查防火墙状态 (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    firewall_status=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -o "enabled\|disabled" || echo "unknown")
    echo -e "防火墙状态: ${BLUE}$firewall_status${NC}"
fi

echo ""
echo -e "${YELLOW}🔧 配置建议:${NC}"

# 配置建议
if [[ "$mode" == "debug" ]]; then
    echo -e "${YELLOW}💡 生产环境建议使用 mode: mainnet${NC}"
fi

if [[ -z "$key_location" ]]; then
    echo -e "${YELLOW}💡 建议配置钱包文件路径${NC}"
fi

if [[ "$port" == "8734" ]]; then
    echo -e "${BLUE}ℹ️ 使用默认端口 8734${NC}"
fi

echo ""
echo -e "${YELLOW}🚀 启动验证:${NC}"

# 检查二进制文件
if [[ -x "bin/hb" ]]; then
    echo -e "HyperBEAM 二进制: ${GREEN}✅ 存在且可执行${NC}"
    
    # 尝试获取版本信息
    version_info=$(./bin/hb versions 2>/dev/null | head -1 || echo "无法获取版本信息")
    echo -e "版本信息: ${BLUE}$version_info${NC}"
else
    echo -e "HyperBEAM 二进制: ${RED}❌ 不存在或不可执行${NC}"
    echo "请确保已正确构建项目: rebar3 release"
fi

echo ""
echo -e "${YELLOW}📋 配置优先级提醒:${NC}"
echo "1. 环境变量 (HB_PORT=xxxx)"
echo "2. 命令行参数 (--port xxxx)"
echo "3. 配置文件 (config.flat)"
echo "4. 默认值 (8734)"

echo ""
echo -e "${YELLOW}🧪 推荐测试命令:${NC}"
echo "# 启动节点（前台）"
echo "./bin/hb console"
echo ""
echo "# 启动节点（后台）"
echo "./bin/hb daemon"
echo ""
echo "# 检查状态"
echo "./bin/hb ping"
echo ""
echo "# 测试 HTTP 访问"
echo "curl -I http://localhost:$port/~meta@1.0/info"

echo ""
echo -e "${GREEN}✅ 配置验证完成${NC}" 