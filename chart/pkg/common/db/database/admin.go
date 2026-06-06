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

package database

import (
	"context"
	"time"

	"github.com/OpenIMSDK/chat/pkg/common/db/cache"
	"github.com/OpenIMSDK/protocol/constant"
	"github.com/OpenIMSDK/tools/errs"
	"github.com/redis/go-redis/v9"

	"github.com/OpenIMSDK/tools/tx"
	"gorm.io/gorm"

	"github.com/OpenIMSDK/chat/pkg/common/db/model/admin"
	table "github.com/OpenIMSDK/chat/pkg/common/db/table/admin"
)

type AdminDatabaseInterface interface {
	InitAdmin(ctx context.Context) error
	GetAdmin(ctx context.Context, account string) (*table.Admin, error)
	GetAdminUserID(ctx context.Context, userID string) (*table.Admin, error)
	UpdateAdmin(ctx context.Context, userID string, update map[string]any) error
	ChangePassword(ctx context.Context, userID string, newPassword string) error
	AddAdminAccount(ctx context.Context, admin *table.Admin) error
	DelAdminAccount(ctx context.Context, userIDs []string) error
	SearchAdminAccount(ctx context.Context, page, size int32) (uint32, []*table.Admin, error)
	CreateApplet(ctx context.Context, applets ...*table.Applet) error
	DelApplet(ctx context.Context, appletIDs []string) error
	GetApplet(ctx context.Context, appletID string) (*table.Applet, error)
	FindApplet(ctx context.Context, appletIDs []string) ([]*table.Applet, error)
	SearchApplet(ctx context.Context, keyword string, page int32, size int32) (uint32, []*table.Applet, error)
	FindOnShelf(ctx context.Context) ([]*table.Applet, error)
	UpdateApplet(ctx context.Context, appletID string, update map[string]any) error
	GetConfig(ctx context.Context) (map[string]string, error)
	SetConfig(ctx context.Context, cs map[string]string) error
	DelConfig(ctx context.Context, keys []string) error
	FindInvitationRegister(ctx context.Context, codes []string) ([]*table.InvitationRegister, error)
	DelInvitationRegister(ctx context.Context, codes []string) error
	UpdateInvitationRegister(ctx context.Context, code string, fields map[string]any) error
	CreatInvitationRegister(ctx context.Context, invitationRegisters []*table.InvitationRegister) error
	SearchInvitationRegister(ctx context.Context, keyword string, state int32, userIDs []string, codes []string, page int32, size int32) (uint32, []*table.InvitationRegister, error)
	SearchIPForbidden(ctx context.Context, keyword string, state int32, page int32, size int32) (uint32, []*table.IPForbidden, error)
	AddIPForbidden(ctx context.Context, ms []*table.IPForbidden) error
	FindIPForbidden(ctx context.Context, ms []string) ([]*table.IPForbidden, error)
	DelIPForbidden(ctx context.Context, ips []string) error
	FindDefaultFriend(ctx context.Context, userIDs []string) ([]string, error)
	AddDefaultFriend(ctx context.Context, ms []*table.RegisterAddFriend) error
	DelDefaultFriend(ctx context.Context, userIDs []string) error
	SearchDefaultFriend(ctx context.Context, keyword string, page int32, size int32) (uint32, []*table.RegisterAddFriend, error)
	FindDefaultGroup(ctx context.Context, groupIDs []string) ([]string, error)
	AddDefaultGroup(ctx context.Context, ms []*table.RegisterAddGroup) error
	DelDefaultGroup(ctx context.Context, groupIDs []string) error
	SearchDefaultGroup(ctx context.Context, keyword string, page int32, size int32) (uint32, []*table.RegisterAddGroup, error)
	FindBlockInfo(ctx context.Context, userIDs []string) ([]*table.ForbiddenAccount, error)
	GetBlockInfo(ctx context.Context, userID string) (*table.ForbiddenAccount, error)
	BlockUser(ctx context.Context, f []*table.ForbiddenAccount) error
	DelBlockUser(ctx context.Context, userID []string) error
	SearchBlockUser(ctx context.Context, keyword string, page int32, size int32) (uint32, []*table.ForbiddenAccount, error)
	FindBlockUser(ctx context.Context, userIDs []string) ([]*table.ForbiddenAccount, error)
	SearchUserLimitLogin(ctx context.Context, keyword string, page int32, size int32) (uint32, []*table.LimitUserLoginIP, error)
	AddUserLimitLogin(ctx context.Context, ms []*table.LimitUserLoginIP) error
	DelUserLimitLogin(ctx context.Context, ms []*table.LimitUserLoginIP) error
	CountLimitUserLoginIP(ctx context.Context, userID string) (uint32, error)
	GetLimitUserLoginIP(ctx context.Context, userID string, ip string) (*table.LimitUserLoginIP, error)
	CacheToken(ctx context.Context, userID string, token string) error
	GetTokens(ctx context.Context, userID string) (map[string]int32, error)

	// UserGroup 用户分组
	CreateUserGroup(ctx context.Context, group *table.UserGroup) error
	UpdateUserGroup(ctx context.Context, groupID string, update map[string]any) error
	DeleteUserGroup(ctx context.Context, groupID string) error
	GetUserGroup(ctx context.Context, groupID string) (*table.UserGroup, error)
	SearchUserGroups(ctx context.Context, keyword string, page, size int32) (uint32, []*table.UserGroup, error)
	FindAllUserGroups(ctx context.Context) ([]*table.UserGroup, error)
	AddUserGroupMembers(ctx context.Context, members []*table.UserGroupMember) error
	RemoveUserGroupMembers(ctx context.Context, groupID string, userIDs []string) error
	ListUserGroupMembers(ctx context.Context, groupID string) ([]*table.UserGroupMember, error)
	ListUserBelongGroups(ctx context.Context, userID string) ([]*table.UserGroupMember, error)
	DeleteUserGroupAllMembers(ctx context.Context, groupID string) error

	// CustomerAgent 客服坐席
	CreateCustomerAgent(ctx context.Context, agent *table.CustomerAgent) error
	UpdateCustomerAgent(ctx context.Context, agentID string, update map[string]any) error
	DeleteCustomerAgent(ctx context.Context, agentID string) error
	GetCustomerAgent(ctx context.Context, agentID string) (*table.CustomerAgent, error)
	GetCustomerAgentByUserID(ctx context.Context, userID string) (*table.CustomerAgent, error)
	SearchCustomerAgents(ctx context.Context, keyword string, page, size int32) (uint32, []*table.CustomerAgent, error)
	NextRoundRobinAgent(ctx context.Context) (*table.CustomerAgent, error)
	IncrAgentLoad(ctx context.Context, agentID string, delta int32) error

	// CustomerAssign 客户分配
	UpsertCustomerAssign(ctx context.Context, assign *table.CustomerAssign) error
	GetCustomerAssign(ctx context.Context, customerID string) (*table.CustomerAssign, error)
	ListAgentCustomers(ctx context.Context, agentID string, page, size int32) (uint32, []*table.CustomerAssign, error)
	DeleteCustomerAssign(ctx context.Context, customerID string) error
	// AcquireRoundRobinLock 获取自动分配轮询的分布式锁，返回 unlock 函数。
	// 调用方必须 defer unlock() 以释放锁。
	AcquireRoundRobinLock(ctx context.Context) (unlock func(), err error)

	// MessageLink 消息外链
	CreateMessageLink(ctx context.Context, link *table.MessageLink) error
	UpdateMessageLink(ctx context.Context, linkID string, update map[string]any) error
	GetMessageLink(ctx context.Context, linkID string) (*table.MessageLink, error)
	DeleteMessageLink(ctx context.Context, linkID string) error
	IncrMessageLinkHitCount(ctx context.Context, linkID string) error
	SearchMessageLinks(ctx context.Context, keyword string, pageNumber, showNumber int32) (uint32, []*table.MessageLink, error)
	// LinkDomainWhitelist 域名白名单
	AddLinkDomain(ctx context.Context, domain *table.LinkDomainWhitelist) error
	DelLinkDomain(ctx context.Context, id uint64) error
	PageLinkDomains(ctx context.Context, keyword string, pageNumber, showNumber int32) (uint32, []*table.LinkDomainWhitelist, error)
	CheckLinkDomain(ctx context.Context, domain string) (bool, error)
	// LinkAuditLog 外链访问日志
	CreateLinkAuditLog(ctx context.Context, log *table.LinkAuditLog) error
	PageLinkAuditLogs(ctx context.Context, linkID, userID string, pageNumber, showNumber int32) (uint32, []*table.LinkAuditLog, error)

	// UserGroupConfig 用户分组扩展配置（新增）
	CreateUserGroupConfig(ctx context.Context, cfg *table.UserGroupConfig) error
	UpdateUserGroupConfig(ctx context.Context, groupID string, update map[string]any) error
	GetUserGroupConfig(ctx context.Context, groupID string) (*table.UserGroupConfig, error)
	GetDefaultUserGroupConfig(ctx context.Context) (*table.UserGroupConfig, error)
	DeleteUserGroupConfig(ctx context.Context, groupID string) error
	CountUserGroups(ctx context.Context) (int64, error)

	// UserGroupChangeLog 用户分组审计日志（新增）
	CreateUserGroupChangeLog(ctx context.Context, log *table.UserGroupChangeLog) error
	ListUserGroupChangeLogs(ctx context.Context, groupID string, page, size int32) (uint32, []*table.UserGroupChangeLog, error)
}

