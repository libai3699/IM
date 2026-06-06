package database

import (
	"context"
	model "github.com/OpenIMSDK/chat/pkg/common/db/model/office"
	table "github.com/OpenIMSDK/chat/pkg/common/db/table/office"
	"go.mongodb.org/mongo-driver/mongo"
	"time"
)

// ---- Moment 接口 ----

type MomentDatabaseInterface interface {
	CreateMoment(ctx context.Context, moment *table.Moment) error
	DeleteMoment(ctx context.Context, momentID string) error
	GetMoment(ctx context.Context, momentID string) (*table.Moment, error)
	SetMomentStatus(ctx context.Context, momentID string, status int32, reviewerID, reviewRemark string) error
	SetMomentTop(ctx context.Context, momentID string, momentType int32) error
	CancelMomentTop(ctx context.Context) error
	GetTopMoment(ctx context.Context) (*table.Moment, error)
	IncrMomentCount(ctx context.Context, momentID string, field string, delta int64) error
	PageMoments(ctx context.Context, showNumber, pageNumber int32) ([]*table.Moment, int64, error)
	PagePendingMoments(ctx context.Context, showNumber, pageNumber int32) ([]*table.Moment, int64, error)
	PageUserMoments(ctx context.Context, userID string, showNumber, pageNumber int32) ([]*table.Moment, int64, error)
	AdminPageMoments(ctx context.Context, keyword string, showNumber, pageNumber int32) ([]*table.Moment, int64, error)

	CreateMomentComment(ctx context.Context, comment *table.MomentComment) error
	DeleteMomentComment(ctx context.Context, commentID string, userID string) error
	GetMomentComment(ctx context.Context, commentID string) (*table.MomentComment, error)
	ListMomentComments(ctx context.Context, momentID string, opUserID string) ([]*table.MomentComment, error)

	UpsertMomentVote(ctx context.Context, vote *table.MomentVote) (int32, error)
	GetMomentVoteByUser(ctx context.Context, momentID string, userID string) (*table.MomentVote, error)
}

type OfficeDatabaseInterface interface {
	GetUserTags(ctx context.Context, userID string) ([]*table.Tag, error)
	CreateTag(ctx context.Context, tag *table.Tag) error
	GetTagByID(ctx context.Context, tagID string) (*table.Tag, error)
	FindTag(ctx context.Context, tagIDs []string) ([]*table.Tag, error)
	DeleteTag(ctx context.Context, tagID string) error
	SetTag(ctx context.Context, tagID, name string, addUserIDs []string, delUserIDs []string, addGroupIDs []string, delGroupIDs []string) error
	GetTagSendLogs(ctx context.Context, userID string, showNumber, pageNumber int32) ([]*table.TagSendLog, error)
	GetTagLogSendUser(ctx context.Context, ids []string) (map[string]string, error)
	DeleteTagLog(ctx context.Context, ids []string) error
	CreateTagSendLog(ctx context.Context, tagSendLog *table.TagSendLog) error
	CreateOneWorkMoment(ctx context.Context, workMoment *table.WorkMoment) error
	DeleteOneWorkMoment(ctx context.Context, workMomentID string) error
	DeleteComment(ctx context.Context, workMomentID, commentID string) error
	GetWorkMomentByID(ctx context.Context, workMomentID string) (*table.WorkMoment, error)
	SetWorkMomentLike(ctx context.Context, workMomentID string, likeUserID string, like bool, time time.Time) (*table.WorkMoment, error)
	CommentOneWorkMoment(ctx context.Context, workMomentID string, comment *table.Comment) (*table.WorkMoment, error)
	GetUserSendWorkMoments(ctx context.Context, userID string, opUserID string, showNumber, pageNumber int32) ([]*table.WorkMoment, error)
	GetUserRecvWorkMoments(ctx context.Context, userID string, friendIDs []string, showNumber, pageNumber int32) ([]*table.WorkMoment, error)
	FindRelevantWorkMoments(ctx context.Context, userID string, time *time.Time, showNumber, pageNumber int32) ([]*table.WorkMoment, error)
	GetUnreadWorkMomentsCount(ctx context.Context, userID string, time *time.Time) (int32, error)
	GetUserReadTime(ctx context.Context, userID string) (*table.WorkMomentRead, error)
	SetUserReadTime(ctx context.Context, userID string, time time.Time, setType int32) error
}

