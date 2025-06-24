# 📊 HyperBEAM ARM64 监控指南

## 🎯 监控概述

本指南介绍如何监控和管理 Apple Silicon Mac 上的 HyperBEAM 节点。

## 🛠️ 监控工具

### 主要监控脚本

```bash
./monitoring/monitor-node.sh
```

支持的监控模式：
- `--status` - 节点状态检查
- `--logs` - 实时日志监控
- `--resources` - 系统资源监控
- `--network` - 网络连接监控

## 📋 基础监控

### 节点状态检查

```bash
# 快速状态检查
./monitoring/monitor-node.sh --status

# 详细状态报告
./monitoring/monitor-node.sh --status --verbose
```

输出信息包括：
- ✅ 进程状态（PID、运行时间）
- 🌐 网络状态（端口监听、连接数）
- 📊 资源使用（CPU、内存）
- 🔧 配置验证

### 实时日志监控

```bash
# 实时查看所有日志
./monitoring/monitor-node.sh --logs

# 只查看错误日志
./monitoring/monitor-node.sh --logs --error-only

# 过滤特定关键词
./monitoring/monitor-node.sh --logs --filter "ERROR"
```

## 📈 性能监控

### 系统资源监控

```bash
# 持续资源监控
./monitoring/monitor-node.sh --resources

# 生成资源报告
./monitoring/monitor-node.sh --resources --report
```

监控指标：
- **CPU 使用率** - 多核心利用率
- **内存使用** - 堆内存、系统内存
- **磁盘 I/O** - 读写速度、磁盘空间
- **网络流量** - 入站/出站流量

### 网络连接监控

```bash
# 网络连接状态
./monitoring/monitor-node.sh --network

# 连接数统计
./monitoring/monitor-node.sh --network --stats
```

监控内容：
- **TCP 连接数** - 当前活跃连接
- **端口监听状态** - 服务端口状态
- **带宽使用** - 实时流量统计
- **连接质量** - 延迟和丢包

## 🔍 高级监控

### 自定义监控脚本

```bash
#!/bin/bash
# custom-monitor.sh

# 检查节点健康度
check_node_health() {
    local pid=$(pgrep -f "beam.*hb_mainnet")
    if [[ -z "$pid" ]]; then
        echo "❌ 节点未运行"
        return 1
    fi
    
    # 检查内存使用
    local memory=$(ps -p $pid -o rss= | awk '{print $1}')
    if [[ $memory -gt 2000000 ]]; then  # 2GB
        echo "⚠️  内存使用过高: ${memory}KB"
    fi
    
    # 检查 CPU 使用
    local cpu=$(ps -p $pid -o pcpu= | awk '{print $1}')
    if [[ $(echo "$cpu > 80" | bc) -eq 1 ]]; then
        echo "⚠️  CPU 使用过高: ${cpu}%"
    fi
    
    echo "✅ 节点运行正常"
}

check_node_health
```

### 日志分析脚本

```bash
#!/bin/bash
# analyze-logs.sh

# 分析错误模式
analyze_errors() {
    echo "🔍 分析最近的错误日志..."
    
    # 统计错误类型
    grep -i error log/erlang.log.* | \
    sed 's/.*\(ERROR\|Error\|error\)[^:]*: *//' | \
    sort | uniq -c | sort -nr | head -10
    
    echo ""
    echo "🔍 分析警告信息..."
    
    # 统计警告类型
    grep -i warning log/erlang.log.* | \
    sed 's/.*\(WARNING\|Warning\|warning\)[^:]*: *//' | \
    sort | uniq -c | sort -nr | head -5
}

analyze_errors
```

## 📊 监控仪表板

### 创建监控仪表板

```bash
#!/bin/bash
# dashboard.sh

show_dashboard() {
    clear
    echo "================================================================"
    echo "           🚀 HyperBEAM 节点监控仪表板"
    echo "================================================================"
    echo ""
    
    # 节点状态
    local pid=$(pgrep -f "beam.*hb_mainnet")
    if [[ -n "$pid" ]]; then
        echo "✅ 节点状态: 运行中 (PID: $pid)"
        
        # 运行时间
        local start_time=$(ps -p $pid -o lstart= | xargs -I {} date -j -f "%a %b %d %H:%M:%S %Y" "{}" +%s)
        local current_time=$(date +%s)
        local uptime=$((current_time - start_time))
        echo "⏱️  运行时间: $(printf '%dd %02dh %02dm' $((uptime/86400)) $((uptime%86400/3600)) $((uptime%3600/60)))"
        
        # 资源使用
        local cpu=$(ps -p $pid -o pcpu= | awk '{print $1}')
        local memory=$(ps -p $pid -o rss= | awk '{print int($1/1024)}')
        echo "💻 CPU 使用: ${cpu}%"
        echo "🧠 内存使用: ${memory}MB"
        
        # 网络状态
        local port=$(lsof -Pan -i TCP -F | grep -A1 "p$pid" | grep ":.*->.*LISTEN" | head -1 | sed 's/.*:\([0-9]*\).*/\1/')
        local connections=$(lsof -Pan -i TCP | grep $pid | grep ESTABLISHED | wc -l | xargs)
        echo "🌐 监听端口: $port"
        echo "🔗 活跃连接: $connections"
    else
        echo "❌ 节点状态: 未运行"
    fi
    
    echo ""
    echo "📊 系统资源:"
    
    # 系统负载
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    echo "⚡ 系统负载: $load"
    
    # 磁盘空间
    local disk_usage=$(df -h . | tail -1 | awk '{print $5}' | sed 's/%//')
    echo "💾 磁盘使用: ${disk_usage}%"
    
    # 内存使用
    local total_memory=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
    local used_memory=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//' | awk '{print int($1*4096/1024/1024)}')
    echo "🧠 系统内存: ${used_memory}MB / ${total_memory}GB"
    
    echo ""
    echo "================================================================"
    echo "按 Ctrl+C 退出 | 刷新间隔: 5秒"
    echo "================================================================"
}

# 持续刷新仪表板
while true; do
    show_dashboard
    sleep 5
done
```

