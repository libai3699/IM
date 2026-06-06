chat.rar 和 server.rar 是后端
ichat-admin.rar 是后台管理前端代码，没有后端，和im共用后端，也就是chat和server
ichat-electron 是pc端，可以打包网页和pc exe
flutter-enterprise是app端
docker-compose down
关于启动：
1.首先要启动中间件，mysql，kafka，redis等等，这些都在 server 的docker-compose.yml 中，直接执行 docker-compose up -d 就全部启动了

2.再启动 server.rar  启动之前先修改 config目录中的文件，所有外网ip改成你自己现在的外网ip，然后进入script目录执行 ./start_all 那个脚本就启动了

3.最后启动 chat，同样先修改config再进入script执行 start_all 脚本

4.最后启动  rtc，rtc同样修改config目录，并且需要修改 start_up.sh 脚本中的ip为你自己的ip

以上步骤不能乱
这个nginx 按照 这个 vhost 里面的nginx 是总的

最后再启动nginx就行了


上传  install_docker.sh 执行 ./install_docker.sh 安装docker

宝塔申请ssl 就行了
然后 nginx 里的配置要按照他的老
执行./start_all

docker exec mysql mysql -uroot -pP8x$K9mQ#vR2wN5L -e "

docker exec -it mysql mysql -uroot -pP8x$K9mQ#vR2wN5L
SELECT
    SUBSTRING_INDEX(host, ':', 1) as ip_address,
    user,
    COUNT(*) as connections
FROM information_schema.processlist
GROUP BY SUBSTRING_INDEX(host, ':', 1), user
ORDER BY connections DESC;
"

use openIM_v3;
docker exec mysql mysql -uroot -pP8x$K9mQ#vR2wN5L -e "SET GLOBAL max_connections = 5000;"


cd /wwwroot/openIm/server/open-im-server-main

# 1. 给所有脚本添加执行权限
chmod +x scripts/*.sh
chmod +x scripts/install/*.sh

# 2. 构建 OpenIM 二进制文件

# 如果 make 命令不存在，需要先安装
# yum install -y make

# 3. 启动所有服务
cd scripts
./start-all.sh


[root@ip-172-31-38-14 scripts]# docker exec redis redis-cli -a 'Qw5!dG8yT1rE3%sA' --no-auth-warning KEYS "*TOKEN*openIM123456*"


# 查看所有 token keys
docker exec redis redis-cli -a 'Qw5!dG8yT1rE3%sA' --no-auth-warning KEYS "*TOKEN*admin2024*"

# 只删除 token（不影响会话、消息等数据）
docker exec redis redis-cli -a 'Qw5!dG8yT1rE3%sA' --no-auth-warning --scan --pattern "*TOKEN*admin2024*" | xargs -I {} docker exec redis redis-cli -a 'Qw5!dG8yT1rE3%sA' --no-auth-warning DEL {}
