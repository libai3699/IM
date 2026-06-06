// Copyright © 2023 OpenIM open source community. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package chat

import (
	"regexp"

	"github.com/OpenIMSDK/tools/utils"

	"github.com/OpenIMSDK/chat/pkg/common/constant"
	constant2 "github.com/OpenIMSDK/protocol/constant"
	"github.com/OpenIMSDK/tools/errs"
)

func (x *UpdateUserInfoReq) Check() error {
	if x.UserID == "" {
		return errs.ErrArgs.Wrap("用户ID不能为空")
	}
	if x.Email != nil && x.Email.Value != "" {
		if err := EmailCheck(x.Email.Value); err != nil {
			return err
		}
	}
	return nil
}

func (x *FindUserPublicInfoReq) Check() error {
	if x.UserIDs == nil {
		return errs.ErrArgs.Wrap("用户ID列表不能为空")
	}
	return nil
}

func (x *SearchUserPublicInfoReq) Check() error {
	if x.Pagination == nil {
		return errs.ErrArgs.Wrap("分页参数不能为空")
	}
	if x.Pagination.PageNumber < 1 {
		return errs.ErrArgs.Wrap("页码无效")
	}
	if x.Pagination.ShowNumber < 1 {
		return errs.ErrArgs.Wrap("每页显示数量无效")
	}
	return nil
}

func (x *FindUserFullInfoReq) Check() error {
	if x.UserIDs == nil {
		return errs.ErrArgs.Wrap("用户ID列表不能为空")
	}
	return nil
}

func (x *SendVerifyCodeReq) Check() error {
	if x.UsedFor < constant.VerificationCodeForRegister || x.UsedFor > constant.VerificationCodeForLogin {
		return errs.ErrArgs.Wrap("用途字段不能为空")
	}
	if x.Email == "" {
		if err := checkPhoneOrLoginID(x.AreaCode, x.PhoneNumber); err != nil {
			return err
		}
	} else {
		if err := EmailCheck(x.Email); err != nil {
			return err
		}
	}

	return nil
}

func (x *VerifyCodeReq) Check() error {
	if x.Email == "" {
		if err := checkPhoneOrLoginID(x.AreaCode, x.PhoneNumber); err != nil {
			return err
		}
	} else {
		if err := EmailCheck(x.Email); err != nil {
			return err
		}
	}
	if x.VerifyCode == "" {
		return errs.ErrArgs.Wrap("验证码不能为空")
	}
	return nil
}

func (x *RegisterUserReq) Check() error {
	//if x.VerifyCode == "" {
	//	return errs.ErrArgs.Wrap("VerifyCode is empty")
	//}
	if x.Platform < constant2.IOSPlatformID || x.Platform > constant2.AdminPlatformID {
		return errs.ErrArgs.Wrap("平台参数无效")
	}
	if x.User == nil {
		return errs.ErrArgs.Wrap("用户信息不能为空")
	}
	if x.User.Email == "" {
		if err := checkPhoneOrLoginID(x.User.AreaCode, x.User.PhoneNumber); err != nil {
			return err
		}
	} else {
		if err := EmailCheck(x.User.Email); err != nil {
			return err
		}
	}
	return nil
}

func (x *LoginReq) Check() error {
	if x.Platform < constant2.IOSPlatformID || x.Platform > constant2.AdminPlatformID {
		return errs.ErrArgs.Wrap("平台参数无效")
	}
	if x.Email == "" && x.Account == "" {
		if err := checkPhoneOrLoginID(x.AreaCode, x.PhoneNumber); err != nil {
			return err
		}
	} else if x.Email != "" {
		if err := EmailCheck(x.Email); err != nil {
			return err
		}
	}
	return nil
}

func (x *ResetPasswordReq) Check() error {
	if x.Password == "" {
		return errs.ErrArgs.Wrap("密码不能为空")
	}
	if x.Email == "" {
		if err := checkPhoneOrLoginID(x.AreaCode, x.PhoneNumber); err != nil {
			return err
		}
	} else {
		if err := EmailCheck(x.Email); err != nil {
			return err
		}
	}
	if x.VerifyCode == "" {
		return errs.ErrArgs.Wrap("验证码不能为空")
	}
	return nil
}

func (x *ChangePasswordReq) Check() error {
	if x.UserID == "" {
		return errs.ErrArgs.Wrap("用户ID不能为空")
	}

	// if x.CurrentPassword == "" {
	// 	return errs.ErrArgs.Wrap("currentPassword is empty")
	// }

	if x.NewPassword == "" {
		return errs.ErrArgs.Wrap("新密码不能为空")
	}

	return nil
}

func (x *FindUserAccountReq) Check() error {
	if x.UserIDs == nil {
		return errs.ErrArgs.Wrap("用户ID列表不能为空")
	}
	return nil
}

func (x *FindAccountUserReq) Check() error {
	if x.Accounts == nil {
		return errs.ErrArgs.Wrap("账号列表不能为空")
	}
	return nil
}