func NewOfficeDatabase(db *mongo.Database) (OfficeDatabaseInterface, error) {
	tag, err := model.NewTagModel(db.Collection("tag"))
	if err != nil {
		return nil, err
	}
	sendTag, err := model.NewSendTagLogModel(db.Collection("send_tag"))
	if err != nil {
		return nil, err
	}
	workMoment, err := model.NewWorkMomentModel(db.Collection("work_moment"))
	if err != nil {
		return nil, err
	}
	read, err := model.NewWorkMomentReadModel(db.Collection("work_moment_read"))
	if err != nil {
		return nil, err
	}
	return &OfficeDatabase{
		tag:        tag,
		read:       read,
		sendTag:    sendTag,
		workMoment: workMoment,
	}, nil
}

func NewMomentDatabase(db *mongo.Database) (MomentDatabaseInterface, error) {
	moment, err := model.NewMomentModel(db.Collection("moment"))
	if err != nil {
		return nil, err
	}
	comment, err := model.NewMomentCommentModel(db.Collection("moment_comment"))
	if err != nil {
		return nil, err
	}
	vote, err := model.NewMomentVoteModel(db.Collection("moment_vote"))
	if err != nil {
		return nil, err
	}
	return &MomentDatabase{
		moment:  moment,
		comment: comment,
		vote:    vote,
	}, nil
}

type MomentDatabase struct {
	moment  table.MomentInterface
	comment table.MomentCommentInterface
	vote    table.MomentVoteInterface
}

func (d *MomentDatabase) CreateMoment(ctx context.Context, moment *table.Moment) error {
	return d.moment.Create(ctx, moment)
}

func (d *MomentDatabase) DeleteMoment(ctx context.Context, momentID string) error {
	return d.moment.Delete(ctx, momentID)
}

func (d *MomentDatabase) GetMoment(ctx context.Context, momentID string) (*table.Moment, error) {
	return d.moment.Get(ctx, momentID)
}

func (d *MomentDatabase) SetMomentStatus(ctx context.Context, momentID string, status int32, reviewerID, reviewRemark string) error {
	return d.moment.SetStatus(ctx, momentID, status, reviewerID, reviewRemark)
}

func (d *MomentDatabase) SetMomentTop(ctx context.Context, momentID string, momentType int32) error {
	return d.moment.SetTop(ctx, momentID, momentType)
}

func (d *MomentDatabase) CancelMomentTop(ctx context.Context) error {
	return d.moment.CancelTop(ctx)
}

func (d *MomentDatabase) GetTopMoment(ctx context.Context) (*table.Moment, error) {
	return d.moment.GetTop(ctx)
}

func (d *MomentDatabase) IncrMomentCount(ctx context.Context, momentID string, field string, delta int64) error {
	return d.moment.IncrCount(ctx, momentID, field, delta)
}

func (d *MomentDatabase) PageMoments(ctx context.Context, showNumber, pageNumber int32) ([]*table.Moment, int64, error) {
	return d.moment.PageApproved(ctx, showNumber, pageNumber)
}

func (d *MomentDatabase) PagePendingMoments(ctx context.Context, showNumber, pageNumber int32) ([]*table.Moment, int64, error) {
	return d.moment.PagePending(ctx, showNumber, pageNumber)
}

func (d *MomentDatabase) PageUserMoments(ctx context.Context, userID string, showNumber, pageNumber int32) ([]*table.Moment, int64, error) {
	return d.moment.PageByUserID(ctx, userID, showNumber, pageNumber)
}

func (d *MomentDatabase) AdminPageMoments(ctx context.Context, keyword string, showNumber, pageNumber int32) ([]*table.Moment, int64, error) {
	return d.moment.AdminPageList(ctx, keyword, showNumber, pageNumber)
}

func (d *MomentDatabase) CreateMomentComment(ctx context.Context, comment *table.MomentComment) error {
	return d.comment.Create(ctx, comment)
}

func (d *MomentDatabase) DeleteMomentComment(ctx context.Context, commentID string, userID string) error {
	return d.comment.Delete(ctx, commentID, userID)
}

func (d *MomentDatabase) GetMomentComment(ctx context.Context, commentID string) (*table.MomentComment, error) {
	return d.comment.GetByID(ctx, commentID)
}

func (d *MomentDatabase) ListMomentComments(ctx context.Context, momentID string, opUserID string) ([]*table.MomentComment, error) {
	return d.comment.ListByMomentID(ctx, momentID, opUserID)
}

func (d *MomentDatabase) UpsertMomentVote(ctx context.Context, vote *table.MomentVote) (int32, error) {
	return d.vote.Upsert(ctx, vote)
}

func (d *MomentDatabase) GetMomentVoteByUser(ctx context.Context, momentID string, userID string) (*table.MomentVote, error) {
	return d.vote.GetByUser(ctx, momentID, userID)
}

type OfficeDatabase struct {
	tag        table.TagInterface
	sendTag    table.SendTagLogInterface
	workMoment table.WorkMomentInterface
	read       table.WorkMomentReadInterface
}

