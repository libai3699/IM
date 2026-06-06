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
	"context"
	"math/rand"
	"strconv"
	"strings"
	"time"

	"github.com/OpenIMSDK/chat/pkg/common/mctx"

	constant2 "github.com/OpenIMSDK/protocol/constant"

	"github.com/OpenIMSDK/tools/errs"
	"github.com/OpenIMSDK/tools/log"
	"github.com/OpenIMSDK/tools/mcontext"
	"github.com/OpenIMSDK/tools/utils"

	"github.com/OpenIMSDK/chat/pkg/common/config"
	"github.com/OpenIMSDK/chat/pkg/common/constant"
	"github.com/OpenIMSDK/chat/pkg/common/db/dbutil"
	chat2 "github.com/OpenIMSDK/chat/pkg/common/db/table/chat"
	"github.com/OpenIMSDK/chat/pkg/common/iputil"
	"github.com/OpenIMSDK/chat/pkg/common/totp"
	"github.com/OpenIMSDK/chat/pkg/eerrs"
	"github.com/OpenIMSDK/chat/pkg/proto/chat"
)

func (o *chatSvr) verifyCodeJoin(areaCode, phoneNumber string) string {
	return areaCode + " " + phoneNumber
}

// verifyCodeKey 验证码存储/校验用的标识（邮箱 / 区号+手机号，含末尾X等）
func verifyCodeKey(email, areaCode, phoneNumber string) string {
	if email != "" {
		return email
	}
	if phoneNumber == "" {
		return ""
	}
	if areaCode != "" {
		return areaCode + " " + phoneNumber
	}
	return phoneNumber
}

func isClientConfigEnabled(val string) bool {
	return utils.Contain(strings.ToLower(val), "1", "true", "yes")
}

