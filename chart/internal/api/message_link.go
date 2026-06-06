package api

import (
	"net"

	"github.com/OpenIMSDK/chat/pkg/common/config"
	"github.com/OpenIMSDK/chat/pkg/proto/admin"
	"github.com/OpenIMSDK/tools/a2r"
	"github.com/OpenIMSDK/tools/apiresp"
	"github.com/gin-gonic/gin"
	"google.golang.org/grpc"
)

// NewMessageLink 创建消息外链 Handler
func NewMessageLink(adminConn grpc.ClientConnInterface) *MessageLink {
	return &MessageLink{adminClient: admin.NewAdminClient(adminConn)}
}

// MessageLink 消息外链 HTTP Handler
type MessageLink struct {
	adminClient admin.AdminClient
}

// CreateMessageLink 创建消息外链
func (o *MessageLink) CreateMessageLink(c *gin.Context) {
	a2r.Call(admin.AdminClient.CreateMessageLink, o.adminClient, c)
}

// GetMessageLink 查询消息外链详情
func (o *MessageLink) GetMessageLink(c *gin.Context) {
	a2r.Call(admin.AdminClient.GetMessageLink, o.adminClient, c)
}

// UpdateMessageLink 更新消息外链
func (o *MessageLink) UpdateMessageLink(c *gin.Context) {
	a2r.Call(admin.AdminClient.UpdateMessageLink, o.adminClient, c)
}

// DeleteMessageLink 删除消息外链
func (o *MessageLink) DeleteMessageLink(c *gin.Context) {
	a2r.Call(admin.AdminClient.DeleteMessageLink, o.adminClient, c)
}

// PageMessageLinks 分页查询消息外链
func (o *MessageLink) PageMessageLinks(c *gin.Context) {
	a2r.Call(admin.AdminClient.PageMessageLinks, o.adminClient, c)
}

// AddLinkDomain 添加域名白名单
func (o *MessageLink) AddLinkDomain(c *gin.Context) {
	a2r.Call(admin.AdminClient.AddLinkDomain, o.adminClient, c)
}

// DelLinkDomain 删除域名白名单
func (o *MessageLink) DelLinkDomain(c *gin.Context) {
	a2r.Call(admin.AdminClient.DelLinkDomain, o.adminClient, c)
}

// PageLinkDomains 分页查询域名白名单
func (o *MessageLink) PageLinkDomains(c *gin.Context) {
	a2r.Call(admin.AdminClient.PageLinkDomains, o.adminClient, c)
}

// PageLinkAuditLogs 分页查询外链访问日志
func (o *MessageLink) PageLinkAuditLogs(c *gin.Context) {
	a2r.Call(admin.AdminClient.PageLinkAuditLogs, o.adminClient, c)
}

// RecordLinkAccess 用户侧记录外链访问（由服务端提取真实 IP，防止客户端伪造）
func (o *MessageLink) RecordLinkAccess(c *gin.Context) {
	var body struct {
		LinkID string `json:"linkID" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		apiresp.GinError(c, err)
		return
	}
	ip := o.extractClientIP(c)
	resp, err := o.adminClient.RecordLinkAccess(c.Request.Context(), &admin.RecordLinkAccessReq{
		LinkID: body.LinkID,
		Ip:     ip,
	})
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, resp)
}

// extractClientIP 提取客户端真实 IP（支持反代 Header 配置）
func (o *MessageLink) extractClientIP(c *gin.Context) string {
	if config.Config.ProxyHeader != "" {
		if ip := c.Request.Header.Get(config.Config.ProxyHeader); ip != "" {
			return ip
		}
	}
	ip, _, err := net.SplitHostPort(c.Request.RemoteAddr)
	if err != nil {
		return c.Request.RemoteAddr
	}
	return ip
}
