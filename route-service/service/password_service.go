package service

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"time"
)

type PasswordService struct {
	routeService  *RouteService
	verifyService *VerifyService
}

func NewPasswordService(verifyService *VerifyService) *PasswordService {
	return &PasswordService{
		routeService:  NewRouteService(),
		verifyService: verifyService,
	}
}

// ResetPasswordRequest 重置密码请求（接收前端参数）
type ResetPasswordRequest struct {
	AreaCode    string `json:"areaCode"`    // 区号
	PhoneNumber string `json:"phoneNumber"` // 手机号
	VerifyCode  string `json:"verifyCode"`  // 验证码
	Password    string `json:"password"`    // 密码（前端发送的字段名）
	Platform    int32  `json:"platform"`
	ClientIP    string `json:"clientIP"`    // 客户端IP（前端传递）
}

// ResetPassword 重置密码
func (s *PasswordService) ResetPassword(req *ResetPasswordRequest, clientIP string, operationID string) (map[string]interface{}, error) {
	// 1. 验证参数
	if req.PhoneNumber == "" {
		return nil, errors.New("手机号不能为空")
	}
	if req.VerifyCode == "" {
		return nil, errors.New("验证码不能为空")
	}
	if req.Password == "" {
		return nil, errors.New("密码不能为空")
	}
	
	// 如果 areaCode 为空，默认设置为 +86
	if req.AreaCode == "" {
		req.AreaCode = "+86"
	}

	// 2. 严格验证验证码（不允许超级验证码）
	if err := s.verifyService.VerifyCodeStrict(req.PhoneNumber, req.VerifyCode); err != nil {
		return nil, fmt.Errorf("验证码验证失败: %w", err)
	}

	// 3. 根据账号查询用户绑定的服务器
	serverInfo, err := s.routeService.GetServerByUserID(req.PhoneNumber)
	if err != nil {
		return nil, errors.New("用户不存在")
	}

	// 4. 解析域名
	if len(serverInfo.Domains) == 0 {
		return nil, errors.New("服务器配置错误：没有可用域名")
	}

	// 使用第一个域名（添加 https 协议）
	apiURL := fmt.Sprintf("https://%s/chat/account/password/reset", serverInfo.Domains[0])

	// 5. 转发重置密码请求到目标服务器（原样传递前端字段）
	// 构建转发请求（使用前端发送的字段名）
	forwardReq := map[string]interface{}{
		"areaCode":    req.AreaCode,
		"phoneNumber": req.PhoneNumber,
		"verifyCode":  s.verifyService.GetForwardCode(), // 使用配置的转发验证码
		"password":    req.Password,                     // 原样传递 password 字段
		"platform":    req.Platform,
	}
	
	// 打印请求参数
	reqBodyDebug, _ := json.Marshal(forwardReq)
	fmt.Printf("[ResetPassword] 请求参数: %s\n", string(reqBodyDebug))

	reqBody, err := json.Marshal(forwardReq)
	if err != nil {
		return nil, errors.New("请求参数序列化失败")
	}

	httpReq, err := http.NewRequest("POST", apiURL, bytes.NewBuffer(reqBody))
	if err != nil {
		return nil, errors.New("创建请求失败")
	}

	httpReq.Header.Set("Content-Type", "application/json")
	// 设置真实客户端 IP
	httpReq.Header.Set("X-Real-IP", clientIP)
	httpReq.Header.Set("X-Forwarded-For", clientIP)
	// 使用客户端传来的 operationID，如果没有则生成一个
	if operationID == "" {
		operationID = fmt.Sprintf("%d", time.Now().UnixNano()/1e6)
	}
	httpReq.Header.Set("operationID", operationID)

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("请求目标服务器失败: %w", err)
	}
	defer resp.Body.Close()

	// 6. 读取响应
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, errors.New("读取响应失败")
	}

	// 7. 解析响应
	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, errors.New("解析响应失败")
	}

	// 8. 返回响应
	return result, nil
}
