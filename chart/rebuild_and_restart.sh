cd /wwwroot/openIm/chat/chat-enterprise

# 2. 停止服务
bash scripts/stop_all.sh

# 3. 生成 Proto
cd pkg/proto
bash gen.sh

# 4. 返回项目根目录
cd /wwwroot/openIm/chat/chat-enterprise

# 5. 编译所有服务
bash scripts/build_all_service.sh

# 6. 启动服务
bash scripts/start_all.sh