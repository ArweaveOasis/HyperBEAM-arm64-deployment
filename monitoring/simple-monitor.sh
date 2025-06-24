#!/bin/bash

# =============================================================================
# HyperBEAM 简化监控脚本
# 快速检查节点状态
# =============================================================================

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 显示标题
echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}           🚀 HyperBEAM 节点快速状态检查${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# 检查节点进程
echo -e "${BLUE}📊 节点状态:${NC}"
pid=$(pgrep -f "beam.*hb")
if [[ -n "$pid" ]]; then
    echo -e "  ✅ 节点运行中 (PID: $pid)"
    
    # 获取启动时间
    start_time=$(ps -p $pid -o lstart= 2>/dev/null)
    if [[ -n "$start_time" ]]; then
        echo -e "  ⏰ 启动时间: $start_time"
    fi
    
    # CPU 和内存使用
    cpu_mem=$(ps -p $pid -o pcpu,rss 2>/dev/null | tail -1)
    if [[ -n "$cpu_mem" ]]; then
        cpu=$(echo $cpu_mem | awk '{print $1}')
        mem_kb=$(echo $cpu_mem | awk '{print $2}')
        mem_mb=$((mem_kb / 1024))
        echo -e "  💻 CPU: ${cpu}%"
        echo -e "  🧠 内存: ${mem_mb}MB"
    fi
else
    echo -e "  ❌ 节点未运行"
fi

echo ""

# 检查网络端口
echo -e "${BLUE}🌐 网络状态:${NC}"
if [[ -n "$pid" ]]; then
    # 查找监听端口
    ports=$(lsof -Pan -i TCP -p $pid 2>/dev/null | grep LISTEN | awk '{print $9}' | cut -d: -f2 | sort -n | uniq)
    if [[ -n "$ports" ]]; then
        for port in $ports; do
            echo -e "  ✅ 监听端口: $port"
            echo -e "     🔗 访问地址: http://localhost:$port"
        done
        
        # 统计连接数
        connections=$(lsof -Pan -i TCP -p $pid 2>/dev/null | grep ESTABLISHED | wc -l | tr -d ' ')
        echo -e "  📈 活跃连接: $connections"
    else
        echo -e "  ⚠️  未发现监听端口"
    fi
else
    echo -e "  ❌ 无网络连接（节点未运行）"
fi

echo ""

# 检查配置文件
echo -e "${BLUE}⚙️  配置状态:${NC}"
config_files=("config.flat" "_build/default/rel/hb/config.flat")
config_found=false

for config in "${config_files[@]}"; do
    if [[ -f "$config" ]]; then
        echo -e "  ✅ 配置文件: $config"
        config_found=true
        
        # 检查配置内容
        if grep -q "mainnet" "$config" 2>/dev/null; then
            echo -e "  🌐 网络模式: 主网"
        elif grep -q "testnet" "$config" 2>/dev/null; then
            echo -e "  🌐 网络模式: 测试网"
        fi
        
        # 检查端口配置
        port_config=$(grep -o '"port"[^}]*' "$config" 2>/dev/null | grep -o '[0-9]\+' | head -1)
        if [[ -n "$port_config" ]]; then
            echo -e "  🔌 配置端口: $port_config"
        fi
        break
    fi
done

if [[ "$config_found" = false ]]; then
    echo -e "  ❌ 未找到配置文件"
fi

echo ""

# 检查密钥文件
echo -e "${BLUE}🔑 密钥状态:${NC}"
key_files=("hyperbeam-key.json" "_build/default/rel/hb/hyperbeam-key.json")
key_found=false

for key in "${key_files[@]}"; do
    if [[ -f "$key" ]]; then
        echo -e "  ✅ 密钥文件: $key"
        
        # 检查文件权限
        perms=$(stat -f "%Sp" "$key" 2>/dev/null)
        if [[ "$perms" =~ ^-rw------- ]]; then
            echo -e "  🔒 权限: 安全 ($perms)"
        else
            echo -e "  ⚠️  权限: 需检查 ($perms)"
        fi
        
        key_found=true
        break
    fi
done

if [[ "$key_found" = false ]]; then
    echo -e "  ❌ 未找到密钥文件"
fi

echo ""

# 检查日志文件
echo -e "${BLUE}📋 日志状态:${NC}"
log_dirs=("log" "_build/default/rel/hb/log")
log_found=false

for log_dir in "${log_dirs[@]}"; do
    if [[ -d "$log_dir" ]]; then
        # 查找最新的日志文件
        latest_log=$(find "$log_dir" -name "*.log*" -type f -exec ls -t {} + 2>/dev/null | head -1)
        if [[ -n "$latest_log" ]]; then
            echo -e "  ✅ 日志目录: $log_dir"
            echo -e "  📄 最新日志: $(basename "$latest_log")"
            
            # 检查最近的错误
            error_count=$(grep -c -i "error" "$latest_log" 2>/dev/null | head -1)
            if [[ -n "$error_count" && "$error_count" -gt 0 ]]; then
                echo -e "  ⚠️  最近错误: $error_count 条"
            else
                echo -e "  ✅ 无明显错误"
            fi
            
            log_found=true
            break
        fi
    fi
done

if [[ "$log_found" = false ]]; then
    echo -e "  ❌ 未找到日志文件"
fi

echo ""

# 系统资源状态
echo -e "${BLUE}💾 系统资源:${NC}"

# 磁盘空间
disk_usage=$(df -h . 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//')
disk_avail=$(df -h . 2>/dev/null | tail -1 | awk '{print $4}')
if [[ -n "$disk_usage" ]]; then
    if [[ "$disk_usage" -lt 80 ]]; then
        echo -e "  ✅ 磁盘使用: ${disk_usage}% (剩余: $disk_avail)"
    elif [[ "$disk_usage" -lt 90 ]]; then
        echo -e "  ⚠️  磁盘使用: ${disk_usage}% (剩余: $disk_avail)"
    else
        echo -e "  ❌ 磁盘使用: ${disk_usage}% (剩余: $disk_avail)"
    fi
fi

# 系统负载
load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
if [[ -n "$load_avg" ]]; then
    echo -e "  ⚡ 系统负载: $load_avg"
fi

echo ""
echo -e "${BLUE}================================================================${NC}"

# 简单的健康评分
echo -e "${BLUE}🏥 健康评分:${NC}"
score=0
total=5

# 评分标准
if [[ -n "$pid" ]]; then ((score++)); fi
if [[ "$config_found" = true ]]; then ((score++)); fi
if [[ "$key_found" = true ]]; then ((score++)); fi
if [[ "$log_found" = true ]]; then ((score++)); fi
if [[ -n "$disk_usage" && "$disk_usage" -lt 90 ]]; then ((score++)); fi

percentage=$((score * 100 / total))

if [[ $percentage -ge 80 ]]; then
    echo -e "  ✅ 健康状态: 良好 (${score}/${total})"
elif [[ $percentage -ge 60 ]]; then
    echo -e "  ⚠️  健康状态: 一般 (${score}/${total})"
else
    echo -e "  ❌ 健康状态: 需要关注 (${score}/${total})"
fi

echo ""
echo -e "${BLUE}💡 快速操作:${NC}"
if [[ -n "$pid" ]]; then
    echo -e "  📊 详细监控: ./monitor-node.sh --status"
    echo -e "  📋 查看日志: ./monitor-node.sh --logs"
    echo -e "  🔄 重启节点: ./bin/hb restart"
else
    echo -e "  🚀 启动节点: ./bin/hb daemon"
    echo -e "  ⚙️  检查配置: ./validate-config.sh"
fi

echo -e "${BLUE}================================================================${NC}" 