package office

import (
	"context"
	constant2 "github.com/OpenIMSDK/chat/pkg/common/constant"
	table "github.com/OpenIMSDK/chat/pkg/common/db/table/office"
	"github.com/OpenIMSDK/chat/pkg/common/mctx"
	"github.com/OpenIMSDK/chat/pkg/proto/office"
	"github.com/OpenIMSDK/tools/errs"
	"time"
)

func (o *officeServer) CreateMoment(ctx context.Context, req *office.CreateMomentReq) (*office.CreateMomentResp, error) {
	opUserID := mctx.GetOpUserID(ctx)
	status := int32(constant2.MomentStatusPending)
	if req.IsOfficial {
		if _, err := mctx.CheckAdmin(ctx); err != nil {
			return nil, errs.ErrNoPermission.Wrap("仅管理员可发布官方动态")
		}
		status = constant2.MomentStatusApproved
	}

	var content *table.MomentContent
	if req.Content != nil {
		metas := make([]*table.Meta, 0, len(req.Content.Metas))
		for _, m := range req.Content.Metas {
			metas = append(metas, &table.Meta{
				Original: m.Original,
				Thumb:    m.Thumb,
				Width:    m.Width,
				Height:   m.Height,
			})
		}
		content = &table.MomentContent{
			Metas: metas,
			Text:  req.Content.Text,
			Type:  req.Content.Type,
		}
	}

	moment := &table.Moment{
		UserID:     opUserID,
		Content:    content,
		MomentType: constant2.MomentTypeNormal,
		Status:     status,
		IsOfficial: req.IsOfficial,
		CreateTime: time.Now(),
	}
	if err := o.momentDB.CreateMoment(ctx, moment); err != nil {
		return nil, err
	}
	pbMoments, err := o.fillMoments(ctx, []*table.Moment{moment}, opUserID)
	if err != nil {
		return nil, err
	}
	return &office.CreateMomentResp{Moment: pbMoments[0]}, nil
}

func (o *officeServer) DeleteMoment(ctx context.Context, req *office.DeleteMomentReq) (*office.DeleteMomentResp, error) {
	opUserID := mctx.GetOpUserID(ctx)
	moment, err := o.momentDB.GetMoment(ctx, req.MomentID)
	if err != nil {
		return nil, err
	}
	if moment.UserID != opUserID {
		if _, err := mctx.CheckAdmin(ctx); err != nil {
			return nil, errs.ErrNoPermission.Wrap("无权删除他人动态")
		}
	}
	if err := o.momentDB.DeleteMoment(ctx, req.MomentID); err != nil {
		return nil, err
	}
	return &office.DeleteMomentResp{}, nil
}

func (o *officeServer) GetMoment(ctx context.Context, req *office.GetMomentReq) (*office.GetMomentResp, error) {
	opUserID := mctx.GetOpUserID(ctx)
	moment, err := o.momentDB.GetMoment(ctx, req.MomentID)
	if err != nil {
		return nil, err
	}
	pbMoments, err := o.fillMoments(ctx, []*table.Moment{moment}, opUserID)
	if err != nil {
		return nil, err
	}
	dbComments, err := o.momentDB.ListMomentComments(ctx, req.MomentID, opUserID)
	if err != nil {
		return nil, err
	}

	userIDs := make([]string, 0, len(dbComments)*2)
	for _, c := range dbComments {
		userIDs = append(userIDs, c.UserID)
		if c.ReplyUserID != "" {
			userIDs = append(userIDs, c.ReplyUserID)
		}
	}
	pbUsers, err := o.user.MapUserPublicInfo(ctx, userIDs)
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

	pbComments := make([]*office.MomentCommentInfo, 0, len(dbComments))
	for _, c := range dbComments {
		pbComments = append(pbComments, o.momentCommentToPb(c, userMap))
	}

	return &office.GetMomentResp{
		Moment:   pbMoments[0],
		Comments: pbComments,
	}, nil
}

func (o *officeServer) PageMoments(ctx context.Context, req *office.PageMomentsReq) (*office.PageMomentsResp, error) {
	opUserID := mctx.GetOpUserID(ctx)
	moments, total, err := o.momentDB.PageMoments(ctx, req.Pagination.ShowNumber, req.Pagination.PageNumber)
	if err != nil {
		return nil, err
	}
	pbMoments, err := o.fillMoments(ctx, moments, opUserID)
	if err != nil {
		return nil, err
	}
	return &office.PageMomentsResp{Total: total, Moments: pbMoments}, nil
}

