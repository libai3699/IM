package api

import (
	"fmt"
	"net/http"
	"openim-route-service/service"

	"github.com/gin-gonic/gin"
)

type Response struct {
	Code int         `json:"code"`
	Msg  string      `json:"msg"`
	Data interface{} `json:"data,omitempty"`
}

func success(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code: 0,
		Msg:  "success",
		Data: data,
	})
}

func fail(c *gin.Context, msg string) {
	c.JSON(http.StatusOK, Response{
		Code: -1,
		Msg:  msg,
	})
}

var verifyService *service.VerifyService
var registerService *service.RegisterService
var loginService *service.LoginService
var passwordService *service.PasswordService

func SetupRouter(verifyConfig service.VerifyConfig) *gin.Engine {
	r := gin.Default()

	// 添加 CORS 中间件
	r.Use(corsMiddleware())

	routeService := service.NewRouteService()
	verifyService = service.NewVerifyService(verifyConfig)
	registerService = service.NewRegisterService(verifyService)
	loginService = service.NewLoginService()
	passwordService = service.NewPasswordService(verifyService)

	// API 路由组
	api := r.Group("/api")
	{
		// 健康检查
		api.GET("/health", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"errCode": 0,
				"errMsg":  "",
				"errDlt":  "",
				"data":    gin.H{"status": "ok"},
			})
		})

		// 验证码相关接口
		verify := api.Group("/verify")
		{
			// 发送验证码
			verify.POST("/send", func(c *gin.Context) {
				var req struct {
					AreaCode    string `json:"areaCode"`
					PhoneNumber string `json:"phoneNumber"`
					UsedFor     int    `json:"usedFor"` // 1:注册 2:重置密码 3:登录
				}

				if err := c.ShouldBindJSON(&req); err != nil {
					fmt.Printf("[SendVerifyCode] 参数绑定失败: %v\n", err)
					// 返回标准错误格式（HTTP 200 + errCode）
					c.JSON(http.StatusOK, gin.H{
						"errCode": 400,
						"errMsg":  "",
						"errDlt":  "参数错误",
					})
					return
				}

				fmt.Printf("[SendVerifyCode] 收到请求 - 区号: %s, 手机号: %s, 用途: %d\n", req.AreaCode, req.PhoneNumber, req.UsedFor)

				if req.PhoneNumber == "" {
					// 返回标准错误格式（HTTP 200 + errCode）
					c.JSON(http.StatusOK, gin.H{
						"errCode": 400,
						"errMsg":  "",
						"errDlt":  "手机号不能为空",
					})
					return
				}

				// 根据使用场景进行不同的验证
				switch req.UsedFor {
				case 1: // 注册：检查用户是否已存在
					exists, err := registerService.CheckUserExists(req.PhoneNumber)
					if err != nil {
						// 返回标准错误格式（HTTP 200 + errCode）
						c.JSON(http.StatusOK, gin.H{
							"errCode": 500,
							"errMsg":  "",
							"errDlt":  "检查用户状态失败",
						})
						return
					}
					if exists {
						// 返回标准错误格式（HTTP 200 + errCode）
						c.JSON(http.StatusOK, gin.H{
							"errCode": 400,
							"errMsg":  "",
							"errDlt":  "该手机号已注册，请直接登录",
						})
						return
					}
				case 2: // 重置密码：检查用户是否存在
					exists, err := registerService.CheckUserExists(req.PhoneNumber)
					if err != nil {
						// 返回标准错误格式（HTTP 200 + errCode）
						c.JSON(http.StatusOK, gin.H{
							"errCode": 500,
							"errMsg":  "",
							"errDlt":  "检查用户状态失败",
						})
						return
					}
					if !exists {
						// 返回标准错误格式（HTTP 200 + errCode）
						c.JSON(http.StatusOK, gin.H{
							"errCode": 400,
							"errMsg":  "",
							"errDlt":  "该手机号未注册，请先注册",
						})
						return
					}
				case 3: // 登录：不需要检查
					// 登录验证码不需要检查用户是否存在
				}

				if err := verifyService.SendVerifyCode(req.PhoneNumber); err != nil {
					fmt.Printf("[SendVerifyCode] 发送失败: %v\n", err)
					// 返回标准错误格式（HTTP 200 + errCode）
					c.JSON(http.StatusOK, gin.H{
						"errCode": 500,
						"errMsg":  "",
						"errDlt":  err.Error(),
					})
					return
				}

				fmt.Printf("[SendVerifyCode] 发送成功\n")
				// 返回标准成功格式（HTTP 200 + errCode）
				c.JSON(http.StatusOK, gin.H{
					"errCode": 0,
					"errMsg":  "",
					"errDlt":  "",
				})
			})

			// 验证验证码
			verify.POST("/check", func(c *gin.Context) {
				var req struct {
					AreaCode    string `json:"areaCode"`
					PhoneNumber string `json:"phoneNumber"`
					VerifyCode  string `json:"verifyCode" binding:"required"`
				}

				if err := c.ShouldBindJSON(&req); err != nil {
					// 返回标准错误格式（HTTP 200 + errCode）
					c.JSON(http.StatusOK, gin.H{
						"errCode": 400,
						"errMsg":  "",
						"errDlt":  "参数错误",
					})
					return
				}

				if req.PhoneNumber == "" {
					// 返回标准错误格式（HTTP 200 + errCode）
					c.JSON(http.StatusOK, gin.H{
						"errCode": 400,
						"errMsg":  "",
						"errDlt":  "手机号不能为空",
					})
					return
				}

				if err := verifyService.VerifyCode(req.PhoneNumber, req.VerifyCode); err != nil {
					// 返回标准错误格式（HTTP 200 + errCode）
					c.JSON(http.StatusOK, gin.H{
						"errCode": 500,
						"errMsg":  "",
						"errDlt":  "验证码错误",
					})
					return
				}

				// 返回标准成功格式（HTTP 200 + errCode）
				c.JSON(http.StatusOK, gin.H{
					"errCode": 0,
					"errMsg":  "",
					"errDlt":  "",
				})
			})
		}

		// 注册和登录相关接口
		auth := api.Group("/auth")
		{
			// 注册用户
			auth.POST("/register", func(c *gin.Context) {
				var req service.RegisterRequest

				if err := c.ShouldBindJSON(&req); err != nil {
					// 返回标准错误格式（HTTP 200 + errCode）
					c.JSON(http.StatusOK, gin.H{
						"errCode": 400,
						"errMsg":  "",
						"errDlt":  "参数错误",
					})
					return
				}

				// 获取客户端传来的 operationID
				operationID := c.GetHeader("operationID")
				
				// 详细打印所有可能的 IP 来源
				fmt.Printf("[Register-Debug] ========== IP 信息调试 ==========\n")
				fmt.Printf("[Register-Debug] c.ClientIP(): %s\n", c.ClientIP())
				fmt.Printf("[Register-Debug] c.Request.RemoteAddr: %s\n", c.Request.RemoteAddr)
				fmt.Printf("[Register-Debug] X-Real-IP Header: %s\n", c.GetHeader("X-Real-IP"))
				fmt.Printf("[Register-Debug] X-Forwarded-For Header: %s\n", c.GetHeader("X-Forwarded-For"))
				fmt.Printf("[Register-Debug] X-Forwarded-Proto Header: %s\n", c.GetHeader("X-Forwarded-Proto"))
				fmt.Printf("[Register-Debug] =====================================\n")
				
				// 获取真实客户端IP
				clientIP := c.GetHeader("X-Real-IP")
				if clientIP == "" {
					clientIP = c.GetHeader("X-Forwarded-For")
					if clientIP == "" {
						clientIP = c.ClientIP()
					}
				}
				fmt.Printf("[Register] 最终使用的客户端IP: %s\n", clientIP)

				// 调用注册服务
				result, err := registerService.Register(&req, clientIP, operationID)
				if err != nil {
					// 返回标准错误格式（HTTP 200 + errCode）
					c.JSON(http.StatusOK, gin.H{
						"errCode": 500,
						"errMsg":  "",
						"errDlt":  err.Error(),
					})
					return
				}

				// 原样返回目标服务器的响应
				c.JSON(http.StatusOK, result)
			})

			// 用户登录
			auth.POST("/login", func(c *gin.Context) {
				var req service.LoginRequest

				if err := c.ShouldBindJSON(&req); err != nil {
					// 返回标准错误格式（HTTP 200 + errCode）
					c.JSON(http.StatusOK, gin.H{
						"errCode": 400,
						"errMsg":  "",
						"errDlt":  "参数错误",
					})
					return
				}

				// 获取客户端传来的 operationID
				operationID := c.GetHeader("operationID")
				
				// 详细打印所有可能的 IP 来源
				fmt.Printf("[Login-Debug] ========== IP 信息调试 ==========\n")
				fmt.Printf("[Login-Debug] c.ClientIP(): %s\n", c.ClientIP())
				fmt.Printf("[Login-Debug] c.Request.RemoteAddr: %s\n", c.Request.RemoteAddr)
				fmt.Printf("[Login-Debug] X-Real-IP Header: %s\n", c.GetHeader("X-Real-IP"))
				fmt.Printf("[Login-Debug] X-Forwarded-For Header: %s\n", c.GetHeader("X-Forwarded-For"))
				fmt.Printf("[Login-Debug] X-Forwarded-Proto Header: %s\n", c.GetHeader("X-Forwarded-Proto"))
				fmt.Printf("[Login-Debug] =====================================\n")
				
				// 获取真实客户端IP
				clientIP := c.GetHeader("X-Real-IP")
				if clientIP == "" {
					clientIP = c.GetHeader("X-Forwarded-For")
					if clientIP == "" {
						clientIP = c.ClientIP()
					}
				}
				fmt.Printf("[Login] 最终使用的客户端IP: %s\n", clientIP)

				// 调用登录服务
				result, err := loginService.Login(&req, clientIP, operationID)
				if err != nil {
					// 返回标准错误格式（HTTP 200 + errCode）
					c.JSON(http.StatusOK, gin.H{
						"errCode": 500,
						"errMsg":  "",
						"errDlt":  err.Error(),
					})
					return
				}

				// 原样返回目标服务器的响应
				c.JSON(http.StatusOK, result)
			})

			// 重置密码
			auth.POST("/reset-password", func(c *gin.Context) {
				var req service.ResetPasswordRequest

				if err := c.ShouldBindJSON(&req); err != nil {
					// 返回标准错误格式（HTTP 200 + errCode）
					c.JSON(http.StatusOK, gin.H{
						"errCode": 400,
						"errMsg":  "",
						"errDlt":  "参数错误",
					})
					return
				}

				// 获取客户端传来的 operationID
				operationID := c.GetHeader("operationID")
				
				// 获取真实客户端IP
				clientIP := c.GetHeader("X-Real-IP")
				if clientIP == "" {
					clientIP = c.GetHeader("X-Forwarded-For")
					if clientIP == "" {
						clientIP = c.ClientIP()
					}
				}

				// 调用密码服务
				result, err := passwordService.ResetPassword(&req, clientIP, operationID)
				if err != nil {
					// 返回标准错误格式（HTTP 200 + errCode）
					c.JSON(http.StatusOK, gin.H{
						"errCode": 500,
						"errMsg":  "",
						"errDlt":  err.Error(),
					})
					return
				}

				// 原样返回目标服务器的响应
				c.JSON(http.StatusOK, result)
			})
		}

		// 客户端配置接口（未登录时也可访问）
		api.POST("/client_config/get", func(c *gin.Context) {
			// 返回默认配置
			config := gin.H{
				"discoverPageURL":            "",                // 发现页URL
				"ordinaryUserAddFriend":      1,                 // 普通用户是否可以添加好友 1=可以 0=不可以
				"bossUserID":                 "",                // 管理员用户ID
				"adminURL":                   "",                // 管理后台URL
				"allowSendMsgNotFriend":      1,                 // 是否允许非好友发消息 1=允许 0=不允许
				"needInvitationCodeRegister": 0,                 // 是否需要邀请码注册 1=需要 0=不需要
				"robots":                     []interface{}{},   // 机器人列表
			}
			
			// 返回标准成功格式（HTTP 200 + errCode）
			c.JSON(http.StatusOK, gin.H{
				"errCode": 0,
				"errMsg":  "",
				"errDlt":  "",
				"data":    gin.H{"config": config},
			})
		})

		// 路由相关接口
		route := api.Group("/route")
		{
			// 根据邀请码获取服务器配置
			route.GET("/server", func(c *gin.Context) {
				code := c.Query("code")
				userID := c.Query("user_id")

				if code != "" {
					// 通过邀请码查询
					server, err := routeService.GetServerByInviteCode(code)
					if err != nil {
						c.JSON(http.StatusOK, gin.H{
							"errCode": 500,
							"errMsg":  "",
							"errDlt":  err.Error(),
						})
						return
					}
					c.JSON(http.StatusOK, gin.H{
						"errCode": 0,
						"errMsg":  "",
						"errDlt":  "",
						"data":    server,
					})
					return
				}

				if userID != "" {
					// 通过用户ID查询
					server, err := routeService.GetServerByUserID(userID)
					if err != nil {
						c.JSON(http.StatusOK, gin.H{
							"errCode": 500,
							"errMsg":  "",
							"errDlt":  err.Error(),
						})
						return
					}
					c.JSON(http.StatusOK, gin.H{
						"errCode": 0,
						"errMsg":  "",
						"errDlt":  "",
						"data":    server,
					})
					return
				}

				c.JSON(http.StatusOK, gin.H{
					"errCode": 400,
					"errMsg":  "",
					"errDlt":  "请提供邀请码或用户ID",
				})
			})

			// 绑定用户到服务器
			route.POST("/bind", func(c *gin.Context) {
				var req struct {
					UserID     string `json:"user_id" binding:"required"`
					ServerID   string `json:"server_id" binding:"required"`
					InviteCode string `json:"invite_code"`
				}

				if err := c.ShouldBindJSON(&req); err != nil {
					c.JSON(http.StatusOK, gin.H{
						"errCode": 400,
						"errMsg":  "",
						"errDlt":  "参数错误",
					})
					return
				}

				if err := routeService.BindUserToServer(req.UserID, req.ServerID, req.InviteCode); err != nil {
					c.JSON(http.StatusOK, gin.H{
						"errCode": 500,
						"errMsg":  "",
						"errDlt":  err.Error(),
					})
					return
				}

				c.JSON(http.StatusOK, gin.H{
					"errCode": 0,
					"errMsg":  "",
					"errDlt":  "",
				})
			})

			// 获取所有可用服务器
			route.GET("/servers", func(c *gin.Context) {
				servers, err := routeService.GetAllServers()
				if err != nil {
					c.JSON(http.StatusOK, gin.H{
						"errCode": 500,
						"errMsg":  "",
						"errDlt":  "获取服务器列表失败",
					})
					return
				}
				c.JSON(http.StatusOK, gin.H{
					"errCode": 0,
					"errMsg":  "",
					"errDlt":  "",
					"data":    servers,
				})
			})
		}
	}

	return r
}

// CORS 中间件
func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With, operationID")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}
