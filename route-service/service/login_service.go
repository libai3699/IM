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

type LoginService struct {
	routeService *RouteService
}

func NewLoginService() *LoginService {
	return &LoginService{
		routeService: NewRouteService(),
	}
}

// LoginRequest 登录请求
type LoginRequest struct {
	AreaCode       string `json:"areaCode"`       // 区号
	PhoneNumber    string `json:"phoneNumber"`    // 手机号
	Password       string `json:"password"`       // 密码
	Platform       int32  `json:"platform"`       // 平台
	DeviceID       string `json:"deviceID"`
	DeviceModel    string `json:"deviceModel"`
	Ip             string `json:"ip"`             // 客户端IP（前端传递）
	GoogleAuthCode string `json:"googleAuthCode"` // 谷歌验证码（6位数字）
}

// Login 用户登录
func (s *LoginService) Login(req *LoginRequest, clientIP string, operationID string) (map[string]interface{}, error) {
	if req.PhoneNumber == "" {
		return nil, errors.New("手机号不能为空")
	}

	

	// 1. 根据账号查询用户绑定的服务器（使用 phoneNumber）
	serverInfo, err := s.routeService.GetServerByUserID(req.PhoneNumber)
	if err != nil {
		return nil, errors.New("用户不存在")
	}

	// 2. 解析域名
	if len(serverInfo.Domains) == 0 {
		return nil, errors.New("服务器配置错误：没有可用域名")
	}

	// 使用第一个域名（添加 https 协议）
	apiURL := fmt.Sprintf("https://%s/chat/account/login", serverInfo.Domains[0])

	fmt.Printf("[Login] 请求URL: %s\n", apiURL)
	fmt.Printf("[Login] 服务器域名: %s\n", serverInfo.Domains[0])

	// 优先使用前端传递的 ip，如果没有则使用从请求头获取的 IP
	finalIP := req.Ip
	if finalIP == "" {
		finalIP = clientIP
	}
	
	// 确保 Ip 字段有值
	req.Ip = finalIP
	
	// 3. 转发登录请求到目标服务器
	reqBody, err := json.Marshal(req)
	if err != nil {
		return nil, errors.New("请求参数序列化失败")
	}

	// 打印请求参数
	fmt.Printf("[Login] 请求参数: %s\n", string(reqBody))

	httpReq, err := http.NewRequest("POST", apiURL, bytes.NewBuffer(reqBody))
	if err != nil {
		return nil, errors.New("创建请求失败")
	}

	httpReq.Header.Set("Content-Type", "application/json")
	
	// 同时也设置到请求头（兼容性）
	httpReq.Header.Set("X-Real-IP", finalIP)
	httpReq.Header.Set("X-Forwarded-For", finalIP)
	
	fmt.Printf("[Login] 转发请求 - 前端传递IP: %s, 请求头IP: %s, 最终使用IP: %s (已放入参数)\n", req.Ip, clientIP, finalIP)
	
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

	// 4. 读取响应
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, errors.New("读取响应失败")
	}

	// 打印原始响应（调试用）
	fmt.Printf("[Login] 目标服务器响应: %s\n", string(body))

	// 5. 解析响应
	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("解析响应失败: %s, 原始响应: %s", err.Error(), string(body))
	}

	// 6. 如果登录成功，添加服务器信息到响应中
	fmt.Printf("[Login] 解析后的 result: %+v\n", result)
	if errCode, ok := result["errCode"].(float64); ok && errCode == 0 {
		fmt.Printf("[Login] 登录成功，errCode=%v，准备添加服务器信息\n", errCode)
		if data, ok := result["data"].(map[string]interface{}); ok {
			fmt.Printf("[Login] data 字段存在: %+v\n", data)
			// 添加服务器信息到响应中
			data["serverInfo"] = map[string]interface{}{
				"serverID":   serverInfo.ServerID,
				"serverName": serverInfo.ServerName,
				"domains":    serverInfo.Domains,
			}
			fmt.Printf("[Login] 添加服务器信息后的 data: %+v\n", data)
		} else {
			fmt.Printf("[Login] data 字段不存在或类型不匹配\n")
		}
	} else {
		fmt.Printf("[Login] 登录失败或 errCode 解析失败，errCode=%v, ok=%v\n", errCode, ok)
	}

	// 7. 返回增强后的响应
	return result, nil
}
