#!/bin/bash

# OpenIM Route Service - 编译脚本
# 用途：编译Go服务

set -e

echo "=========================================="
echo "🔨 开始编译 OpenIM Route Service"
echo "=========================================="

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目目录
PROJECT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$PROJECT_DIR"

echo -e "${YELLOW}📁 项目目录: $PROJECT_DIR${NC}"

# 检查Go环境
if ! command -v go &> /dev/null; then
    echo -e "${RED}❌ 错误: 未安装Go环境${NC}"
    echo "请先安装Go: https://golang.org/dl/"
    exit 1
fi

GO_VERSION=$(go version)
echo -e "${GREEN}✅ Go环境: $GO_VERSION${NC}"

# 清理旧的编译文件
echo ""
echo "🧹 清理旧的编译文件..."
if [ -f "route-service" ]; then
    rm -f route-service
    echo -e "${GREEN}✅ 已删除旧的可执行文件${NC}"
fi

# 下载依赖
echo ""
echo "📦 下载Go依赖..."
go mod tidy
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 依赖下载完成${NC}"
else
    echo -e "${RED}❌ 依赖下载失败${NC}"
    exit 1
fi

# 编译
echo ""
echo "🔨 开始编译..."
BUILD_TIME=$(date +"%Y-%m-%d %H:%M:%S")
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

go build -ldflags "-X 'main.BuildTime=$BUILD_TIME' -X 'main.GitCommit=$GIT_COMMIT'" -o route-service main.go

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 编译成功！${NC}"
    echo ""
    echo "📊 编译信息:"
    echo "   - 可执行文件: route-service"
    echo "   - 文件大小: $(du -h route-service | cut -f1)"
    echo "   - 编译时间: $BUILD_TIME"
    echo "   - Git提交: $GIT_COMMIT"
    
    # 添加执行权限
    chmod +x route-service
    echo -e "${GREEN}✅ 已添加执行权限${NC}"
else
    echo -e "${RED}❌ 编译失败${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}🎉 编译完成！${NC}"
echo "=========================================="
echo ""
echo "💡 提示:"
echo "   - 运行服务: ./start.sh"
echo "   - 直接运行: ./route-service"
echo "   - 查看帮助: ./route-service --help"
echo ""