func (o *chatSvr) SendVerifyCode(ctx context.Context, req *chat.SendVerifyCodeReq) (*chat.SendVerifyCodeResp, error) {
	defer log.ZDebug(ctx, "return")
	switch int(req.UsedFor) {
	case constant.VerificationCodeForRegister:
		if err := o.Admin.CheckRegister(ctx, req.Ip); err != nil {
			return nil, err
		}
		if req.Email == "" {
			if req.PhoneNumber == "" {
				return nil, errs.ErrArgs.Wrap("手机号不能为空")
			}
			if req.AreaCode == "" {
				return nil, errs.ErrArgs.Wrap("区号不能为空")
			}
			if req.AreaCode[0] != '+' {
				req.AreaCode = "+" + req.AreaCode
			}
			if _, err := strconv.ParseUint(req.AreaCode[1:], 10, 64); err != nil {
				return nil, errs.ErrArgs.Wrap("区号必须是数字")
			}
			if len(req.PhoneNumber) < 6 {
				return nil, errs.ErrArgs.Wrap("手机号至少6位")
			}
			_, err := o.Database.TakeAttributeByPhone(ctx, req.AreaCode, req.PhoneNumber)
			if err == nil {
				return nil, eerrs.ErrPhoneAlreadyRegister.Wrap("手机号已注册")
			} else if !o.Database.IsNotFound(err) {
				return nil, err
			}
		} else {
			if err := chat.EmailCheck(req.Email); err != nil {
				return nil, errs.ErrArgs.Wrap("邮箱格式必须正确")
			}
			_, err := o.Database.TakeAttributeByEmail(ctx, req.Email)
			if err == nil {
				return nil, eerrs.ErrEmailAlreadyRegister.Wrap("邮箱已注册")
			} else if !o.Database.IsNotFound(err) {
				return nil, err
			}
		}
		conf, err := o.Admin.GetConfig(ctx)
		if err != nil {
			return nil, err
		}
		if val := conf[constant.NeedInvitationCodeRegisterConfigKey]; isClientConfigEnabled(val) {
			if req.InvitationCode == "" {
				return nil, errs.ErrArgs.Wrap("邀请码不能为空")
			}
			if err := o.Admin.CheckInvitationCode(ctx, req.InvitationCode); err != nil {
				return nil, err
			}
		}
		if !isClientConfigEnabled(conf[constant.NeedVerificationCodeRegisterConfigKey]) {
			return &chat.SendVerifyCodeResp{}, nil
		}
	case constant.VerificationCodeForLogin, constant.VerificationCodeForResetPassword:
		if req.Email == "" {
			var err error
			_, err = o.Database.TakeAttributeByPhone(ctx, req.AreaCode, req.PhoneNumber)
			if o.Database.IsNotFound(err) {
				return nil, eerrs.ErrAccountNotFound.Wrap("手机号未注册")
			} else if err != nil {
				return nil, err
			}
		} else {
			_, err := o.Database.TakeAttributeByEmail(ctx, req.Email)
			if o.Database.IsNotFound(err) {
				return nil, eerrs.ErrAccountNotFound.Wrap("邮箱未注册")
			} else if err != nil {
				return nil, err
			}
		}

	default:
		return nil, errs.ErrArgs.Wrap("未知的使用场景")
	}
	var account string
	var isEmail bool
	if req.Email != "" {
		isEmail = true
		account = req.Email
	} else {
		account = verifyCodeKey("", req.AreaCode, req.PhoneNumber)
		isEmail = false
	}

	verifyCode := config.Config.VerifyCode
	if verifyCode.UintTime == 0 || verifyCode.MaxCount == 0 {
			return nil, errs.ErrNoPermission.Wrap("验证码功能已禁用")
	}
	if verifyCode.Use == "" {
		if verifyCode.SuperCode == "" {
			return nil, errs.ErrInternalServer.Wrap("超级验证码未配置")
		}
		return &chat.SendVerifyCodeResp{}, nil
	}
	now := time.Now()

	var count uint32
	var err error
	if !isEmail {
		count, err = o.Database.CountVerifyCodeRange(ctx, o.verifyCodeJoin(req.AreaCode, req.PhoneNumber), now.Add(-time.Duration(verifyCode.UintTime)*time.Second), now)
		if err != nil {
			return nil, err
		}
	} else {
		count, err = o.Database.CountVerifyCodeRange(ctx, req.Email, now.Add(-time.Duration(verifyCode.UintTime)*time.Second), now)
	}
	if verifyCode.MaxCount < int(count) {
		return nil, eerrs.ErrVerifyCodeSendFrequently.Wrap()
	}

	t := &chat2.VerifyCode{
		Account:    account,
		Code:       o.genVerifyCode(),
		Duration:   uint(config.Config.VerifyCode.ValidTime),
		CreateTime: time.Now(),
	}
	if !isEmail {
		err = o.Database.AddVerifyCode(ctx, t, func() error {
			return o.SMS.SendCode(ctx, req.AreaCode, req.PhoneNumber, t.Code)
		})
	} else {
		// 发送邮件验证码
		err = o.Database.AddVerifyCode(ctx, t, func() error {
			return o.Mail.SendMail(ctx, req.Email, t.Code)
		})
	}
	if err != nil {
		return nil, err
	}
	return &chat.SendVerifyCodeResp{}, nil
}

func (o *chatSvr) verifyCode(ctx context.Context, account string, verifyCode string) (uint, error) {
	return o.verifyCodeWithSuperCodeCheck(ctx, account, verifyCode, true)
}

func (o *chatSvr) verifyCodeStrict(ctx context.Context, account string, verifyCode string) (uint, error) {
	return o.verifyCodeWithSuperCodeCheck(ctx, account, verifyCode, false)
}

// verifyCodeForResetPassword 找回密码专用验证，不允许使用万能验证码
func (o *chatSvr) verifyCodeForResetPassword(ctx context.Context, account string, verifyCode string) (uint, error) {
	return o.verifyCodeWithSuperCodeCheck(ctx, account, verifyCode, false)
}

