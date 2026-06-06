#!/bin/bash

# OpenIM Route Service - 启动脚本
# 用途：启动、停止、重启Go服务

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目目录
PROJECT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$PROJECT_DIR"

# 配置
SERVICE_NAME="route-service"
PID_FILE="$PROJECT_DIR/route-service.pid"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/app.log"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 检查服务是否运行
check_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            return 0  # 运行中
        else
            rm -f "$PID_FILE"
            return 1  # 未运行
        fi
    fi
    return 1  # 未运行
}

# 启动服务
start() {
    echo "=========================================="
    echo "🚀 启动 OpenIM Route Service"
    echo "=========================================="
    
    # 检查是否已经运行
    if check_status; then
        PID=$(cat "$PID_FILE")
        echo -e "${YELLOW}⚠️  服务已经在运行中 (PID: $PID)${NC}"
        echo "如需重启，请使用: ./start.sh restart"
        exit 1
    fi
    
    # 检查可执行文件
    if [ ! -f "$SERVICE_NAME" ]; then
        echo -e "${RED}❌ 错误: 找不到可执行文件 $SERVICE_NAME${NC}"
        echo "请先编译: ./build.sh"
        exit 1
    fi
    
    # 检查配置文件
    if [ ! -f "config.yaml" ]; then
        echo -e "${RED}❌ 错误: 找不到配置文件 config.yaml${NC}"
        exit 1
    fi
    
    # 启动服务
    echo "📝 日志文件: $LOG_FILE"
    echo "🔧 配置文件: config.yaml"
    echo ""
    
    nohup ./$SERVICE_NAME > "$LOG_FILE" 2>&1 &
    PID=$!
    echo $PID > "$PID_FILE"
    
    # 等待服务启动
    sleep 2
    
    if check_status; then
        echo -e "${GREEN}✅ 服务启动成功！${NC}"
        echo ""
        echo "📊 服务信息:"
        echo "   - PID: $PID"
        echo "   - 端口: 10010"
        echo "   - 日志: $LOG_FILE"
        echo ""
        echo "💡 常用命令:"
        echo "   - 查看状态: ./start.sh status"
        echo "   - 查看日志: ./start.sh logs"
        echo "   - 停止服务: ./start.sh stop"
        echo "   - 重启服务: ./start.sh restart"
        echo ""
        echo "🔗 测试接口:"
        echo "   curl http://localhost:10010/api/health"
    else
        echo -e "${RED}❌ 服务启动失败${NC}"
        echo "请查看日志: tail -f $LOG_FILE"
        exit 1
    fi
}

# 停止服务
stop() {
    echo "=========================================="
    echo "🛑 停止 OpenIM Route Service"
    echo "=========================================="
    
    if ! check_status; then
        echo -e "${YELLOW}⚠️  服务未运行${NC}"
        exit 0
    fi
    
    PID=$(cat "$PID_FILE")
    echo "正在停止服务 (PID: $PID)..."
    
    kill "$PID"
    
    # 等待进程结束
    for i in {1..10}; do
        if ! ps -p "$PID" > /dev/null 2>&1; then
            rm -f "$PID_FILE"
            echo -e "${GREEN}✅ 服务已停止${NC}"
            exit 0
        fi
        sleep 1
    done
    
    # 强制杀死
    echo "强制停止服务..."
    kill -9 "$PID" 2>/dev/null || true
    rm -f "$PID_FILE"
    echo -e "${GREEN}✅ 服务已强制停止${NC}"
}

# 重启服务
restart() {
    echo "=========================================="
    echo "🔄 重启 OpenIM Route Service"
    echo "=========================================="
    
    if check_status; then
        stop
        sleep 2
    fi
    
    start
}

# 查看状态
status() {
    echo "=========================================="
    echo "📊 OpenIM Route Service 状态"
    echo "=========================================="
    
    if check_status; then
        PID=$(cat "$PID_FILE")
        echo -e "${GREEN}✅ 服务运行中${NC}"
        echo ""
        echo "📊 进程信息:"
        ps -p "$PID" -o pid,ppid,%cpu,%mem,etime,cmd
        echo ""
        echo "🔗 端口监听:"
        netstat -tlnp 2>/dev/null | grep ":10010" || echo "   未找到监听端口"
        echo ""
        echo "💡 查看日志: ./start.sh logs"
    else
        echo -e "${RED}❌ 服务未运行${NC}"
    fi
}

# 查看日志
logs() {
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${YELLOW}⚠️  日志文件不存在${NC}"
        exit 1
    fi
    
    echo "=========================================="
    echo "📋 查看日志 (Ctrl+C 退出)"
    echo "=========================================="
    tail -f "$LOG_FILE"
}

# 显示帮助
help() {
    echo "=========================================="
    echo "OpenIM Route Service 管理脚本"
    echo "=========================================="
    echo ""
    echo "用法: ./start.sh [命令]"
    echo ""
    echo "命令:"
    echo "  start    - 启动服务"
    echo "  stop     - 停止服务"
    echo "  restart  - 重启服务"
    echo "  status   - 查看状态"
    echo "  logs     - 查看日志"
    echo "  help     - 显示帮助"
    echo ""
    echo "示例:"
    echo "  ./start.sh start    # 启动服务"
    echo "  ./start.sh status   # 查看状态"
    echo "  ./start.sh logs     # 查看日志"
    echo ""
}

# 主逻辑
case "${1:-start}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    help|--help|-h)
        help
        ;;
    *)
        echo -e "${RED}❌ 未知命令: $1${NC}"
        echo ""
        help
        exit 1
        ;;
esac