func NewAdminDatabase(db *gorm.DB, rdb redis.UniversalClient) AdminDatabaseInterface {
	return &AdminDatabase{
		rdb:                rdb,
		tx:                 tx.NewGorm(db),
		admin:              admin.NewAdmin(db),
		ipForbidden:        admin.NewIPForbidden(db),
		forbiddenAccount:   admin.NewForbiddenAccount(db),
		limitUserLoginIP:   admin.NewLimitUserLoginIP(db),
		invitationRegister: admin.NewInvitationRegister(db),
		registerAddFriend:  admin.NewRegisterAddFriend(db),
		registerAddGroup:   admin.NewRegisterAddGroup(db),
		applet:             admin.NewApplet(db),
		clientConfig:       admin.NewClientConfig(db),
		cache:              cache.NewTokenInterface(rdb),
		userGroup:          admin.NewUserGroup(db),
		userGroupMember:    admin.NewUserGroupMember(db),
		customerAgent:      admin.NewCustomerAgent(db),
		customerAssign:     admin.NewCustomerAssign(db),
		userGroupConfig:    admin.NewUserGroupConfig(db),    // 分组扩展配置（新增）
		userGroupChangeLog: admin.NewUserGroupChangeLog(db), // 分组审计日志（新增）
		messageLink:        admin.NewMessageLink(db),
		linkDomain:         admin.NewLinkDomainWhitelist(db),
		linkAuditLog:       admin.NewLinkAuditLog(db),
	}
}

