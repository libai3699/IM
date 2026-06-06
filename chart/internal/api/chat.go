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

package api

import (
	"encoding/json"
	"fmt"
	"io"
	"math/rand"
	"net"
	"time"

	"github.com/OpenIMSDK/chat/pkg/common/apicall"
	"github.com/OpenIMSDK/chat/pkg/common/apistruct"
	constant2 "github.com/OpenIMSDK/chat/pkg/common/constant"
	"github.com/OpenIMSDK/chat/pkg/common/mctx"
	"github.com/OpenIMSDK/protocol/sdkws"
	"github.com/OpenIMSDK/tools/checker"
	"github.com/OpenIMSDK/tools/log"

	"github.com/OpenIMSDK/protocol/constant"
	"github.com/OpenIMSDK/tools/a2r"
	"github.com/OpenIMSDK/tools/apiresp"
	"github.com/OpenIMSDK/tools/errs"
	"github.com/gin-gonic/gin"
	"google.golang.org/grpc"

	"github.com/OpenIMSDK/chat/pkg/common/config"
	"github.com/OpenIMSDK/chat/pkg/proto/admin"
	"github.com/OpenIMSDK/chat/pkg/proto/chat"
)

func NewChat(chatConn, adminConn grpc.ClientConnInterface) *ChatApi {
	return &ChatApi{chatClient: chat.NewChatClient(chatConn), adminClient: admin.NewAdminClient(adminConn), imApiCaller: apicall.NewCallerInterface()}
}

type ChatApi struct {
	chatClient  chat.ChatClient
	adminClient admin.AdminClient
	imApiCaller apicall.CallerInterface
}

// ################## ACCOUNT ##################

func (o *ChatApi) SendVerifyCode(c *gin.Context) {
	req := chat.SendVerifyCodeReq{}

	if err := c.BindJSON(&req); err != nil {
		apiresp.GinError(c, err)
		return
	}
	ip, err := o.getClientIP(c)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	req.Ip = ip
	resp, err := o.chatClient.SendVerifyCode(c, &req)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, resp)
}

func (o *ChatApi) VerifyCode(c *gin.Context) {
	a2r.Call(chat.ChatClient.VerifyCode, o.chatClient, c)
}

func (o *ChatApi) RegisterUser(c *gin.Context) {
	var (
		req  chat.RegisterUserReq
		resp apistruct.UserRegisterResp
	)
	if err := c.BindJSON(&req); err != nil {
		apiresp.GinError(c, err)
		return
	}
	log.ZInfo(c, "registerUser", "req", &req)
	if err := checker.Validate(&req); err != nil {
		apiresp.GinError(c, err) // 参数校验失败
		return
	}
	ip, err := o.getClientIP(c)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	req.Ip = ip
	respRegisterUser, err := o.chatClient.RegisterUser(c, &req)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	userInfo := &sdkws.UserInfo{
		UserID:     respRegisterUser.UserID,
		Nickname:   req.User.Nickname,
		FaceURL:    req.User.FaceURL,
		CreateTime: time.Now().UnixMilli(),
	}
	err = o.imApiCaller.RegisterUser(c, []*sdkws.UserInfo{userInfo})
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	imToken, err := o.imApiCaller.ImAdminTokenWithDefaultAdmin(c)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiCtx := mctx.WithApiToken(c, imToken)
	rpcCtx := mctx.WithAdminUser(c)
	if resp, err := o.adminClient.FindDefaultFriend(rpcCtx, &admin.FindDefaultFriendReq{}); err == nil {
		// 随机选择一个默认好友添加
		if len(resp.UserIDs) > 0 {
			randomIndex := rand.Intn(len(resp.UserIDs))
			_ = o.imApiCaller.ImportFriend(apiCtx, respRegisterUser.UserID, []string{resp.UserIDs[randomIndex]})
			log.ZInfo(c, "Add random default friend", "userID", respRegisterUser.UserID, "friendID", resp.UserIDs[randomIndex])
		}
	}
	if resp, err := o.adminClient.FindDefaultGroup(rpcCtx, &admin.FindDefaultGroupReq{}); err == nil {
		_ = o.imApiCaller.InviteToGroup(apiCtx, respRegisterUser.UserID, resp.GroupIDs)
	}
	if req.AutoLogin {
		resp.ImToken, err = o.imApiCaller.UserToken(c, respRegisterUser.UserID, req.Platform)
		if err != nil {
			apiresp.GinError(c, err)
			return
		}
	}
	resp.ChatToken = respRegisterUser.ChatToken
	resp.UserID = respRegisterUser.UserID
	log.ZInfo(c, "registerUser api", "resp", &resp)
	apiresp.GinSuccess(c, &resp)
}