## 🚨 告警设置

### 创建告警脚本

```bash
#!/bin/bash
# alerts.sh

# 配置告警阈值
CPU_THRESHOLD=80
MEMORY_THRESHOLD=2048000  # 2GB in KB
DISK_THRESHOLD=90
CONNECTION_THRESHOLD=1000

send_alert() {
    local message="$1"
    local level="$2"
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> alerts.log
    
    # 可以添加其他通知方式：
    # - 邮件通知
    # - Slack 通知
    # - 微信通知
    
    case $level in
        "CRITICAL")
            echo "🚨 CRITICAL: $message"
            ;;
        "WARNING")
            echo "⚠️  WARNING: $message"
            ;;
        "INFO")
            echo "ℹ️  INFO: $message"
            ;;
    esac
}

check_alerts() {
    local pid=$(pgrep -f "beam.*hb_mainnet")
    
    if [[ -z "$pid" ]]; then
        send_alert "HyperBEAM 节点已停止运行" "CRITICAL"
        return
    fi
    
    # 检查 CPU 使用
    local cpu=$(ps -p $pid -o pcpu= | awk '{print int($1)}')
    if [[ $cpu -gt $CPU_THRESHOLD ]]; then
        send_alert "CPU 使用率过高: ${cpu}%" "WARNING"
    fi
    
    # 检查内存使用
    local memory=$(ps -p $pid -o rss= | awk '{print $1}')
    if [[ $memory -gt $MEMORY_THRESHOLD ]]; then
        send_alert "内存使用过高: $((memory/1024))MB" "WARNING"
    fi
    
    # 检查磁盘空间
    local disk_usage=$(df . | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $disk_usage -gt $DISK_THRESHOLD ]]; then
        send_alert "磁盘空间不足: ${disk_usage}%" "CRITICAL"
    fi
    
    # 检查连接数
    local connections=$(lsof -Pan -i TCP | grep $pid | grep ESTABLISHED | wc -l | xargs)
    if [[ $connections -gt $CONNECTION_THRESHOLD ]]; then
        send_alert "连接数过多: $connections" "WARNING"
    fi
}

# 定期检查告警
while true; do
    check_alerts
    sleep 60  # 每分钟检查一次
done
```

## 📝 日志管理

### 日志轮转配置

```bash
#!/bin/bash
# rotate-logs.sh

LOG_DIR="log"
MAX_SIZE="100M"
MAX_AGE="30"  # 天

rotate_logs() {
    echo "🔄 开始日志轮转..."
    
    # 压缩旧日志
    find $LOG_DIR -name "*.log" -size +$MAX_SIZE -exec gzip {} \;
    
    # 删除过期日志
    find $LOG_DIR -name "*.log.gz" -mtime +$MAX_AGE -delete
    
    # 清理空文件
    find $LOG_DIR -empty -delete
    
    echo "✅ 日志轮转完成"
}

rotate_logs
```

### 日志监控 launchd 服务

```xml
<!-- ~/Library/LaunchAgents/com.hyperbeam.monitor.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.hyperbeam.monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/your/monitoring/monitor-node.sh</string>
        <string>--continuous</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/hyperbeam-monitor.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/hyperbeam-monitor-error.log</string>
</dict>
</plist>
```

## 📞 监控支持

### 获取监控帮助

```bash
# 监控工具帮助
./monitoring/monitor-node.sh --help

# 配置验证
./scripts/validate-config.sh --verbose

# 生成监控报告
./monitoring/monitor-node.sh --report > monitoring-report.txt
```

### 监控最佳实践

1. **定期检查** - 每天至少检查一次节点状态
2. **资源监控** - 设置合理的告警阈值
3. **日志分析** - 定期分析错误和警告日志
4. **备份监控** - 监控配置和密钥文件
5. **网络监控** - 关注网络连接和同步状态

### 故障诊断

当监控发现问题时：

1. **立即检查** - 运行 `--status` 获取当前状态
2. **查看日志** - 使用 `--logs` 查看最近的日志
3. **资源分析** - 运行 `--resources` 检查资源使用
4. **配置验证** - 运行配置验证脚本
5. **重启恢复** - 必要时重启节点服务 