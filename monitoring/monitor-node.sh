#!/bin/bash

# HyperBEAM 节点实时监控脚本
# 使用方法: ./monitor-node.sh [选项]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 节点配置
NODE_PORT=8734
NODE_HOST="localhost"
LOG_DIR="./log"
REFRESH_INTERVAL=5

# 显示帮助信息
show_help() {
    echo "HyperBEAM 节点监控工具"
    echo ""
    echo "使用方法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  logs      - 实时查看节点日志"
    echo "  status    - 实时监控节点状态"
    echo "  network   - 实时监控网络连接"
    echo "  resources - 实时监控系统资源"
    echo "  requests  - 实时监控HTTP请求"
    echo "  all       - 综合监控面板"
    echo "  help      - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 logs     # 查看实时日志"
    echo "  $0 status   # 查看节点状态"
    echo "  $0 all      # 综合监控"
}

# 检查节点是否运行
check_node_running() {
    if ! pgrep -f "./bin/hb" > /dev/null; then
        echo -e "${RED}❌ HyperBEAM 节点未运行${NC}"
        exit 1
    fi
}

# 实时日志监控
monitor_logs() {
    echo -e "${CYAN}📜 HyperBEAM 实时日志监控${NC}"
    echo -e "${YELLOW}按 Ctrl+C 退出${NC}"
    echo "============================================"
    
    if [[ -f "$LOG_DIR/erlang.log.1" ]]; then
        tail -f "$LOG_DIR/erlang.log.1"
    elif [[ -f "startup.log" ]]; then
        tail -f startup.log
    else
        echo -e "${RED}未找到日志文件${NC}"
        exit 1
    fi
}

# 获取节点状态信息
get_node_status() {
    local status_json=$(curl -s -H "Accept: application/json" "http://$NODE_HOST:$NODE_PORT/~meta@1.0/info" || echo "{}")
    local headers=$(curl -s -I "http://$NODE_HOST:$NODE_PORT/~meta@1.0/info" 2>/dev/null || echo "")
    
    # 从响应头提取信息
    local port=$(echo "$headers" | grep -i "^port:" | cut -d' ' -f2 | tr -d '\r')
    local mode=$(echo "$headers" | grep -i "^mode:" | cut -d' ' -f2 | tr -d '\r')
    local status=$(echo "$headers" | grep -i "^status:" | cut -d' ' -f2 | tr -d '\r')
    local initialized=$(echo "$headers" | grep -i "^initialized:" | cut -d' ' -f2 | tr -d '\r')
    local compute_mode=$(echo "$headers" | grep -i "^compute_mode:" | cut -d' ' -f2 | tr -d '\r')
    local scheduling_mode=$(echo "$headers" | grep -i "^scheduling_mode:" | cut -d' ' -f2 | tr -d '\r')
    local address=$(echo "$headers" | grep -i "^address:" | cut -d' ' -f2 | tr -d '\r')
    
    echo "端口: ${port:-未知}"
    echo "模式: ${mode:-未知}"
    echo "状态: ${status:-未知}"
    echo "初始化: ${initialized:-未知}"
    echo "计算模式: ${compute_mode:-未知}"
    echo "调度模式: ${scheduling_mode:-未知}"
    echo "节点地址: ${address:-未知}"
}

# 实时状态监控
monitor_status() {
    echo -e "${GREEN}📊 HyperBEAM 节点状态监控${NC}"
    echo -e "${YELLOW}每 $REFRESH_INTERVAL 秒刷新，按 Ctrl+C 退出${NC}"
    
    while true; do
        clear
        echo -e "${GREEN}📊 HyperBEAM 节点状态监控${NC}"
        echo "更新时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "============================================"
        
        # 进程状态
        echo -e "${BLUE}🔧 进程状态:${NC}"
        local pid=$(pgrep -f "./bin/hb" || echo "未运行")
        echo "PID: $pid"
        
        if [[ "$pid" != "未运行" ]]; then
            local cpu_mem=$(ps -p "$pid" -o %cpu,%mem --no-headers 2>/dev/null || echo "未知 未知")
            echo "CPU使用率: $(echo $cpu_mem | awk '{print $1}')%"
            echo "内存使用率: $(echo $cpu_mem | awk '{print $2}')%"
        fi
        
        echo ""
        
        # 网络状态
        echo -e "${PURPLE}🌐 网络状态:${NC}"
        local connections=$(netstat -an | grep ":$NODE_PORT " | wc -l | tr -d ' ')
        echo "端口 $NODE_PORT 连接数: $connections"
        
        echo ""
        
        # 节点状态
        echo -e "${CYAN}⚙️  节点状态:${NC}"
        get_node_status
        
        echo ""
        echo "============================================"
        sleep $REFRESH_INTERVAL
    done
}

