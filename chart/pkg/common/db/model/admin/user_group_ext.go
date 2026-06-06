package admin

import (
	"context"

	"github.com/OpenIMSDK/chat/pkg/common/db/table/admin"
	"github.com/OpenIMSDK/tools/errs"
	"gorm.io/gorm"
)

// NewUserGroupConfig 创建 UserGroupConfig 实例
func NewUserGroupConfig(db *gorm.DB) admin.UserGroupConfigInterface {
	return &userGroupConfig{db: db}
}

type userGroupConfig struct {
	db *gorm.DB
}

func (u *userGroupConfig) Create(ctx context.Context, cfg *admin.UserGroupConfig) error {
	return errs.Wrap(u.db.WithContext(ctx).Create(cfg).Error)
}

func (u *userGroupConfig) Update(ctx context.Context, groupID string, update map[string]any) error {
	return errs.Wrap(u.db.WithContext(ctx).
		Model(&admin.UserGroupConfig{}).
		Where("group_id = ?", groupID).
		Updates(update).Error)
}

func (u *userGroupConfig) Get(ctx context.Context, groupID string) (*admin.UserGroupConfig, error) {
	var cfg admin.UserGroupConfig
	return &cfg, errs.Wrap(u.db.WithContext(ctx).
		Where("group_id = ?", groupID).
		Take(&cfg).Error)
}

func (u *userGroupConfig) GetDefault(ctx context.Context) (*admin.UserGroupConfig, error) {
	var cfg admin.UserGroupConfig
	return &cfg, errs.Wrap(u.db.WithContext(ctx).
		Where("is_default = 1").
		Take(&cfg).Error)
}

func (u *userGroupConfig) Delete(ctx context.Context, groupID string) error {
	return errs.Wrap(u.db.WithContext(ctx).
		Where("group_id = ?", groupID).
		Delete(&admin.UserGroupConfig{}).Error)
}

// CountGroups 统计 user_groups 表总数（用于校验 100 个上限）
func (u *userGroupConfig) CountGroups(ctx context.Context) (int64, error) {
	var count int64
	err := u.db.WithContext(ctx).
		Model(&admin.UserGroup{}).
		Count(&count).Error
	return count, errs.Wrap(err)
}

// NewUserGroupChangeLog 创建 UserGroupChangeLog 实例
func NewUserGroupChangeLog(db *gorm.DB) admin.UserGroupChangeLogInterface {
	return &userGroupChangeLog{db: db}
}

type userGroupChangeLog struct {
	db *gorm.DB
}

func (u *userGroupChangeLog) Create(ctx context.Context, log *admin.UserGroupChangeLog) error {
	return errs.Wrap(u.db.WithContext(ctx).Create(log).Error)
}

func (u *userGroupChangeLog) ListByGroup(ctx context.Context, groupID string, pageNumber, showNumber int32) (uint32, []*admin.UserGroupChangeLog, error) {
	var logs []*admin.UserGroupChangeLog
	var total int64
	db := u.db.WithContext(ctx).
		Model(&admin.UserGroupChangeLog{}).
		Where("group_id = ?", groupID)
	if err := db.Count(&total).Error; err != nil {
		return 0, nil, errs.Wrap(err)
	}
	offset := int((pageNumber - 1) * showNumber)
	if err := db.Order("create_time DESC").
		Offset(offset).
		Limit(int(showNumber)).
		Find(&logs).Error; err != nil {
		return 0, nil, errs.Wrap(err)
	}
	return uint32(total), logs, nil
}

func (u *userGroupChangeLog) ListByUser(ctx context.Context, userID string, pageNumber, showNumber int32) (uint32, []*admin.UserGroupChangeLog, error) {
	var logs []*admin.UserGroupChangeLog
	var total int64
	db := u.db.WithContext(ctx).
		Model(&admin.UserGroupChangeLog{}).
		Where("user_id = ?", userID)
	if err := db.Count(&total).Error; err != nil {
		return 0, nil, errs.Wrap(err)
	}
	offset := int((pageNumber - 1) * showNumber)
	if err := db.Order("create_time DESC").
		Offset(offset).
		Limit(int(showNumber)).
		Find(&logs).Error; err != nil {
		return 0, nil, errs.Wrap(err)
	}
	return uint32(total), logs, nil
}
