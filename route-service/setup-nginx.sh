#!/bin/bash

# OpenIM Route Service - Nginx 配置脚本
# 用途：自动配置Nginx反向代理

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "🔧 配置 Nginx 反向代理"
echo "=========================================="

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ 请使用root用户运行此脚本${NC}"
    echo "使用: sudo ./setup-nginx.sh"
    exit 1
fi

# 检查Nginx是否安装
if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}⚠️  Nginx未安装，正在安装...${NC}"
    dnf install -y nginx
fi

# 获取域名
read -p "请输入你的域名 (例如: route.pbtf.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}❌ 域名不能为空${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}📝 配置信息:${NC}"
echo "   域名: $DOMAIN"
echo "   后端服务: http://127.0.0.1:10010"
echo ""

# 创建SSL证书目录
mkdir -p /etc/nginx/ssl

# 询问是否已有SSL证书
read -p "是否已有SSL证书? (y/n): " HAS_SSL

if [ "$HAS_SSL" = "y" ] || [ "$HAS_SSL" = "Y" ]; then
    read -p "请输入证书文件路径 (.crt): " CERT_PATH
    read -p "请输入私钥文件路径 (.key): " KEY_PATH
    
    if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ]; then
        cp "$CERT_PATH" "/etc/nginx/ssl/${DOMAIN}.crt"
        cp "$KEY_PATH" "/etc/nginx/ssl/${DOMAIN}.key"
        echo -e "${GREEN}✅ SSL证书已复制${NC}"
    else
        echo -e "${RED}❌ 证书文件不存在${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  将使用Let's Encrypt自动申请证书${NC}"
    
    # 安装certbot
    if ! command -v certbot &> /dev/null; then
        echo "正在安装certbot..."
        dnf install -y certbot python3-certbot-nginx
    fi
    
    # 申请证书
    echo "正在申请SSL证书..."
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email admin@$DOMAIN
fi

# 生成Nginx配置文件
cat > /etc/nginx/conf.d/route-service.conf <<EOF
# OpenIM Route Service - Nginx 配置
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    
    # 强制跳转到HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN;
    
    # SSL证书配置
    ssl_certificate /www/server/nginx/conf/ssl/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /www/server/nginx/conf/ssl/${DOMAIN}/privkey.pem;
    
    # SSL优化配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;
    
    # 日志配置
    access_log /var/log/nginx/route-access.log;
    error_log /var/log/nginx/route-error.log;
    
    # 客户端上传大小限制
    client_max_body_size 100M;
    
    # 公共 Proxy 设置
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-Port \$server_port;
    
    # WebSocket 支持
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";

    # 超时设置
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;

    # 1. 根路径转发
    location / {
        proxy_pass http://127.0.0.1:10010;
    }
    
    # 2. API 路径优化
    location /api/ {
        proxy_pass http://127.0.0.1:10010;
        
        # CORS配置
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With" always;
        
        if (\$request_method = OPTIONS) {
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain; charset=utf-8';
            add_header Content-Length 0;
            return 204;
        }
    }
    
    # 3. 健康检查
    location /api/health {
        proxy_pass http://127.0.0.1:10010;
        access_log off;
    }
}
EOF

echo -e "${GREEN}✅ Nginx配置文件已生成${NC}"

# 测试Nginx配置
echo ""
echo "🔍 测试Nginx配置..."
if nginx -t; then
    echo -e "${GREEN}✅ Nginx配置测试通过${NC}"
else
    echo -e "${RED}❌ Nginx配置测试失败${NC}"
    exit 1
fi

# 重启Nginx
echo ""
echo "🔄 重启Nginx..."
systemctl restart nginx
systemctl enable nginx

echo ""
echo "=========================================="
echo -e "${GREEN}🎉 Nginx配置完成！${NC}"
echo "=========================================="
echo ""
echo "📊 配置信息:"
echo "   域名: https://$DOMAIN"
echo "   配置文件: /etc/nginx/conf.d/route-service.conf"
echo "   访问日志: /var/log/nginx/route-access.log"
echo "   错误日志: /var/log/nginx/route-error.log"
echo ""
echo "🔗 测试访问:"
echo "   curl https://$DOMAIN/api/health"
echo ""
echo "💡 提示:"
echo "   - 确保域名已解析到服务器IP"
echo "   - 确保防火墙开放80和443端口"
echo "   - 确保路由服务正在运行 (./start.sh status)"
echo ""