func (o *officeServer) PageMyMoments(ctx context.Context, req *office.PageMyMomentsReq) (*office.PageMyMomentsResp, error) {
	opUserID := mctx.GetOpUserID(ctx)
	moments, total, err := o.momentDB.PageUserMoments(ctx, opUserID, req.Pagination.ShowNumber, req.Pagination.PageNumber)
	if err != nil {
		return nil, err
	}
	pbMoments, err := o.fillMoments(ctx, moments, opUserID)
	if err != nil {
		return nil, err
	}
	return &office.PageMyMomentsResp{Total: total, Moments: pbMoments}, nil
}

func (o *officeServer) VoteMoment(ctx context.Context, req *office.VoteMomentReq) (*office.VoteMomentResp, error) {
	opUserID := mctx.GetOpUserID(ctx)
	if req.VoteType != int32(constant2.MomentVoteLike) && req.VoteType != int32(constant2.MomentVoteDislike) {
		return nil, errs.ErrArgs.Wrap("不支持的投票类型")
	}

	moment, err := o.momentDB.GetMoment(ctx, req.MomentID)
	if err != nil {
		return nil, err
	}
	if moment.MomentType != int32(constant2.MomentTypeTop) {
		return nil, errs.ErrArgs.Wrap("仅置顶动态支持投票")
	}

	vote := &table.MomentVote{
		MomentID: req.MomentID,
		UserID:   opUserID,
		VoteType: req.VoteType,
	}
	oldType, err := o.momentDB.UpsertMomentVote(ctx, vote)
	if err != nil {
		return nil, err
	}

	// 调整计数
	if oldType == 0 {
		// 首次投票
		if req.VoteType == int32(constant2.MomentVoteLike) {
			_ = o.momentDB.IncrMomentCount(ctx, req.MomentID, "like_count", 1)
		} else {
			_ = o.momentDB.IncrMomentCount(ctx, req.MomentID, "dislike_count", 1)
		}
	} else if oldType != req.VoteType {
		// 切换投票方向
		if req.VoteType == int32(constant2.MomentVoteLike) {
			_ = o.momentDB.IncrMomentCount(ctx, req.MomentID, "like_count", 1)
			_ = o.momentDB.IncrMomentCount(ctx, req.MomentID, "dislike_count", -1)
		} else {
			_ = o.momentDB.IncrMomentCount(ctx, req.MomentID, "dislike_count", 1)
			_ = o.momentDB.IncrMomentCount(ctx, req.MomentID, "like_count", -1)
		}
	}

	updated, err := o.momentDB.GetMoment(ctx, req.MomentID)
	if err != nil {
		return nil, err
	}
	return &office.VoteMomentResp{
		LikeCount:    updated.LikeCount,
		DislikeCount: updated.DislikeCount,
	}, nil
}

func (o *officeServer) CommentMoment(ctx context.Context, req *office.CommentMomentReq) (*office.CommentMomentResp, error) {
	opUserID := mctx.GetOpUserID(ctx)
	if req.Content == "" {
		return nil, errs.ErrArgs.Wrap("评论内容不能为空")
	}

	moment, err := o.momentDB.GetMoment(ctx, req.MomentID)
	if err != nil {
		return nil, err
	}

	// 可见性：官方动态或动态发布者回复时，评论对所有人可见
	visibility := int32(constant2.MomentCommentVisibilitySelfOnly)
	if moment.IsOfficial || moment.UserID == opUserID {
		visibility = constant2.MomentCommentVisibilityPublic
	}
	// isOfficial 仅由评论者身份决定（是否为管理员），与动态属性无关
	// 修复：原逻辑错误地将动态发布者的自回复也标记为官方评论
	_, isAdminErr := mctx.CheckAdmin(ctx)
	isOfficial := isAdminErr == nil

	comment := &table.MomentComment{
		MomentID:    req.MomentID,
		UserID:      opUserID,
		ReplyToID:   req.ReplyToID,
		ReplyUserID: req.ReplyUserID,
		Content:     req.Content,
		Visibility:  visibility,
		IsOfficial:  isOfficial,
	}
	if err := o.momentDB.CreateMomentComment(ctx, comment); err != nil {
		return nil, err
	}
	_ = o.momentDB.IncrMomentCount(ctx, req.MomentID, "comment_count", 1)

	pbUsers, err := o.user.MapUserPublicInfo(ctx, []string{opUserID, req.ReplyUserID})
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

	return &office.CommentMomentResp{Comment: o.momentCommentToPb(comment, userMap)}, nil
}