type AdminDatabase struct {
	rdb                redis.UniversalClient
	tx                 tx.Tx
	admin              table.AdminInterface
	ipForbidden        table.IPForbiddenInterface
	forbiddenAccount   table.ForbiddenAccountInterface
	limitUserLoginIP   table.LimitUserLoginIPInterface
	invitationRegister table.InvitationRegisterInterface
	registerAddFriend  table.RegisterAddFriendInterface
	registerAddGroup   table.RegisterAddGroupInterface
	applet             table.AppletInterface
	clientConfig       table.ClientConfigInterface
	cache              cache.TokenInterface
	userGroup          table.UserGroupInterface
	userGroupMember    table.UserGroupMemberInterface
	customerAgent      table.CustomerAgentInterface
	customerAssign     table.CustomerAssignInterface
	userGroupConfig    table.UserGroupConfigInterface    // 分组扩展配置（新增）
	userGroupChangeLog table.UserGroupChangeLogInterface // 分组审计日志（新增）
	messageLink        table.MessageLinkInterface
	linkDomain         table.LinkDomainWhitelistInterface
	linkAuditLog       table.LinkAuditLogInterface
}

func (o *AdminDatabase) InitAdmin(ctx context.Context) error {
	return o.admin.InitAdmin(ctx)
}