func (o *OfficeDatabase) GetUserTags(ctx context.Context, userID string) ([]*table.Tag, error) {
	return o.tag.GetUserTags(ctx, userID)
}

func (o *OfficeDatabase) CreateTag(ctx context.Context, tag *table.Tag) error {
	return o.tag.Create(ctx, tag)
}

func (o *OfficeDatabase) GetTagByID(ctx context.Context, tagID string) (*table.Tag, error) {
	return o.tag.Get(ctx, tagID)
}

func (o *OfficeDatabase) FindTag(ctx context.Context, tagIDs []string) ([]*table.Tag, error) {
	return o.tag.Find(ctx, tagIDs)
}

func (o *OfficeDatabase) DeleteTag(ctx context.Context, tagID string) error {
	return o.tag.Delete(ctx, tagID)
}

func (o *OfficeDatabase) SetTag(ctx context.Context, tagID, name string, addUserIDs []string, delUserIDs []string, addGroupIDs []string, delGroupIDs []string) error {
	return o.tag.Update(ctx, tagID, name, addUserIDs, delUserIDs, addGroupIDs, delGroupIDs)
}

func (o *OfficeDatabase) GetTagSendLogs(ctx context.Context, userID string, showNumber, pageNumber int32) ([]*table.TagSendLog, error) {
	return o.sendTag.Page(ctx, userID, pageNumber, showNumber)
}

func (o *OfficeDatabase) GetTagLogSendUser(ctx context.Context, ids []string) (map[string]string, error) {
	return o.sendTag.FindSendUserID(ctx, ids)
}

func (o *OfficeDatabase) DeleteTagLog(ctx context.Context, ids []string) error {
	return o.sendTag.Delete(ctx, ids)
}

func (o *OfficeDatabase) CreateTagSendLog(ctx context.Context, tagSendLog *table.TagSendLog) error {
	return o.sendTag.Create(ctx, tagSendLog)
}

func (o *OfficeDatabase) CreateOneWorkMoment(ctx context.Context, workMoment *table.WorkMoment) error {
	return o.workMoment.Create(ctx, workMoment)
}

func (o *OfficeDatabase) DeleteOneWorkMoment(ctx context.Context, workMomentID string) error {
	return o.workMoment.Delete(ctx, workMomentID)
}

func (o *OfficeDatabase) DeleteComment(ctx context.Context, workMomentID, commentID string) error {
	return o.workMoment.DeleteComment(ctx, workMomentID, commentID)
}

func (o *OfficeDatabase) GetWorkMomentByID(ctx context.Context, workMomentID string) (*table.WorkMoment, error) {
	return o.workMoment.Get(ctx, workMomentID)
}

func (o *OfficeDatabase) SetWorkMomentLike(ctx context.Context, workMomentID string, likeUserID string, like bool, time time.Time) (*table.WorkMoment, error) {
	return o.workMoment.SetWorkMomentLike(ctx, workMomentID, likeUserID, like, time)
}

func (o *OfficeDatabase) CommentOneWorkMoment(ctx context.Context, workMomentID string, comment *table.Comment) (*table.WorkMoment, error) {
	return o.workMoment.FindPushComment(ctx, workMomentID, comment)
}

func (o *OfficeDatabase) GetUserSendWorkMoments(ctx context.Context, userID string, opUserID string, showNumber, pageNumber int32) ([]*table.WorkMoment, error) {
	return o.workMoment.GetUserSend(ctx, userID, opUserID, showNumber, pageNumber)
}

func (o *OfficeDatabase) GetUserRecvWorkMoments(ctx context.Context, userID string, friendIDs []string, showNumber, pageNumber int32) ([]*table.WorkMoment, error) {
	return o.workMoment.GetUserRecv(ctx, userID, friendIDs, showNumber, pageNumber)
}

func (o *OfficeDatabase) FindRelevantWorkMoments(ctx context.Context, userID string, time *time.Time, showNumber, pageNumber int32) ([]*table.WorkMoment, error) {
	return o.workMoment.FindRelevant(ctx, userID, time, showNumber, pageNumber)
}

func (o *OfficeDatabase) GetUnreadWorkMomentsCount(ctx context.Context, userID string, time *time.Time) (int32, error) {
	return o.workMoment.GetUnreadCount(ctx, userID, time)
}

func (o *OfficeDatabase) GetUserReadTime(ctx context.Context, userID string) (*table.WorkMomentRead, error) {
	res, err := o.read.Get(ctx, userID)
	return res, err
}

func (o *OfficeDatabase) SetUserReadTime(ctx context.Context, userID string, time time.Time, setType int32) error {
	return o.read.Set(ctx, userID, time, setType)
}
