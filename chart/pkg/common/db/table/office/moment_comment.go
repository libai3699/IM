package office

import (
	"context"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"time"
)

// MomentComment 朋友圈评论集合（独立存储，支持可见性过滤）
type MomentComment struct {
	CommentID   primitive.ObjectID `bson:"_id"`
	MomentID    string             `bson:"moment_id"`     // 索引
	UserID      string             `bson:"user_id"`
	ReplyToID   string             `bson:"reply_to_id"`   // 回复的评论ID（可空）
	ReplyUserID string             `bson:"reply_user_id"` // 被回复用户ID（可空）
	Content     string             `bson:"content"`
	Visibility  int32              `bson:"visibility"`   // 1=public 2=self_only
	IsOfficial  bool               `bson:"is_official"`  // 官方用户评论
	CreateTime  time.Time          `bson:"create_time"`
}

type MomentCommentInterface interface {
	Create(ctx context.Context, comment *MomentComment) error
	Delete(ctx context.Context, commentID string, userID string) error
	GetByID(ctx context.Context, commentID string) (*MomentComment, error)
	// ListByMomentID 按 momentID 查，按可见性过滤：返回 visibility=public 的所有 + visibility=self_only 且 user_id=opUserID 的
	ListByMomentID(ctx context.Context, momentID string, opUserID string) ([]*MomentComment, error)
}
