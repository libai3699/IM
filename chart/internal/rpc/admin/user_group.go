package admin

import (
	"context"
	table "github.com/OpenIMSDK/chat/pkg/common/db/table/admin"
	"github.com/OpenIMSDK/chat/pkg/common/mctx"
	"github.com/OpenIMSDK/chat/pkg/proto/admin"
	"github.com/OpenIMSDK/tools/errs"
	"github.com/OpenIMSDK/tools/utils"
	"time"
)


const (
	// userGroupMembersMaxBatch 单次添加/移除成员的上限，防止超大批量请求打垮数据库
	userGroupMembersMaxBatch = 500
)

func (o *adminServer) CreateUserGroup(ctx context.Context, req *admin.CreateUserGroupReq) (*admin.CreateUserGroupResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	if req.GroupName == "" {
		return nil, errs.ErrArgs.Wrap("分组名称不能为空")
	}
	// 集成分组数量上限校验（最多 100 个）
	if err := o.checkGroupLimit(ctx); err != nil {
		return nil, err
	}
	group := &table.UserGroup{
		GroupID:   utils.Md5(req.GroupName + time.Now().String()),
		GroupName: req.GroupName,
		Remark:    req.Remark,
	}
	if err := o.Database.CreateUserGroup(ctx, group); err != nil {
		return nil, err
	}
	return &admin.CreateUserGroupResp{
		Group: &admin.UserGroupInfo{
			GroupID:     group.GroupID,
			GroupName:   group.GroupName,
			Remark:      group.Remark,
			CreateTime:  group.CreateTime.UnixMilli(),
			MemberCount: 0,
		},
	}, nil
}

func (o *adminServer) UpdateUserGroup(ctx context.Context, req *admin.UpdateUserGroupReq) (*admin.UpdateUserGroupResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	update := map[string]any{}
	if req.GroupName != "" {
		update["group_name"] = req.GroupName
	}
	if req.Remark != "" {
		update["remark"] = req.Remark
	}
	if len(update) == 0 {
		return &admin.UpdateUserGroupResp{}, nil
	}
	if err := o.Database.UpdateUserGroup(ctx, req.GroupID, update); err != nil {
		return nil, err
	}
	return &admin.UpdateUserGroupResp{}, nil
}

func (o *adminServer) DeleteUserGroup(ctx context.Context, req *admin.DeleteUserGroupReq) (*admin.DeleteUserGroupResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	// 集成默认分组保护：默认分组不允许删除
	if err := o.checkGroupNotDefault(ctx, req.GroupID); err != nil {
		return nil, err
	}
	if err := o.Database.DeleteUserGroupAllMembers(ctx, req.GroupID); err != nil {
		return nil, err
	}
	if err := o.Database.DeleteUserGroup(ctx, req.GroupID); err != nil {
		return nil, err
	}
	return &admin.DeleteUserGroupResp{}, nil
}

func (o *adminServer) GetUserGroup(ctx context.Context, req *admin.GetUserGroupReq) (*admin.GetUserGroupResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	group, err := o.Database.GetUserGroup(ctx, req.GroupID)
	if err != nil {
		return nil, err
	}
	members, err := o.Database.ListUserGroupMembers(ctx, req.GroupID)
	if err != nil {
		return nil, err
	}
	userIDs := make([]string, 0, len(members))
	for _, m := range members {
		userIDs = append(userIDs, m.UserID)
	}
	return &admin.GetUserGroupResp{
		Group: &admin.UserGroupInfo{
			GroupID:     group.GroupID,
			GroupName:   group.GroupName,
			Remark:      group.Remark,
			CreateTime:  group.CreateTime.UnixMilli(),
			MemberCount: int32(len(members)),
		},
		UserIDs: userIDs,
	}, nil
}

