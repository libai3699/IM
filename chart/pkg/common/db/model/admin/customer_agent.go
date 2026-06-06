package admin

import (
	"context"
	"github.com/OpenIMSDK/tools/errs"
	"github.com/OpenIMSDK/tools/ormutil"
	"gorm.io/gorm"

	"github.com/OpenIMSDK/chat/pkg/common/db/table/admin"
)

func NewCustomerAgent(db *gorm.DB) admin.CustomerAgentInterface {
	return &CustomerAgent{db: db}
}

type CustomerAgent struct {
	db *gorm.DB
}

func (c *CustomerAgent) Create(ctx context.Context, agent *admin.CustomerAgent) error {
	return errs.Wrap(c.db.WithContext(ctx).Create(agent).Error)
}

func (c *CustomerAgent) Update(ctx context.Context, agentID string, update map[string]any) error {
	return errs.Wrap(c.db.WithContext(ctx).Model(&admin.CustomerAgent{}).Where("agent_id = ?", agentID).Updates(update).Error)
}

func (c *CustomerAgent) Delete(ctx context.Context, agentID string) error {
	return errs.Wrap(c.db.WithContext(ctx).Where("agent_id = ?", agentID).Delete(&admin.CustomerAgent{}).Error)
}

func (c *CustomerAgent) Get(ctx context.Context, agentID string) (*admin.CustomerAgent, error) {
	var a admin.CustomerAgent
	return &a, errs.Wrap(c.db.WithContext(ctx).Where("agent_id = ?", agentID).Take(&a).Error)
}

func (c *CustomerAgent) GetByUserID(ctx context.Context, userID string) (*admin.CustomerAgent, error) {
	var a admin.CustomerAgent
	return &a, errs.Wrap(c.db.WithContext(ctx).Where("user_id = ?", userID).Take(&a).Error)
}

func (c *CustomerAgent) Search(ctx context.Context, keyword string, page, size int32) (uint32, []*admin.CustomerAgent, error) {
	return ormutil.GormSearch[admin.CustomerAgent](c.db.WithContext(ctx), []string{"agent_name", "user_id"}, keyword, page, size)
}

func (c *CustomerAgent) NextRoundRobin(ctx context.Context) (*admin.CustomerAgent, error) {
	var a admin.CustomerAgent
	err := c.db.WithContext(ctx).
		Where("status = 1").
		Where("cur_load < max_load").
		Order("cur_load ASC").
		Limit(1).
		Take(&a).Error
	return &a, errs.Wrap(err)
}

func (c *CustomerAgent) IncrLoad(ctx context.Context, agentID string, delta int32) error {
	return errs.Wrap(c.db.WithContext(ctx).
		Model(&admin.CustomerAgent{}).
		Where("agent_id = ?", agentID).
		UpdateColumn("cur_load", gorm.Expr("cur_load + ?", delta)).Error)
}