// verifyCodeWithSuperCodeCheck 验证码验证的内部实现
// allowSuperCode: 是否允许使用万能验证码
func (o *chatSvr) verifyCodeWithSuperCodeCheck(ctx context.Context, account string, verifyCode string, allowSuperCode bool) (uint, error) {
	defer log.ZDebug(ctx, "return")
	if verifyCode == "" {
		return 0, errs.ErrArgs.Wrap("验证码不能为空")
	}
	// 优先从数据库读取 super_code，使用内部调用标记跳过敏感字段过滤
	superCode := config.Config.VerifyCode.SuperCode
	internalCtx := mctx.WithInternalCall(ctx)
	if dbConf, err := o.Admin.GetConfig(internalCtx); err == nil {
		if dbVal, ok := dbConf["super_code"]; ok && dbVal != "" {
			superCode = dbVal
		}
	}

	if superCode != "" && verifyCode == superCode {
		if allowSuperCode {
			return 0, nil
		} else {
			return 0, eerrs.ErrVerifyCodeNotMatch.Wrap("验证码错误")
		}
	}

	// 如果没有启用短信/邮件服务，只能使用万能验证码
	if config.Config.VerifyCode.Use == "" {
		return 0, eerrs.ErrVerifyCodeNotMatch.Wrap("验证服务未启用")
	}

	// 正常验证码验证流程
	last, err := o.Database.TakeLastVerifyCode(ctx, account)
	if err != nil {
		if dbutil.IsGormNotFound(err) {
			return 0, eerrs.ErrVerifyCodeExpired.Wrap()
		}
		return 0, err
	}
	if last.CreateTime.Unix()+int64(last.Duration) < time.Now().Unix() {
		return last.ID, eerrs.ErrVerifyCodeExpired.Wrap()
	}
	if last.Used {
		return last.ID, eerrs.ErrVerifyCodeUsed.Wrap()
	}
	if config.Config.VerifyCode.MaxCount > 0 {
		if last.Count >= config.Config.VerifyCode.MaxCount {
			return last.ID, eerrs.ErrVerifyCodeMaxCount.Wrap()
		}
		if last.Code != verifyCode {
			if err := o.Database.UpdateVerifyCodeIncrCount(ctx, last.ID); err != nil {
				return last.ID, err
			}
		}
	}
	if last.Code != verifyCode {
		return last.ID, eerrs.ErrVerifyCodeNotMatch.Wrap()
	}
	return last.ID, nil
}

func (o *chatSvr) VerifyCode(ctx context.Context, req *chat.VerifyCodeReq) (*chat.VerifyCodeResp, error) {
	defer log.ZDebug(ctx, "return")
	account := verifyCodeKey(req.Email, req.AreaCode, req.PhoneNumber)
	if account == "" {
		return nil, errs.ErrArgs.Wrap("手机号、邮箱或账号不能为空")
	}
	if _, err := o.verifyCode(ctx, account, req.VerifyCode); err != nil {
		return nil, err
	}
	return &chat.VerifyCodeResp{}, nil
}

func (o *chatSvr) genUserID() string {
	const l = 10
	data := make([]byte, l)
	rand.Read(data)
	chars := []byte("0123456789")
	for i := 0; i < len(data); i++ {
		if i == 0 {
			data[i] = chars[1:][data[i]%9]
		} else {
			data[i] = chars[data[i]%10]
		}
	}
	return string(data)
}

func (o *chatSvr) genVerifyCode() string {
	data := make([]byte, config.Config.VerifyCode.Len)
	rand.Read(data)
	chars := []byte("0123456789")
	for i := 0; i < len(data); i++ {
		data[i] = chars[data[i]%10]
	}
	return string(data)
}