func (o *adminServer) SearchUserGroups(ctx context.Context, req *admin.SearchUserGroupsReq) (*admin.SearchUserGroupsResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	total, groups, err := o.Database.SearchUserGroups(ctx, req.Keyword, req.Pagination.PageNumber, req.Pagination.ShowNumber)
	if err != nil {
		return nil, err
	}
	// 查询默认分组（全局唯一），用于在列表中标记
	defaultGroupID := ""
	if defaultCfg, err := o.Database.GetDefaultUserGroupConfig(ctx); err == nil && defaultCfg != nil {
		defaultGroupID = defaultCfg.GroupID
	}
	pbGroups := make([]*admin.UserGroupInfo, 0, len(groups))
	for _, g := range groups {
		isDefault := int32(0)
		if g.GroupID == defaultGroupID {
			isDefault = 1
		}
		pbGroups = append(pbGroups, &admin.UserGroupInfo{
			GroupID:    g.GroupID,
			GroupName:  g.GroupName,
			Remark:     g.Remark,
			CreateTime: g.CreateTime.UnixMilli(),
			IsDefault:  isDefault,
		})
	}
	return &admin.SearchUserGroupsResp{Total: total, Groups: pbGroups}, nil
}

func (o *adminServer) AddUserGroupMembers(ctx context.Context, req *admin.AddUserGroupMembersReq) (*admin.AddUserGroupMembersResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	// 输入校验：非空 + 长度上限 + 去重
	if len(req.UserIDs) == 0 {
		return nil, errs.ErrArgs.Wrap("用户ID列表不能为空")
	}
	if len(req.UserIDs) > userGroupMembersMaxBatch {
		return nil, errs.ErrArgs.Wrap("单次添加成员数不能超过 500")
	}
	uniqueIDs := utils.Distinct(req.UserIDs)
	members := make([]*table.UserGroupMember, 0, len(uniqueIDs))
	for _, uid := range uniqueIDs {
		if uid == "" {
			return nil, errs.ErrArgs.Wrap("用户ID列表中包含空值")
		}
		members = append(members, &table.UserGroupMember{
			GroupID: req.GroupID,
			UserID:  uid,
		})
	}
	if err := o.Database.AddUserGroupMembers(ctx, members); err != nil {
		return nil, err
	}
	return &admin.AddUserGroupMembersResp{}, nil
}

func (o *adminServer) RemoveUserGroupMembers(ctx context.Context, req *admin.RemoveUserGroupMembersReq) (*admin.RemoveUserGroupMembersResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	// 输入校验：非空 + 长度上限 + 去重
	if len(req.UserIDs) == 0 {
		return nil, errs.ErrArgs.Wrap("用户ID列表不能为空")
	}
	if len(req.UserIDs) > userGroupMembersMaxBatch {
		return nil, errs.ErrArgs.Wrap("单次移除成员数不能超过 500")
	}
	uniqueIDs := utils.Distinct(req.UserIDs)
	if err := o.Database.RemoveUserGroupMembers(ctx, req.GroupID, uniqueIDs); err != nil {
		return nil, err
	}
	return &admin.RemoveUserGroupMembersResp{}, nil
}

func (o *adminServer) ListUserGroupMembers(ctx context.Context, req *admin.ListUserGroupMembersReq) (*admin.ListUserGroupMembersResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	members, err := o.Database.ListUserGroupMembers(ctx, req.GroupID)
	if err != nil {
		return nil, err
	}
	userIDs := make([]string, 0, len(members))
	for _, m := range members {
		userIDs = append(userIDs, m.UserID)
	}
	return &admin.ListUserGroupMembersResp{UserIDs: userIDs}, nil
}

// GetUserGroupConfig 获取分组扩展配置（排序值、是否默认、扩展 JSON）
func (o *adminServer) GetUserGroupConfig(ctx context.Context, req *admin.GetUserGroupConfigReq) (*admin.GetUserGroupConfigResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	if req.GroupID == "" {
		return nil, errs.ErrArgs.Wrap("groupID 不能为空")
	}
	cfg, err := o.Database.GetUserGroupConfig(ctx, req.GroupID)
	if err != nil {
		// 分组尚未设置扩展配置时，返回空配置
		return &admin.GetUserGroupConfigResp{
			Config: &admin.UserGroupConfigInfo{GroupID: req.GroupID},
		}, nil
	}
	return &admin.GetUserGroupConfigResp{
		Config: &admin.UserGroupConfigInfo{
			GroupID:   cfg.GroupID,
			IsDefault: cfg.IsDefault,
			SortOrder: cfg.SortOrder,
			ExtConfig: cfg.ExtConfig,
		},
	}, nil
}

