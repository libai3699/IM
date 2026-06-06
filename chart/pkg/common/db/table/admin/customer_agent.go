package admin

import (
	"context"
	"time"
)

// CustomerAgent 客服坐席表
type CustomerAgent struct {
	AgentID    string    `gorm:"column:agent_id;primary_key;type:char(64)"`
	UserID     string    `gorm:"column:user_id;type:char(64);uniqueIndex"`
	AgentName  string    `gorm:"column:agent_name;type:varchar(128)"`
	Status     int32     `gorm:"column:status;type:int;default:1"` // 1=启用 2=停用
	MaxLoad    int32     `gorm:"column:max_load;type:int;default:50"`
	CurLoad    int32     `gorm:"column:cur_load;type:int;default:0"`
	CreateTime time.Time `gorm:"column:create_time;autoCreateTime"`
	UpdateTime time.Time `gorm:"column:update_time;autoUpdateTime"`
}

func (CustomerAgent) TableName() string {
	return "customer_agents"
}

type CustomerAgentInterface interface {
	Create(ctx context.Context, agent *CustomerAgent) error
	Update(ctx context.Context, agentID string, update map[string]any) error
	Delete(ctx context.Context, agentID string) error
	Get(ctx context.Context, agentID string) (*CustomerAgent, error)
	GetByUserID(ctx context.Context, userID string) (*CustomerAgent, error)
	Search(ctx context.Context, keyword string, page, size int32) (uint32, []*CustomerAgent, error)
	// NextRoundRobin 获取下一个可分配坐席（轮询：status=1 且 cur_load < max_load，按 cur_load 升序）
	NextRoundRobin(ctx context.Context) (*CustomerAgent, error)
	IncrLoad(ctx context.Context, agentID string, delta int32) error
}
