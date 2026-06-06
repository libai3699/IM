// Copyright © 2023 OpenIM open source community. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package chat

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/OpenIMSDK/protocol/constant"
	"github.com/OpenIMSDK/tools/errs"
	"github.com/OpenIMSDK/tools/log"

	constant2 "github.com/OpenIMSDK/chat/pkg/common/constant"
	"github.com/OpenIMSDK/chat/pkg/common/mctx"
	chat2 "github.com/OpenIMSDK/chat/pkg/common/db/table/chat"
	"github.com/OpenIMSDK/chat/pkg/eerrs"
	"github.com/OpenIMSDK/chat/pkg/proto/chat"
)

const (
	callbackBeforeCreateGroupCommand    = "callbackBeforeCreateGroupCommand"
	callbackBeforeInviteJoinGroupCommand = "callbackBeforeInviteJoinGroupCommand"
)

type CallbackBeforeAddFriendReq struct {
	CallbackCommand `json:"callbackCommand"`
	FromUserID      string `json:"fromUserID" `
	ToUserID        string `json:"toUserID"`
	ReqMsg          string `json:"reqMsg"`
	OperationID     string `json:"operationID"`
}

type CallbackBeforeCreateGroupReq struct {
	CallbackCommand `json:"callbackCommand"`
	OperationID     string `json:"operationID"`
	OwnerUserID     string `json:"ownerUserID"`
	CreatorUserID   string `json:"creatorUserID"`
}

type CallbackBeforeInviteUserToGroupReq struct {
	CallbackCommand `json:"callbackCommand"`
	OperationID     string   `json:"operationID"`
	GroupID         string   `json:"groupID"`
	InviterUserID   string   `json:"inviterUserID"`
	InvitedUserIDs  []string `json:"invitedUserIDs"`
}

type CallbackCommand string

func (c CallbackCommand) GetCallbackCommand() string {
	return string(c)
}

func (o *chatSvr) OpenIMCallback(ctx context.Context, req *chat.OpenIMCallbackReq) (*chat.OpenIMCallbackResp, error) {
	log.ZError(ctx, "========== 收到回调请求 ==========", nil, "command", req.Command, "body", req.Body)
	defer log.ZDebug(ctx, "return")
	switch req.Command {
	case constant.CallbackBeforeAddFriendCommand:
		var data CallbackBeforeAddFriendReq
		if err := json.Unmarshal([]byte(req.Body), &data); err != nil {
			return nil, errs.Wrap(err)
		}
		log.ZError(ctx, "========== 准备查询接收者 ==========", nil, "toUserID", data.ToUserID)
		user, err := o.Database.GetAttribute(ctx, data.ToUserID)
		if err != nil {
			log.ZError(ctx, "========== 查询接收者失败 ==========", err, "toUserID", data.ToUserID)
			return nil, err
		}
		log.ZError(ctx, "========== 查询接收者成功 ==========", nil, "toUserID", data.ToUserID, "user", user)
		log.ZInfo(ctx, "OpenIMCallback", "user", user)
		if user.AllowAddFriend != constant2.OrdinaryUserAddFriendEnable {
			return nil, eerrs.ErrRefuseFriend.Wrap(fmt.Sprintf("拒绝添加好友状态 %d", user.AllowAddFriend))
		}
		if err := o.checkAddFriendRestriction(ctx, data.FromUserID, user); err != nil {
			return nil, err
		}
		log.ZError(ctx, "========== 回调成功，允许加好友 ==========", nil, "fromUserID", data.FromUserID, "toUserID", data.ToUserID)
		return &chat.OpenIMCallbackResp{}, nil

	case callbackBeforeCreateGroupCommand:
		var data CallbackBeforeCreateGroupReq
		if err := json.Unmarshal([]byte(req.Body), &data); err != nil {
			return nil, errs.Wrap(err)
		}
		creatorID := data.OwnerUserID
		if creatorID == "" {
			creatorID = data.CreatorUserID
		}
		if creatorID == "" {
			return &chat.OpenIMCallbackResp{}, nil
		}
		if err := o.checkGroupRestriction(ctx, creatorID, "allow_create_group", "只有高级用户才能创建群组"); err != nil {
			return nil, err
		}
		return &chat.OpenIMCallbackResp{}, nil

	case callbackBeforeInviteJoinGroupCommand:
		var data CallbackBeforeInviteUserToGroupReq
		if err := json.Unmarshal([]byte(req.Body), &data); err != nil {
			return nil, errs.Wrap(err)
		}
		if data.InviterUserID == "" {
			return &chat.OpenIMCallbackResp{}, nil
		}
		if err := o.checkGroupRestriction(ctx, data.InviterUserID, "allow_create_group", "只有高级用户才能邀请用户入群"); err != nil {
			return nil, err
		}
		// 被邀请的人必须是邀请者的好友
		adminToken, err := o.ImApiCaller.ImAdminTokenWithDefaultAdmin(ctx)
		if err != nil {
			log.ZError(ctx, "callbackBeforeInviteJoinGroup: 获取 admin token 失败，降级放行", err)
			return &chat.OpenIMCallbackResp{}, nil
		}
		ctxWithToken := mctx.WithApiToken(ctx, adminToken)
		friendIDs, err := o.ImApiCaller.FindFriendUserIDs(ctxWithToken, data.InviterUserID)
		if err != nil {
			log.ZError(ctx, "callbackBeforeInviteJoinGroup: 获取好友列表失败，降级放行", err, "inviterUserID", data.InviterUserID)
			return &chat.OpenIMCallbackResp{}, nil
		}
		friendSet := make(map[string]struct{}, len(friendIDs))
		for _, fid := range friendIDs {
			friendSet[fid] = struct{}{}
		}
		for _, uid := range data.InvitedUserIDs {
			if _, ok := friendSet[uid]; !ok {
				return nil, eerrs.ErrRefuseFriend.Wrap(fmt.Sprintf("用户 %s 不是您的好友，无法邀请入群", uid))
			}
		}
		return &chat.OpenIMCallbackResp{}, nil

	default:
		log.ZDebug(ctx, "OpenIMCallback: 未处理的命令，放行", "command", req.Command)
		return &chat.OpenIMCallbackResp{}, nil
	}
}