// SetUserGroupConfig 设置分组扩展配置（ExtConfig JSON / SortOrder）
func (o *adminServer) SetUserGroupConfig(ctx context.Context, req *admin.SetUserGroupConfigReq) (*admin.SetUserGroupConfigResp, error) {
	opUserID, err := mctx.CheckAdmin(ctx)
	if err != nil {
		return nil, err
	}
	if req.GroupID == "" {
		return nil, errs.ErrArgs.Wrap("groupID 不能为空")
	}
	if req.ExtConfig != "" {
		if err := o.setGroupExtConfig(ctx, opUserID, req.GroupID, req.ExtConfig); err != nil {
			return nil, err
		}
	}
	if req.SortOrder != 0 {
		update := map[string]any{"sort_order": req.SortOrder}
		_, getErr := o.Database.GetUserGroupConfig(ctx, req.GroupID)
		if getErr != nil {
			if err := o.Database.CreateUserGroupConfig(ctx, &table.UserGroupConfig{
				GroupID:   req.GroupID,
				SortOrder: req.SortOrder,
			}); err != nil {
				return nil, err
			}
		} else {
			if err := o.Database.UpdateUserGroupConfig(ctx, req.GroupID, update); err != nil {
				return nil, err
			}
		}
	}
	return &admin.SetUserGroupConfigResp{}, nil
}

// SetUserGroupDefault 设置/取消默认分组（全局唯一）
func (o *adminServer) SetUserGroupDefault(ctx context.Context, req *admin.SetUserGroupDefaultReq) (*admin.SetUserGroupDefaultResp, error) {
	opUserID, err := mctx.CheckAdmin(ctx)
	if err != nil {
		return nil, err
	}
	if req.GroupID == "" {
		// 传空表示取消当前默认分组
		oldDefault, err := o.Database.GetDefaultUserGroupConfig(ctx)
		if err != nil {
			return &admin.SetUserGroupDefaultResp{}, nil // 当前无默认分组，幂等返回
		}
		if err := o.Database.UpdateUserGroupConfig(ctx, oldDefault.GroupID, map[string]any{"is_default": 0}); err != nil {
			return nil, err
		}
		_ = o.Database.CreateUserGroupChangeLog(ctx, &table.UserGroupChangeLog{
			GroupID:  oldDefault.GroupID,
			OpUserID: opUserID,
			Action:   "UNSET_DEFAULT",
			OldValue: "1",
			NewValue: "0",
		})
		return &admin.SetUserGroupDefaultResp{}, nil
	}
	// 检查分组是否存在
	if _, err := o.Database.GetUserGroup(ctx, req.GroupID); err != nil {
		return nil, err
	}
	if err := o.setGroupDefault(ctx, opUserID, req.GroupID); err != nil {
		return nil, err
	}
	return &admin.SetUserGroupDefaultResp{}, nil
}

// GetUserGroupChangeLogs 查询分组变更审计日志（分页，按时间倒序）
func (o *adminServer) GetUserGroupChangeLogs(ctx context.Context, req *admin.GetUserGroupChangeLogsReq) (*admin.GetUserGroupChangeLogsResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	total, logs, err := o.Database.ListUserGroupChangeLogs(ctx, req.GroupID, req.Pagination.PageNumber, req.Pagination.ShowNumber)
	if err != nil {
		return nil, err
	}
	pbLogs := make([]*admin.UserGroupChangeLogInfo, 0, len(logs))
	for _, l := range logs {
		pbLogs = append(pbLogs, &admin.UserGroupChangeLogInfo{
			Id:         l.ID,
			GroupID:    l.GroupID,
			UserID:     l.UserID,
			OpUserID:   l.OpUserID,
			Action:     l.Action,
			OldValue:   l.OldValue,
			NewValue:   l.NewValue,
			Remark:     l.Remark,
			CreateTime: l.CreateTime.UnixMilli(),
		})
	}
	return &admin.GetUserGroupChangeLogsResp{Total: total, Logs: pbLogs}, nil
}