func (o *ChatApi) Login(c *gin.Context) {
	var (
		req  chat.LoginReq
		resp apistruct.LoginResp
	)
	if err := c.BindJSON(&req); err != nil {
		apiresp.GinError(c, err)
		return
	}

	// 【调试日志】打印接收到的请求（包含完整结构体）
	log.ZInfo(c, "Chat API received login request",
		"areaCode", req.AreaCode,
		"phoneNumber", req.PhoneNumber,
		"platform", req.Platform,
		"deviceID", req.DeviceID,
		"deviceModel", req.DeviceModel,
		"fullReq", req)

	if err := checker.Validate(&req); err != nil {
		apiresp.GinError(c, err) // 参数校验失败
		return
	}
	ip, err := o.getClientIP(c)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	req.Ip = ip

	// 【调试日志】打印即将发送给 RPC 的请求（包含完整结构体）
	log.ZInfo(c, "Chat API calling RPC",
		"deviceID", req.DeviceID,
		"deviceModel", req.DeviceModel,
		"ip", req.Ip,
		"fullReqBeforeRPC", req)

	resp1, err := o.chatClient.Login(c, &req)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	imToken, err := o.imApiCaller.UserToken(c, resp1.UserID, req.Platform)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	resp.ImToken = imToken
	resp.UserID = resp1.UserID
	resp.ChatToken = resp1.ChatToken
	apiresp.GinSuccess(c, resp)
}

func (o *ChatApi) ResetPassword(c *gin.Context) {
	a2r.Call(chat.ChatClient.ResetPassword, o.chatClient, c)
}

func (o *ChatApi) ChangePassword(c *gin.Context) {
	a2r.Call(chat.ChatClient.ChangePassword, o.chatClient, c)
}

// ################## USER ##################

func (o *ChatApi) UpdateUserInfo(c *gin.Context) {
	var (
		req  chat.UpdateUserInfoReq
		resp apistruct.UpdateUserInfoResp
	)
	if err := c.BindJSON(&req); err != nil {
		apiresp.GinError(c, err)
		return
	}
	log.ZInfo(c, "updateUserInfo", "req", &req)
	if err := checker.Validate(&req); err != nil {
		apiresp.GinError(c, err) // 参数校验失败
		return
	}
	respUpdate, err := o.chatClient.UpdateUserInfo(c, &req)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	opUserType, err := mctx.GetUserType(c)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	var imToken string
	if opUserType == constant2.NormalUser {
		imToken, err = o.imApiCaller.ImAdminTokenWithDefaultAdmin(c)
	} else if opUserType == constant2.AdminUser {
		imToken, err = o.imApiCaller.UserToken(c, config.GetIMAdmin(mctx.GetOpUserID(c)), constant.AdminPlatformID)
	} else {
		apiresp.GinError(c, errs.ErrArgs.Wrap("opUserType unknown"))
		return
	}
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	var (
		nickName string
		faceURL  string
	)
	if req.Nickname != nil {
		nickName = req.Nickname.Value
	} else {
		nickName = respUpdate.NickName
	}
	if req.FaceURL != nil {
		faceURL = req.FaceURL.Value
	} else {
		faceURL = respUpdate.FaceUrl
	}
	err = o.imApiCaller.UpdateUserInfo(mctx.WithApiToken(c, imToken), req.UserID, nickName, faceURL)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, resp)
}

func (o *ChatApi) FindUserPublicInfo(c *gin.Context) {
	a2r.Call(chat.ChatClient.FindUserPublicInfo, o.chatClient, c)
}

func (o *ChatApi) FindUserFullInfo(c *gin.Context) {
	a2r.Call(chat.ChatClient.FindUserFullInfo, o.chatClient, c)
}

//func (o *ChatApi) GetUsersFullInfo(c *gin.Context) {
//	a2r.Call(chat.ChatClient.GetUsersFullInfo, o.chatClient, c)
//}

func (o *ChatApi) SearchUserFullInfo(c *gin.Context) {
	a2r.Call(chat.ChatClient.SearchUserFullInfo, o.chatClient, c)
}

func (o *ChatApi) SearchUserPublicInfo(c *gin.Context) {
	a2r.Call(chat.ChatClient.SearchUserPublicInfo, o.chatClient, c)
}

// ################## APPLET ##################

func (o *ChatApi) FindApplet(c *gin.Context) {
	a2r.Call(admin.AdminClient.FindApplet, o.adminClient, c)
}

// ################## CONFIG ##################

