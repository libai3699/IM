# Changelog - chart (Admin Service)

All notable changes to the chart admin service will be documented here.

---

## [2026-03-16] - 四大业务功能上线

### Added - 用户分组系统 (Feature D)
- `internal/rpc/admin/user_group.go` — 分组 CRUD + 成员批量分配
- `internal/api/user_group.go` — HTTP 层接口（GET/POST/PUT/DELETE）
- `pkg/db/model/user_group_config.go` — UserGroupConfig 表模型
- `pkg/db/model/user_group_change_log.go` — UserGroupChangeLog 审计表
- AutoMigrate 注册：`admin2.UserGroupConfig{}` + `admin2.UserGroupChangeLog{}`

### Added - 客户轮询分配 (Feature B)
- `internal/rpc/admin/customer_assign.go` — NextRoundRobin 分配算法
- `internal/api/customer_assign.go` — 分配记录查询 + 坐席状态接口
- ⚠️ **待加固**：NextRoundRobin 高并发下需补 Redis 分布式锁

### Added - 消息外链 (Feature C)
- `pkg/proto/admin/admin.proto` — 新增 MessageLink 相关 message 和 RPC 定义
- `pkg/proto/admin/admin.pb.go` — protoc 重新生成
- `internal/rpc/admin/message_link.go` — CreateLink / GetLink / DeleteLink / PageLinks
- `internal/api/office.go` — LinkManage HTTP 层（CRUD + 审计日志只读）
- ⚠️ **待加固**：外链 URL 需加 IP 段过滤防 SSRF

### Added - 朋友圈/Moments (Feature A)
- `internal/api/office.go` — 补充 13 个 Moment HTTP 处理器
  - CreateMoment / DeleteMoment / GetMoment / PageMoments / PageMyMoments
  - VoteMoment / CommentMoment / DeleteMomentComment
  - AdminReviewMoment / AdminCancelTopMoment / AdminPageMoments / AdminPagePendingMoments
- 均为 `a2r.Call` 代理，对应 proto 中已有的 Office RPC 方法

### Modified
- `internal/rpc/admin/admin.go` — AutoMigrate 列表追加新表（仅追加）
- `config/router.go` — 路由注册追加新接口（仅追加）

---

## [2026-03-16 v2] - 安全加固 + 扩展 API 补全

### Security - 安全加固

- `pkg/common/urlutil/ssrf.go`（**新建**）— SSRF 防护工具
  - 协议白名单：仅允许 `http` / `https`
  - 私有 IP 段拦截：RFC1918 + loopback + link-local + IPv6 私有段
  - 域名白名单双重校验（结合数据库 `link_domain_whitelist` 表）
  - URL 最大长度限制：2048 字符

- `internal/rpc/admin/message_link.go` — 外链创建/更新前强制 SSRF 校验
  - `CreateMessageLink` / `UpdateMessageLink` 均调用 `validateLinkURL()`
  - 域名不在白名单时返回明确错误提示，引导管理员先添加白名单

- `pkg/common/db/database/admin.go` — 新增 Redis 分布式锁接口
  - `AcquireRoundRobinLock(ctx) (unlock func(), err)` — SET NX PX 5000
  - 解锁函数使用 `context.Background()` 防止 ctx 取消导致锁泄露
  - 锁 Key：`customer:assign:roundrobin:lock`

- `internal/rpc/admin/customer_assign.go` — 轮询分配加锁
  - 自动分配分支在 `NextRoundRobinAgent()` 前获取分布式锁
  - `IncrAgentLoad` 错误不再静默吞掉，改为返回错误

- `internal/rpc/office/moment.go` — 修复 isOfficial 逻辑
  - `CommentMoment`：仅管理员（`CheckAdmin` 成功）发布的评论才设 `isOfficial=true`
  - `AdminReviewMoment`：加状态机校验，只有 `pending` 状态才可审核

### Added - 用户分组扩展 API

- `internal/rpc/admin/user_group.go` — 4 个扩展 RPC 处理器
  - `GetUserGroupConfig` — 查询分组配置项（最大分组数 / 最大成员数）
  - `SetUserGroupConfig` — 更新分组配置项
  - `SetUserGroupDefault` — 设置/取消默认分组
  - `GetUserGroupChangeLogs` — 分页查询分组变更审计日志

- `internal/api/user_group.go` — 4 个对应 HTTP 接口（`a2r.Call` 代理）

- `pkg/proto/admin/admin.proto` — proto 协议扩展
  - `UserGroupInfo` 新增 `int32 isDefault = 6`
  - 新增 RPC：`GetUserGroupConfig` / `SetUserGroupConfig` / `SetUserGroupDefault` / `GetUserGroupChangeLogs` / `RecordLinkAccess`
  - 新增 message：`UserGroupConfigInfo` / `GetUserGroupConfigReq/Resp` / `SetUserGroupConfigReq/Resp` / `SetUserGroupDefaultReq/Resp` / `UserGroupChangeLogInfo` / `GetUserGroupChangeLogsReq/Resp` / `RecordLinkAccessReq/Resp`

- `pkg/proto/admin/admin.pb.go` + `admin_grpc.pb.go` — protoc 重新生成
  - 兼容性补丁：`SupportPackageIsVersion9` → `SupportPackageIsVersion7`，移除 `grpc.StaticMethod()`

### Added - 用户侧外链访问记录接口

- `internal/api/message_link.go` — 自定义 `RecordLinkAccess` HTTP 处理器
  - 非 `a2r.Call` 代理，需服务端注入客户端真实 IP
  - IP 提取优先级：`config.ProxyHeader` 配置头 → `RemoteAddr`
  - 路由：`POST /message_link/access`（chat 侧，需用户 Token）

### Fixed

- `internal/rpc/admin/user_group.go`
  - `SearchUserGroups` 正确从 `GetDefaultUserGroupConfig` 获取默认分组 ID，填充 `IsDefault` 字段
  - `AddUserGroupMembers` / `RemoveUserGroupMembers` 增加空列表校验 + 最大 500 条限制 + `utils.Distinct()` 去重
  - `CreateUserGroup` 创建前调用 `checkGroupLimit()` 校验分组数上限
  - `DeleteUserGroup` 删除前调用 `checkGroupNotDefault()` 禁止删除默认分组
