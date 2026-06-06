#!/bin/bash
################################################################################
# Docker 和 Docker Compose 自动安装脚本
# 适用于: CentOS, Ubuntu, Debian
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 检查root权限
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        error "请使用 root 用户运行此脚本，或使用 sudo"
    fi
}

# 检测操作系统
detect_os() {
    log "检测操作系统..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        error "无法检测操作系统类型"
    fi
    
    success "操作系统: $OS $VERSION"
}

# 安装Docker - CentOS
install_docker_centos() {
    log "在 CentOS 上安装 Docker..."
    
    # 卸载旧版本
    yum remove -y docker docker-client docker-client-latest docker-common \
        docker-latest docker-latest-logrotate docker-logrotate docker-engine || true
    
    # 安装依赖
    yum install -y yum-utils device-mapper-persistent-data lvm2
    
    # 添加Docker仓库
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # 或使用阿里云镜像（如果上面的慢）
    # yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    
    # 安装Docker
    yum install -y docker-ce docker-ce-cli containerd.io
    
    success "Docker 安装完成"
}

# 安装Docker - Ubuntu/Debian
install_docker_ubuntu() {
    log "在 Ubuntu/Debian 上安装 Docker..."
    
    # 更新包索引
    apt-get update
    
    # 卸载旧版本
    apt-get remove -y docker docker-engine docker.io containerd runc || true
    
    # 安装依赖
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # 添加Docker GPG密钥
    curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # 添加Docker仓库
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 更新并安装Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    
    success "Docker 安装完成"
}

# 安装Docker Compose
install_docker_compose() {
    log "安装 Docker Compose..."
    
    # 获取最新版本
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    
    if [ -z "$DOCKER_COMPOSE_VERSION" ]; then
        warn "无法获取最新版本，使用 v2.20.0"
        DOCKER_COMPOSE_VERSION="v2.20.0"
    fi
    
    log "下载 Docker Compose $DOCKER_COMPOSE_VERSION ..."
    
    # 下载Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # 如果GitHub下载慢，使用国内镜像
    # curl -L "https://get.daocloud.io/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # 添加执行权限
    chmod +x /usr/local/bin/docker-compose
    
    # 创建软链接
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    success "Docker Compose 安装完成"
}

# 启动Docker服务
start_docker() {
    log "启动 Docker 服务..."
    
    # 启动Docker
    systemctl start docker
    systemctl enable docker
    
    # 检查状态
    if systemctl is-active --quiet docker; then
        success "Docker 服务已启动"
    else
        error "Docker 服务启动失败"
    fi
}

# 配置Docker
configure_docker() {
    log "配置 Docker..."
    
    # 创建Docker配置目录
    mkdir -p /etc/docker
    
    # 配置Docker镜像加速（使用阿里云）
    cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
    "https://mirror.ccs.tencentyun.com",
    "https://registry.docker-cn.com",
    "https://docker.mirrors.ustc.edu.cn"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
    
    # 重启Docker
    systemctl daemon-reload
    systemctl restart docker
    
    success "Docker 配置完成"
}

# 验证安装
verify_installation() {
    log "验证安装..."
    echo ""
    
    # 检查Docker版本
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        success "Docker: $DOCKER_VERSION"
    else
        error "Docker 安装失败"
    fi
    
    # 检查Docker Compose版本
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version)
        success "Docker Compose: $COMPOSE_VERSION"
    else
        error "Docker Compose 安装失败"
    fi
    
    # 测试Docker
    log "测试 Docker..."
    if docker run --rm hello-world &> /dev/null; then
        success "Docker 运行测试通过"
    else
        warn "Docker 运行测试失败，但可能只是网络问题"
    fi
    
    echo ""
}

# 显示结果
show_results() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════╗"
    echo -e "║                                               ║"
    echo -e "║       🎉 Docker 安装完成！                    ║"
    echo -e "║                                               ║"
    echo -e "╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BLUE}📋 常用命令:${NC}"
    echo "  查看Docker版本:    docker --version"
    echo "  查看Docker状态:    systemctl status docker"
    echo "  启动Docker:        systemctl start docker"
    echo "  停止Docker:        systemctl stop docker"
    echo "  重启Docker:        systemctl restart docker"
    echo ""
    
    echo -e "${BLUE}🔧 Docker Compose 命令:${NC}"
    echo "  查看版本:          docker-compose --version"
    echo "  启动容器:          docker-compose up -d"
    echo "  停止容器:          docker-compose down"
    echo "  查看日志:          docker-compose logs -f"
    echo ""
    
    echo -e "${GREEN}✅ 现在可以运行部署脚本了:${NC}"
    echo "  ./deploy.sh"
    echo ""
}

# 主函数
main() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════╗"
    echo "║                                               ║"
    echo "║     Docker & Docker Compose 安装脚本         ║"
    echo "║                                               ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    # 检查是否已安装
    if command -v docker &> /dev/null; then
        warn "Docker 已经安装: $(docker --version)"
        read -p "是否要重新安装？(y/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "已取消安装"
            exit 0
        fi
    fi
    
    # 执行安装
    check_root
    detect_os
    
    # 根据系统类型安装Docker
    case $OS in
        centos|rhel|rocky|almalinux)
            install_docker_centos
            ;;
        ubuntu|debian)
            install_docker_ubuntu
            ;;
        *)
            error "不支持的操作系统: $OS"
            ;;
    esac
    
    # 安装Docker Compose
    install_docker_compose
    
    # 启动Docker
    start_docker
    
    # 配置Docker
    configure_docker
    
    # 验证安装
    verify_installation
    
    # 显示结果
    show_results
}

# 运行主函数
main "$@"

