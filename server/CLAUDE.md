<!-- 分析参考: go.mod, config/config.yaml, internal/api/route.go, pkg/common/*, Makefile -->

# OpenIM Server — 子项目工程规范

## 技术栈

| 组件 | 版本 |
|---|---|
| Go | 1.19 |
| Gin | v1.9.1 |
| gRPC | v1.59.0 |
| MongoDB | go.mongodb.org/mongo-driver v1.12.1 |
| Redis | go-redis/v9 v9.2.1 |
| Kafka | IBM/sarama v1.41.3 |
| MinIO | minio-go/v7 v0.63 |
| Protobuf | v1.31.0 |
| Zookeeper | go-zookeeper/zk v1.0.3 |
| 日志 | OpenIMSDK/tools/log (基于 zap) |

---

## 真实目录结构

```
server/
├── cmd/                          # 各服务入口
│   ├── openim-api/               # HTTP API 网关入口
│   ├── openim-crontask/          # 定时任务入口
│   ├── openim-msggateway/        # 消息网关（WebSocket）入口
│   ├── openim-msgtransfer/       # 消息转发（Kafka 消费者）入口
│   ├── openim-push/              # 推送服务入口
│   └── openim-rpc/               # gRPC 服务入口
│       ├── openim-rpc-auth/      # 认证 RPC
│       ├── openim-rpc-conversation/ # 会话 RPC
│       ├── openim-rpc-encryption/   # 加密 RPC
│       ├── openim-rpc-friend/    # 好友 RPC
│       ├── openim-rpc-group/     # 群组 RPC
│       ├── openim-rpc-msg/       # 消息 RPC
│       ├── openim-rpc-third/     # 第三方服务 RPC
│       └── openim-rpc-user/      # 用户 RPC
├── config/                       # 配置文件（YAML）
│   ├── config.yaml               # 主配置文件
│   └── notification.yaml         # 通知配置
├── internal/                     # 内部业务逻辑
│   ├── api/                      # HTTP Handler 层（Gin）
│   ├── msggateway/               # WebSocket 消息网关
│   ├── msgtransfer/              # Kafka 消息消费与转发
│   ├── push/                     # 推送服务
│   │   └── offlinepush/          # 离线推送（FCM / 个推 / 极光）
│   ├── rpc/                      # gRPC 服务实现
│   │   ├── auth/                 # 认证服务
│   │   ├── conversation/         # 会话服务
│   │   ├── encryption/           # 加密服务
│   │   ├── friend/               # 好友服务
│   │   ├── group/                # 群组服务
│   │   ├── msg/                  # 消息服务
│   │   ├── statistics/           # 统计服务
│   │   ├── third/                # 第三方服务（文件上传等）
│   │   └── user/                 # 用户服务
│   └── tools/                    # 内部工具（消息清理等）
├── pkg/                          # 可复用包
│   ├── apistruct/                # API 请求/响应结构体
│   ├── authverify/               # 鉴权验证
│   ├── callbackstruct/           # 回调结构体
│   ├── common/
│   │   ├── cmd/                  # 命令行工具
│   │   ├── config/               # 配置加载
│   │   ├── convert/              # 数据转换
│   │   ├── db/                   # 数据库层
│   │   │   ├── cache/            # Redis 缓存
│   │   │   ├── controller/       # 数据库 Controller
│   │   │   ├── mgo/              # MongoDB 操作
│   │   │   ├── s3/               # 对象存储
│   │   │   ├── table/            # 表结构定义（接口）
│   │   │   └── unrelation/       # MongoDB 集合操作
│   │   ├── discoveryregister/    # 服务发现（ZK / K8s）
│   │   ├── kafka/                # Kafka 生产者/消费者
│   │   └── startrpc/             # RPC 启动工具
│   ├── msgprocessor/             # 消息处理器
│   ├── protocol/                 # Protobuf 协议定义（本地 replace）
│   │   ├── auth/
│   │   ├── constant/             # 常量定义
│   │   ├── conversation/
│   │   ├── friend/
│   │   ├── group/
│   │   ├── msg/
│   │   ├── sdkws/                # SDK WebSocket 协议
│   │   ├── third/
│   │   └── user/
│   └── rpcclient/                # RPC 客户端封装
│       └── notification/         # 通知发送
```

---

## 核心文件位置

| 用途 | 真实路径 |
|---|---|
| HTTP 路由注册 | `internal/api/route.go` → `NewGinRouter()` |
| 配置加载 | `pkg/common/config/` |
| 主配置文件 | `config/config.yaml` |
| 日志工具 | `github.com/OpenIMSDK/tools/log`（外部依赖） |
| Token 解析中间件 | `internal/api/route.go` → `GinParseToken()` |
| RPC 客户端封装 | `pkg/rpcclient/` |
| 协议定义 | `pkg/protocol/`（本地 replace，原 `github.com/OpenIMSDK/protocol`） |

---

## 新功能文件规范

- **新 HTTP Handler**：在 `internal/api/` 下新建文件，如 `internal/api/xxx.go`
- **新 RPC 服务**：在 `internal/rpc/` 下新建目录，如 `internal/rpc/xxx/`
- **新路由注册**：仅在 `internal/api/route.go` 的 `NewGinRouter()` 中新增路由组
- **命名规范**：文件名 snake_case，Handler 函数 PascalCase

---

## 分层职责

| 层 | 目录 | 职责 |
|---|---|---|
| API Handler | `internal/api/` | 接收 HTTP 请求，参数校验，调用 RPC 客户端 |
| RPC Service | `internal/rpc/*/` | 业务逻辑实现，gRPC 服务端 |
| RPC Client | `pkg/rpcclient/` | gRPC 客户端封装，供 API 层调用 |
| DB Controller | `pkg/common/db/controller/` | 数据访问控制层 |
| MongoDB 操作 | `pkg/common/db/mgo/` | MongoDB 具体操作实现 |
| Cache | `pkg/common/db/cache/` | Redis 缓存操作 |
| Table 定义 | `pkg/common/db/table/` | 数据表接口定义 |
| 协议定义 | `pkg/protocol/` | Protobuf 消息与 RPC 接口定义 |

---

## 日志规范

使用 `github.com/OpenIMSDK/tools/log` 包，调用格式为 `log.ZXxx(ctx, msg, key, value, ...)`：

```go
// 信息日志
log.ZInfo(context.Background(), "load config", "config", config.Config)

