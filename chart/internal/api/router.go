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
	"context"

	"github.com/OpenIMSDK/chat/pkg/common/config"
	"github.com/OpenIMSDK/chat/pkg/common/db/database"
	"github.com/OpenIMSDK/chat/pkg/common/dbconn"
	"github.com/OpenIMSDK/tools/discoveryregistry"
	"github.com/gin-gonic/gin"
)

func NewChatRoute(router gin.IRouter, discov discoveryregistry.SvcDiscoveryRegistry) {
	chatConn, err := discov.GetConn(context.Background(), config.Config.RpcRegisterName.OpenImChatName)
	if err != nil {
		panic(err)
	}
	adminConn, err := discov.GetConn(context.Background(), config.Config.RpcRegisterName.OpenImAdminName)
	if err != nil {
		panic(err)
	}
	officeConn, err := discov.GetConn(context.Background(), config.Config.RpcRegisterName.OpenImOfficeName)
	if err != nil {
		panic(err)
	}
	mw := NewMW(adminConn)
	chat := NewChat(chatConn, adminConn)
	account := router.Group("/account")
	account.POST("/code/send", chat.SendVerifyCode)                      // Send verification code
	account.POST("/code/verify", chat.VerifyCode)                        // Verify the verification code
	account.POST("/register", mw.CheckAdminOrNil, chat.RegisterUser)     // Register
	account.POST("/login", chat.Login)                                   // Login
	account.POST("/password/reset", chat.ResetPassword)                  // Forgot password
	account.POST("/password/change", mw.CheckToken, chat.ChangePassword) // Change password

	user := router.Group("/user", mw.CheckToken)
	user.POST("/update", chat.UpdateUserInfo)              // Edit personal information
	user.POST("/find/public", chat.FindUserPublicInfo)     // Get user's public information
	user.POST("/find/full", chat.FindUserFullInfo)         // Get all information of the user
	user.POST("/search/full", chat.SearchUserFullInfo)     // Search user's public information
	user.POST("/search/public", chat.SearchUserPublicInfo) // Search all information of the user
	user.POST("/login_record/latest", chat.GetUserLatestLoginRecord) // Get user's latest login record
	user.POST("/login_record/list", chat.GetUserLoginRecords)       // Get user's login records list
	
	// 谷歌验证码相关接口（管理员使用，需要 admin token）
	googleAuth := router.Group("/google_auth", mw.CheckAdminOrNil)
	googleAuth.POST("/qrcode", chat.GetGoogleAuthQRCode)     // 获取谷歌验证码二维码
	googleAuth.POST("/bind", chat.BindGoogleAuth)            // 绑定谷歌验证码
	googleAuth.POST("/reset", chat.ResetGoogleAuth)          // 重置谷歌验证码
	googleAuth.POST("/status", chat.GetUserGoogleAuthStatus) // 获取用户谷歌验证码状态

	router.POST("/friend/search", mw.CheckToken, chat.SearchFriend)

	router.Group("/applet").POST("/find", mw.CheckToken, chat.FindApplet) // Applet list

	router.Group("/client_config").POST("/get", chat.GetClientConfig) // Get client initialization configuration

	router.Group("/callback").POST("/open_im/*command", chat.OpenIMCallback) // Callback

	logs := router.Group("/logs", mw.CheckToken)
	logs.POST("/upload", chat.UploadLogs)
	logs.POST("/delete", chat.DeleteLogs)

	office := NewOffice(officeConn)
	officeRouter := router.Group("/office", mw.CheckToken)
	officeRouter.POST("/tag/add", office.CreateTag)
	officeRouter.POST("/tag/del", office.DeleteTag)
	officeRouter.POST("/tag/set", office.SetTag)
	officeRouter.POST("/tag/get", office.GetUserTagByID)
	officeRouter.POST("/tag/find/user", office.GetUserTags)
	officeRouter.POST("/tag/send", office.SendMsg2Tag)
	officeRouter.POST("/tag/send/log", office.GetTagSendLogs)
	officeRouter.POST("/tag/send/log/del", office.DelTagSendLogs)

	officeRouter.POST("/work_moment/add", office.CreateOneWorkMoment)
	officeRouter.POST("/work_moment/del", office.DeleteOneWorkMoment)
	officeRouter.POST("/work_moment/like", office.LikeOneWorkMoment)
	officeRouter.POST("/work_moment/comment/add", office.CommentOneWorkMoment)
	officeRouter.POST("/work_moment/comment/del", office.DeleteComment)
	officeRouter.POST("/work_moment/get", office.GetWorkMomentByID)
	officeRouter.POST("/work_moment/find/send", office.GetUserSendWorkMoments)
	officeRouter.POST("/work_moment/find/recv", office.GetUserRecvWorkMoments)

	officeRouter.POST("/work_moment/logs", office.GetUnreadWorkMoments)
	officeRouter.POST("/work_moment/unread/count", office.GetUnreadWorkMomentsCount)
	officeRouter.POST("/work_moment/unread/clear", office.ReadWorkMoments)

	// Moment 朋友圈
	momentRouter := router.Group("/moment", mw.CheckToken)
	momentRouter.POST("/create", office.CreateMoment)
	momentRouter.POST("/del", office.DeleteMoment)
	momentRouter.POST("/get", office.GetMoment)
	momentRouter.POST("/list", office.PageMoments)
	momentRouter.POST("/mine", office.PageMyMoments)
	momentRouter.POST("/vote", office.VoteMoment)
	momentRouter.POST("/comment/add", office.CommentMoment)
	momentRouter.POST("/comment/del", office.DeleteMomentComment)

	// 客服（用户侧查询自己被分配的坐席）
	adminApi := NewAdminApiOnly(adminConn)
	customerRouter := router.Group("/customer", mw.CheckToken)
	customerRouter.POST("/my_agent", adminApi.GetMyAgent)

	// 消息外链访问记录（用户侧：点击外链后上报，写入访问日志并累加命中次数）
	userLinkHandler := NewMessageLink(adminConn)
	userLinkRouter := router.Group("/message_link", mw.CheckToken)
	userLinkRouter.POST("/access", userLinkHandler.RecordLinkAccess)

}

