package api

import (
	"github.com/OpenIMSDK/chat/pkg/proto/office"
	"github.com/OpenIMSDK/tools/a2r"
	"github.com/gin-gonic/gin"
)

func (o *Office) CreateMoment(c *gin.Context) {
	a2r.Call(office.OfficeClient.CreateMoment, o.officeClient, c)
}

func (o *Office) DeleteMoment(c *gin.Context) {
	a2r.Call(office.OfficeClient.DeleteMoment, o.officeClient, c)
}

func (o *Office) GetMoment(c *gin.Context) {
	a2r.Call(office.OfficeClient.GetMoment, o.officeClient, c)
}

func (o *Office) PageMoments(c *gin.Context) {
	a2r.Call(office.OfficeClient.PageMoments, o.officeClient, c)
}

func (o *Office) PageMyMoments(c *gin.Context) {
	a2r.Call(office.OfficeClient.PageMyMoments, o.officeClient, c)
}

func (o *Office) VoteMoment(c *gin.Context) {
	a2r.Call(office.OfficeClient.VoteMoment, o.officeClient, c)
}

func (o *Office) CommentMoment(c *gin.Context) {
	a2r.Call(office.OfficeClient.CommentMoment, o.officeClient, c)
}

func (o *Office) DeleteMomentComment(c *gin.Context) {
	a2r.Call(office.OfficeClient.DeleteMomentComment, o.officeClient, c)
}

func (o *Office) AdminReviewMoment(c *gin.Context) {
	a2r.Call(office.OfficeClient.AdminReviewMoment, o.officeClient, c)
}

func (o *Office) AdminSetTopMoment(c *gin.Context) {
	a2r.Call(office.OfficeClient.AdminSetTopMoment, o.officeClient, c)
}

func (o *Office) AdminCancelTopMoment(c *gin.Context) {
	a2r.Call(office.OfficeClient.AdminCancelTopMoment, o.officeClient, c)
}

func (o *Office) AdminPageMoments(c *gin.Context) {
	a2r.Call(office.OfficeClient.AdminPageMoments, o.officeClient, c)
}

func (o *Office) AdminPagePendingMoments(c *gin.Context) {
	a2r.Call(office.OfficeClient.AdminPagePendingMoments, o.officeClient, c)
}