func (x *SearchUserFullInfoReq) Check() error {
	if x.Pagination == nil {
		return errs.ErrArgs.Wrap("分页参数不能为空")
	}
	if x.Pagination.PageNumber < 1 {
		return errs.ErrArgs.Wrap("页码无效")
	}
	if x.Pagination.ShowNumber < 1 {
		return errs.ErrArgs.Wrap("每页显示数量无效")
	}
	if x.Normal < constant.FinDAllUser || x.Normal > constant.FindNormalUser {
		return errs.ErrArgs.Wrap("查询类型参数无效")
	}
	return nil
}

func (x *DeleteLogsReq) Check() error {
	if x.LogIDs == nil {
		return errs.ErrArgs.Wrap("日志ID列表不能为空")
	}
	if utils.Duplicate(x.LogIDs) {
		return errs.ErrArgs.Wrap("日志ID存在重复")
	}
	return nil
}

func (x *UploadLogsReq) Check() error {
	if x.FileURLs == nil {
		return errs.ErrArgs.Wrap("文件URL列表不能为空")
	}
	if x.Platform < constant2.IOSPlatformID || x.Platform > constant2.AdminPlatformID {
		return errs.ErrArgs.Wrap("平台参数无效")
	}
	return nil
}

func (x *SearchLogsReq) Check() error {
	if x.Pagination == nil {
		return errs.ErrArgs.Wrap("分页参数不能为空")
	}
	if x.Pagination.PageNumber < 1 {
		return errs.ErrArgs.Wrap("页码无效")
	}
	if x.Pagination.ShowNumber < 1 {
		return errs.ErrArgs.Wrap("每页显示数量无效")
	}
	return nil
}

func EmailCheck(email string) error {
	pattern := `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
	if err := regexMatch(pattern, email); err != nil {
		return errs.Wrap(err, "邮箱格式无效")
	}
	return nil
}

func AreaCodeCheck(areaCode string) error {
	//pattern := `\+[1-9][0-9]{1,2}`
	//if err := regexMatch(pattern, areaCode); err != nil {
	//	return errs.Wrap(err, "AreaCode is invalid")
	//}
	return nil
}

// checkPhoneOrLoginID 手机号：至少6位，可含字母（如身份证尾号X），区号必填
func checkPhoneOrLoginID(areaCode, phoneNumber string) error {
	if phoneNumber == "" {
		return errs.ErrArgs.Wrap("手机号不能为空")
	}
	if areaCode == "" {
		return errs.ErrArgs.Wrap("区号不能为空")
	}
	if err := AreaCodeCheck(areaCode); err != nil {
		return err
	}
	return PhoneNumberCheck(phoneNumber)
}

func PhoneNumberCheck(phoneNumber string) error {
	if phoneNumber == "" {
		return errs.ErrArgs.Wrap("手机号不能为空")
	}
	if len(phoneNumber) < 6 {
		return errs.ErrArgs.Wrap("手机号至少6位")
	}
	if len(phoneNumber) > 32 {
		return errs.ErrArgs.Wrap("手机号过长")
	}
	return nil
}

func regexMatch(pattern string, target string) error {
	reg := regexp.MustCompile(pattern)
	ok := reg.MatchString(target)
	if !ok {
		return errs.ErrArgs
	}
	return nil
}

func (x *SearchUserInfoReq) Check() error {
	if x.Pagination == nil {
		return errs.ErrArgs.Wrap("分页参数不能为空")
	}
	if x.Pagination.PageNumber < 1 {
		return errs.ErrArgs.Wrap("页码无效")
	}
	if x.Pagination.ShowNumber < 1 {
		return errs.ErrArgs.Wrap("每页显示数量无效")
	}
	return nil
}

func (x *AddUserAccountReq) Check() error {
	if x.User == nil {
		return errs.ErrArgs.Wrap("用户信息不能为空")
	}

	if x.User.Email == "" {
		if err := checkPhoneOrLoginID(x.User.AreaCode, x.User.PhoneNumber); err != nil {
			return err
		}
	} else {
		if err := EmailCheck(x.User.Email); err != nil {
			return errs.ErrArgs.Wrap("邮箱格式必须正确")
		}
	}

	return nil
}

func (x *GetUserLatestLoginRecordReq) Check() error {
	if x.UserID == "" {
		return errs.ErrArgs.Wrap("用户ID不能为空")
	}
	return nil
}

func (x *GetUserLoginRecordsReq) Check() error {
	if x.UserID == "" {
		return errs.ErrArgs.Wrap("用户ID不能为空")
	}
	if x.Pagination == nil {
		return errs.ErrArgs.Wrap("分页参数不能为空")
	}
	if x.Pagination.PageNumber < 1 {
		return errs.ErrArgs.Wrap("页码无效")
	}
	if x.Pagination.ShowNumber < 1 {
		return errs.ErrArgs.Wrap("每页显示数量无效")
	}
	return nil
}
