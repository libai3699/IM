package office

import (
	"context"
	"github.com/OpenIMSDK/chat/pkg/common/db/dbutil"
	table "github.com/OpenIMSDK/chat/pkg/common/db/table/office"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"time"
)

func NewMomentCommentModel(coll *mongo.Collection) (table.MomentCommentInterface, error) {
	indexModels := []mongo.IndexModel{
		{Keys: bson.D{{Key: "moment_id", Value: 1}}, Options: options.Index()},
		{Keys: bson.D{{Key: "user_id", Value: 1}}, Options: options.Index()},
	}
	if _, err := coll.Indexes().CreateMany(context.Background(), indexModels); err != nil {
		return nil, err
	}
	return &MomentCommentModel{coll: coll}, nil
}

type MomentCommentModel struct {
	coll *mongo.Collection
}

func (m *MomentCommentModel) Create(ctx context.Context, comment *table.MomentComment) error {
	if comment.CommentID.IsZero() {
		comment.CommentID = primitive.NewObjectID()
	}
	if comment.CreateTime.IsZero() {
		comment.CreateTime = time.Now()
	}
	return dbutil.MongoInsertOne(ctx, m.coll, comment)
}

func (m *MomentCommentModel) Delete(ctx context.Context, commentID string, userID string) error {
	id, err := dbutil.MongoID(commentID)
	if err != nil {
		return err
	}
	filter := bson.M{"_id": id}
	if userID != "" {
		filter["user_id"] = userID
	}
	return dbutil.MongoDeleteOne(ctx, m.coll, filter)
}

func (m *MomentCommentModel) GetByID(ctx context.Context, commentID string) (*table.MomentComment, error) {
	id, err := dbutil.MongoID(commentID)
	if err != nil {
		return nil, err
	}
	return dbutil.MongoFindOne[table.MomentComment](ctx, m.coll, bson.M{"_id": id})
}

func (m *MomentCommentModel) ListByMomentID(ctx context.Context, momentID string, opUserID string) ([]*table.MomentComment, error) {
	filter := bson.M{
		"moment_id": momentID,
		"$or": bson.A{
			bson.M{"visibility": 1},
			bson.M{"visibility": 2, "user_id": opUserID},
		},
	}
	opts := options.Find().SetSort(bson.D{{Key: "create_time", Value: 1}})
	return dbutil.MongoFindAll[table.MomentComment](ctx, m.coll, filter, opts)
}