func (o *AdminDatabase) GetAdmin(ctx context.Context, account string) (*table.Admin, error) {
	return o.admin.Take(ctx, account)
}

func (o *AdminDatabase) GetAdminUserID(ctx context.Context, userID string) (*table.Admin, error) {
	return o.admin.TakeUserID(ctx, userID)
}

func (o *AdminDatabase) UpdateAdmin(ctx context.Context, userID string, update map[string]any) error {
	return o.admin.Update(ctx, userID, update)
}

func (o *AdminDatabase) ChangePassword(ctx context.Context, userID string, newPassword string) error {
	return o.admin.ChangePassword(ctx, userID, newPassword)
}
func (o *AdminDatabase) AddAdminAccount(ctx context.Context, admin *table.Admin) error {
	return o.admin.Create(ctx, admin)
}

func (o *AdminDatabase) DelAdminAccount(ctx context.Context, userIDs []string) error {
	return o.admin.Delete(ctx, userIDs)
}

func (o *AdminDatabase) SearchAdminAccount(ctx context.Context, page, size int32) (uint32, []*table.Admin, error) {
	return o.admin.Search(ctx, page, size)
}

func (o *AdminDatabase) CreateApplet(ctx context.Context, applets ...*table.Applet) error {
	return o.applet.Create(ctx, applets...)
}

func (o *AdminDatabase) DelApplet(ctx context.Context, appletIDs []string) error {
	return o.applet.Del(ctx, appletIDs)
}

func (o *AdminDatabase) GetApplet(ctx context.Context, appletID string) (*table.Applet, error) {
	return o.applet.Take(ctx, appletID)
}

func (o *AdminDatabase) FindApplet(ctx context.Context, appletIDs []string) ([]*table.Applet, error) {
	return o.applet.FindID(ctx, appletIDs)
}

func (o *AdminDatabase) SearchApplet(ctx context.Context, keyword string, page int32, size int32) (uint32, []*table.Applet, error) {
	return o.applet.Search(ctx, keyword, page, size)
}

func (o *AdminDatabase) FindOnShelf(ctx context.Context) ([]*table.Applet, error) {
	return o.applet.FindOnShelf(ctx)
}

func (o *AdminDatabase) UpdateApplet(ctx context.Context, appletID string, update map[string]any) error {
	return o.applet.Update(ctx, appletID, update)
}

func (o *AdminDatabase) GetConfig(ctx context.Context) (map[string]string, error) {
	return o.clientConfig.Get(ctx)
}

func (o *AdminDatabase) SetConfig(ctx context.Context, cs map[string]string) error {
	return o.clientConfig.Set(ctx, cs)
}

func (o *AdminDatabase) DelConfig(ctx context.Context, keys []string) error {
	return o.clientConfig.Del(ctx, keys)
}

func (o *AdminDatabase) FindInvitationRegister(ctx context.Context, codes []string) ([]*table.InvitationRegister, error) {
	return o.invitationRegister.Find(ctx, codes)
}

func (o *AdminDatabase) DelInvitationRegister(ctx context.Context, codes []string) error {
	return o.invitationRegister.Del(ctx, codes)
}

