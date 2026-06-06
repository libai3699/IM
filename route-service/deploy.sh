#!/bin/bash

# OpenIM Route Service 部署脚本

set -e

echo "========================================="
echo "  OpenIM Route Service 部署工具"
echo "========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安装，请先安装 Docker${NC}"
    exit 1
fi

# 检查 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose 未安装，请先安装 Docker Compose${NC}"
    exit 1
fi

# 菜单
show_menu() {
    echo ""
    echo "请选择操作："
    echo "1. 首次部署（构建并启动）"
    echo "2. 启动服务"
    echo "3. 停止服务"
    echo "4. 重启服务"
    echo "5. 查看日志"
    echo "6. 查看状态"
    echo "7. 重新构建"
    echo "8. 完全清理（删除数据）"
    echo "9. 退出"
    echo ""
}

# 首次部署
first_deploy() {
    echo -e "${GREEN}🚀 开始首次部署...${NC}"
    
    # 创建必要的目录
    mkdir -p data/mysql logs
    
    # 构建并启动
    docker-compose up -d --build
    
    echo ""
    echo -e "${GREEN}✅ 部署完成！${NC}"
    echo ""
    echo "服务信息："
    echo "  - 路由服务: http://localhost:10010"
    echo "  - MySQL: localhost:23306"
    echo ""
    echo "测试 API："
    echo "  curl http://localhost:10010/api/health"
    echo ""
}

# 启动服务
start_service() {
    echo -e "${GREEN}🚀 启动服务...${NC}"
    docker-compose up -d
    echo -e "${GREEN}✅ 服务已启动${NC}"
}

# 停止服务
stop_service() {
    echo -e "${YELLOW}🛑 停止服务...${NC}"
    docker-compose stop
    echo -e "${GREEN}✅ 服务已停止${NC}"
}

# 重启服务
restart_service() {
    echo -e "${YELLOW}🔄 重启服务...${NC}"
    docker-compose restart
    echo -e "${GREEN}✅ 服务已重启${NC}"
}

# 查看日志
view_logs() {
    echo -e "${GREEN}📋 查看日志（Ctrl+C 退出）${NC}"
    docker-compose logs -f
}

# 查看状态
view_status() {
    echo -e "${GREEN}📊 服务状态：${NC}"
    docker-compose ps
    echo ""
    echo -e "${GREEN}📊 容器资源使用：${NC}"
    docker stats --no-stream route-service route-mysql
}

# 重新构建
rebuild() {
    echo -e "${YELLOW}🔨 重新构建...${NC}"
    docker-compose down
    docker-compose build --no-cache
    docker-compose up -d
    echo -e "${GREEN}✅ 重新构建完成${NC}"
}

# 完全清理
clean_all() {
    echo -e "${RED}⚠️  警告：这将删除所有数据！${NC}"
    read -p "确认删除？(yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo -e "${YELLOW}🗑️  清理中...${NC}"
        docker-compose down -v
        rm -rf data logs
        echo -e "${GREEN}✅ 清理完成${NC}"
    else
        echo -e "${YELLOW}❌ 已取消${NC}"
    fi
}

# 主循环
while true; do
    show_menu
    read -p "请输入选项 (1-9): " choice
    
    case $choice in
        1)
            first_deploy
            ;;
        2)
            start_service
            ;;
        3)
            stop_service
            ;;
        4)
            restart_service
            ;;
        5)
            view_logs
            ;;
        6)
            view_status
            ;;
        7)
            rebuild
            ;;
        8)
            clean_all
            ;;
        9)
            echo -e "${GREEN}👋 再见！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ 无效选项${NC}"
            ;;
    esac
done
