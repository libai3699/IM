package sms

import (
	"fmt"
	"io"
	"net/http"
	"net/url"
)

type SmsbaoConfig struct {
	ApiUrl   string
	Username string
	Password string
	SignName string
}

type SmsbaoSMS struct {
	config SmsbaoConfig
}

func NewSmsbaoSMS(config SmsbaoConfig) *SmsbaoSMS {
	return &SmsbaoSMS{
		config: config,
	}
}

// SendCode 发送验证码短信
func (s *SmsbaoSMS) SendCode(phoneNumber string, verifyCode string) error {
	// 短信宝API地址
	apiUrl := s.config.ApiUrl
	if apiUrl == "" {
		apiUrl = "https://api.smsbao.com/sms" // 默认短信宝API地址
	}

	// 构建短信内容
	content := fmt.Sprintf("【%s】您的验证码是：%s", s.config.SignName, verifyCode)

	// 构建请求参数
	params := url.Values{}
	params.Set("u", s.config.Username) // 短信宝用户名
	params.Set("p", s.config.Password) // 短信宝密码（建议使用MD5加密后的密码）
	params.Set("m", phoneNumber)       // 手机号
	params.Set("c", content)           // 短信内容

	// 发送HTTP GET请求
	fullUrl := fmt.Sprintf("%s?%s", apiUrl, params.Encode())
	resp, err := http.Get(fullUrl)
	if err != nil {
		return fmt.Errorf("发送短信失败: %w", err)
	}
	defer resp.Body.Close()

	// 读取响应
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("读取响应失败: %w", err)
	}

	// 短信宝返回码说明：
	// 0    发送成功
	// 30   密码错误
	// 40   账号不存在
	// 41   余额不足
	// 42   账户已过期
	// 43   IP地址限制
	// 50   内容含有敏感词
	// 51   手机号码不正确
	statusCode := string(body)
	if statusCode != "0" {
		return fmt.Errorf("短信宝发送失败，错误码: %s", statusCode)
	}

	return nil
}