func (o *AdminDatabase) UpdateInvitationRegister(ctx context.Context, code string, fields map[string]any) error {
	return o.invitationRegister.Update(ctx, code, fields)
}

func (o *AdminDatabase) CreatInvitationRegister(ctx context.Context, invitationRegisters []*table.InvitationRegister) error {
	return o.invitationRegister.Create(ctx, invitationRegisters...)
}

func (o *AdminDatabase) SearchInvitationRegister(ctx context.Context, keyword string, state int32, userIDs []string, codes []string, page int32, size int32) (uint32, []*table.InvitationRegister, error) {
	return o.invitationRegister.Search(ctx, keyword, state, userIDs, codes, page, size)
}

func (o *AdminDatabase) SearchIPForbidden(ctx context.Context, keyword string, state int32, page int32, size int32) (uint32, []*table.IPForbidden, error) {
	return o.ipForbidden.Search(ctx, keyword, state, page, size)
}

func (o *AdminDatabase) AddIPForbidden(ctx context.Context, ms []*table.IPForbidden) error {
	return o.ipForbidden.Create(ctx, ms)
}

func (o *AdminDatabase) FindIPForbidden(ctx context.Context, ms []string) ([]*table.IPForbidden, error) {
	return o.ipForbidden.Find(ctx, ms)
}

func (o *AdminDatabase) DelIPForbidden(ctx context.Context, ips []string) error {
	return o.ipForbidden.Delete(ctx, ips)
}

func (o *AdminDatabase) FindDefaultFriend(ctx context.Context, userIDs []string) ([]string, error) {
	return o.registerAddFriend.FindUserID(ctx, userIDs)
}

func (o *AdminDatabase) AddDefaultFriend(ctx context.Context, ms []*table.RegisterAddFriend) error {
	return o.registerAddFriend.Add(ctx, ms)
}

func (o *AdminDatabase) DelDefaultFriend(ctx context.Context, userIDs []string) error {
	return o.registerAddFriend.Del(ctx, userIDs)
}

func (o *AdminDatabase) SearchDefaultFriend(ctx context.Context, keyword string, page int32, size int32) (uint32, []*table.RegisterAddFriend, error) {
	return o.registerAddFriend.Search(ctx, keyword, page, size)
}

func (o *AdminDatabase) FindDefaultGroup(ctx context.Context, groupIDs []string) ([]string, error) {
	return o.registerAddGroup.FindGroupID(ctx, groupIDs)
}

func (o *AdminDatabase) AddDefaultGroup(ctx context.Context, ms []*table.RegisterAddGroup) error {
	return o.registerAddGroup.Add(ctx, ms)
}

func (o *AdminDatabase) DelDefaultGroup(ctx context.Context, groupIDs []string) error {
	return o.registerAddGroup.Del(ctx, groupIDs)
}

func (o *AdminDatabase) SearchDefaultGroup(ctx context.Context, keyword string, page int32, size int32) (uint32, []*table.RegisterAddGroup, error) {
	return o.registerAddGroup.Search(ctx, keyword, page, size)
}

func (o *AdminDatabase) FindBlockInfo(ctx context.Context, userIDs []string) ([]*table.ForbiddenAccount, error) {
	return o.forbiddenAccount.Find(ctx, userIDs)
}

func (o *AdminDatabase) GetBlockInfo(ctx context.Context, userID string) (*table.ForbiddenAccount, error) {
	return o.forbiddenAccount.Take(ctx, userID)
}

func (o *AdminDatabase) BlockUser(ctx context.Context, f []*table.ForbiddenAccount) error {
	return o.forbiddenAccount.Create(ctx, f)
}

func (o *AdminDatabase) DelBlockUser(ctx context.Context, userID []string) error {
	return o.forbiddenAccount.Delete(ctx, userID)
}

