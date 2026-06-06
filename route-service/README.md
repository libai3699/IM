# OpenIM Route Service

OpenIM 路由服务 - 用于多服务器架构的用户路由分配

## 功能特性

- 🎯 基于邀请码的服务器分配
- 👤 用户与服务器绑定管理
- 🔄 自动路由到对应服务器
- 📊 服务器负载管理
- 🔐 邀请码使用次数限制
- ⏰ 邀请码过期时间控制

## 快速开始

### 方式1：Docker Compose 部署（推荐）

```bash
# 1. 进入项目目录
cd route-service

# 2. 启动服务（包含 MySQL）
docker-compose up -d

# 3. 查看日志
docker-compose logs -f

# 4. 停止服务
docker-compose down
```

### 方式2：本地运行

```bash
# 1. 安装依赖
go mod download

# 2. 修改配置文件 config.yaml
# 配置 MySQL 连接信息

# 3. 初始化数据库
mysql -h127.0.0.1 -P3306 -uroot -p < sql/init.sql

# 4. 运行服务
go run main.go
```

## API 文档

### 1. 健康检查

```http
GET /api/health
```

**响应示例：**
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "status": "ok"
  }
}
```

### 2. 发送验证码

```http
POST /api/verify/send
Content-Type: application/json

{
  "phone": "13800138000"
}
```

**cURL 示例：**
```bash
curl -X POST http://localhost:10010/api/verify/send \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}'
```

**响应示例：**
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "message": "验证码已发送"
  }
}
```

**说明：**
- 验证码有效期：5分钟（300秒）
- 验证码长度：6位数字
- 如果配置了短信宝，会真实发送短信
- 可以使用超级验证码 `123456` 进行测试（任何手机号都有效）

### 3. 验证验证码

```http
POST /api/verify/check
Content-Type: application/json

{
  "phone": "13800138000",
  "code": "123456"
}
```

**cURL 示例：**
```bash
curl -X POST http://localhost:10010/api/verify/check \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456"}'
```

**响应示例：**
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "message": "验证成功"
  }
}
```

**错误响应：**
```json
{
  "code": -1,
  "msg": "验证码错误"
}
```

**说明：**
- 验证成功后，验证码会自动失效
- 超级验证码 `123456` 始终有效（用于测试）
- 注意：找回密码时不能使用超级验证码

### 4. 注册用户

```http
POST /api/auth/register
Content-Type: application/json

{
  "invitationCode": "SERVER1",
  "verifyCode": "123456",
  "deviceID": "device123",
  "platform": 1,
  "autoLogin": true,
  "user": {
    "userID": "user123",
    "nickname": "张三",
    "faceURL": "https://example.com/avatar.jpg",
    "phoneNumber": "13800138000"
  },
  "deviceModel": "iPhone 14"
}
```

**cURL 示例：**
```bash
curl -X POST http://localhost:10010/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "invitationCode": "SERVER1",
    "verifyCode": "123456",
    "user": {
      "userID": "user123",
      "nickname": "张三",
      "phoneNumber": "13800138000"
    }
  }'
```

**响应示例（增强后的响应）：**
```json
{
  "errCode": 0,
  "errMsg": "",
  "data": {
    "userID": "user123",
    "chatToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "imToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "serverInfo": {
      "serverID": "server1",
      "serverName": "服务器1",
      "domains": [
        "domain1.example.com",
        "domain2.example.com",
        "domain3.example.com"
      ]
    }
  }
}
```

**说明：**
- 路由服务会根据邀请码自动转发到对应的服务器
- 注册成功后自动绑定用户到服务器
- 响应中会额外添加 `serverInfo` 字段，包含服务器域名列表
- 前端可以使用 `domains` 数组连接到服务器

### 5. 用户登录

```http
POST /api/auth/login
Content-Type: application/json

{
  "account": "13800138000",
  "password": "123456",
  "deviceID": "device123",
  "platform": 1,
  "deviceModel": "iPhone 14"
}
```

**cURL 示例：**
```bash
curl -X POST http://localhost:10010/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "account": "13800138000",
    "password": "123456"
  }'
```

**响应示例（增强后的响应）：**
```json
{
  "errCode": 0,
  "errMsg": "",
  "data": {
    "userID": "user123",
    "chatToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "imToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "serverInfo": {
      "serverID": "server1",
      "serverName": "服务器1",
      "domains": [
        "domain1.example.com",
        "domain2.example.com",
        "domain3.example.com"
      ]
    }
  }
}
```

**说明：**
- 路由服务会根据账号自动查询用户绑定的服务器
- 自动转发到目标服务器
- 响应中会额外添加 `serverInfo` 字段
- 前端可以使用 `domains` 数组连接到服务器

### 6. 重置密码

```http
POST /api/auth/reset-password
Content-Type: application/json

