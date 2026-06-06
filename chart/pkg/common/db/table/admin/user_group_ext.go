package admin

import (
	"context"
	"time"
)

// UserGroupConfig 用户分组扩展配置表（与 user_groups 1:1 关联）
// 新增表，不修改现有 user_groups 表结构
type UserGroupConfig struct {
	ID         uint64    `gorm:"column:id;primaryKey;autoIncrement"`
	GroupID    string    `gorm:"column:group_id;type:char(64);uniqueIndex:uk_group_id"`
	IsDefault  int32     `gorm:"column:is_default;type:tinyint(1);default:0"` // 0=否 1=是，应用层保证全局唯一
	SortOrder  int32     `gorm:"column:sort_order;type:int;default:0"`
	ExtConfig  string    `gorm:"column:ext_config;type:text"`   // 扩展配置 JSON（content_visibility/permissions）
	CreateTime time.Time `gorm:"column:create_time;autoCreateTime"`
	UpdateTime time.Time `gorm:"column:update_time;autoUpdateTime"`
}

func (UserGroupConfig) TableName() string {
	return "user_group_configs"
}

// UserGroupChangeLog 用户分组变更审计日志（只增不删，永久保留）
type UserGroupChangeLog struct {
	ID         uint64    `gorm:"column:id;primaryKey;autoIncrement"`
	GroupID    string    `gorm:"column:group_id;type:char(64);index:idx_group_id"`
	UserID     string    `gorm:"column:user_id;type:char(64);index:idx_user_id;default:''"`
	OpUserID   string    `gorm:"column:op_user_id;type:char(64);index:idx_op_user_id"`
	Action     string    `gorm:"column:action;type:varchar(32)"`              // CREATE_GROUP/DELETE_GROUP/RENAME_GROUP/ADD_MEMBER/REMOVE_MEMBER/SET_DEFAULT
	OldValue   string    `gorm:"column:old_value;type:varchar(512);default:''"`
	NewValue   string    `gorm:"column:new_value;type:varchar(512);default:''"`
	Remark     string    `gorm:"column:remark;type:varchar(255);default:''"`
	CreateTime time.Time `gorm:"column:create_time;autoCreateTime;index:idx_create_time"`
}

func (UserGroupChangeLog) TableName() string {
	return "user_group_change_logs"
}

// UserGroupConfigInterface 分组扩展配置数据库接口
type UserGroupConfigInterface interface {
	// Create 创建分组扩展配置（随分组创建时调用）
	Create(ctx context.Context, cfg *UserGroupConfig) error
	// Update 更新分组扩展配置（仅更新传入的字段）
	Update(ctx context.Context, groupID string, update map[string]any) error
	// Get 根据 groupID 获取扩展配置
	Get(ctx context.Context, groupID string) (*UserGroupConfig, error)
	// GetDefault 获取当前默认分组配置（全局唯一）
	GetDefault(ctx context.Context) (*UserGroupConfig, error)
	// Delete 删除分组扩展配置（随分组删除时调用）
	Delete(ctx context.Context, groupID string) error
	// CountGroups 获取当前分组总数（用于校验 100 个上限）
	CountGroups(ctx context.Context) (int64, error)
}

// UserGroupChangeLogInterface 审计日志数据库接口（只增不删）
type UserGroupChangeLogInterface interface {
	// Create 写入审计日志（只允许 INSERT，禁止 UPDATE/DELETE）
	Create(ctx context.Context, log *UserGroupChangeLog) error
	// ListByGroup 查询分组的变更历史（按时间倒序分页）
	ListByGroup(ctx context.Context, groupID string, pageNumber, showNumber int32) (uint32, []*UserGroupChangeLog, error)
	// ListByUser 查询用户的分组变更历史
	ListByUser(ctx context.Context, userID string, pageNumber, showNumber int32) (uint32, []*UserGroupChangeLog, error)
}