func (o *AdminDatabase) SearchBlockUser(ctx context.Context, keyword string, page int32, size int32) (uint32, []*table.ForbiddenAccount, error) {
	return o.forbiddenAccount.Search(ctx, keyword, page, size)
}

func (o *AdminDatabase) FindBlockUser(ctx context.Context, userIDs []string) ([]*table.ForbiddenAccount, error) {
	return o.forbiddenAccount.Find(ctx, userIDs)
}

func (o *AdminDatabase) SearchUserLimitLogin(ctx context.Context, keyword string, page int32, size int32) (uint32, []*table.LimitUserLoginIP, error) {
	return o.limitUserLoginIP.Search(ctx, keyword, page, size)
}

func (o *AdminDatabase) AddUserLimitLogin(ctx context.Context, ms []*table.LimitUserLoginIP) error {
	return o.limitUserLoginIP.Create(ctx, ms)
}

func (o *AdminDatabase) DelUserLimitLogin(ctx context.Context, ms []*table.LimitUserLoginIP) error {
	return o.limitUserLoginIP.Delete(ctx, ms)
}

func (o *AdminDatabase) CountLimitUserLoginIP(ctx context.Context, userID string) (uint32, error) {
	return o.limitUserLoginIP.Count(ctx, userID)
}

func (o *AdminDatabase) GetLimitUserLoginIP(ctx context.Context, userID string, ip string) (*table.LimitUserLoginIP, error) {
	return o.limitUserLoginIP.Take(ctx, userID, ip)
}

func (o *AdminDatabase) CacheToken(ctx context.Context, userID string, token string) error {
	return o.cache.AddTokenFlag(ctx, userID, token, constant.NormalToken)
}

func (o *AdminDatabase) GetTokens(ctx context.Context, userID string) (map[string]int32, error) {
	return o.cache.GetTokensWithoutError(ctx, userID)
}

// ---- UserGroup ----

func (o *AdminDatabase) CreateUserGroup(ctx context.Context, group *table.UserGroup) error {
	return o.userGroup.Create(ctx, group)
}

func (o *AdminDatabase) UpdateUserGroup(ctx context.Context, groupID string, update map[string]any) error {
	return o.userGroup.Update(ctx, groupID, update)
}

func (o *AdminDatabase) DeleteUserGroup(ctx context.Context, groupID string) error {
	return o.userGroup.Delete(ctx, groupID)
}

func (o *AdminDatabase) GetUserGroup(ctx context.Context, groupID string) (*table.UserGroup, error) {
	return o.userGroup.Get(ctx, groupID)
}

func (o *AdminDatabase) SearchUserGroups(ctx context.Context, keyword string, page, size int32) (uint32, []*table.UserGroup, error) {
	return o.userGroup.Search(ctx, keyword, page, size)
}

func (o *AdminDatabase) FindAllUserGroups(ctx context.Context) ([]*table.UserGroup, error) {
	return o.userGroup.FindAll(ctx)
}

func (o *AdminDatabase) AddUserGroupMembers(ctx context.Context, members []*table.UserGroupMember) error {
	return o.userGroupMember.Add(ctx, members)
}

func (o *AdminDatabase) RemoveUserGroupMembers(ctx context.Context, groupID string, userIDs []string) error {
	return o.userGroupMember.Remove(ctx, groupID, userIDs)
}

func (o *AdminDatabase) ListUserGroupMembers(ctx context.Context, groupID string) ([]*table.UserGroupMember, error) {
	return o.userGroupMember.ListByGroupID(ctx, groupID)
}

func (o *AdminDatabase) ListUserBelongGroups(ctx context.Context, userID string) ([]*table.UserGroupMember, error) {
	return o.userGroupMember.ListByUserID(ctx, userID)
}

func (o *AdminDatabase) DeleteUserGroupAllMembers(ctx context.Context, groupID string) error {
	return o.userGroupMember.DeleteByGroupID(ctx, groupID)
}

// ---- CustomerAgent ----