// 警告日志（带 error）
log.ZWarn(c, "header get token error", errs.ErrArgs.Wrap("header must have token"))

// 错误日志
log.ZError(ctx, "get all conversation ids failed", err)

// 调试日志
log.ZDebug(ctx, "all userIDs", "len userIDs", len(userIDs))
```

---

## 错误处理规范

使用 `github.com/OpenIMSDK/tools/errs` 包：

```go
// 预定义错误码使用
errs.ErrArgs.Wrap("header must have token")
errs.ErrArgs.WithDetail("not support err contentType")
errs.ErrTokenNotExist.Wrap()

// API 层错误响应
apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
```

---

## 数据库约定

- **主数据库**：MongoDB（消息、会话等核心数据）
- **缓存**：Redis（Token、在线状态等）
- **配置文件中数据库名**：`openIM_v3`
- **主键类型**：string（userID 为 char(64)）
- **消息存储**：MongoDB 集合

---

## 配置规范

配置文件 `config/config.yaml` 使用 YAML 格式，顶层 key 使用 camelCase：

```yaml
envs:
  discovery: zookeeper
zookeeper:
  schema: openim
  address: [ 127.0.0.1:12181 ]
mysql:
  address: [ 127.0.0.1:13306 ]
  database: openIM_v3
```

---

## 实际命令

```bash
# 构建（通过 Makefile）
make build BINS="openim-api openim-msggateway"

# 全量构建
make all

# 测试
make test
```

---

## 禁止修改的文件

- `config/config.yaml` — 全局配置文件
- `pkg/protocol/` — Protobuf 协议定义（需通过 proto 文件重新生成）
- `pkg/authverify/` — 鉴权核心模块
- `pkg/common/config/` — 配置加载核心
- `internal/api/route.go` 中 `GinParseToken()` — Token 解析中间件