func (o *ChatApi) GetClientConfig(c *gin.Context) {
	a2r.Call(admin.AdminClient.GetClientConfig, o.adminClient, c)
}

// ################## CALLBACK ##################

func (o *ChatApi) OpenIMCallback(c *gin.Context) {
	body, err := io.ReadAll(c.Request.Body)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	command := c.Query(constant.CallbackCommand)
	if command == "" {
		command = c.Param("command")
		if len(command) > 0 && command[0] == '/' {
			command = command[1:]
		}
	}

	// Fallback: extract from body
	if command == "" {
		var bodyMap map[string]interface{}
		if err := json.Unmarshal(body, &bodyMap); err == nil {
			if cmd, ok := bodyMap["callbackCommand"].(string); ok {
				command = cmd
			}
		}
	}
	req := &chat.OpenIMCallbackReq{
		Command: command,
		Body:    string(body),
	}
	if _, err := o.chatClient.OpenIMCallback(c, req); err != nil {
		log.ZError(c, "OpenIMCallback 拒绝", err, "command", command)
		// 必须返回 actionCode != 0，OpenIM Server 才会识别为拒绝
		c.JSON(200, gin.H{
			"actionCode": 1,
			"errCode":    20013,
			"errMsg":     err.Error(),
		})
		return
	}
	apiresp.GinSuccess(c, nil)
}

func (o *ChatApi) getClientIP(c *gin.Context) (string, error) {
	if config.Config.ProxyHeader == "" {
		ip, _, err := net.SplitHostPort(c.Request.RemoteAddr)
		return ip, err
	}
	ip := c.Request.Header.Get(config.Config.ProxyHeader)
	if ip == "" {
		return "", errs.ErrInternalServer.Wrap()
	}
	if ip := net.ParseIP(ip); ip == nil {
		return "", errs.ErrInternalServer.Wrap(fmt.Sprintf("解析代理IP头失败 %s", ip))
	}
	return ip, nil
}

func (o *ChatApi) UploadLogs(c *gin.Context) {
	a2r.Call(chat.ChatClient.UploadLogs, o.chatClient, c)
}

func (o *ChatApi) SearchFriend(c *gin.Context) {
	var req struct {
		UserID string `json:"userID"`
		chat.SearchUserInfoReq
	}
	if err := c.BindJSON(&req); err != nil {
		apiresp.GinError(c, err)
		return
	}
	if req.UserID == "" {
		req.UserID = mctx.GetOpUserID(c)
	}
	imToken, err := o.imApiCaller.ImAdminTokenWithDefaultAdmin(c)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	userIDs, err := o.imApiCaller.FriendUserIDs(mctx.WithApiToken(c, imToken), req.UserID)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	if len(userIDs) == 0 {
		apiresp.GinSuccess(c, &chat.SearchUserInfoResp{})
		return
	}
	req.SearchUserInfoReq.UserIDs = userIDs
	resp, err := o.chatClient.SearchUserInfo(c, &req.SearchUserInfoReq)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, resp)
}

func (o *ChatApi) DeleteLogs(c *gin.Context) {
	a2r.Call(chat.ChatClient.DeleteLogs, o.chatClient, c)
}

// ################## LOGIN RECORD ##################

// 获取用户最新登录记录
func (o *ChatApi) GetUserLatestLoginRecord(c *gin.Context) {
	a2r.Call(chat.ChatClient.GetUserLatestLoginRecord, o.chatClient, c)
}

// 获取用户登录记录列表
func (o *ChatApi) GetUserLoginRecords(c *gin.Context) {
	a2r.Call(chat.ChatClient.GetUserLoginRecords, o.chatClient, c)
}

// ################## GOOGLE AUTH ##################

// GetGoogleAuthQRCode 获取谷歌验证码二维码
func (o *ChatApi) GetGoogleAuthQRCode(c *gin.Context) {
	a2r.Call(chat.ChatClient.GetGoogleAuthQRCode, o.chatClient, c)
}

// BindGoogleAuth 绑定谷歌验证码
func (o *ChatApi) BindGoogleAuth(c *gin.Context) {
	a2r.Call(chat.ChatClient.BindGoogleAuth, o.chatClient, c)
}

// ResetGoogleAuth 重置谷歌验证码
func (o *ChatApi) ResetGoogleAuth(c *gin.Context) {
	a2r.Call(chat.ChatClient.ResetGoogleAuth, o.chatClient, c)
}

// GetUserGoogleAuthStatus 获取用户谷歌验证码状态
func (o *ChatApi) GetUserGoogleAuthStatus(c *gin.Context) {
	a2r.Call(chat.ChatClient.GetUserGoogleAuthStatus, o.chatClient, c)
}
