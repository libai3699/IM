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

	"github.com/OpenIMSDK/chat/pkg/common/totp"
	"github.com/OpenIMSDK/chat/pkg/proto/chat"
	"github.com/OpenIMSDK/tools/errs"
	"github.com/OpenIMSDK/tools/log"
)

// BindGoogleAuth 绑定谷歌验证码
func (o *chatSvr) BindGoogleAuth(ctx context.Context, req *chat.BindGoogleAuthReq) (*chat.BindGoogleAuthResp, error) {
	defer log.ZDebug(ctx, "return")
	
	// 验证用户输入的验证码
	if !totp.ValidateCode(req.Secret, req.Code, 1) {
		return nil, errs.ErrArgs.Wrap("验证码错误")
	}
	
	// 更新用户属性
	updateData := map[string]any{
		"google_auth_secret":  req.Secret,
		"google_auth_enabled": true,
	}
	
	if err := o.Database.UpdateUseInfo(ctx, req.UserID, updateData); err != nil {
		log.ZError(ctx, "更新用户谷歌验证码失败", err, "userID", req.UserID)
		return nil, err
	}
	
	log.ZInfo(ctx, "绑定谷歌验证码成功", "userID", req.UserID)
	return &chat.BindGoogleAuthResp{}, nil
}

// GetGoogleAuthQRCode 获取谷歌验证码二维码
func (o *chatSvr) GetGoogleAuthQRCode(ctx context.Context, req *chat.GetGoogleAuthQRCodeReq) (*chat.GetGoogleAuthQRCodeResp, error) {
	defer log.ZDebug(ctx, "return")
	
	// 生成密钥
	secret := totp.GenerateSecret()
	
	// 生成二维码 URL
	qrCodeURL := totp.GenerateQRCodeURL("OpenIM", req.UserID, secret)
	
	log.ZInfo(ctx, "生成谷歌验证码二维码", "userID", req.UserID)
	return &chat.GetGoogleAuthQRCodeResp{
		Secret:    secret,
		QrCodeURL: qrCodeURL,
	}, nil
}

// ResetGoogleAuth 重置谷歌验证码
func (o *chatSvr) ResetGoogleAuth(ctx context.Context, req *chat.ResetGoogleAuthReq) (*chat.ResetGoogleAuthResp, error) {
	defer log.ZDebug(ctx, "return")
	
	// 更新用户属性，清空谷歌验证码
	updateData := map[string]any{
		"google_auth_secret":  "",
		"google_auth_enabled": false,
	}
	
	if err := o.Database.UpdateUseInfo(ctx, req.UserID, updateData); err != nil {
		log.ZError(ctx, "重置用户谷歌验证码失败", err, "userID", req.UserID)
		return nil, err
	}
	
	log.ZInfo(ctx, "重置谷歌验证码成功", "userID", req.UserID)
	return &chat.ResetGoogleAuthResp{}, nil
}

// GetUserGoogleAuthStatus 获取用户谷歌验证码状态
func (o *chatSvr) GetUserGoogleAuthStatus(ctx context.Context, req *chat.GetUserGoogleAuthStatusReq) (*chat.GetUserGoogleAuthStatusResp, error) {
	defer log.ZDebug(ctx, "return")
	
	// 获取用户属性
	attribute, err := o.Database.GetAttribute(ctx, req.UserID)
	if err != nil {
		if o.Database.IsNotFound(err) {
			// 用户不存在，返回未启用
			return &chat.GetUserGoogleAuthStatusResp{Enabled: false}, nil
		}
		log.ZError(ctx, "获取用户属性失败", err, "userID", req.UserID)
		return nil, err
	}
	
	return &chat.GetUserGoogleAuthStatusResp{
		Enabled: attribute.GoogleAuthEnabled,
	}, nil
}
