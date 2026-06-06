package admin

import (
	"context"
	"time"
)

// UserGroup 用户分组表
type UserGroup struct {
	GroupID    string    `gorm:"column:group_id;primary_key;type:char(64)"`
	GroupName  string    `gorm:"column:group_name;type:varchar(128);not null"`
	Remark     string    `gorm:"column:remark;type:varchar(255)"`
	CreateTime time.Time `gorm:"column:create_time;autoCreateTime"`
	UpdateTime time.Time `gorm:"column:update_time;autoUpdateTime"`
}

func (UserGroup) TableName() string {
	return "user_groups"
}

// UserGroupMember 用户分组成员表
type UserGroupMember struct {
	ID         uint64    `gorm:"column:id;primary_key;autoIncrement"`
	GroupID    string    `gorm:"column:group_id;type:char(64);index:idx_group"`
	UserID     string    `gorm:"column:user_id;type:char(64);index:idx_user"`
	CreateTime time.Time `gorm:"column:create_time;autoCreateTime"`
}

func (UserGroupMember) TableName() string {
	return "user_group_members"
}

type UserGroupInterface interface {
	Create(ctx context.Context, group *UserGroup) error
	Update(ctx context.Context, groupID string, update map[string]any) error
	Delete(ctx context.Context, groupID string) error
	Get(ctx context.Context, groupID string) (*UserGroup, error)
	Search(ctx context.Context, keyword string, page, size int32) (uint32, []*UserGroup, error)
	FindAll(ctx context.Context) ([]*UserGroup, error)
}

type UserGroupMemberInterface interface {
	Add(ctx context.Context, members []*UserGroupMember) error
	Remove(ctx context.Context, groupID string, userIDs []string) error
	ListByGroupID(ctx context.Context, groupID string) ([]*UserGroupMember, error)
	ListByUserID(ctx context.Context, userID string) ([]*UserGroupMember, error)
	DeleteByGroupID(ctx context.Context, groupID string) error
}