func (o *chatSvr) RegisterUser(ctx context.Context, req *chat.RegisterUserReq) (*chat.RegisterUserResp, error) {
	resp := &chat.RegisterUserResp{}

	isAdmin, err := o.Admin.CheckNilOrAdmin(ctx)
	ctx = mctx.WithAdminUser(ctx)
	if err != nil {
		return nil, err
	}
	if req.User == nil {
		return nil, errs.ErrArgs.Wrap("用户信息不能为空")
	}
	log.ZDebug(ctx, "email", req.User.Email)
	if req.User.Email == "" {
		if req.User.PhoneNumber == "" && req.User.Account == "" {
			return nil, errs.ErrArgs.Wrap("请提供手机号、邮箱或账号")
		}
		if req.User.PhoneNumber != "" {
			if (req.User.AreaCode == "" && req.User.PhoneNumber != "") || (req.User.AreaCode != "" && req.User.PhoneNumber == "") {
				return nil, errs.ErrArgs.Wrap("区号或手机号错误，且未提供邮箱")
			}
		}
	}
	var usedInvitationCode bool
	if !isAdmin {
		if req.User.UserID != "" {
			return nil, errs.ErrNoPermission.Wrap("只有管理员可以设置用户ID")
		}
		if err := o.Admin.CheckRegister(ctx, req.Ip); err != nil {
			return nil, err
		}
		conf, err := o.Admin.GetConfig(ctx)
		if err != nil {
			return nil, err
		}
		if val := conf[constant.NeedInvitationCodeRegisterConfigKey]; isClientConfigEnabled(val) {
			usedInvitationCode = true
			if req.InvitationCode == "" {
				return nil, errs.ErrArgs.Wrap("邀请码不能为空")
			}
			if err := o.Admin.CheckInvitationCode(ctx, req.InvitationCode); err != nil {
				return nil, err
			}
		}
		if isClientConfigEnabled(conf[constant.NeedVerificationCodeRegisterConfigKey]) {
			key := verifyCodeKey(req.User.Email, req.User.AreaCode, req.User.PhoneNumber)
			if key == "" && req.User.Account != "" {
				key = req.User.Account
			}
			if _, err := o.verifyCode(ctx, key, req.VerifyCode); err != nil {
				return nil, err
			}
		}

	}
	log.ZDebug(ctx, "usedInvitationCode", usedInvitationCode)
	if req.User.UserID == "" {
		for i := 0; i < 20; i++ {
			userID := o.genUserID()
			_, err := o.Database.GetUser(ctx, userID)
			if err == nil {
				continue
			} else if dbutil.IsGormNotFound(err) {
				req.User.UserID = userID
				break
			} else {
				return nil, err
			}
		}
		if req.User.UserID == "" {
			return nil, errs.ErrInternalServer.Wrap("生成用户ID失败")
		}
	} else {
		_, err := o.Database.GetUser(ctx, req.User.UserID)
		if err == nil {
			return nil, errs.ErrArgs.Wrap("指定的用户ID已被注册")
		} else if !dbutil.IsGormNotFound(err) {
			return nil, err
		}
	}
	var registerType int32
	if req.User.PhoneNumber != "" {
		if req.User.AreaCode[0] != '+' {
			req.User.AreaCode = "+" + req.User.AreaCode
		}
		if _, err := strconv.ParseUint(req.User.AreaCode[1:], 10, 64); err != nil {
			return nil, errs.ErrArgs.Wrap("区号必须是数字")
		}
		if len(req.User.PhoneNumber) < 6 {
			return nil, errs.ErrArgs.Wrap("手机号至少6位")
		}
		_, err := o.Database.TakeAttributeByPhone(ctx, req.User.AreaCode, req.User.PhoneNumber)
		if err == nil {
			return nil, eerrs.ErrPhoneAlreadyRegister.Wrap()
		} else if !o.Database.IsNotFound(err) {
			return nil, err
		}
		registerType = constant.PhoneRegister
	}

	if req.User.Account != "" {
		_, err := o.Database.TakeAttributeByAccount(ctx, req.User.Account)
		if err == nil {
			return nil, eerrs.ErrAccountAlreadyRegister.Wrap()
		} else if !o.Database.IsNotFound(err) {
			return nil, err
		}
	}

	if req.User.Email != "" {
		_, err := o.Database.TakeAttributeByEmail(ctx, req.User.Email)
		registerType = constant.EmailRegister
		if err == nil {
			return nil, eerrs.ErrEmailAlreadyRegister.Wrap()
		} else if !o.Database.IsNotFound(err) {
			return nil, err
		}
	}
	register := &chat2.Register{
		UserID:      req.User.UserID,
		DeviceID:    req.DeviceID,
		IP:          req.Ip,
		Platform:    constant2.PlatformID2Name[int(req.Platform)],
		AccountType: "",
		Mode:        constant.UserMode,
		CreateTime:  time.Now(),
	}
	account := &chat2.Account{
		UserID:         req.User.UserID,
		Password:       req.User.Password,
		OperatorUserID: mcontext.GetOpUserID(ctx),
		ChangeTime:     register.CreateTime,
		CreateTime:     register.CreateTime,
	}
	attribute := &chat2.Attribute{
		UserID:         req.User.UserID,
		Account:        req.User.Account,
		PhoneNumber:    req.User.PhoneNumber,
		AreaCode:       req.User.AreaCode,
		Email:          req.User.Email,
		Nickname:       req.User.Nickname,
		FaceURL:        req.User.FaceURL,
		Gender:         req.User.Gender,
		BirthTime:      time.UnixMilli(req.User.Birth),
		ChangeTime:     register.CreateTime,
		CreateTime:     register.CreateTime,
		AllowVibration: constant.DefaultAllowVibration,
		AllowBeep:      constant.DefaultAllowBeep,
		AllowAddFriend: constant.DefaultAllowAddFriend,
		RegisterType:   registerType,
	}
	if err := o.Database.RegisterUser(ctx, register, account, attribute); err != nil {
		return nil, err
	}
	if req.InvitationCode != "" {
		if err := o.Admin.UseInvitationCode(ctx, req.User.UserID, req.InvitationCode); err != nil {
			log.ZError(ctx, "UseInvitationCode", err, "userID", req.User.UserID, "invitationCode", req.InvitationCode)
			return nil, err
		}
	}
	if req.AutoLogin {
		chatToken, adminErr := o.Admin.CreateToken(ctx, req.User.UserID, constant.NormalUser)
		if err != nil {
			log.ZError(ctx, "Admin CreateToken Failed", err, "userID", req.User.UserID, "platform", req.Platform)
		}
		if adminErr == nil {
			resp.ChatToken = chatToken.Token
		}

		// 【新增】注册并自动登录时，记录登录信息到 user_login_records 表
		// 获取登录地区信息
		location := iputil.GetLocationByIPWithFallback(req.Ip)

		log.ZInfo(ctx, "Register with auto login - recording login info",
			"userID", req.User.UserID,
			"ip", req.Ip,
			"deviceID", req.DeviceID,
			"platform", req.Platform,
			"deviceModel", req.DeviceModel,
			"location", location)

		loginRecord := &chat2.UserLoginRecord{
			UserID:      req.User.UserID,
			LoginTime:   time.Now(),
			IP:          req.Ip,
			DeviceID:    req.DeviceID,
			Platform:    constant2.PlatformIDToName(int(req.Platform)),
			DeviceModel: req.DeviceModel, // 从请求中直接获取设备型号
			Location:    location,
		}

		// 保存登录记录（注册时不需要验证码ID）
		if err := o.Database.LoginRecord(ctx, loginRecord, nil); err != nil {
			log.ZError(ctx, "Failed to save login record after registration", err,
				"userID", loginRecord.UserID,
				"deviceModel", loginRecord.DeviceModel)
			// 不影响注册流程，只记录错误日志
		} else {
			log.ZInfo(ctx, "Login record saved successfully after registration",
				"userID", loginRecord.UserID,
				"deviceModel", loginRecord.DeviceModel)
		}
	}
	resp.UserID = req.User.UserID
	return resp, nil
}