func (o *officeServer) DeleteMomentComment(ctx context.Context, req *office.DeleteMomentCommentReq) (*office.DeleteMomentCommentResp, error) {
	opUserID := mctx.GetOpUserID(ctx)
	comment, err := o.momentDB.GetMomentComment(ctx, req.CommentID)
	if err != nil {
		return nil, err
	}

	ownerUserID := opUserID
	if comment.UserID != opUserID {
		if _, err := mctx.CheckAdmin(ctx); err != nil {
			return nil, errs.ErrNoPermission.Wrap("无权删除他人评论")
		}
		ownerUserID = "" // 管理员不限制 user_id
	}

	if err := o.momentDB.DeleteMomentComment(ctx, req.CommentID, ownerUserID); err != nil {
		return nil, err
	}
	_ = o.momentDB.IncrMomentCount(ctx, comment.MomentID, "comment_count", -1)
	return &office.DeleteMomentCommentResp{}, nil
}

// ---- 管理员接口 ----

func (o *officeServer) AdminReviewMoment(ctx context.Context, req *office.AdminReviewMomentReq) (*office.AdminReviewMomentResp, error) {
	opUserID := mctx.GetOpUserID(ctx)
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	if req.Status != int32(constant2.MomentStatusApproved) && req.Status != int32(constant2.MomentStatusRejected) {
		return nil, errs.ErrArgs.Wrap("状态值无效")
	}
	// 修复：先校验当前状态，只有 Pending 状态才允许审核（严格状态机）
	moment, err := o.momentDB.GetMoment(ctx, req.MomentID)
	if err != nil {
		return nil, err
	}
	if moment.Status != int32(constant2.MomentStatusPending) {
		return nil, errs.ErrArgs.Wrap("只有待审核状态的动态才可进行审核操作")
	}
	if err := o.momentDB.SetMomentStatus(ctx, req.MomentID, req.Status, opUserID, req.ReviewRemark); err != nil {
		return nil, err
	}
	return &office.AdminReviewMomentResp{}, nil
}

func (o *officeServer) AdminSetTopMoment(ctx context.Context, req *office.AdminSetTopMomentReq) (*office.AdminSetTopMomentResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	if err := o.momentDB.CancelMomentTop(ctx); err != nil {
		return nil, err
	}
	if err := o.momentDB.SetMomentTop(ctx, req.MomentID, int32(constant2.MomentTypeTop)); err != nil {
		return nil, err
	}
	return &office.AdminSetTopMomentResp{}, nil
}

func (o *officeServer) AdminCancelTopMoment(ctx context.Context, req *office.AdminCancelTopMomentReq) (*office.AdminCancelTopMomentResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	if err := o.momentDB.CancelMomentTop(ctx); err != nil {
		return nil, err
	}
	return &office.AdminCancelTopMomentResp{}, nil
}

func (o *officeServer) AdminPageMoments(ctx context.Context, req *office.AdminPageMomentsReq) (*office.AdminPageMomentsResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	moments, total, err := o.momentDB.AdminPageMoments(ctx, req.Keyword, req.Pagination.ShowNumber, req.Pagination.PageNumber)
	if err != nil {
		return nil, err
	}
	pbMoments, err := o.fillMoments(ctx, moments, "")
	if err != nil {
		return nil, err
	}
	return &office.AdminPageMomentsResp{Total: total, Moments: pbMoments}, nil
}

func (o *officeServer) AdminPagePendingMoments(ctx context.Context, req *office.AdminPagePendingMomentsReq) (*office.AdminPagePendingMomentsResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	moments, total, err := o.momentDB.PagePendingMoments(ctx, req.Pagination.ShowNumber, req.Pagination.PageNumber)
	if err != nil {
		return nil, err
	}
	pbMoments, err := o.fillMoments(ctx, moments, "")
	if err != nil {
		return nil, err
	}
	return &office.AdminPagePendingMomentsResp{Total: total, Moments: pbMoments}, nil
}