{
  "account": "13800138000",
  "verifyCode": "123456",
  "newPassword": "newpass123",
  "platform": 1
}
```

**cURL 示例：**
```bash
curl -X POST http://localhost:10010/api/auth/reset-password \
  -H "Content-Type: application/json" \
  -d '{
    "account": "13800138000",
    "verifyCode": "123456",
    "newPassword": "newpass123"
  }'
```

**响应示例：**
```json
{
  "errCode": 0,
  "errMsg": "",
  "data": {}
}
```

**说明：**
- 需要先调用 `/api/verify/send` 发送验证码
- 路由服务会严格验证验证码（**不允许使用超级验证码**）
- 自动查询用户绑定的服务器并转发请求
- 密码重置成功后返回结果

**安全特性：**
- ⚠️ 找回密码时禁用超级验证码，必须使用真实短信验证码
- ✅ 注册和登录时可以使用超级验证码（测试用）

### 7. 根据邀请码获取服务器

```http
GET /api/route/server?code=SERVER1
```

**cURL 示例：**
```bash
curl http://localhost:10010/api/route/server?code=SERVER1
```

**响应示例：**
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "server_id": "server1",
    "server_name": "服务器1",
    "domains": [
      "https://domain1.example.com",
      "https://domain2.example.com",
      "https://domain3.example.com"
    ]
  }
}
```

**前端使用示例：**
```javascript
// 获取服务器配置
const response = await fetch('/api/route/server?code=SERVER1');
const { data } = await response.json();

// 前端自行添加协议和拼接路径
const apiUrls = data.domains.map(domain => `https://${domain}/api`);
const wsUrls = data.domains.map(domain => `wss://${domain}/ws`);

// 使用第一个域名，失败时自动切换到下一个
let apiUrl = apiUrls[0];
let wsUrl = wsUrls[0];

// 或者让用户选择域名
console.log('可用域名:', data.domains);
```

**说明：**
- 只返回主域名数组，前端自行拼接 `/api`、`/ws` 等路径
- 前端可以选择任意一个域名使用
- 建议前端实现自动切换：如果第一个域名连接失败，自动尝试下一个

### 8. 根据用户ID获取服务器

```http
GET /api/route/server?user_id=user123
```

**cURL 示例：**
```bash
curl http://localhost:10010/api/route/server?user_id=user123
```

**响应示例：**
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "server_id": "server1",
    "server_name": "服务器1",
    "domains": [
      "https://domain1.example.com",
      "https://domain2.example.com",
      "https://domain3.example.com"
    ]
  }
}
```

### 9. 绑定用户到服务器

```http
POST /api/route/bind
Content-Type: application/json

{
  "user_id": "user123",
  "server_id": "server1",
  "invite_code": "SERVER1"
}
```

**cURL 示例：**
```bash
curl -X POST http://localhost:10010/api/route/bind \
  -H "Content-Type: application/json" \
  -d '{"user_id":"user123","server_id":"server1","invite_code":"SERVER1"}'
```

**响应示例：**
```json
{
  "code": 0,
  "msg": "success"
}
```

### 10. 获取所有可用服务器

```http
GET /api/route/servers
```

**cURL 示例：**
```bash
curl http://localhost:10010/api/route/servers
```

**响应示例：**
```json
{
  "code": 0,
  "msg": "success",
  "data": [
    {
      "id": 1,
      "server_id": "server1",
      "server_name": "服务器1",
      "api_url": "https://server1.example.com/api",
      "ws_url": "wss://server1.example.com/ws",
      "status": 1,
      "max_users": 0,
      "current_users": 10
    }
  ]
}
```

## 配置说明

### config.yaml

```yaml
server:
  port: 10010        # 服务端口
  mode: release      # 运行模式: debug / release

mysql:
  host: mysql        # MySQL 地址
  port: 3306         # MySQL 端口
  username: root     # 用户名
  password: route123456  # 密码
  database: openim_route # 数据库名
  maxOpenConn: 100   # 最大连接数
  maxIdleConn: 10    # 最大空闲连接数
  maxLifeTime: 3600  # 连接最大生命周期（秒）

log:
  level: info        # 日志级别
  file: ./logs/route.log  # 日志文件路径
```

## 数据库表结构

### server_config（服务器配置表）
- 存储各个 OpenIM 服务器的配置信息
- 包含 API 地址、WebSocket 地址等

### invite_code（邀请码表）
- 管理邀请码及其关联的服务器
- 支持使用次数限制和过期时间

### user_server_binding（用户服务器绑定表）
- 记录用户与服务器的绑定关系
- 用于后续登录时自动路由

## 使用流程

### 注册流程

**方式1：直接注册（推荐）**

1. **发送验证码**
   ```bash
   POST /api/verify/send
   {"phone": "13800138000"}
   ```

2. **调用注册接口**（路由服务自动处理）
   ```bash
   POST /api/auth/register
   {
     "invitationCode": "SERVER1",  # 可选，不传则使用默认服务器
     "verifyCode": "123456",
     "user": {...}
   }
   ```
   - 如果不传 `invitationCode`，自动使用默认服务器
   - 路由服务自动验证邀请码
   - 自动转发到目标服务器
   - 自动绑定用户到服务器
   - 原样返回注册结果

