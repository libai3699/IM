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

func NewMomentModel(coll *mongo.Collection) (table.MomentInterface, error) {
	indexModels := []mongo.IndexModel{
		{Keys: bson.D{{Key: "user_id", Value: 1}}, Options: options.Index()},
		{Keys: bson.D{{Key: "status", Value: 1}}, Options: options.Index()},
		{Keys: bson.D{{Key: "moment_type", Value: 1}}, Options: options.Index()},
		{Keys: bson.D{{Key: "create_time", Value: -1}}, Options: options.Index()},
	}
	if _, err := coll.Indexes().CreateMany(context.Background(), indexModels); err != nil {
		return nil, err
	}
	return &MomentModel{coll: coll}, nil
}

type MomentModel struct {
	coll *mongo.Collection
}

func (m *MomentModel) Create(ctx context.Context, moment *table.Moment) error {
	if moment.MomentID.IsZero() {
		moment.MomentID = primitive.NewObjectID()
	}
	if moment.CreateTime.IsZero() {
		moment.CreateTime = time.Now()
	}
	if moment.Content == nil {
		moment.Content = &table.MomentContent{Metas: []*table.Meta{}}
	}
	if moment.Content.Metas == nil {
		moment.Content.Metas = []*table.Meta{}
	}
	return dbutil.MongoInsertOne(ctx, m.coll, moment)
}

func (m *MomentModel) Delete(ctx context.Context, momentID string) error {
	id, err := dbutil.MongoID(momentID)
	if err != nil {
		return err
	}
	return dbutil.MongoDeleteOne(ctx, m.coll, bson.M{"_id": id})
}

func (m *MomentModel) Get(ctx context.Context, momentID string) (*table.Moment, error) {
	id, err := dbutil.MongoID(momentID)
	if err != nil {
		return nil, err
	}
	return dbutil.MongoFindOne[table.Moment](ctx, m.coll, bson.M{"_id": id})
}

func (m *MomentModel) SetStatus(ctx context.Context, momentID string, status int32, reviewerID, reviewRemark string) error {
	id, err := dbutil.MongoID(momentID)
	if err != nil {
		return err
	}
	update := bson.M{
		"$set": bson.M{
			"status":        status,
			"reviewer_id":   reviewerID,
			"review_time":   time.Now(),
			"review_remark": reviewRemark,
		},
	}
	return dbutil.MongoUpdateOne(ctx, m.coll, bson.M{"_id": id}, update)
}

func (m *MomentModel) SetTop(ctx context.Context, momentID string, momentType int32) error {
	id, err := dbutil.MongoID(momentID)
	if err != nil {
		return err
	}
	return dbutil.MongoUpdateOne(ctx, m.coll, bson.M{"_id": id}, bson.M{
		"$set": bson.M{"moment_type": momentType},
	})
}

func (m *MomentModel) CancelTop(ctx context.Context) error {
	_, err := m.coll.UpdateMany(ctx,
		bson.M{"moment_type": 2},
		bson.M{"$set": bson.M{"moment_type": 1}},
	)
	return err
}

func (m *MomentModel) GetTop(ctx context.Context) (*table.Moment, error) {
	return dbutil.MongoFindOne[table.Moment](ctx, m.coll, bson.M{"moment_type": 2, "status": 1})
}

func (m *MomentModel) IncrCount(ctx context.Context, momentID string, field string, delta int64) error {
	id, err := dbutil.MongoID(momentID)
	if err != nil {
		return err
	}
	return dbutil.MongoUpdateOne(ctx, m.coll, bson.M{"_id": id}, bson.M{
		"$inc": bson.M{field: delta},
	})
}

func (m *MomentModel) PageList(ctx context.Context, showNumber, pageNumber int32) ([]*table.Moment, int64, error) {
	return m.pageQuery(ctx, bson.M{"status": 1}, showNumber, pageNumber)
}

func (m *MomentModel) PageApproved(ctx context.Context, showNumber, pageNumber int32) ([]*table.Moment, int64, error) {
	return m.pageQuery(ctx, bson.M{"status": 1}, showNumber, pageNumber)
}

func (m *MomentModel) PageByUserID(ctx context.Context, userID string, showNumber, pageNumber int32) ([]*table.Moment, int64, error) {
	return m.pageQuery(ctx, bson.M{"user_id": userID}, showNumber, pageNumber)
}

func (m *MomentModel) PagePending(ctx context.Context, showNumber, pageNumber int32) ([]*table.Moment, int64, error) {
	return m.pageQuery(ctx, bson.M{"status": 0}, showNumber, pageNumber)
}

func (m *MomentModel) AdminPageList(ctx context.Context, keyword string, showNumber, pageNumber int32) ([]*table.Moment, int64, error) {
	filter := bson.M{}
	if keyword != "" {
		filter["user_id"] = bson.M{"$regex": keyword}
	}
	return m.pageQuery(ctx, filter, showNumber, pageNumber)
}

func (m *MomentModel) pageQuery(ctx context.Context, filter bson.M, showNumber, pageNumber int32) ([]*table.Moment, int64, error) {
	total, err := m.coll.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}
	opts := options.Find().
		SetLimit(int64(showNumber)).
		SetSkip(int64(showNumber) * int64(pageNumber-1)).
		SetSort(bson.D{{Key: "moment_type", Value: -1}, {Key: "create_time", Value: -1}})
	list, err := dbutil.MongoFindAll[table.Moment](ctx, m.coll, filter, opts)
	return list, total, err
}
