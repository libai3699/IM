package office

import (
	"context"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"time"
)

// Moment 朋友圈动态集合
type Moment struct {
	MomentID     primitive.ObjectID `bson:"_id"`
	UserID       string             `bson:"user_id"`
	Content      *MomentContent     `bson:"content"`
	MomentType   int32              `bson:"moment_type"`    // 1=普通 2=置顶
	Status       int32              `bson:"status"`         // 0=待审核 1=通过 2=拒绝
	IsOfficial   bool               `bson:"is_official"`    // 官方发布(免审核)
	LikeCount    int64              `bson:"like_count"`
	DislikeCount int64              `bson:"dislike_count"`
	CommentCount int64              `bson:"comment_count"`
	ReviewerID   string             `bson:"reviewer_id"`
	ReviewTime   time.Time          `bson:"review_time"`
	ReviewRemark string             `bson:"review_remark"`
	CreateTime   time.Time          `bson:"create_time"`
}

// MomentContent 动态内容，复用 Meta 结构
type MomentContent struct {
	Metas []*Meta `bson:"metas"`
	Text  string  `bson:"text"`
	Type  int32   `bson:"type"` // 0=纯文字 1=图片 2=视频
}

type MomentInterface interface {
	Create(ctx context.Context, moment *Moment) error
	Delete(ctx context.Context, momentID string) error
	Get(ctx context.Context, momentID string) (*Moment, error)
	SetStatus(ctx context.Context, momentID string, status int32, reviewerID, reviewRemark string) error
	SetTop(ctx context.Context, momentID string, momentType int32) error
	CancelTop(ctx context.Context) error
	GetTop(ctx context.Context) (*Moment, error)
	IncrCount(ctx context.Context, momentID string, field string, delta int64) error
	PageList(ctx context.Context, showNumber, pageNumber int32) ([]*Moment, int64, error)
	PageApproved(ctx context.Context, showNumber, pageNumber int32) ([]*Moment, int64, error)
	PageByUserID(ctx context.Context, userID string, showNumber, pageNumber int32) ([]*Moment, int64, error)
	PagePending(ctx context.Context, showNumber, pageNumber int32) ([]*Moment, int64, error)
	AdminPageList(ctx context.Context, keyword string, showNumber, pageNumber int32) ([]*Moment, int64, error)
}