func (o *AdminDatabase) CreateCustomerAgent(ctx context.Context, agent *table.CustomerAgent) error {
	return o.customerAgent.Create(ctx, agent)
}

func (o *AdminDatabase) UpdateCustomerAgent(ctx context.Context, agentID string, update map[string]any) error {
	return o.customerAgent.Update(ctx, agentID, update)
}

func (o *AdminDatabase) DeleteCustomerAgent(ctx context.Context, agentID string) error {
	return o.customerAgent.Delete(ctx, agentID)
}

func (o *AdminDatabase) GetCustomerAgent(ctx context.Context, agentID string) (*table.CustomerAgent, error) {
	return o.customerAgent.Get(ctx, agentID)
}

func (o *AdminDatabase) GetCustomerAgentByUserID(ctx context.Context, userID string) (*table.CustomerAgent, error) {
	return o.customerAgent.GetByUserID(ctx, userID)
}

func (o *AdminDatabase) SearchCustomerAgents(ctx context.Context, keyword string, page, size int32) (uint32, []*table.CustomerAgent, error) {
	return o.customerAgent.Search(ctx, keyword, page, size)
}

func (o *AdminDatabase) NextRoundRobinAgent(ctx context.Context) (*table.CustomerAgent, error) {
	return o.customerAgent.NextRoundRobin(ctx)
}

func (o *AdminDatabase) IncrAgentLoad(ctx context.Context, agentID string, delta int32) error {
	return o.customerAgent.IncrLoad(ctx, agentID, delta)
}

// ---- CustomerAssign ----

func (o *AdminDatabase) UpsertCustomerAssign(ctx context.Context, assign *table.CustomerAssign) error {
	return o.customerAssign.Upsert(ctx, assign)
}

func (o *AdminDatabase) GetCustomerAssign(ctx context.Context, customerID string) (*table.CustomerAssign, error) {
	return o.customerAssign.GetByCustomer(ctx, customerID)
}

func (o *AdminDatabase) ListAgentCustomers(ctx context.Context, agentID string, page, size int32) (uint32, []*table.CustomerAssign, error) {
	return o.customerAssign.ListByAgent(ctx, agentID, page, size)
}

func (o *AdminDatabase) DeleteCustomerAssign(ctx context.Context, customerID string) error {
	return o.customerAssign.Delete(ctx, customerID)
}

// ---- UserGroupConfig 分组扩展配置 ----

func (o *AdminDatabase) CreateUserGroupConfig(ctx context.Context, cfg *table.UserGroupConfig) error {
	return o.userGroupConfig.Create(ctx, cfg)
}

func (o *AdminDatabase) UpdateUserGroupConfig(ctx context.Context, groupID string, update map[string]any) error {
	return o.userGroupConfig.Update(ctx, groupID, update)
}

func (o *AdminDatabase) GetUserGroupConfig(ctx context.Context, groupID string) (*table.UserGroupConfig, error) {
	return o.userGroupConfig.Get(ctx, groupID)
}

func (o *AdminDatabase) GetDefaultUserGroupConfig(ctx context.Context) (*table.UserGroupConfig, error) {
	return o.userGroupConfig.GetDefault(ctx)
}

func (o *AdminDatabase) DeleteUserGroupConfig(ctx context.Context, groupID string) error {
	return o.userGroupConfig.Delete(ctx, groupID)
}

func (o *AdminDatabase) CountUserGroups(ctx context.Context) (int64, error) {
	return o.userGroupConfig.CountGroups(ctx)
}

// ---- UserGroupChangeLog 审计日志 ----

func (o *AdminDatabase) CreateUserGroupChangeLog(ctx context.Context, log *table.UserGroupChangeLog) error {
	return o.userGroupChangeLog.Create(ctx, log)
}