func (o *chatSvr) Login(ctx context.Context, req *chat.LoginReq) (*chat.LoginResp, error) {
	defer log.ZDebug(ctx, "return")
	resp := &chat.LoginResp{}
	if req.Password == "" && req.VerifyCode == "" {
		return nil, errs.ErrArgs.Wrap("密码或验证码必须设置其中一个")
	}
	var err error
	var attribute *chat2.Attribute
	if req.Account != "" {
		attribute, err = o.Database.GetAttributeByAccount(ctx, req.Account)
	} else if req.PhoneNumber != "" {
		if req.AreaCode == "" {
			return nil, errs.ErrArgs.Wrap("必须提供区号")
		}
		if req.AreaCode[0] != '+' {
			req.AreaCode = "+" + req.AreaCode
		}
		if _, err := strconv.ParseUint(req.AreaCode[1:], 10, 64); err != nil {
			return nil, errs.ErrArgs.Wrap("区号必须是数字")
		}
		attribute, err = o.Database.GetAttributeByPhone(ctx, req.AreaCode, req.PhoneNumber)
	} else if req.Email != "" {
		attribute, err = o.Database.GetAttributeByEmail(ctx, req.Email)
	} else {
		err = errs.ErrArgs.Wrap("account or phone number or email must be set")
	}
	if err != nil {
		if o.Database.IsNotFound(err) {
			return nil, eerrs.ErrAccountNotFound.Wrap("用户未注册")
		}
		return nil, err
	}
	if err := o.Admin.CheckLogin(ctx, attribute.UserID, req.Ip); err != nil {
		return nil, err
	}

	// 单设备登录校验：从后台配置 singleDeviceLogin=1 开启
	// 只看 iOS/Android 的 app 登录记录，web/桌面端不计入绑定设备
	if conf, confErr := o.Admin.GetConfig(ctx); confErr == nil {
		if val := conf[constant.SingleDeviceLoginConfigKey]; utils.Contain(strings.ToLower(val), "1", "true", "yes") {
			// 只对 app 平台（iOS=1, Android=2）执行单设备校验
			platform := constant2.PlatformIDToName(int(req.Platform))
			if platform == "IOS" || platform == "Android" {
				deviceID := req.DeviceID
				if deviceID == "" {
					return nil, errs.ErrArgs.Wrap("设备ID不能为空")
				}
				// 取最近一次 app 端登录记录的 device_id 作为绑定设备
				lastRecord, recErr := o.Database.GetLatestAppLoginRecord(ctx, attribute.UserID)
				if recErr == nil && lastRecord.DeviceID != "" && lastRecord.DeviceID != deviceID {
					// 已有 app 端绑定记录且设备不同，拒绝登录
					return nil, eerrs.ErrDeviceNotBound.Wrap()
				}
				// recErr != nil → 从未从 app 端登录过，首次绑定，放行
			}
		}
	}
	var verifyCodeID *uint
	if req.Password == "" {
		key := verifyCodeKey(req.Email, req.AreaCode, req.PhoneNumber)
		if key == "" {
			return nil, errs.ErrArgs.Wrap("手机号、邮箱或账号不能为空")
		}
		id, err := o.verifyCodeStrict(ctx, key, req.VerifyCode)
		if err != nil {
			return nil, err
		}
		verifyCodeID = &id
	} else {
		account, err := o.Database.GetAccount(ctx, attribute.UserID)
		if err != nil {
			return nil, err
		}
		if account.Password != req.Password {
			return nil, eerrs.ErrPassword.Wrap()
		}
	}

	// 如果用户启用了谷歌验证码，且提供了验证码，则进行验证
	if attribute.GoogleAuthEnabled {
		if req.GoogleAuthCode == "" {
			return nil, errs.ErrArgs.Wrap("该账户已启用谷歌验证码，请输入验证码")
		}
		// 验证谷歌验证码
		if !totp.ValidateCode(attribute.GoogleAuthSecret, req.GoogleAuthCode, 1) {
			return nil, errs.ErrArgs.Wrap("谷歌验证码错误")
		}
		log.ZInfo(ctx, "Google auth code validated successfully", "userID", attribute.UserID)
	} else if req.GoogleAuthCode != "" {
		// 如果用户没有启用谷歌验证码，但提供了验证码，提示用户
		log.ZWarn(ctx, "User provided google auth code but not enabled", nil, "userID", attribute.UserID)
		// 不返回错误，只是忽略验证码
	}
	chatToken, err := o.Admin.CreateToken(ctx, attribute.UserID, constant.NormalUser)
	if err != nil {
		return nil, err
	}
	// 获取登录地区信息
	location := iputil.GetLocationByIPWithFallback(req.Ip)

	// 【调试日志】打印登录请求信息
	log.ZInfo(ctx, "Login request details",
		"userID", attribute.UserID,
		"ip", req.Ip,
		"deviceID", req.DeviceID,
		"platform", req.Platform,
		"DeviceModel", req.DeviceModel,
		"location", location)

	record := &chat2.UserLoginRecord{
		UserID:      attribute.UserID,
		LoginTime:   time.Now(),
		IP:          req.Ip,
		DeviceID:    req.DeviceID,
		Platform:    constant2.PlatformIDToName(int(req.Platform)),
		DeviceModel: req.DeviceModel, // 设备型号
		Location:    location,         // 登录地区
	}
	if err := o.Database.LoginRecord(ctx, record, verifyCodeID); err != nil {
		log.ZError(ctx, "Failed to save login record", err,
			"userID", record.UserID,
			"DeviceModel", record.DeviceModel)
		return nil, err
	}

	log.ZInfo(ctx, "Login record saved successfully",
		"userID", record.UserID,
		"DeviceModel", record.DeviceModel)
	if verifyCodeID != nil {
		if err := o.Database.DelVerifyCode(ctx, *verifyCodeID); err != nil {
			return nil, err
		}
	}
	resp.UserID = attribute.UserID
	resp.ChatToken = chatToken.Token
	return resp, nil
}

