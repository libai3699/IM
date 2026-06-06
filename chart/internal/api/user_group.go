package api

import (
	"github.com/OpenIMSDK/chat/pkg/proto/admin"
	"github.com/OpenIMSDK/tools/a2r"
	"github.com/gin-gonic/gin"
)

func (o *AdminApi) CreateUserGroup(c *gin.Context) {
	a2r.Call(admin.AdminClient.CreateUserGroup, o.adminClient, c)
}

func (o *AdminApi) UpdateUserGroup(c *gin.Context) {
	a2r.Call(admin.AdminClient.UpdateUserGroup, o.adminClient, c)
}

func (o *AdminApi) DeleteUserGroup(c *gin.Context) {
	a2r.Call(admin.AdminClient.DeleteUserGroup, o.adminClient, c)
}

func (o *AdminApi) GetUserGroup(c *gin.Context) {
	a2r.Call(admin.AdminClient.GetUserGroup, o.adminClient, c)
}

func (o *AdminApi) SearchUserGroups(c *gin.Context) {
	a2r.Call(admin.AdminClient.SearchUserGroups, o.adminClient, c)
}

func (o *AdminApi) AddUserGroupMembers(c *gin.Context) {
	a2r.Call(admin.AdminClient.AddUserGroupMembers, o.adminClient, c)
}

func (o *AdminApi) RemoveUserGroupMembers(c *gin.Context) {
	a2r.Call(admin.AdminClient.RemoveUserGroupMembers, o.adminClient, c)
}

func (o *AdminApi) ListUserGroupMembers(c *gin.Context) {
	a2r.Call(admin.AdminClient.ListUserGroupMembers, o.adminClient, c)
}

func (o *AdminApi) GetUserGroupConfig(c *gin.Context) {
	a2r.Call(admin.AdminClient.GetUserGroupConfig, o.adminClient, c)
}

func (o *AdminApi) SetUserGroupConfig(c *gin.Context) {
	a2r.Call(admin.AdminClient.SetUserGroupConfig, o.adminClient, c)
}

func (o *AdminApi) SetUserGroupDefault(c *gin.Context) {
	a2r.Call(admin.AdminClient.SetUserGroupDefault, o.adminClient, c)
}

func (o *AdminApi) GetUserGroupChangeLogs(c *gin.Context) {
	a2r.Call(admin.AdminClient.GetUserGroupChangeLogs, o.adminClient, c)
}

func (o *AdminApi) CreateCustomerAgent(c *gin.Context) {
	a2r.Call(admin.AdminClient.CreateCustomerAgent, o.adminClient, c)
}

func (o *AdminApi) UpdateCustomerAgent(c *gin.Context) {
	a2r.Call(admin.AdminClient.UpdateCustomerAgent, o.adminClient, c)
}

func (o *AdminApi) DeleteCustomerAgent(c *gin.Context) {
	a2r.Call(admin.AdminClient.DeleteCustomerAgent, o.adminClient, c)
}

func (o *AdminApi) SearchCustomerAgents(c *gin.Context) {
	a2r.Call(admin.AdminClient.SearchCustomerAgents, o.adminClient, c)
}

func (o *AdminApi) AssignCustomer(c *gin.Context) {
	a2r.Call(admin.AdminClient.AssignCustomer, o.adminClient, c)
}

func (o *AdminApi) GetMyAgent(c *gin.Context) {
	a2r.Call(admin.AdminClient.GetMyAgent, o.adminClient, c)
}

func (o *AdminApi) ListAgentCustomers(c *gin.Context) {
	a2r.Call(admin.AdminClient.ListAgentCustomers, o.adminClient, c)
}
