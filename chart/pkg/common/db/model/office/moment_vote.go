package office

import (
	"context"
	"github.com/OpenIMSDK/chat/pkg/common/db/dbutil"
	table "github.com/OpenIMSDK/chat/pkg/common/db/table/office"
	"github.com/OpenIMSDK/tools/errs"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"time"
)

func NewMomentVoteModel(coll *mongo.Collection) (table.MomentVoteInterface, error) {
	indexModels := []mongo.IndexModel{
		{
			Keys: bson.D{{Key: "moment_id", Value: 1}, {Key: "user_id", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
	}
	if _, err := coll.Indexes().CreateMany(context.Background(), indexModels); err != nil {
		return nil, err
	}
	return &MomentVoteModel{coll: coll}, nil
}

type MomentVoteModel struct {
	coll *mongo.Collection
}

// Upsert 投票，返回旧的 voteType（0=首次）
func (m *MomentVoteModel) Upsert(ctx context.Context, vote *table.MomentVote) (int32, error) {
	existing, err := m.GetByUser(ctx, vote.MomentID, vote.UserID)
	if err != nil && errs.Unwrap(err) != mongo.ErrNoDocuments {
		return 0, err
	}
	oldType := int32(0)
	if existing != nil {
		oldType = existing.VoteType
	}

	if vote.VoteID.IsZero() {
		vote.VoteID = primitive.NewObjectID()
	}
	if vote.CreateTime.IsZero() {
		vote.CreateTime = time.Now()
	}
	filter := bson.M{"moment_id": vote.MomentID, "user_id": vote.UserID}
	update := bson.M{
		"$set": bson.M{
			"vote_type":   vote.VoteType,
			"create_time": vote.CreateTime,
		},
		"$setOnInsert": bson.M{
			"_id": vote.VoteID,
		},
	}
	opts := options.Update().SetUpsert(true)
	if _, err := m.coll.UpdateOne(ctx, filter, update, opts); err != nil {
		return 0, errs.Wrap(err)
	}
	return oldType, nil
}

func (m *MomentVoteModel) GetByUser(ctx context.Context, momentID string, userID string) (*table.MomentVote, error) {
	return dbutil.MongoFindOne[table.MomentVote](ctx, m.coll, bson.M{"moment_id": momentID, "user_id": userID})
}
