package admin

import (
	"context"
	"time"
)

// CustomerAssign 客户-坐席分配关系表
type CustomerAssign struct {
	ID           uint64    `gorm:"column:id;primary_key;autoIncrement"`
	CustomerID   string    `gorm:"column:customer_id;type:char(64);uniqueIndex"` // 客户 userID
	AgentID      string    `gorm:"column:agent_id;type:char(64);index"`
	AssignType   int32     `gorm:"column:assign_type;type:int;default:1"` // 1=自动轮询 2=手动分配
	AssignedBy   string    `gorm:"column:assigned_by;type:char(64)"`      // 手动分配时操作员ID
	CreateTime   time.Time `gorm:"column:create_time;autoCreateTime"`
	UpdateTime   time.Time `gorm:"column:update_time;autoUpdateTime"`
}

func (CustomerAssign) TableName() string {
	return "customer_assigns"
}

type CustomerAssignInterface interface {
	Upsert(ctx context.Context, assign *CustomerAssign) error
	GetByCustomer(ctx context.Context, customerID string) (*CustomerAssign, error)
	ListByAgent(ctx context.Context, agentID string, page, size int32) (uint32, []*CustomerAssign, error)
	Delete(ctx context.Context, customerID string) error
}