// checkGroupRestriction 检查群组操作限制，逻辑与 checkAddFriendRestriction 一致：
// 后台配置 configKey="false" 时启用限制，只有高级用户才能操作。
func (o *chatSvr) checkGroupRestriction(ctx context.Context, userID string, configKey string, errMsg string) error {
	clientConfig, err := o.Admin.GetConfig(ctx)
	if err != nil {
		log.ZError(ctx, "checkGroupRestriction: 获取配置失败，降级放行", err)
		return nil
	}
	if allow, ok := clientConfig[configKey]; ok && allow == "false" {
		user, err := o.Database.GetAttribute(ctx, userID)
		if err != nil {
			log.ZError(ctx, "checkGroupRestriction: 查询用户失败，降级放行", err, "userID", userID)
			return nil
		}
		if user.Level <= constant2.OrdinaryUserLevel {
			return eerrs.ErrRefuseFriend.Wrap(errMsg)
		}
	}
	return nil
}

func (o *chatSvr) checkAddFriendRestriction(ctx context.Context, fromUserID string, toUser *chat2.Attribute) error {
	clientConfig, err := o.Admin.GetConfig(ctx)
	if err != nil {
		log.ZError(ctx, "GetClientConfig failed", err)
		// 获取配置失败时是继续还是报错？
		// 为了业务连续性，这里选择降级处理（Fail Open），仅记录错误日志但不阻止操作。
		// 如果因为 Admin 服务异常导致无法获取配置，不应影响正常加好友功能。
		return nil
	}
	log.ZError(ctx, "========== 获取到全局配置 ==========", nil, "allow_add_friend", clientConfig["allow_add_friend"])

	if allow, ok := clientConfig["allow_add_friend"]; ok && allow == "false" {
		// 获取发起者信息
		log.ZError(ctx, "========== 准备查询发起者 ==========", nil, "fromUserID", fromUserID)
		sender, err := o.Database.GetAttribute(ctx, fromUserID)
		if err != nil {
			log.ZError(ctx, "========== 查询发起者失败 ==========", err, "fromUserID", fromUserID)
			// 如果用户不存在（例如系统用户或仅 IM 用户），降级处理，允许操作继续
			// 不阻止加好友，避免影响正常业务
			return nil
		}
		log.ZError(ctx, "========== 查询发起者成功 ==========", nil, "fromUserID", fromUserID, "senderLevel", sender.Level)

		// 只要一方是高级用户（Level > 1），就允许添加
		// Check if sender or receiver is advanced user
		isPrivileged := false
		if sender.Level > constant2.OrdinaryUserLevel || toUser.Level > constant2.OrdinaryUserLevel {
			isPrivileged = true
		}

		if !isPrivileged {
			return eerrs.ErrRefuseFriend.Wrap("当前系统禁止普通用户添加好友")
		}
	}
	return nil
}
