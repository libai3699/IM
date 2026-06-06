package office

import (
	"context"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"time"
)

// MomentVote 置顶动态投票集合
// 唯一索引: {moment_id, user_id}，每人只能投一票
type MomentVote struct {
	VoteID     primitive.ObjectID `bson:"_id"`
	MomentID   string             `bson:"moment_id"`  // 索引
	UserID     string             `bson:"user_id"`    // 索引
	VoteType   int32              `bson:"vote_type"`  // 1=like 2=dislike
	CreateTime time.Time          `bson:"create_time"`
}

type MomentVoteInterface interface {
	// Upsert 投票（已投过则更新类型）
	Upsert(ctx context.Context, vote *MomentVote) (int32, error) // 返回旧的 voteType（0表示首次）
	GetByUser(ctx context.Context, momentID string, userID string) (*MomentVote, error)
}
