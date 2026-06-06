#!/bin/bash
# 解决OOM问题 - 增加SwapSwap和优化内存配置

echo "================================"
echo "OOM问题修复方案"
echo "时间: $(date)"
echo "================================"

echo ""
echo "当前内存状态:"
free -h

echo ""
echo "1. 创建Swap交换空间(8GB)"
echo "================================"
# 检查是否已有swap
if [ $(swapon --show | wc -l) -eq 0 ]; then
    echo "创建8GB swap文件..."
    dd if=/dev/zero of=/swapfile bs=1G count=8 status=progress
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    # 永久生效
    if ! grep -q '/swapfile' /etc/fstab; then
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi

    echo "✅ Swap创建成功"
else
    echo "⚠️  Swap已存在,跳过创建"
    swapon --show
fi

echo ""
echo "2. 优化MongoDB内存配置"
echo "================================"
echo "MongoDB当前没有限制内存,建议限制为2GB"
echo "修改docker-compose.yml中的MongoDB配置:"
echo ""
echo "  mongodb:"
echo "    deploy:"
echo "      resources:"
echo "        limits:"
echo "          memory: 2G"
echo "        reservations:"
echo "          memory: 512M"

echo ""
echo "3. 优化Kafka内存配置"
echo "================================"
echo "Kafka当前使用1GB内存,可以适当减小"
echo "环境变量配置建议:"
echo "  KAFKA_HEAP_OPTS: '-Xmx768m -Xms512m'"

echo ""
echo "4. 配置系统OOM优先级"
echo "================================"
echo "降低关键服务被OOM Killer杀掉的概率"

# 找到OpenIM关键进程并设置oom_score_adj
for service in openim-api openim-msggateway openim-rpc-msg; do
    pid=$(pgrep -f $service | head -1)
    if [ ! -z "$pid" ]; then
        echo "设置 $service (PID:$pid) OOM优先级"
        echo -500 > /proc/$pid/oom_score_adj 2>/dev/null || echo "  需要root权限"
    fi
done

echo ""
echo "5. 启用内存监控告警"
echo "================================"
cat > /root/check_memory.sh << 'EOF'
#!/bin/bash
# 内存监控脚本

THRESHOLD=85  # 内存使用超过85%告警
USED=$(free | grep Mem | awk '{print int($3/$2 * 100)}')

if [ $USED -gt $THRESHOLD ]; then
    echo "$(date): 内存使用率 ${USED}% 超过阈值!" >> /var/log/memory_alert.log

    # 记录当前内存使用情况
    ps aux --sort=-%mem | head -20 >> /var/log/memory_alert.log

    # 可以在这里添加告警通知(邮件/webhook等)
fi
EOF

chmod +x /root/check_memory.sh

# 添加到crontab
if ! crontab -l 2>/dev/null | grep -q "check_memory.sh"; then
    (crontab -l 2>/dev/null; echo "*/5 * * * * /root/check_memory.sh") | crontab -
    echo "✅ 已添加内存监控定时任务(每5分钟检查一次)"
fi

echo ""
echo "6. 检查当前内存使用Top10进程"
echo "================================"
ps aux --sort=-%mem | head -11

echo ""
echo "================================"
echo "修复建议完成!"
echo "================================"
echo ""
echo "⚠️  必须执行的操作:"
echo ""
echo "1. ✅ Swap已创建(如果之前没有)"
echo "2. 📝 修改docker-compose.yml限制MongoDB和Kafka内存"
echo "3. 🔄 重启Docker容器使配置生效:"
echo "     cd /wwwroot/openIm/server/open-im-server-main"
echo "     docker-compose down"
echo "     docker-compose up -d"
echo ""
echo "4. 📊 持续监控内存使用:"
echo "     watch -n 2 'free -h'"
echo "     tail -f /var/log/memory_alert.log"
echo ""
echo "5. 💡 如果问题持续,考虑:"
echo "     - 升级服务器内存到16GB"
echo "     - 将MongoDB迁移到独立服务器"
echo "     - 减少OpenIM并发进程数"
echo ""


