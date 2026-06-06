package office

import "github.com/OpenIMSDK/tools/errs"

func (x *CreateOneWorkMomentReq) Check() error {
	if x.Content == nil {
		return errs.ErrArgs.Wrap("内容不能为空")
	}
	return nil
}

func (x *FindRelevantWorkMomentsReq) Check() error {
	if x.Pagination == nil {
		return errs.ErrArgs.Wrap("分页参数不能为空")
	}
	if x.Pagination.PageNumber < 1 {
		return errs.ErrArgs.Wrap("页码无效")
	}
	return nil
}
