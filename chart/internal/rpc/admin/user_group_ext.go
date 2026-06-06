package admin

import (
	"context"
	"encoding/json"

	table "github.com/OpenIMSDK/chat/pkg/common/db/table/admin"
	"github.com/OpenIMSDK/tools/errs"
)

// userGroupExtLimit 用户分组数量上限
const userGroupExtLimit = 100

// checkGroupLimit 校验分组总数是否已达 100 个上限
// 在 CreateUserGroup 逻辑中调用（待 proto 扩展后集成）
func (o *adminServer) checkGroupLimit(ctx context.Context) error {
	count, err := o.Database.CountUserGroups(ctx)
	if err != nil {
		return err
	}
	if count >= userGroupExtLimit {
		return errs.ErrArgs.Wrap("分组数量已达上限（最多 100 个）")
	}
	return nil
}

// checkGroupNotDefault 校验分组是否为默认分组，默认分组不允许删除
// 在 DeleteUserGroup 逻辑中调用（待 proto 扩展后集成）
func (o *adminServer) checkGroupNotDefault(ctx context.Context, groupID string) error {
	cfg, err := o.Database.GetUserGroupConfig(ctx, groupID)
	if err != nil {
		// 找不到配置说明该分组尚未设置为默认，可以删除
		return nil
	}
	if cfg.IsDefault == 1 {
		return errs.ErrArgs.Wrap("默认分组不可删除，请先取消默认分组设置")
	}
	return nil
}

// setGroupDefault 设置默认分组（全局唯一）
// 先将现有默认分组取消，再设置新的默认分组
func (o *adminServer) setGroupDefault(ctx context.Context, opUserID, groupID string) error {
	// 取消当前默认分组
	oldDefault, err := o.Database.GetDefaultUserGroupConfig(ctx)
	if err == nil && oldDefault != nil && oldDefault.GroupID != groupID {
		if err := o.Database.UpdateUserGroupConfig(ctx, oldDefault.GroupID, map[string]any{
			"is_default": 0,
		}); err != nil {
			return err
		}
		// 记录取消默认的审计日志
		_ = o.Database.CreateUserGroupChangeLog(ctx, &table.UserGroupChangeLog{
			GroupID:  oldDefault.GroupID,
			OpUserID: opUserID,
			Action:   "UNSET_DEFAULT",
			OldValue: "1",
			NewValue: "0",
		})
	}

	// 设置新的默认分组
	// 先检查是否已有配置记录
	_, getErr := o.Database.GetUserGroupConfig(ctx, groupID)
	if getErr != nil {
		// 记录不存在，创建
		if err := o.Database.CreateUserGroupConfig(ctx, &table.UserGroupConfig{
			GroupID:   groupID,
			IsDefault: 1,
		}); err != nil {
			return err
		}
	} else {
		if err := o.Database.UpdateUserGroupConfig(ctx, groupID, map[string]any{
			"is_default": 1,
		}); err != nil {
			return err
		}
	}

	// 记录设置默认的审计日志
	_ = o.Database.CreateUserGroupChangeLog(ctx, &table.UserGroupChangeLog{
		GroupID:  groupID,
		OpUserID: opUserID,
		Action:   "SET_DEFAULT",
		OldValue: "0",
		NewValue: "1",
	})
	return nil
}

// setGroupExtConfig 更新分组扩展配置（校验 JSON 格式）
func (o *adminServer) setGroupExtConfig(ctx context.Context, opUserID, groupID, extConfig string) error {
	// 校验 JSON 格式
	if extConfig != "" {
		var tmp interface{}
		if err := json.Unmarshal([]byte(extConfig), &tmp); err != nil {
			return errs.ErrArgs.Wrap("扩展配置格式不合法，请输入有效 JSON")
		}
	}

	// 检查是否已有配置记录
	_, getErr := o.Database.GetUserGroupConfig(ctx, groupID)
	if getErr != nil {
		// 创建新配置
		if err := o.Database.CreateUserGroupConfig(ctx, &table.UserGroupConfig{
			GroupID:   groupID,
			ExtConfig: extConfig,
		}); err != nil {
			return err
		}
	} else {
		if err := o.Database.UpdateUserGroupConfig(ctx, groupID, map[string]any{
			"ext_config": extConfig,
		}); err != nil {
			return err
		}
	}

	// 记录审计日志
	_ = o.Database.CreateUserGroupChangeLog(ctx, &table.UserGroupChangeLog{
		GroupID:  groupID,
		OpUserID: opUserID,
		Action:   "UPDATE_CONFIG",
		NewValue: extConfig,
		Remark:   "更新扩展配置",
	})
	return nil
}

// writeGroupMemberLog 写入成员变更审计日志
func (o *adminServer) writeGroupMemberLog(ctx context.Context, opUserID, groupID, userID, action string) {
	_ = o.Database.CreateUserGroupChangeLog(ctx, &table.UserGroupChangeLog{
		GroupID:  groupID,
		UserID:   userID,
		OpUserID: opUserID,
		Action:   action,
	})
}