func (o *AdminDatabase) ListUserGroupChangeLogs(ctx context.Context, groupID string, page, size int32) (uint32, []*table.UserGroupChangeLog, error) {
	return o.userGroupChangeLog.ListByGroup(ctx, groupID, page, size)
}

// ---- MessageLink 消息外链 ----

func (o *AdminDatabase) CreateMessageLink(ctx context.Context, link *table.MessageLink) error {
	return o.messageLink.Create(ctx, link)
}

func (o *AdminDatabase) UpdateMessageLink(ctx context.Context, linkID string, update map[string]any) error {
	return o.messageLink.Update(ctx, linkID, update)
}

func (o *AdminDatabase) GetMessageLink(ctx context.Context, linkID string) (*table.MessageLink, error) {
	return o.messageLink.Get(ctx, linkID)
}

func (o *AdminDatabase) DeleteMessageLink(ctx context.Context, linkID string) error {
	return o.messageLink.Delete(ctx, linkID)
}

func (o *AdminDatabase) IncrMessageLinkHitCount(ctx context.Context, linkID string) error {
	return o.messageLink.IncrHitCount(ctx, linkID)
}

func (o *AdminDatabase) SearchMessageLinks(ctx context.Context, keyword string, pageNumber, showNumber int32) (uint32, []*table.MessageLink, error) {
	return o.messageLink.Search(ctx, keyword, pageNumber, showNumber)
}

// ---- LinkDomainWhitelist 域名白名单 ----

func (o *AdminDatabase) AddLinkDomain(ctx context.Context, domain *table.LinkDomainWhitelist) error {
	return o.linkDomain.Create(ctx, domain)
}

func (o *AdminDatabase) DelLinkDomain(ctx context.Context, id uint64) error {
	return o.linkDomain.Delete(ctx, id)
}

func (o *AdminDatabase) PageLinkDomains(ctx context.Context, keyword string, pageNumber, showNumber int32) (uint32, []*table.LinkDomainWhitelist, error) {
	return o.linkDomain.Page(ctx, keyword, pageNumber, showNumber)
}

func (o *AdminDatabase) CheckLinkDomain(ctx context.Context, domain string) (bool, error) {
	return o.linkDomain.Check(ctx, domain)
}

// ---- LinkAuditLog 外链访问日志 ----

func (o *AdminDatabase) CreateLinkAuditLog(ctx context.Context, log *table.LinkAuditLog) error {
	return o.linkAuditLog.Create(ctx, log)
}

func (o *AdminDatabase) PageLinkAuditLogs(ctx context.Context, linkID, userID string, pageNumber, showNumber int32) (uint32, []*table.LinkAuditLog, error) {
	return o.linkAuditLog.Page(ctx, linkID, userID, pageNumber, showNumber)
}

// ---- 分布式锁 ----

const (
	// roundRobinLockKey 客户自动分配轮询的全局 Redis 锁 key
	roundRobinLockKey = "customer:assign:roundrobin:lock"
	// roundRobinLockTTL 锁的超时时间，防止持锁方崩溃导致死锁
	roundRobinLockTTL = 5 * time.Second
)

// AcquireRoundRobinLock 获取客户分配轮询的分布式锁。
// 返回 unlock 函数，调用方必须 defer unlock() 释放锁。
// 若锁已被持有（并发请求），返回错误让调用方重试。
func (o *AdminDatabase) AcquireRoundRobinLock(ctx context.Context) (func(), error) {
	ok, err := o.rdb.SetNX(ctx, roundRobinLockKey, "1", roundRobinLockTTL).Result()
	if err != nil {
		return nil, errs.Wrap(err)
	}
	if !ok {
		return nil, errs.ErrInternalServer.Wrap("系统繁忙，客户分配请求并发冲突，请稍后重试")
	}
	unlock := func() {
		// 使用独立 context 防止父 ctx 已取消导致无法释放锁
		_ = o.rdb.Del(context.Background(), roundRobinLockKey).Err()
	}
	return unlock, nil
}
