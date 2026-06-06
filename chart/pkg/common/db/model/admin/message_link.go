package admin

import (
	"context"
	"strings"

	table "github.com/OpenIMSDK/chat/pkg/common/db/table/admin"
	"github.com/OpenIMSDK/tools/errs"
	"gorm.io/gorm"
)

// ---- MessageLink ----

type messageLinkModel struct{ db *gorm.DB }

func NewMessageLink(db *gorm.DB) table.MessageLinkInterface {
	return &messageLinkModel{db: db}
}

func (m *messageLinkModel) Create(ctx context.Context, link *table.MessageLink) error {
	return errs.Wrap(m.db.WithContext(ctx).Create(link).Error)
}

func (m *messageLinkModel) Update(ctx context.Context, linkID string, update map[string]any) error {
	return errs.Wrap(m.db.WithContext(ctx).Model(&table.MessageLink{}).Where("link_id = ?", linkID).Updates(update).Error)
}

func (m *messageLinkModel) Get(ctx context.Context, linkID string) (*table.MessageLink, error) {
	var link table.MessageLink
	if err := m.db.WithContext(ctx).Where("link_id = ?", linkID).First(&link).Error; err != nil {
		return nil, errs.Wrap(err)
	}
	return &link, nil
}

func (m *messageLinkModel) Delete(ctx context.Context, linkID string) error {
	return errs.Wrap(m.db.WithContext(ctx).Where("link_id = ?", linkID).Delete(&table.MessageLink{}).Error)
}

func (m *messageLinkModel) IncrHitCount(ctx context.Context, linkID string) error {
	return errs.Wrap(m.db.WithContext(ctx).Model(&table.MessageLink{}).
		Where("link_id = ?", linkID).
		UpdateColumn("hit_count", gorm.Expr("hit_count + 1")).Error)
}

func (m *messageLinkModel) Search(ctx context.Context, keyword string, pageNumber, showNumber int32) (uint32, []*table.MessageLink, error) {
	db := m.db.WithContext(ctx).Model(&table.MessageLink{})
	if keyword != "" {
		kw := strings.TrimSpace(keyword)
		kw = strings.ReplaceAll(kw, `\`, `\\`)
		kw = strings.ReplaceAll(kw, `%`, `\%`)
		kw = strings.ReplaceAll(kw, `_`, `\_`)
		like := "%" + kw + "%"
		db = db.Where("title LIKE ? ESCAPE '\\\\' OR url LIKE ? ESCAPE '\\\\'", like, like)
	}
	var total int64
	if err := db.Count(&total).Error; err != nil {
		return 0, nil, errs.Wrap(err)
	}
	var links []*table.MessageLink
	offset := int((pageNumber - 1) * showNumber)
	if err := db.Order("create_time DESC").Offset(offset).Limit(int(showNumber)).Find(&links).Error; err != nil {
		return 0, nil, errs.Wrap(err)
	}
	return uint32(total), links, nil
}

// ---- LinkDomainWhitelist ----

type linkDomainModel struct{ db *gorm.DB }

func NewLinkDomainWhitelist(db *gorm.DB) table.LinkDomainWhitelistInterface {
	return &linkDomainModel{db: db}
}

func (m *linkDomainModel) Create(ctx context.Context, domain *table.LinkDomainWhitelist) error {
	return errs.Wrap(m.db.WithContext(ctx).Create(domain).Error)
}

func (m *linkDomainModel) Delete(ctx context.Context, id uint64) error {
	return errs.Wrap(m.db.WithContext(ctx).Where("id = ?", id).Delete(&table.LinkDomainWhitelist{}).Error)
}

func (m *linkDomainModel) Page(ctx context.Context, keyword string, pageNumber, showNumber int32) (uint32, []*table.LinkDomainWhitelist, error) {
	db := m.db.WithContext(ctx).Model(&table.LinkDomainWhitelist{})
	if keyword != "" {
		kw := strings.TrimSpace(keyword)
		kw = strings.ReplaceAll(kw, `\`, `\\`)
		kw = strings.ReplaceAll(kw, `%`, `\%`)
		kw = strings.ReplaceAll(kw, `_`, `\_`)
		like := "%" + kw + "%"
		db = db.Where("domain LIKE ? ESCAPE '\\\\' OR remark LIKE ? ESCAPE '\\\\'", like, like)
	}
	var total int64
	if err := db.Count(&total).Error; err != nil {
		return 0, nil, errs.Wrap(err)
	}
	var domains []*table.LinkDomainWhitelist
	offset := int((pageNumber - 1) * showNumber)
	if err := db.Order("id DESC").Offset(offset).Limit(int(showNumber)).Find(&domains).Error; err != nil {
		return 0, nil, errs.Wrap(err)
	}
	return uint32(total), domains, nil
}

func (m *linkDomainModel) Check(ctx context.Context, domain string) (bool, error) {
	var count int64
	if err := m.db.WithContext(ctx).Model(&table.LinkDomainWhitelist{}).
		Where("domain = ? AND status = 1", domain).Count(&count).Error; err != nil {
		return false, errs.Wrap(err)
	}
	return count > 0, nil
}

// ---- LinkAuditLog ----

type linkAuditLogModel struct{ db *gorm.DB }

func NewLinkAuditLog(db *gorm.DB) table.LinkAuditLogInterface {
	return &linkAuditLogModel{db: db}
}

func (m *linkAuditLogModel) Create(ctx context.Context, log *table.LinkAuditLog) error {
	return errs.Wrap(m.db.WithContext(ctx).Create(log).Error)
}

func (m *linkAuditLogModel) Page(ctx context.Context, linkID, userID string, pageNumber, showNumber int32) (uint32, []*table.LinkAuditLog, error) {
	db := m.db.WithContext(ctx).Model(&table.LinkAuditLog{})
	if linkID != "" {
		db = db.Where("link_id = ?", linkID)
	}
	if userID != "" {
		db = db.Where("user_id = ?", userID)
	}
	var total int64
	if err := db.Count(&total).Error; err != nil {
		return 0, nil, errs.Wrap(err)
	}
	var logs []*table.LinkAuditLog
	offset := int((pageNumber - 1) * showNumber)
	if err := db.Order("id DESC").Offset(offset).Limit(int(showNumber)).Find(&logs).Error; err != nil {
		return 0, nil, errs.Wrap(err)
	}
	return uint32(total), logs, nil
}
