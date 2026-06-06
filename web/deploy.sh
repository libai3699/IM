#!/bin/bash

# Web打包脚本 - OpenIM Web
# 生成可部署的静态文件包

echo "======================================"
echo "  OpenIM Web 打包脚本"
echo "======================================"

# 清理旧的构建文件
echo ""
echo "1. 清理旧的构建文件..."
rm -rf dist
rm -f dist.zip

# 安装依赖（如果需要）
if [ ! -d "node_modules" ]; then
    echo ""
    echo "2. 安装依赖..."
    npm install
fi

# 构建项目
echo ""
echo "3. 开始构建项目..."
npm run build

# 检查构建是否成功
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    
    # 打包 dist 目录
    echo ""
    echo "4. 打包 dist 目录..."
    cd dist
    zip -r ../dist.zip ./*
    cd ..
    
    echo ""
    echo "======================================"
    echo "✅ 打包完成！"
    echo "======================================"
    echo ""
    echo "📦 输出文件："
    echo "   - dist/          (静态文件目录)"
    echo "   - dist.zip       (压缩包)"
    echo ""
    echo "📋 部署说明："
    echo "   1. 将 dist.zip 上传到服务器"
    echo "   2. 解压到 Nginx 根目录，例如："
    echo "      unzip dist.zip -d /app/im/dist/"
    echo "   3. 配置 Nginx 指向该目录"
    echo ""
    echo "🔧 Nginx 配置示例："
    echo "   location / {"
    echo "       root /app/im/dist;"
    echo "       index index.html;"
    echo "       try_files \$uri \$uri/ /index.html;"
    echo "   }"
    echo ""
    echo "======================================"
else
    echo ""
    echo "❌ 构建失败，请检查错误信息"
    exit 1
fi
