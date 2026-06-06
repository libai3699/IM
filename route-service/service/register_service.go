package service

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"openim-route-service/model"
	"time"
)

type RegisterService struct {
	routeService  *RouteService
	verifyService *VerifyService
}

func NewRegisterService(verifyService *VerifyService) *RegisterService {
	return &RegisterService{
		routeService:  NewRouteService(),
		verifyService: verifyService,
	}
}

// RegisterRequest 注册请求
type RegisterRequest struct {
	InvitationCode string                 `json:"invitationCode"` // 邀请码
	VerifyCode     string                 `json:"verifyCode"`     // 验证码
	DeviceID       string                 `json:"deviceID"`
	Platform       int32                  `json:"platform"`
	AutoLogin      bool                   `json:"autoLogin"`
	User           map[string]interface{} `json:"user"` // 用户信息
	DeviceModel    string                 `json:"deviceModel"`
	Ip             string                 `json:"ip"`             // 客户端IP（前端传递）
}

// RegisterRequestToServer 转发到目标服务器的注册请求（去掉验证码，添加已验证标记）
type RegisterRequestToServer struct {
	InvitationCode string                 `json:"invitationCode"`
	VerifyCode     string                 `json:"verifyCode"` // 使用特殊值表示已验证
	DeviceID       string                 `json:"deviceID"`
	Platform       int32                  `json:"platform"`
	AutoLogin      bool                   `json:"autoLogin"`
	User           map[string]interface{} `json:"user"`
	DeviceModel    string                 `json:"deviceModel"`
	Ip             string                 `json:"ip"` // 客户端IP
}

// Register 注册用户
func (s *RegisterService) Register(req *RegisterRequest, clientIP string, operationID string) (map[string]interface{}, error) {
	// 1. 验证验证码（从 user 中提取手机号）
	var phoneNumber string
	if user, ok := req.User["phoneNumber"].(string); ok {
		phoneNumber = user
	}
	
	if phoneNumber == "" {
		return nil, errors.New("手机号不能为空")
	}
	
	// 如果 user 中没有 areaCode，默认设置为 +86
	if _, ok := req.User["areaCode"]; !ok {
		req.User["areaCode"] = "+86"
	}
	
	if req.VerifyCode == "" {
		return nil, errors.New("验证码不能为空")
	}
	
	// 验证验证码（路由服务验证）
	if err := s.verifyService.VerifyCode(phoneNumber, req.VerifyCode); err != nil {
		return nil, fmt.Errorf("验证码验证失败: %w", err)
	}

	// 2. 验证邀请码并获取服务器配置（邀请码为空时使用默认服务器）
	serverInfo, err := s.routeService.GetServerByInviteCode(req.InvitationCode)
	if err != nil {
		return nil, err
	}

	// 3. 解析域名
	if len(serverInfo.Domains) == 0 {
		return nil, errors.New("服务器配置错误：没有可用域名")
	}

	// 使用第一个域名（添加 https 协议）
	apiURL := fmt.Sprintf("https://%s/chat/account/register", serverInfo.Domains[0])

	// 优先使用前端传递的 ip，如果没有则使用从请求头获取的 IP
	finalIP := req.Ip
	if finalIP == "" {
		finalIP = clientIP
	}
	
	// 4. 构建转发请求（使用配置的转发验证码）
	forwardReq := RegisterRequestToServer{
		InvitationCode: req.InvitationCode,
		VerifyCode:     s.verifyService.GetForwardCode(), // 使用配置的转发验证码
		DeviceID:       req.DeviceID,
		Platform:       req.Platform,
		AutoLogin:      req.AutoLogin,
		User:           req.User,
		DeviceModel:    req.DeviceModel,
		Ip:             finalIP, // 传递客户端IP到参数中
	}
	
	// 打印请求参数（调试用）
	reqBodyDebug, _ := json.Marshal(forwardReq)
	fmt.Printf("[Register] 请求参数: %s\n", string(reqBodyDebug))

	// 5. 转发注册请求到目标服务器
	reqBody, err := json.Marshal(forwardReq)
	if err != nil {
		return nil, errors.New("请求参数序列化失败")
	}

	httpReq, err := http.NewRequest("POST", apiURL, bytes.NewBuffer(reqBody))
	if err != nil {
		return nil, errors.New("创建请求失败")
	}

	httpReq.Header.Set("Content-Type", "application/json")
	
	// 同时也设置到请求头（兼容性）
	httpReq.Header.Set("X-Real-IP", finalIP)
	httpReq.Header.Set("X-Forwarded-For", finalIP)
	
	fmt.Printf("[Register] 转发请求 - 前端传递IP: %s, 请求头IP: %s, 最终使用IP: %s (已放入参数)\n", req.Ip, clientIP, finalIP)
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

	// 8. 如果注册成功，绑定用户到服务器并添加域名信息
	fmt.Printf("[Register] 解析后的 result: %+v\n", result)
	if errCode, ok := result["errCode"].(float64); ok && errCode == 0 {
		fmt.Printf("[Register] 注册成功，errCode=%v，准备绑定用户和添加服务器信息\n", errCode)
		// 使用手机号作为 userID 进行绑定
		fmt.Printf("[Register] 使用手机号 %s 作为 userID，准备绑定到服务器 %s\n", phoneNumber, serverInfo.ServerID)
		
		// 绑定用户到服务器（使用手机号）
		if err := s.routeService.BindUserToServer(phoneNumber, serverInfo.ServerID, req.InvitationCode); err != nil {
			// 绑定失败不影响注册结果，只记录错误
			fmt.Printf("[Register] Warning: Failed to bind user %s to server: %v\n", phoneNumber, err)
		} else {
			fmt.Printf("[Register] 用户 %s 成功绑定到服务器 %s\n", phoneNumber, serverInfo.ServerID)
		}

		// 添加服务器信息到响应中
		if data, ok := result["data"].(map[string]interface{}); ok {
			fmt.Printf("[Register] data 字段存在: %+v\n", data)
			data["serverInfo"] = map[string]interface{}{
				"serverID":   serverInfo.ServerID,
				"serverName": serverInfo.ServerName,
				"domains":    serverInfo.Domains,
			}
			fmt.Printf("[Register] 添加服务器信息后的 data: %+v\n", data)
		} else {
			fmt.Printf("[Register] data 字段不存在或类型不匹配\n")
		}
	} else {
		fmt.Printf("[Register] 注册失败或 errCode 解析失败，errCode=%v, ok=%v\n", errCode, ok)
	}

	// 8. 返回增强后的响应
	return result, nil
}

// GetServerByInviteCode 根据邀请码获取服务器信息（用于前端预查询）
func (s *RegisterService) GetServerByInviteCode(inviteCode string) (*model.RouteResponse, error) {
	return s.routeService.GetServerByInviteCode(inviteCode)
}

// CheckUserExists 检查用户是否已注册（通过查询用户绑定表）
func (s *RegisterService) CheckUserExists(phone string) (bool, error) {
	// 查询用户绑定表，如果用户已绑定服务器，说明已注册
	_, err := s.routeService.GetServerByUserID(phone)
	if err != nil {
		// 如果查询失败（用户不存在），返回 false
		return false, nil
	}
	// 用户已存在
	return true, nil
}
