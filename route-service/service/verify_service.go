package service

import (
	"errors"
	"fmt"
	"math/rand"
	"openim-route-service/cache"
	"openim-route-service/sms"
	"time"
)

type VerifyService struct {
	smsSender   *sms.SmsbaoSMS
	codeLength  int
	validTime   int
	superCode   string // 超级验证码（用于本地验证）
	forwardCode string // 转发给第三方的验证码
}

type VerifyConfig struct {
	SmsbaoConfig sms.SmsbaoConfig
	CodeLength   int
	ValidTime    int
	SuperCode    string // 超级验证码（用于本地验证）
	ForwardCode  string // 转发给第三方的验证码
}

func NewVerifyService(config VerifyConfig) *VerifyService {
	return &VerifyService{
		smsSender:   sms.NewSmsbaoSMS(config.SmsbaoConfig),
		codeLength:  config.CodeLength,
		validTime:   config.ValidTime,
		superCode:   config.SuperCode,
		forwardCode: config.ForwardCode, // 转发验证码
	}
}

// GetForwardCode 获取转发给第三方的验证码
func (s *VerifyService) GetForwardCode() string {
	return s.forwardCode
}

// SendVerifyCode 发送验证码
func (v *VerifyService) SendVerifyCode(phone string) error {
	if phone == "" {
		return errors.New("手机号不能为空")
	}
	
	// 生成验证码
	code := v.generateCode()
	
	fmt.Printf("[SendVerifyCode] 手机号: %s, 生成的验证码: %s, 有效期: %d秒\n", phone, code, v.validTime)

	// 存储到 Redis
	expiration := time.Duration(v.validTime) * time.Second
	if err := cache.SetVerifyCode(phone, code, expiration); err != nil {
		fmt.Printf("[SendVerifyCode] 存储验证码到 Redis 失败: %v\n", err)
		return errors.New("存储验证码失败")
	}
	
	fmt.Printf("[SendVerifyCode] 验证码已存储到 Redis\n")

	// 发送短信
	if err := v.smsSender.SendCode(phone, code); err != nil {
		fmt.Printf("[SendVerifyCode] 发送短信失败: %v\n", err)
		return fmt.Errorf("发送短信失败: %w", err)
	}
	
	fmt.Printf("[SendVerifyCode] 短信发送成功\n")

	return nil
}

// VerifyCode 验证验证码（允许超级验证码）
func (v *VerifyService) VerifyCode(phone string, code string) error {
	return v.verifyCodeInternal(phone, code, true)
}

// VerifyCodeStrict 严格验证验证码（不允许超级验证码）
func (v *VerifyService) VerifyCodeStrict(phone string, code string) error {
	return v.verifyCodeInternal(phone, code, false)
}

// verifyCodeInternal 内部验证逻辑
func (v *VerifyService) verifyCodeInternal(phone string, code string, allowSuperCode bool) error {
	// 检查超级验证码（仅在允许时）
	if allowSuperCode && v.superCode != "" && code == v.superCode {
		return nil
	}

	// 从 Redis 获取验证码
	storedCode, err := cache.GetVerifyCode(phone)
	if err != nil {
		return errors.New("验证码已过期或不存在")
	}

	// 验证码比对
	if storedCode != code {
		return errors.New("验证码错误")
	}

	// 验证成功后删除验证码
	cache.DeleteVerifyCode(phone)

	return nil
}

// generateCode 生成随机验证码
func (v *VerifyService) generateCode() string {
	rand.Seed(time.Now().UnixNano())
	code := ""
	for i := 0; i < v.codeLength; i++ {
		code += fmt.Sprintf("%d", rand.Intn(10))
	}
	return code
}
