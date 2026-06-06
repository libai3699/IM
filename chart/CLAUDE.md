<!-- 分析参考: go.mod, config/config.yaml, internal/api/router.go, pkg/eerrs/predefine.go, pkg/common/db/table/*, Makefile -->

# OpenIM Chat — 子项目工程规范

## 技术栈

| 组件 | 版本 |
|---|---|
| Go | 1.19 |
| Gin | v1.9.1 |
| gRPC | v1.58.0 |
| GORM (MySQL) | gorm.io/gorm v1.25.4 |
| MongoDB | go.mongodb.org/mongo-driver v1.12.0 |
| Redis | go-redis/v9 v9.1.0 |
| 日志 | OpenIMSDK/tools/log (基于 zap) |
| 短信 | 阿里云 dysmsapi |
| Excel | xuri/excelize/v2 v2.8.0 |
| 邮件 | gomail.v2 |

---

## 真实目录结构

```
chart/
├── cmd/                          # 各服务入口
│   ├── api/
│   │   ├── admin-api/            # 管理后台 API 入口
│   │   └── chat-api/             # 用户端 API 入口
│   └── rpc/
│       ├── admin-rpc/            # 管理后台 RPC 入口
│       ├── chat-rpc/             # 用户端 RPC 入口
│       └── office-rpc/           # 办公（朋友圈/标签）RPC 入口
├── config/
│   └── config.yaml               # 主配置文件
├── internal/                     # 内部业务逻辑
│   ├── api/                      # HTTP Handler 层
│   │   ├── router.go             # 路由注册（NewChatRoute / NewAdminRoute）
│   │   ├── admin.go              # 管理员 Handler
│   │   ├── chat.go               # 用户端 Handler
│   │   └── office.go             # 朋友圈/标签 Handler
│   └── rpc/                      # gRPC 服务实现
│       ├── admin/                # 管理员 RPC 服务
│       ├── chat/                 # 用户端 RPC 服务
│       └── office/               # 办公 RPC 服务
├── pkg/                          # 可复用包
│   ├── common/
│   │   ├── apicall/              # OpenIM Server API 调用封装
│   │   ├── apistruct/            # API 请求/响应结构体
│   │   ├── chatrpcstart/         # RPC 启动工具
│   │   ├── config/               # 配置加载
│   │   ├── constant/             # 常量定义
│   │   ├── db/
│   │   │   ├── cache/            # Redis 缓存
│   │   │   ├── database/         # 数据库接口（admin.go / chat.go / office.go）
│   │   │   ├── dbutil/           # GORM / Mongo 工具
│   │   │   ├── model/            # GORM Model 实现
│   │   │   │   ├── admin/        # 管理员相关表实现
│   │   │   │   ├── chat/         # 用户相关表实现
│   │   │   │   └── office/       # 朋友圈相关表实现
│   │   │   └── table/            # 表结构定义（接口 + struct）
│   │   │       ├── admin/        # 管理员表定义
│   │   │       ├── chat/         # 用户表定义
│   │   │       └── office/       # 朋友圈表定义
│   │   ├── dbconn/               # 数据库连接
│   │   ├── mctx/                 # Context 工具
│   │   ├── mw/                   # 中间件
│   │   ├── tokenverify/          # Token 验证
│   │   ├── totp/                 # TOTP 谷歌验证码
│   │   └── xlsx/                 # Excel 导入导出
│   ├── eerrs/                    # 业务错误码定义
│   ├── email/                    # 邮件发送
│   ├── proto/                    # Protobuf 定义
│   │   ├── admin/
│   │   ├── chat/
│   │   ├── common/
│   │   ├── office/
│   │   └── pub/
│   ├── rpclient/                 # RPC 客户端
│   ├── sms/                      # 短信发送
│   └── discovery_register/       # 服务发现
├── scripts/                      # 脚本
│   ├── start_all.sh              # 启动所有服务
│   ├── stop_all.sh               # 停止所有服务
│   └── build_all_service.sh      # 构建所有服务
├── sql/                          # SQL 迁移文件
└── test/                         # 测试
```

---

## 核心文件位置

| 用途 | 真实路径 |
|---|---|
| 路由注册（用户端） | `internal/api/router.go` → `NewChatRoute()` |
| 路由注册（管理端） | `internal/api/router.go` → `NewAdminRoute()` |
| 配置加载 | `pkg/common/config/` |
| 主配置文件 | `config/config.yaml` |
| 错误码定义 | `pkg/eerrs/predefine.go` |
| 数据库表定义 | `pkg/common/db/table/` |
| 数据库实现 | `pkg/common/db/model/` |
| Token 验证 | `pkg/common/tokenverify/` |
| 中间件 | `pkg/common/mw/` |

---

## 新功能文件规范

- **新 HTTP Handler**：在 `internal/api/` 下新建文件
- **新 RPC 服务**：在 `internal/rpc/` 下新建目录
- **新路由注册**：仅在 `internal/api/router.go` 的 `NewChatRoute()` 或 `NewAdminRoute()` 中新增
- **新数据库表**：在 `pkg/common/db/table/` 下对应子目录新建接口文件，在 `pkg/common/db/model/` 下新建实现
- **命名规范**：文件名 snake_case，Handler/Service 函数 PascalCase

---

## 错误码规范

错误码定义在 `pkg/eerrs/predefine.go`，范围 20001-20014：

```go
var (
    ErrPassword                 = errs.NewCodeError(20001, "密码错误")
    ErrAccountNotFound          = errs.NewCodeError(20002, "账号不存在")
    ErrPhoneAlreadyRegister     = errs.NewCodeError(20003, "手机号已注册")
    ErrAccountAlreadyRegister   = errs.NewCodeError(20004, "账号已注册")
    ErrVerifyCodeSendFrequently = errs.NewCodeError(20005, "验证码发送过于频繁")
    ErrVerifyCodeNotMatch       = errs.NewCodeError(20006, "验证码错误")
    ErrVerifyCodeExpired        = errs.NewCodeError(20007, "验证码已过期")
    ErrVerifyCodeMaxCount       = errs.NewCodeError(20008, "验证码错误次数过多")
    ErrVerifyCodeUsed           = errs.NewCodeError(20009, "验证码已使用")
    ErrInvitationCodeUsed       = errs.NewCodeError(20010, "邀请码已使用")
    ErrInvitationNotFound       = errs.NewCodeError(20011, "邀请码不存在")
    ErrForbidden                = errs.NewCodeError(20012, "禁止登录或注册")
    ErrRefuseFriend             = errs.NewCodeError(20013, "拒绝添加好友")
    ErrEmailAlreadyRegister     = errs.NewCodeError(20014, "邮箱已注册")
)
```

新增错误码从 **20015** 开始递增。

---

## 日志规范

使用 `github.com/OpenIMSDK/tools/log` 包：

```go
// 信息日志
log.ZInfo(c, "AdminLogin api", "req", &req)

// 错误日志
log.ZError(c, "AdminUpdateInfo ImAdminTokenWithDefaultAdmin", err)

// 调试日志
defer log.ZDebug(ctx, "return")
```

---

## 数据库约定

### MySQL（GORM）

- **主键类型**：`string`（`char(64)` 或 `varchar(64)`）
- **无软删除字段**，使用物理删除
- **时间字段**：`create_time`（autoCreateTime）、`change_time`（autoUpdateTime）

### 核心业务表

| 表名 | 文件路径 | 说明 |
|---|---|---|
| `accounts` | `pkg/common/db/table/chat/account.go` | 账号密码 |
| `attributes` | `pkg/common/db/table/chat/attribute.go` | 用户属性 |
| `registers` | `pkg/common/db/table/chat/register.go` | 注册记录 |
| `verify_codes` | `pkg/common/db/table/chat/verify_code.go` | 验证码 |
| `user_login_records` | `pkg/common/db/table/chat/user_login_record.go` | 登录记录 |
| `admins` | `pkg/common/db/table/admin/admin.go` | 管理员 |
| `applets` | `pkg/common/db/table/admin/applet.go` | 小程序 |
| `client_configs` | `pkg/common/db/table/admin/client_config.go` | 客户端配置 |
| `ip_forbiddens` | `pkg/common/db/table/admin/ip_forbidden.go` | IP 封禁 |
| `invitation_registers` | `pkg/common/db/table/admin/invitation_register.go` | 邀请码 |

### MongoDB

- 用于朋友圈（work_moment）、标签（tag）等办公功能数据

---

## 配置规范

配置文件 `config/config.yaml` 使用 YAML 格式：

```yaml
envs:
  discovery: "zookeeper"
chatApi:
  openImChatApiPort: [ 10008 ]
adminApi:
  openImAdminApiPort: [ 10009 ]
rpcPort:
  openImAdminPort: [ 30200 ]
  openImChatPort: [ 30300 ]
  openImOfficePort: [ 30400 ]
rpcRegisterName:
  openImAdminName: admin
  openImChatName: chat
  openImOfficeName: office
mysql:
  address: [ 127.0.0.1:13306 ]
  database: openIM_v3
```

---

## 实际命令

```bash
# 构建所有服务
bash scripts/build_all_service.sh

# 启动所有服务
bash scripts/start_all.sh

# 停止所有服务
bash scripts/stop_all.sh

# 通过 Makefile 构建
make build
```

---

## 禁止修改的文件

- `config/config.yaml` — 全局配置文件
- `pkg/common/tokenverify/` — Token 验证核心
- `pkg/common/mw/` — 中间件核心
- `pkg/proto/` — Protobuf 协议定义（需通过 proto 文件重新生成）
- `pkg/common/config/` — 配置加载核心
- `sql/` — 已执行的数据库迁移文件