func NewAdminRoute(router gin.IRouter, discov discoveryregistry.SvcDiscoveryRegistry) {
	adminConn, err := discov.GetConn(context.Background(), config.Config.RpcRegisterName.OpenImAdminName)
	if err != nil {
		panic(err)
	}
	chatConn, err := discov.GetConn(context.Background(), config.Config.RpcRegisterName.OpenImChatName)
	if err != nil {
		panic(err)
	}
	rtcConn, err := discov.GetConn(context.Background(), *config.Config.RpcRegisterName.OpenImRtcName)
	if err != nil {
		panic(err)
	}
	officeConn, err := discov.GetConn(context.Background(), config.Config.RpcRegisterName.OpenImOfficeName)
	if err != nil {
		panic(err)
	}
	// 直接连接 DB 用于设备绑定管理（避免改动 proto）
	db, err := dbconn.NewGormDB()
	if err != nil {
		panic(err)
	}
	mw := NewMW(adminConn)
	admin := NewAdmin(chatConn, adminConn, rtcConn)
	device := NewDeviceApi(database.NewChatDatabase(db))
	office := NewOffice(officeConn)
	adminRouterGroup := router.Group("/account")
	adminRouterGroup.POST("/login", admin.AdminLogin)                                   // Login
	adminRouterGroup.POST("/update", mw.CheckAdmin, admin.AdminUpdateInfo)              // Modify information
	adminRouterGroup.POST("/info", mw.CheckAdmin, admin.AdminInfo)                      // Get information
	adminRouterGroup.POST("/change_password", mw.CheckAdmin, admin.ChangeAdminPassword) // Change admin account's password
	adminRouterGroup.POST("/add_admin", mw.CheckAdmin, admin.AddAdminAccount)           // Add admin account
	adminRouterGroup.POST("/add_user", mw.CheckAdmin, admin.AddUserAccount)             // Add user account
	adminRouterGroup.POST("/del_admin", mw.CheckAdmin, admin.DelAdminAccount)           // Delete admin
	adminRouterGroup.POST("/search", mw.CheckAdmin, admin.SearchAdminAccount)           // Get admin list

	// 管理员谷歌验证码
	googleAuthAdminGroup := router.Group("/google_auth_manager")
	googleAuthAdminGroup.POST("/qrcode", admin.GetAdminGoogleAuthQRCode)                 // Get QR code (登录前不需要 token)
	googleAuthAdminGroup.POST("/bind", admin.BindAdminGoogleAuth)                        // Bind Google Auth (登录前不需要 token，通过账号密码验证)
	googleAuthAdminGroup.POST("/reset", mw.CheckAdmin, admin.ResetAdminGoogleAuth)       // Reset Google Auth (super admin only)
	googleAuthAdminGroup.POST("/status", admin.GetAdminGoogleAuthStatus)                 // Get Google Auth status (登录前不需要 token)

	importGroup := router.Group("/user/import")
	importGroup.POST("/json", mw.CheckAdminOrNil, admin.ImportUserByJson)
	importGroup.POST("/xlsx", mw.CheckAdminOrNil, admin.ImportUserByXlsx)
	importGroup.GET("/xlsx", admin.BatchImportTemplate)

	defaultRouter := router.Group("/default", mw.CheckAdmin)
	defaultUserRouter := defaultRouter.Group("/user")
	defaultUserRouter.POST("/add", admin.AddDefaultFriend)       // Add default friend at registration
	defaultUserRouter.POST("/del", admin.DelDefaultFriend)       // Delete default friend at registration
	defaultUserRouter.POST("/find", admin.FindDefaultFriend)     // Default friend list
	defaultUserRouter.POST("/search", admin.SearchDefaultFriend) // Search default friend list at registration
	defaultGroupRouter := defaultRouter.Group("/group")
	defaultGroupRouter.POST("/add", admin.AddDefaultGroup)       // Add default group at registration
	defaultGroupRouter.POST("/del", admin.DelDefaultGroup)       // Delete default group at registration
	defaultGroupRouter.POST("/find", admin.FindDefaultGroup)     // Get default group list at registration
	defaultGroupRouter.POST("/search", admin.SearchDefaultGroup) // Search default group list at registration

	invitationCodeRouter := router.Group("/invitation_code", mw.CheckAdmin)
	invitationCodeRouter.POST("/add", admin.AddInvitationCode)       // Add invitation code
	invitationCodeRouter.POST("/gen", admin.GenInvitationCode)       // Generate invitation code
	invitationCodeRouter.POST("/del", admin.DelInvitationCode)       // Delete invitation code
	invitationCodeRouter.POST("/search", admin.SearchInvitationCode) // Search invitation code

	forbiddenRouter := router.Group("/forbidden", mw.CheckAdmin)
	ipForbiddenRouter := forbiddenRouter.Group("/ip")
	ipForbiddenRouter.POST("/add", admin.AddIPForbidden)       // Add forbidden IP for registration/login
	ipForbiddenRouter.POST("/del", admin.DelIPForbidden)       // Delete forbidden IP for registration/login
	ipForbiddenRouter.POST("/search", admin.SearchIPForbidden) // Search forbidden IPs for registration/login
	userForbiddenRouter := forbiddenRouter.Group("/user")
	userForbiddenRouter.POST("/add", admin.AddUserIPLimitLogin)       // Add limit for user login on specific IP
	userForbiddenRouter.POST("/del", admin.DelUserIPLimitLogin)       // Delete user limit on specific IP for login
	userForbiddenRouter.POST("/search", admin.SearchUserIPLimitLogin) // Search limit for user login on specific IP

	appletRouterGroup := router.Group("/applet", mw.CheckAdmin)
	appletRouterGroup.POST("/add", admin.AddApplet)       // Add applet
	appletRouterGroup.POST("/del", admin.DelApplet)       // Delete applet
	appletRouterGroup.POST("/update", admin.UpdateApplet) // Modify applet
	appletRouterGroup.POST("/search", admin.SearchApplet) // Search applet

	blockRouter := router.Group("/block", mw.CheckAdmin)
	blockRouter.POST("/add", admin.BlockUser)          // Block user
	blockRouter.POST("/del", admin.UnblockUser)        // Unblock user
	blockRouter.POST("/search", admin.SearchBlockUser) // Search blocked users

	userRouter := router.Group("/user", mw.CheckAdmin)
	userRouter.POST("/password/reset", admin.ResetUserPassword)     // Reset user password
	userRouter.POST("/device/unbind", device.UnbindUserDevice)      // 解绑用户设备（清除登录记录，下次登录重新绑定）

	initGroup := router.Group("/client_config", mw.CheckAdmin)
	initGroup.POST("/get", admin.GetClientConfig) // Get client initialization configuration
	initGroup.POST("/set", admin.SetClientConfig) // Set client initialization configuration
	initGroup.POST("/del", admin.DelClientConfig) // Delete client initialization configuration

	statistic := router.Group("/statistic", mw.CheckAdmin)
	statistic.POST("/new_user_count", admin.NewUserCount)
	statistic.POST("/login_user_count", admin.LoginUserCount)

	rtc := router.Group("/rtc", mw.CheckAdmin)
	rtc.POST("/get_signal_invitation_records", admin.GetSignalInvitationRecords)
	rtc.POST("/delete_signal_records", admin.DeleteSignalRecords)
	rtc.POST("/get_meeting_records", admin.GetMeetingRecords)
	rtc.POST("/delete_meeting_records", admin.DeleteMeetingRecords)

	logs := router.Group("/logs", mw.CheckAdmin)
	logs.POST("/search", admin.SearchLogs)
	logs.POST("/delete", admin.DeleteLogs)

	// 朋友圈管理
	adminMomentRouter := router.Group("/moment", mw.CheckAdmin)
	adminMomentRouter.POST("/review", office.AdminReviewMoment)
	adminMomentRouter.POST("/top/set", office.AdminSetTopMoment)
	adminMomentRouter.POST("/top/cancel", office.AdminCancelTopMoment)
	adminMomentRouter.POST("/list", office.AdminPageMoments)
	adminMomentRouter.POST("/pending", office.AdminPagePendingMoments)

	// 用户分组管理
	userGroupRouter := router.Group("/user_group", mw.CheckAdmin)
	userGroupRouter.POST("/create", admin.CreateUserGroup)
	userGroupRouter.POST("/update", admin.UpdateUserGroup)
	userGroupRouter.POST("/del", admin.DeleteUserGroup)
	userGroupRouter.POST("/get", admin.GetUserGroup)
	userGroupRouter.POST("/search", admin.SearchUserGroups)
	userGroupRouter.POST("/member/add", admin.AddUserGroupMembers)
	userGroupRouter.POST("/member/del", admin.RemoveUserGroupMembers)
	userGroupRouter.POST("/member/list", admin.ListUserGroupMembers)
	// 用户分组扩展接口：扩展配置 / 默认分组 / 审计日志
	userGroupRouter.POST("/config/get", admin.GetUserGroupConfig)
	userGroupRouter.POST("/config/set", admin.SetUserGroupConfig)
	userGroupRouter.POST("/default/set", admin.SetUserGroupDefault)
	userGroupRouter.POST("/change/logs", admin.GetUserGroupChangeLogs)

	// 客服坐席管理
	agentRouter := router.Group("/customer_agent", mw.CheckAdmin)
	agentRouter.POST("/create", admin.CreateCustomerAgent)
	agentRouter.POST("/update", admin.UpdateCustomerAgent)
	agentRouter.POST("/del", admin.DeleteCustomerAgent)
	agentRouter.POST("/search", admin.SearchCustomerAgents)

	// 客户分配
	assignRouter := router.Group("/customer_assign", mw.CheckAdmin)
	assignRouter.POST("/assign", admin.AssignCustomer)
	assignRouter.POST("/list", admin.ListAgentCustomers)

	// 消息外链管理
	msgLink := NewMessageLink(adminConn)
	msgLinkRouter := router.Group("/message_link", mw.CheckAdmin)
	msgLinkRouter.POST("/create", msgLink.CreateMessageLink)
	msgLinkRouter.POST("/update", msgLink.UpdateMessageLink)
	msgLinkRouter.POST("/del", msgLink.DeleteMessageLink)
	msgLinkRouter.POST("/get", msgLink.GetMessageLink)
	msgLinkRouter.POST("/page", msgLink.PageMessageLinks)

	// 域名白名单管理
	domainRouter := router.Group("/link_domain", mw.CheckAdmin)
	domainRouter.POST("/add", msgLink.AddLinkDomain)
	domainRouter.POST("/del", msgLink.DelLinkDomain)
	domainRouter.POST("/page", msgLink.PageLinkDomains)

	// 外链访问日志
	auditRouter := router.Group("/link_audit", mw.CheckAdmin)
	auditRouter.POST("/page", msgLink.PageLinkAuditLogs)
}
