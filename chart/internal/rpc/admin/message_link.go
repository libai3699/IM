package admin

import (
	"context"
	"time"

	table "github.com/OpenIMSDK/chat/pkg/common/db/table/admin"
	"github.com/OpenIMSDK/chat/pkg/common/mctx"
	"github.com/OpenIMSDK/chat/pkg/common/urlutil"
	"github.com/OpenIMSDK/chat/pkg/proto/admin"
	"github.com/OpenIMSDK/tools/errs"
	"github.com/OpenIMSDK/tools/utils"
)

// validateLinkURL 校验外链 URL 安全性：协议、内网IP、域名白名单
func (o *adminServer) validateLinkURL(ctx context.Context, rawURL string) error {
	if rawURL == "" {
		return nil
	}
	// 1. 协议 + 内网 IP 校验（纯本地，无 IO）
	if err := urlutil.ValidateURL(rawURL); err != nil {
		return err
	}
	// 2. 域名白名单校验（数据库查询）
	hostname := urlutil.ExtractHostname(rawURL)
	if hostname == "" {
		return errs.ErrArgs.Wrap("URL 格式不合法，无法提取主机名")
	}
	allowed, err := o.Database.CheckLinkDomain(ctx, hostname)
	if err != nil {
		return err
	}
	if !allowed {
		return errs.ErrArgs.Wrap("URL 域名不在白名单中，请先在「域名白名单」中添加：" + hostname)
	}
	return nil
}

// messageLinkToPb 将数据库 MessageLink 转换为 proto 消息
func messageLinkToPb(l *table.MessageLink) *admin.MessageLinkInfo {
	return &admin.MessageLinkInfo{
		LinkID:      l.LinkID,
		Title:       l.Title,
		Url:         l.URL,
		Description: l.Description,
		CoverURL:    l.CoverURL,
		Status:      l.Status,
		HitCount:    l.HitCount,
		CreatorID:   l.CreatorID,
		CreateTime:  l.CreateTime.UnixMilli(),
	}
}

// linkDomainToPb 将数据库 LinkDomainWhitelist 转换为 proto 消息
func linkDomainToPb(d *table.LinkDomainWhitelist) *admin.LinkDomainInfo {
	return &admin.LinkDomainInfo{
		Id:         d.ID,
		Domain:     d.Domain,
		Remark:     d.Remark,
		Status:     d.Status,
		CreateTime: d.CreateTime.UnixMilli(),
	}
}

// linkAuditLogToPb 将数据库 LinkAuditLog 转换为 proto 消息
func linkAuditLogToPb(l *table.LinkAuditLog) *admin.LinkAuditLogInfo {
	return &admin.LinkAuditLogInfo{
		Id:         l.ID,
		LinkID:     l.LinkID,
		UserID:     l.UserID,
		Url:        l.URL,
		Ip:         l.IP,
		CreateTime: l.CreateTime.UnixMilli(),
	}
}

// CreateMessageLink 创建消息外链
func (o *adminServer) CreateMessageLink(ctx context.Context, req *admin.CreateMessageLinkReq) (*admin.CreateMessageLinkResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	if req.Title == "" {
		return nil, errs.ErrArgs.Wrap("title 不能为空")
	}
	if req.Url == "" {
		return nil, errs.ErrArgs.Wrap("url 不能为空")
	}
	// SSRF 防护：校验外链 URL 和封面图 URL
	if err := o.validateLinkURL(ctx, req.Url); err != nil {
		return nil, err
	}
	if err := o.validateLinkURL(ctx, req.CoverURL); err != nil {
		return nil, errs.ErrArgs.Wrap("coverURL 校验失败：" + err.Error())
	}
	link := &table.MessageLink{
		LinkID:      utils.Md5(req.Url + time.Now().String()),
		Title:       req.Title,
		URL:         req.Url,
		Description: req.Description,
		CoverURL:    req.CoverURL,
		Status:      1,
		CreatorID:   mctx.GetOpUserID(ctx),
	}
	if err := o.Database.CreateMessageLink(ctx, link); err != nil {
		return nil, err
	}
	return &admin.CreateMessageLinkResp{Link: messageLinkToPb(link)}, nil
}

// GetMessageLink 查询消息外链详情
func (o *adminServer) GetMessageLink(ctx context.Context, req *admin.GetMessageLinkReq) (*admin.GetMessageLinkResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	link, err := o.Database.GetMessageLink(ctx, req.LinkID)
	if err != nil {
		return nil, err
	}
	return &admin.GetMessageLinkResp{Link: messageLinkToPb(link)}, nil
}

// UpdateMessageLink 更新消息外链
func (o *adminServer) UpdateMessageLink(ctx context.Context, req *admin.UpdateMessageLinkReq) (*admin.UpdateMessageLinkResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	update := map[string]any{}
	if req.Title != "" {
		update["title"] = req.Title
	}
	if req.Url != "" {
		// SSRF 防护：校验新 URL
		if err := o.validateLinkURL(ctx, req.Url); err != nil {
			return nil, err
		}
		update["url"] = req.Url
	}
	if req.Description != "" {
		update["description"] = req.Description
	}
	if req.CoverURL != "" {
		// SSRF 防护：校验封面图 URL
		if err := o.validateLinkURL(ctx, req.CoverURL); err != nil {
			return nil, errs.ErrArgs.Wrap("coverURL 校验失败：" + err.Error())
		}
		update["cover_url"] = req.CoverURL
	}
	if req.Status != 0 {
		update["status"] = req.Status
	}
	if len(update) == 0 {
		return &admin.UpdateMessageLinkResp{}, nil
	}
	if err := o.Database.UpdateMessageLink(ctx, req.LinkID, update); err != nil {
		return nil, err
	}
	return &admin.UpdateMessageLinkResp{}, nil
}

