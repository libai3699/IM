package admin

import (
	"context"
	"github.com/OpenIMSDK/tools/errs"
	"github.com/OpenIMSDK/tools/ormutil"
	"gorm.io/gorm"

	"github.com/OpenIMSDK/chat/pkg/common/db/table/admin"
)

func NewUserGroup(db *gorm.DB) admin.UserGroupInterface {
	return &UserGroup{db: db}
}

type UserGroup struct {
	db *gorm.DB
}

func (u *UserGroup) Create(ctx context.Context, group *admin.UserGroup) error {
	return errs.Wrap(u.db.WithContext(ctx).Create(group).Error)
}

func (u *UserGroup) Update(ctx context.Context, groupID string, update map[string]any) error {
	return errs.Wrap(u.db.WithContext(ctx).Model(&admin.UserGroup{}).Where("group_id = ?", groupID).Updates(update).Error)
}

func (u *UserGroup) Delete(ctx context.Context, groupID string) error {
	return errs.Wrap(u.db.WithContext(ctx).Where("group_id = ?", groupID).Delete(&admin.UserGroup{}).Error)
}

func (u *UserGroup) Get(ctx context.Context, groupID string) (*admin.UserGroup, error) {
	var g admin.UserGroup
	return &g, errs.Wrap(u.db.WithContext(ctx).Where("group_id = ?", groupID).Take(&g).Error)
}

func (u *UserGroup) Search(ctx context.Context, keyword string, page, size int32) (uint32, []*admin.UserGroup, error) {
	return ormutil.GormSearch[admin.UserGroup](u.db.WithContext(ctx), []string{"group_name", "remark"}, keyword, page, size)
}

func (u *UserGroup) FindAll(ctx context.Context) ([]*admin.UserGroup, error) {
	var gs []*admin.UserGroup
	return gs, errs.Wrap(u.db.WithContext(ctx).Find(&gs).Error)
}

func NewUserGroupMember(db *gorm.DB) admin.UserGroupMemberInterface {
	return &UserGroupMember{db: db}
}

type UserGroupMember struct {
	db *gorm.DB
}

func (u *UserGroupMember) Add(ctx context.Context, members []*admin.UserGroupMember) error {
	return errs.Wrap(u.db.WithContext(ctx).Create(&members).Error)
}

func (u *UserGroupMember) Remove(ctx context.Context, groupID string, userIDs []string) error {
	return errs.Wrap(u.db.WithContext(ctx).
		Where("group_id = ? AND user_id IN ?", groupID, userIDs).
		Delete(&admin.UserGroupMember{}).Error)
}

func (u *UserGroupMember) ListByGroupID(ctx context.Context, groupID string) ([]*admin.UserGroupMember, error) {
	var ms []*admin.UserGroupMember
	return ms, errs.Wrap(u.db.WithContext(ctx).Where("group_id = ?", groupID).Find(&ms).Error)
}

func (u *UserGroupMember) ListByUserID(ctx context.Context, userID string) ([]*admin.UserGroupMember, error) {
	var ms []*admin.UserGroupMember
	return ms, errs.Wrap(u.db.WithContext(ctx).Where("user_id = ?", userID).Find(&ms).Error)
}

func (u *UserGroupMember) DeleteByGroupID(ctx context.Context, groupID string) error {
	return errs.Wrap(u.db.WithContext(ctx).Where("group_id = ?", groupID).Delete(&admin.UserGroupMember{}).Error)
}