**方式2：手动流程（灵活）**

1. **发送验证码**
2. **验证验证码**
3. **获取服务器配置**
   ```bash
   GET /api/route/server?code=SERVER1
   ```
4. **前端直接连接目标服务器注册**
5. **手动绑定用户到服务器**
   ```bash
   POST /api/route/bind
   ```

### 登录流程

**方式1：直接登录（推荐）**

1. **调用登录接口**（路由服务自动处理）
   ```bash
   POST /api/auth/login
   {
     "account": "13800138000",  # 账号（手机号/用户ID）
     "password": "123456"
   }
   ```
   - 路由服务自动查询用户绑定的服务器
   - 自动转发到目标服务器
   - 返回登录结果和服务器信息

**方式2：手动流程**

1. **获取服务器配置**（根据用户ID）
   ```bash
   GET /api/route/server?user_id=user123
   ```

2. **前端直接连接目标服务器登录**

### 找回密码流程

1. **发送验证码**
   ```bash
   POST /api/verify/send
   {"phone": "13800138000"}
   ```

2. **重置密码**
   ```bash
   POST /api/auth/reset-password
   {
     "account": "13800138000",
     "verifyCode": "123456",
     "newPassword": "newpass123"
   }
   ```
   - 路由服务自动验证验证码
   - 自动查询用户服务器并转发请求

## 测试示例

### 完整注册流程测试

```bash
# 1. 发送验证码
curl -X POST http://localhost:10010/api/verify/send \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}'

# 2. 验证验证码（使用超级验证码测试）
curl -X POST http://localhost:10010/api/verify/check \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456"}'

# 3. 根据邀请码获取服务器
curl http://localhost:10010/api/route/server?code=SERVER1

# 4. 绑定用户到服务器
curl -X POST http://localhost:10010/api/route/bind \
  -H "Content-Type: application/json" \
  -d '{"user_id":"user123","server_id":"server1","invite_code":"SERVER1"}'
```

### 完整登录流程测试

```bash
# 1. 根据用户ID获取服务器
curl http://localhost:10010/api/route/server?user_id=user123

# 2. 使用返回的服务器地址进行登录（在目标服务器上操作）
```

## 管理操作

### 添加新服务器（支持多域名）

```sql
-- 单域名服务器（逗号分隔，不带协议前缀）
INSERT INTO server_config (server_id, server_name, domains, status) 
VALUES ('server3', '服务器3', 'server3.example.com', 1);

-- 多域名服务器（推荐）
INSERT INTO server_config (server_id, server_name, domains, is_default, status) 
VALUES ('server4', '服务器4', 
  'domain1.example.com,domain2.example.com,domain3.example.com', 
  0, 1);

-- 设置默认服务器
UPDATE server_config SET is_default = 1 WHERE server_id = 'server1';
```

**说明：**
- `domains` 字段存储逗号分隔的域名字符串，不带 `https://` 前缀
- `is_default` 字段：1=默认服务器，0=普通服务器（只能有一个默认服务器）
- 多个域名用英文逗号 `,` 分隔
- 前端收到域名后，自行添加协议和拼接路径：
  - API: `https://${domain}/api`
  - WebSocket: `wss://${domain}/ws`
  - Admin: `https://${domain}/admin`

### 创建邀请码

```sql
INSERT INTO invite_code (code, server_id, max_use_count, status, remark) 
VALUES ('NEWCODE', 'server3', 100, 1, '新服务器邀请码');
```

### 查看服务器用户分布

```sql
SELECT s.server_name, COUNT(b.user_id) as user_count
FROM server_config s
LEFT JOIN user_server_binding b ON s.server_id = b.server_id
GROUP BY s.server_id;
```

## 端口说明

- `10010` - 路由服务 HTTP API 端口
- `23306` - MySQL 数据库端口（映射到宿主机）
- `26379` - Redis 缓存端口（映射到宿主机）

## 目录结构

```
route-service/
├── main.go              # 主程序入口
├── config.yaml          # 配置文件
├── go.mod              # Go 模块定义
├── Dockerfile          # Docker 镜像构建文件
├── docker-compose.yml  # Docker Compose 配置
├── README.md           # 说明文档
├── api/
│   └── router.go       # API 路由定义
├── service/
│   └── route_service.go # 业务逻辑
├── model/
│   └── models.go       # 数据模型
├── db/
│   └── mysql.go        # 数据库连接
└── sql/
    └── init.sql        # 数据库初始化脚本
```

## 常见问题

### 1. 如何修改服务器地址？

直接修改数据库中的 `server_config` 表即可，无需重启服务。

### 2. 如何禁用某个邀请码？

```sql
UPDATE invite_code SET status = 0 WHERE code = 'XXX';
```

### 3. 如何查看邀请码使用情况？

```sql
SELECT code, server_id, used_count, max_use_count, status 
FROM invite_code 
ORDER BY created_at DESC;
```

## 许可证

Apache License 2.0