# 网络连接监控
monitor_network() {
    echo -e "${PURPLE}🌐 HyperBEAM 网络连接监控${NC}"
    echo -e "${YELLOW}每 $REFRESH_INTERVAL 秒刷新，按 Ctrl+C 退出${NC}"
    
    while true; do
        clear
        echo -e "${PURPLE}🌐 HyperBEAM 网络连接监控${NC}"
        echo "更新时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "============================================"
        
        echo "监听端口:"
        netstat -an | grep "LISTEN" | grep ":$NODE_PORT"
        
        echo ""
        echo "活跃连接:"
        netstat -an | grep ":$NODE_PORT" | grep -v "LISTEN"
        
        echo ""
        echo "连接统计:"
        local total=$(netstat -an | grep ":$NODE_PORT" | wc -l | tr -d ' ')
        local established=$(netstat -an | grep ":$NODE_PORT" | grep "ESTABLISHED" | wc -l | tr -d ' ')
        local listen=$(netstat -an | grep ":$NODE_PORT" | grep "LISTEN" | wc -l | tr -d ' ')
        
        echo "总连接数: $total"
        echo "已建立连接: $established"
        echo "监听端口: $listen"
        
        echo "============================================"
        sleep $REFRESH_INTERVAL
    done
}

# 系统资源监控
monitor_resources() {
    echo -e "${YELLOW}💾 HyperBEAM 系统资源监控${NC}"
    echo -e "${YELLOW}每 $REFRESH_INTERVAL 秒刷新，按 Ctrl+C 退出${NC}"
    
    while true; do
        clear
        echo -e "${YELLOW}💾 HyperBEAM 系统资源监控${NC}"
        echo "更新时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "============================================"
        
        # 节点进程资源使用
        local pid=$(pgrep -f "beam.smp.*hb")
        if [[ -n "$pid" ]]; then
            echo -e "${GREEN}HyperBEAM 进程资源 (PID: $pid):${NC}"
            ps -p "$pid" -o pid,ppid,%cpu,%mem,vsz,rss,tty,stat,start,time,command
            echo ""
        fi
        
        # 系统总体资源
        echo -e "${BLUE}系统总体资源:${NC}"
        echo "CPU 使用率:"
        top -l 1 | grep "CPU usage" | head -1
        
        echo ""
        echo "内存使用:"
        vm_stat | head -5
        
        echo ""
        echo "磁盘使用:"
        df -h . | grep -v "Filesystem"
        
        echo "============================================"
        sleep $REFRESH_INTERVAL
    done
}

# HTTP 请求监控
monitor_requests() {
    echo -e "${RED}🌍 HTTP 请求监控${NC}"
    echo -e "${YELLOW}实时监控端口 $NODE_PORT 的HTTP访问，按 Ctrl+C 退出${NC}"
    echo "============================================"
    
    # 使用 lsof 监控网络连接
    echo "开始监控 HTTP 请求..."
    while true; do
        # 简单的连接监控
        local timestamp=$(date '+%H:%M:%S')
        local connections=$(lsof -i :$NODE_PORT -P 2>/dev/null | grep -v "COMMAND" || echo "")
        
        if [[ -n "$connections" ]]; then
            echo "[$timestamp] 活跃连接:"
            echo "$connections"
            echo "---"
        fi
        
        sleep 2
    done
}

# 综合监控面板
monitor_all() {
    echo -e "${CYAN}🎛️  HyperBEAM 综合监控面板${NC}"
    echo -e "${YELLOW}每 $REFRESH_INTERVAL 秒刷新，按 Ctrl+C 退出${NC}"
    
    while true; do
        clear
        echo -e "${CYAN}🎛️  HyperBEAM 综合监控面板${NC}"
        echo "更新时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "=========================================="
        
        # 节点基本状态
        echo -e "${GREEN}📊 节点状态${NC}"
        local pid=$(pgrep -f "./bin/hb" || echo "")
        if [[ -n "$pid" ]]; then
            echo "✅ 节点运行中 (PID: $pid)"
            local cpu_mem=$(ps -p "$pid" -o %cpu,%mem --no-headers 2>/dev/null || echo "0 0")
            echo "CPU: $(echo $cpu_mem | awk '{print $1}')% | 内存: $(echo $cpu_mem | awk '{print $2}')%"
        else
            echo "❌ 节点未运行"
        fi
        
        echo ""
        
        # 网络状态简要
        echo -e "${PURPLE}🌐 网络状态${NC}"
        local connections=$(netstat -an | grep ":$NODE_PORT " | wc -l | tr -d ' ')
        echo "活跃连接: $connections"
        echo "监听地址: 0.0.0.0:$NODE_PORT"
        
        echo ""
        
        # 最近日志
        echo -e "${BLUE}📜 最近日志 (最后5行)${NC}"
        if [[ -f "$LOG_DIR/erlang.log.1" ]]; then
            tail -5 "$LOG_DIR/erlang.log.1" 2>/dev/null || echo "无法读取日志"
        else
            echo "日志文件不存在"
        fi
        
        echo ""
        echo "=========================================="
        echo "快捷命令："
        echo "  ./monitor-node.sh logs    - 查看完整日志"
        echo "  ./monitor-node.sh status  - 详细状态监控"
        echo "  ./monitor-node.sh network - 网络连接监控"
        
        sleep $REFRESH_INTERVAL
    done
}

# 主程序
main() {
    # 检查节点是否运行
    check_node_running
    
    case "${1:-help}" in
        "logs")
            monitor_logs
            ;;
        "status")
            monitor_status
            ;;
        "network")
            monitor_network
            ;;
        "resources")
            monitor_resources
            ;;
        "requests")
            monitor_requests
            ;;
        "all")
            monitor_all
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# 信号处理
trap 'echo -e "\n${GREEN}监控已停止${NC}"; exit 0' INT TERM

# 运行主程序
main "$@" 