#!/bin/bash
# Chart服务一键部署脚本
# 使用方法：bash deploy.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  OpenIM Chart 服务一键部署${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 获取脚本所在目录
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

echo -e "${BLUE}当前目录: $SCRIPT_DIR${NC}"
echo ""

# ==================== 第1步：停止服务 ====================
echo -e "${YELLOW}[1/5] 停止所有服务...${NC}"

# 使用脚本停止
if [ -f "scripts/stop_all.sh" ]; then
    bash scripts/stop_all.sh
    echo -e "${GREEN}  ✓ stop_all.sh 执行完成${NC}"
else
    echo -e "${YELLOW}  ⚠ 未找到 stop_all.sh${NC}"
fi

# 强制杀死所有进程（确保完全停止）
sleep 2
pkill -9 -f chat-api 2>/dev/null && echo -e "${GREEN}  ✓ chat-api 进程已杀死${NC}" || echo -e "${YELLOW}  - chat-api 进程不存在${NC}"
pkill -9 -f chat-rpc 2>/dev/null && echo -e "${GREEN}  ✓ chat-rpc 进程已杀死${NC}" || echo -e "${YELLOW}  - chat-rpc 进程不存在${NC}"
pkill -9 -f admin-api 2>/dev/null && echo -e "${GREEN}  ✓ admin-api 进程已杀死${NC}" || echo -e "${YELLOW}  - admin-api 进程不存在${NC}"
pkill -9 -f admin-rpc 2>/dev/null && echo -e "${GREEN}  ✓ admin-rpc 进程已杀死${NC}" || echo -e "${YELLOW}  - admin-rpc 进程不存在${NC}"

echo -e "${GREEN}✓ 所有服务已停止${NC}"
echo ""

# ==================== 第2步：清理旧文件 ====================
echo -e "${YELLOW}[2/5] 清理旧的编译文件...${NC}"

if [ -d "_output/bin/platforms/linux/amd64" ]; then
    rm -rf _output/bin/platforms/linux/amd64/*
    echo -e "${GREEN}  ✓ 已清理 _output/bin/platforms/linux/amd64/${NC}"
else
    echo -e "${YELLOW}  ⚠ 目录不存在，跳过清理${NC}"
fi

echo -e "${GREEN}✓ 清理完成${NC}"
echo ""

# ==================== 第3步：编译服务 ====================
echo -e "${YELLOW}[3/5] 开始编译（需要2-3分钟）...${NC}"
echo -e "${BLUE}请耐心等待...${NC}"
echo ""

if [ -f "scripts/build_all_service.sh" ]; then
    # 修复脚本格式（如果有换行符问题）
    sed -i 's/\r$//' scripts/build_all_service.sh 2>/dev/null || true
    
    # 执行编译
    bash scripts/build_all_service.sh
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ 编译成功${NC}"
    else
        echo ""
        echo -e "${RED}✗ 编译失败！${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ 未找到 build_all_service.sh${NC}"
    exit 1
fi

echo ""

# ==================== 第4步：验证编译结果 ====================
echo -e "${YELLOW}[4/5] 验证编译结果...${NC}"

if [ -d "_output/bin/platforms/linux/amd64" ]; then
    echo -e "${BLUE}编译生成的文件：${NC}"
    ls -lh _output/bin/platforms/linux/amd64/ | grep -E "chat-api|chat-rpc|admin-api|admin-rpc" || echo -e "${RED}  ✗ 未找到编译文件${NC}"
    echo ""
    
    # 检查文件是否是今天生成的
    TODAY=$(date +%Y-%m-%d)
    CHAT_API_DATE=$(ls -l _output/bin/platforms/linux/amd64/chat-api 2>/dev/null | awk '{print $6}')
    
    if [ "$CHAT_API_DATE" == "$(date +%b)" ] || [ "$CHAT_API_DATE" == "$TODAY" ]; then
        echo -e "${GREEN}  ✓ 文件是最新编译的${NC}"
    else
        echo -e "${YELLOW}  ⚠ 文件可能不是今天编译的${NC}"
    fi
else
    echo -e "${RED}✗ 编译目录不存在${NC}"
    exit 1
fi

echo ""

# ==================== 第5步：启动服务 ====================
echo -e "${YELLOW}[5/5] 启动服务...${NC}"

if [ -f "scripts/start_all.sh" ]; then
    # 修复脚本格式
    sed -i 's/\r$//' scripts/start_all.sh 2>/dev/null || true
    
    # 执行启动
    bash scripts/start_all.sh
    
    echo -e "${GREEN}  ✓ start_all.sh 执行完成${NC}"
else
    echo -e "${RED}✗ 未找到 start_all.sh${NC}"
    exit 1
fi

# 等待服务启动
echo -e "${BLUE}等待服务启动...${NC}"
sleep 5

echo -e "${GREEN}✓ 服务已启动${NC}"
echo ""

# ==================== 验证服务状态 ====================
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  服务状态${NC}"
echo -e "${GREEN}========================================${NC}"

RUNNING_SERVICES=$(ps aux | grep -E "chat-api|chat-rpc|admin-api|admin-rpc" | grep -v grep)

if [ -n "$RUNNING_SERVICES" ]; then
    echo -e "${GREEN}运行中的服务：${NC}"
    echo "$RUNNING_SERVICES" | awk '{print "  - " $11 " (PID: " $2 ")"}'
else
    echo -e "${RED}✗ 没有服务在运行！${NC}"
    echo -e "${YELLOW}请查看日志：tail -f logs/openIM.log${NC}"
    exit 1
fi

echo ""

# ==================== 端口检查 ====================
echo -e "${BLUE}端口监听状态：${NC}"
netstat -tlnp 2>/dev/null | grep -E "10008|10009|10010|10011" | awk '{print "  - " $4 " -> " $7}' || \
ss -tlnp 2>/dev/null | grep -E "10008|10009|10010|10011" | awk '{print "  - " $5}' || \
echo -e "${YELLOW}  ⚠ 无法检查端口状态${NC}"

echo ""

# ==================== 完成提示 ====================
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}后续操作：${NC}"
echo ""
echo -e "${YELLOW}1. 测试登录：${NC}"
echo "   使用 Flutter 应用重新登录"
echo ""
echo -e "${YELLOW}2. 查看实时日志（含调试信息）：${NC}"
echo "   tail -f logs/openIM.log | grep -E 'Login request details|deviceModel'"
echo ""
echo -e "${YELLOW}3. 查看数据库记录：${NC}"
echo '   mysql -u root -p -e "SELECT user_id, login_time, ip, device_model, platform, location FROM openIM_v3.user_login_records ORDER BY login_time DESC LIMIT 5;"'
echo ""
echo -e "${YELLOW}4. 如果遇到问题：${NC}"
echo "   查看完整日志: tail -n 100 logs/openIM.log"
echo ""