// 获取用户最新的登录记录
func (o *chatSvr) GetUserLatestLoginRecord(ctx context.Context, req *chat.GetUserLatestLoginRecordReq) (*chat.GetUserLatestLoginRecordResp, error) {
	defer log.ZDebug(ctx, "return")

	// 权限检查：管理员、用户本人或好友可以查看
	opUserID, userType, err := mctx.Check(ctx)
	if err != nil {
		return nil, err
	}

	// 管理员和本人可以直接查看
	if userType != constant.AdminUser && req.UserID != opUserID {
		log.ZInfo(ctx, "Checking friend relationship", "opUserID", opUserID, "targetUserID", req.UserID)

		// 获取 Admin Token 用于调用 OpenIM API
		adminToken, err := o.ImApiCaller.ImAdminTokenWithDefaultAdmin(ctx)
		if err != nil {
			log.ZError(ctx, "Failed to get admin token", err)
			return nil, errs.ErrNoPermission.Wrap("权限验证失败")
		}

		// 将 token 添加到 context
		ctxWithToken := mctx.WithApiToken(ctx, adminToken)

		// 检查是否是好友关系 - 查询当前用户的好友列表
		friendIDs, err := o.ImApiCaller.FindFriendUserIDs(ctxWithToken, opUserID)
		if err != nil {
			log.ZError(ctx, "Failed to get friend list", err, "opUserID", opUserID)
			return nil, errs.ErrNoPermission.Wrap("无权查看该用户的登录记录")
		}

		log.ZInfo(ctx, "Got friend list", "opUserID", opUserID, "friendCount", len(friendIDs), "friendIDs", friendIDs)

		isFriend := false
		for _, friendID := range friendIDs {
			if friendID == req.UserID {
				isFriend = true
				break
			}
		}

		if !isFriend {
			log.ZWarn(ctx, "Not friend relationship", nil, "opUserID", opUserID, "targetUserID", req.UserID, "friendIDs", friendIDs)
			return nil, errs.ErrNoPermission.Wrap("无权查看其他用户的登录记录")
		}
		log.ZInfo(ctx, "Friend relationship verified", "opUserID", opUserID, "targetUserID", req.UserID)
	} else {
		log.ZInfo(ctx, "Permission granted", "userType", userType, "opUserID", opUserID, "targetUserID", req.UserID)
	}

	record, err := o.Database.GetLatestLoginRecord(ctx, req.UserID)
	if err != nil {
		if o.Database.IsNotFound(err) {
			return &chat.GetUserLatestLoginRecordResp{}, nil
		}
		return nil, err
	}

	// 检测同一设备是否有其他账户登录
	var otherUserIDs []string
	var isMultiDevice bool
	if record.DeviceID != "" {
		otherUserIDs, err = o.Database.GetOtherUserIDsByDeviceID(ctx, record.DeviceID, req.UserID)
		if err != nil {
			log.ZWarn(ctx, "Failed to check multi-device login", err, "deviceID", record.DeviceID)
			otherUserIDs = []string{}
		}
		isMultiDevice = len(otherUserIDs) > 0
	}

	resp := &chat.GetUserLatestLoginRecordResp{
		Record: &chat.UserLoginRecord{
			UserID:       record.UserID,
			LoginTime:    record.LoginTime.UnixMilli(),
			Ip:           record.IP,
			DeviceID:     record.DeviceID,
			Platform:     record.Platform,
			DeviceModel:  record.DeviceModel,
			Location:     record.Location,
			IsMultiDevice: isMultiDevice,
			OtherUserIDs: otherUserIDs,
		},
	}

	return resp, nil
}