// DeleteMessageLink 删除消息外链
func (o *adminServer) DeleteMessageLink(ctx context.Context, req *admin.DeleteMessageLinkReq) (*admin.DeleteMessageLinkResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	if err := o.Database.DeleteMessageLink(ctx, req.LinkID); err != nil {
		return nil, err
	}
	return &admin.DeleteMessageLinkResp{}, nil
}

// PageMessageLinks 分页查询消息外链列表
func (o *adminServer) PageMessageLinks(ctx context.Context, req *admin.PageMessageLinksReq) (*admin.PageMessageLinksResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	total, links, err := o.Database.SearchMessageLinks(ctx, req.Keyword, req.Pagination.PageNumber, req.Pagination.ShowNumber)
	if err != nil {
		return nil, err
	}
	pbLinks := make([]*admin.MessageLinkInfo, 0, len(links))
	for _, l := range links {
		pbLinks = append(pbLinks, messageLinkToPb(l))
	}
	return &admin.PageMessageLinksResp{Total: total, Links: pbLinks}, nil
}

// AddLinkDomain 添加域名白名单
func (o *adminServer) AddLinkDomain(ctx context.Context, req *admin.AddLinkDomainReq) (*admin.AddLinkDomainResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	if req.Domain == "" {
		return nil, errs.ErrArgs.Wrap("domain 不能为空")
	}
	domain := &table.LinkDomainWhitelist{
		Domain: req.Domain,
		Remark: req.Remark,
		Status: 1,
	}
	if err := o.Database.AddLinkDomain(ctx, domain); err != nil {
		return nil, err
	}
	return &admin.AddLinkDomainResp{Domain: linkDomainToPb(domain)}, nil
}

// DelLinkDomain 删除域名白名单
func (o *adminServer) DelLinkDomain(ctx context.Context, req *admin.DelLinkDomainReq) (*admin.DelLinkDomainResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	if err := o.Database.DelLinkDomain(ctx, req.Id); err != nil {
		return nil, err
	}
	return &admin.DelLinkDomainResp{}, nil
}

// PageLinkDomains 分页查询域名白名单
func (o *adminServer) PageLinkDomains(ctx context.Context, req *admin.PageLinkDomainsReq) (*admin.PageLinkDomainsResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	total, domains, err := o.Database.PageLinkDomains(ctx, req.Keyword, req.Pagination.PageNumber, req.Pagination.ShowNumber)
	if err != nil {
		return nil, err
	}
	pbDomains := make([]*admin.LinkDomainInfo, 0, len(domains))
	for _, d := range domains {
		pbDomains = append(pbDomains, linkDomainToPb(d))
	}
	return &admin.PageLinkDomainsResp{Total: total, Domains: pbDomains}, nil
}

// RecordLinkAccess 用户侧调用：记录外链访问日志并累加命中次数（无需管理员身份）
func (o *adminServer) RecordLinkAccess(ctx context.Context, req *admin.RecordLinkAccessReq) (*admin.RecordLinkAccessResp, error) {
	opUserID := mctx.GetOpUserID(ctx)
	if req.LinkID == "" {
		return nil, errs.ErrArgs.Wrap("linkID 不能为空")
	}
	// 查询外链信息，获取真实 URL（访问日志需记录实际访问的 URL）
	link, err := o.Database.GetMessageLink(ctx, req.LinkID)
	if err != nil {
		return nil, err
	}
	// 写入访问日志（异步写，失败不影响主流程）
	_ = o.Database.CreateLinkAuditLog(ctx, &table.LinkAuditLog{
		LinkID: req.LinkID,
		UserID: opUserID,
		URL:    link.URL,
		IP:     req.Ip,
	})
	// 累加命中次数
	_ = o.Database.IncrMessageLinkHitCount(ctx, req.LinkID)
	return &admin.RecordLinkAccessResp{}, nil
}

// PageLinkAuditLogs 分页查询外链访问日志
func (o *adminServer) PageLinkAuditLogs(ctx context.Context, req *admin.PageLinkAuditLogsReq) (*admin.PageLinkAuditLogsResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	total, logs, err := o.Database.PageLinkAuditLogs(ctx, req.LinkID, req.UserID, req.Pagination.PageNumber, req.Pagination.ShowNumber)
	if err != nil {
		return nil, err
	}
	pbLogs := make([]*admin.LinkAuditLogInfo, 0, len(logs))
	for _, l := range logs {
		pbLogs = append(pbLogs, linkAuditLogToPb(l))
	}
	return &admin.PageLinkAuditLogsResp{Total: total, Logs: pbLogs}, nil
}
