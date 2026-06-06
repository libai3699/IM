package admin

import (
	"context"
	"github.com/OpenIMSDK/tools/errs"
	"github.com/OpenIMSDK/tools/ormutil"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/OpenIMSDK/chat/pkg/common/db/table/admin"
)

func NewCustomerAssign(db *gorm.DB) admin.CustomerAssignInterface {
	return &CustomerAssign{db: db}
}

type CustomerAssign struct {
	db *gorm.DB
}

func (c *CustomerAssign) Upsert(ctx context.Context, assign *admin.CustomerAssign) error {
	return errs.Wrap(c.db.WithContext(ctx).
		Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "customer_id"}},
			DoUpdates: clause.AssignmentColumns([]string{"agent_id", "assign_type", "assigned_by", "update_time"}),
		}).
		Create(assign).Error)
}

func (c *CustomerAssign) GetByCustomer(ctx context.Context, customerID string) (*admin.CustomerAssign, error) {
	var a admin.CustomerAssign
	return &a, errs.Wrap(c.db.WithContext(ctx).Where("customer_id = ?", customerID).Take(&a).Error)
}

func (c *CustomerAssign) ListByAgent(ctx context.Context, agentID string, page, size int32) (uint32, []*admin.CustomerAssign, error) {
	return ormutil.GormSearch[admin.CustomerAssign](
		c.db.WithContext(ctx).Where("agent_id = ?", agentID),
		[]string{}, "", page, size,
	)
}

func (c *CustomerAssign) Delete(ctx context.Context, customerID string) error {
	return errs.Wrap(c.db.WithContext(ctx).Where("customer_id = ?", customerID).Delete(&admin.CustomerAssign{}).Error)
}