// 获取用户登录记录列表
func (o *chatSvr) GetUserLoginRecords(ctx context.Context, req *chat.GetUserLoginRecordsReq) (*chat.GetUserLoginRecordsResp, error) {
	defer log.ZDebug(ctx, "return")

	// 权限检查：管理员、用户本人或好友可以查看
	opUserID, userType, err := mctx.Check(ctx)
	if err != nil {
		return nil, err
	}

	// 管理员和本人可以直接查看
	if userType != constant.AdminUser && req.UserID != opUserID {
		log.ZInfo(ctx, "Checking friend relationship for records list", "opUserID", opUserID, "targetUserID", req.UserID)

		// 获取 Admin Token 用于调用 OpenIM API
		adminToken, err := o.ImApiCaller.ImAdminTokenWithDefaultAdmin(ctx)
		if err != nil {
			log.ZError(ctx, "Failed to get admin token", err)
			return nil, errs.ErrNoPermission.Wrap("权限验证失败")
		}

		// 将 token 添加到 context
		ctxWithToken := mctx.WithApiToken(ctx, adminToken)

		// 检查是否是好友关系 - 查询当前用户的好友列表
		friendIDs, err := o.ImApiCaller.FindFriendUserIDs(ctxWithToken, opUserID)
		if err != nil {
			log.ZError(ctx, "Failed to get friend list", err, "opUserID", opUserID)
			return nil, errs.ErrNoPermission.Wrap("无权查看该用户的登录记录列表")
		}

		log.ZInfo(ctx, "Got friend list for records", "opUserID", opUserID, "friendCount", len(friendIDs))

		isFriend := false
		for _, friendID := range friendIDs {
			if friendID == req.UserID {
				isFriend = true
				break
			}
		}

		if !isFriend {
			log.ZWarn(ctx, "Not friend relationship for records", nil, "opUserID", opUserID, "targetUserID", req.UserID)
			return nil, errs.ErrNoPermission.Wrap("无权查看其他用户的登录记录列表")
		}
		log.ZInfo(ctx, "Friend relationship verified for records", "opUserID", opUserID, "targetUserID", req.UserID)
	} else {
		log.ZInfo(ctx, "Permission granted for records", "userType", userType, "opUserID", opUserID, "targetUserID", req.UserID)
	}

	total, records, err := o.Database.GetUserLoginRecords(ctx, req.UserID, req.Pagination.PageNumber, req.Pagination.ShowNumber)
	if err != nil {
		return nil, err
	}

	resp := &chat.GetUserLoginRecordsResp{
		Total:   total,
		Records: make([]*chat.UserLoginRecord, 0, len(records)),
	}

	for _, record := range records {
		// 检测同一设备是否有其他账户登录
		var otherUserIDs []string
		var isMultiDevice bool
		if record.DeviceID != "" {
			otherUserIDs, err = o.Database.GetOtherUserIDsByDeviceID(ctx, record.DeviceID, req.UserID)
			if err != nil {
				log.ZWarn(ctx, "Failed to check multi-device login", err, "deviceID", record.DeviceID)
				otherUserIDs = []string{}
			}
			isMultiDevice = len(otherUserIDs) > 0
		}

		resp.Records = append(resp.Records, &chat.UserLoginRecord{
			UserID:       record.UserID,
			LoginTime:    record.LoginTime.UnixMilli(),
			Ip:           record.IP,
			DeviceID:     record.DeviceID,
			Platform:     record.Platform,
			DeviceModel:  record.DeviceModel,
			Location:     record.Location,
			IsMultiDevice: isMultiDevice,
			OtherUserIDs: otherUserIDs,
		})
	}

	return resp, nil
}
