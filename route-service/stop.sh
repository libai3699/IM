#!/bin/bash

# OpenIM Route Service - 停止脚本
# 用途：停止Go服务

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目目录
PROJECT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$PROJECT_DIR"

# 配置
SERVICE_NAME="route-service"
PID_FILE="$PROJECT_DIR/route-service.pid"

echo "=========================================="
echo "🛑 停止 OpenIM Route Service"
echo "=========================================="

# 检查服务是否运行
if [ ! -f "$PID_FILE" ]; then
    echo -e "${YELLOW}⚠️  服务未运行（PID文件不存在）${NC}"
    exit 0
fi

PID=$(cat "$PID_FILE")

# 检查进程是否存在
if ! ps -p "$PID" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  服务未运行（进程不存在）${NC}"
    rm -f "$PID_FILE"
    exit 0
fi

echo "正在停止服务 (PID: $PID)..."

# 尝试优雅停止
kill "$PID" 2>/dev/null || true

# 等待进程结束（最多10秒）
for i in {1..10}; do
    if ! ps -p "$PID" > /dev/null 2>&1; then
        rm -f "$PID_FILE"
        echo -e "${GREEN}✅ 服务已停止${NC}"
        exit 0
    fi
    sleep 1
    echo -n "."
done

echo ""
echo -e "${YELLOW}⚠️  服务未能优雅停止，尝试强制停止...${NC}"

# 强制停止
kill -9 "$PID" 2>/dev/null || true
sleep 1

# 再次检查
if ps -p "$PID" > /dev/null 2>&1; then
    echo -e "${RED}❌ 无法停止服务${NC}"
    exit 1
else
    rm -f "$PID_FILE"
    echo -e "${GREEN}✅ 服务已强制停止${NC}"
fi
