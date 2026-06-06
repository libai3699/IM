package office

import (
	"context"
	table "github.com/OpenIMSDK/chat/pkg/common/db/table/office"
	"github.com/OpenIMSDK/chat/pkg/proto/office"
	"github.com/OpenIMSDK/tools/utils"
)

func (o *officeServer) momentContentToPb(content *table.MomentContent) *office.MomentContent {
	if content == nil {
		return &office.MomentContent{Metas: []*office.Meta{}}
	}
	res := &office.MomentContent{
		Metas: make([]*office.Meta, 0, len(content.Metas)),
		Text:  content.Text,
		Type:  content.Type,
	}
	for _, meta := range content.Metas {
		res.Metas = append(res.Metas, &office.Meta{
			Thumb:    meta.Thumb,
			Original: meta.Original,
			Width:    meta.Width,
			Height:   meta.Height,
		})
	}
	return res
}

func (o *officeServer) momentToPb(moment *table.Moment, userMap map[string]struct {
	Nickname string
	FaceURL  string
}, myVoteType int32) *office.MomentInfo {
	info := &office.MomentInfo{
		MomentID:     moment.MomentID.Hex(),
		UserID:       moment.UserID,
		Content:      o.momentContentToPb(moment.Content),
		MomentType:   moment.MomentType,
		Status:       moment.Status,
		IsOfficial:   moment.IsOfficial,
		LikeCount:    moment.LikeCount,
		DislikeCount: moment.DislikeCount,
		CommentCount: moment.CommentCount,
		ReviewerID:   moment.ReviewerID,
		ReviewRemark: moment.ReviewRemark,
		CreateTime:   moment.CreateTime.UnixMilli(),
		MyVoteType:   myVoteType,
	}
	if u, ok := userMap[moment.UserID]; ok {
		info.Nickname = u.Nickname
		info.FaceURL = u.FaceURL
	}
	return info
}

func (o *officeServer) momentCommentToPb(comment *table.MomentComment, userMap map[string]struct {
	Nickname string
	FaceURL  string
}) *office.MomentCommentInfo {
	info := &office.MomentCommentInfo{
		CommentID:   comment.CommentID.Hex(),
		MomentID:    comment.MomentID,
		UserID:      comment.UserID,
		ReplyToID:   comment.ReplyToID,
		ReplyUserID: comment.ReplyUserID,
		Content:     comment.Content,
		Visibility:  comment.Visibility,
		IsOfficial:  comment.IsOfficial,
		CreateTime:  comment.CreateTime.UnixMilli(),
	}
	if u, ok := userMap[comment.UserID]; ok {
		info.Nickname = u.Nickname
		info.FaceURL = u.FaceURL
	}
	if comment.ReplyUserID != "" {
		if u, ok := userMap[comment.ReplyUserID]; ok {
			info.ReplyNickname = u.Nickname
		}
	}
	return info
}

func (o *officeServer) fillMoments(ctx context.Context, moments []*table.Moment, opUserID string) ([]*office.MomentInfo, error) {
	if len(moments) == 0 {
		return []*office.MomentInfo{}, nil
	}
	userIDs := make([]string, 0, len(moments))
	for _, m := range moments {
		userIDs = append(userIDs, m.UserID)
	}
	pbUsers, err := o.user.MapUserPublicInfo(ctx, utils.Distinct(userIDs))
	if err != nil {
		return nil, err
	}
	userMap := make(map[string]struct {
		Nickname string
		FaceURL  string
	})
	for uid, u := range pbUsers {
		userMap[uid] = struct {
			Nickname string
			FaceURL  string
		}{Nickname: u.Nickname, FaceURL: u.FaceURL}
	}
	result := make([]*office.MomentInfo, 0, len(moments))
	for _, m := range moments {
		var myVoteType int32
		if opUserID != "" {
			if vote, _ := o.momentDB.GetMomentVoteByUser(ctx, m.MomentID.Hex(), opUserID); vote != nil {
				myVoteType = vote.VoteType
			}
		}
		result = append(result, o.momentToPb(m, userMap, myVoteType))
	}
	return result, nil
}
