package admin

import (
	"context"
	"time"
)

// MessageLink 消息外链
type MessageLink struct {
	LinkID      string    `gorm:"column:link_id;type:char(64);primaryKey"`
	Title       string    `gorm:"column:title;type:varchar(200);not null"`
	URL         string    `gorm:"column:url;type:varchar(1000);not null"`
	Description string    `gorm:"column:description;type:varchar(500);default:''"`
	CoverURL    string    `gorm:"column:cover_url;type:varchar(500);default:''"`
	Status      int32     `gorm:"column:status;type:tinyint(1);default:1;index:idx_status"`
	HitCount    int64     `gorm:"column:hit_count;type:bigint;default:0"`
	CreatorID   string    `gorm:"column:creator_id;type:char(64);index:idx_creator_id"`
	CreateTime  time.Time `gorm:"column:create_time;autoCreateTime;index:idx_create_time"`
	UpdateTime  time.Time `gorm:"column:update_time;autoUpdateTime"`
}

func (MessageLink) TableName() string { return "message_links" }

// LinkDomainWhitelist 域名白名单
type LinkDomainWhitelist struct {
	ID         uint64    `gorm:"column:id;primaryKey;autoIncrement"`
	Domain     string    `gorm:"column:domain;type:varchar(255);uniqueIndex:uk_domain"`
	Remark     string    `gorm:"column:remark;type:varchar(255);default:''"`
	Status     int32     `gorm:"column:status;type:tinyint(1);default:1"`
	CreateTime time.Time `gorm:"column:create_time;autoCreateTime"`
}

func (LinkDomainWhitelist) TableName() string { return "link_domain_whitelist" }

// LinkAuditLog 外链访问日志
type LinkAuditLog struct {
	ID         uint64    `gorm:"column:id;primaryKey;autoIncrement"`
	LinkID     string    `gorm:"column:link_id;type:char(64);index:idx_link_id"`
	UserID     string    `gorm:"column:user_id;type:char(64);index:idx_user_id"`
	URL        string    `gorm:"column:url;type:varchar(1000)"`
	IP         string    `gorm:"column:ip;type:varchar(64);default:''"`
	CreateTime time.Time `gorm:"column:create_time;autoCreateTime;index:idx_create_time"`
}

func (LinkAuditLog) TableName() string { return "link_audit_logs" }

// MessageLinkInterface 消息外链数据库操作接口
type MessageLinkInterface interface {
	Create(ctx context.Context, link *MessageLink) error
	Update(ctx context.Context, linkID string, update map[string]any) error
	Get(ctx context.Context, linkID string) (*MessageLink, error)
	Delete(ctx context.Context, linkID string) error
	IncrHitCount(ctx context.Context, linkID string) error
	Search(ctx context.Context, keyword string, pageNumber, showNumber int32) (uint32, []*MessageLink, error)
}

// LinkDomainWhitelistInterface 域名白名单数据库操作接口
type LinkDomainWhitelistInterface interface {
	Create(ctx context.Context, domain *LinkDomainWhitelist) error
	Delete(ctx context.Context, id uint64) error
	Page(ctx context.Context, keyword string, pageNumber, showNumber int32) (uint32, []*LinkDomainWhitelist, error)
	Check(ctx context.Context, domain string) (bool, error)
}

// LinkAuditLogInterface 外链访问日志数据库操作接口
type LinkAuditLogInterface interface {
	Create(ctx context.Context, log *LinkAuditLog) error
	Page(ctx context.Context, linkID, userID string, pageNumber, showNumber int32) (uint32, []*LinkAuditLog, error)
}
