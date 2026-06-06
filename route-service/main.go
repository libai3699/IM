package main

import (
	"fmt"
	"log"
	"openim-route-service/api"
	"openim-route-service/cache"
	"openim-route-service/db"
	"openim-route-service/service"
	"openim-route-service/sms"
	"os"
	"os/signal"
	"syscall"

	"gopkg.in/yaml.v3"
)

type Config struct {
	Server struct {
		Port int    `yaml:"port"`
		Mode string `yaml:"mode"`
	} `yaml:"server"`
	MySQL struct {
		Host        string `yaml:"host"`
		Port        int    `yaml:"port"`
		Username    string `yaml:"username"`
		Password    string `yaml:"password"`
		Database    string `yaml:"database"`
		MaxOpenConn int    `yaml:"maxOpenConn"`
		MaxIdleConn int    `yaml:"maxIdleConn"`
		MaxLifeTime int    `yaml:"maxLifeTime"`
	} `yaml:"mysql"`
	VerifyCode struct {
		ValidTime   int    `yaml:"validTime"`
		Len         int    `yaml:"len"`
		SuperCode   string `yaml:"superCode"`
		ForwardCode string `yaml:"forwardCode"` // 转发给第三方的验证码
		Smsbao      struct {
			ApiUrl   string `yaml:"apiUrl"`
			Username string `yaml:"username"`
			Password string `yaml:"password"`
			SignName string `yaml:"signName"`
		} `yaml:"smsbao"`
	} `yaml:"verifyCode"`
	Redis struct {
		Address  string `yaml:"address"`
		Password string `yaml:"password"`
		DB       int    `yaml:"db"`
	} `yaml:"redis"`
}

func loadConfig() (*Config, error) {
	data, err := os.ReadFile("config.yaml")
	if err != nil {
		return nil, err
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, err
	}

	return &config, nil
}

func main() {
	log.Println("🚀 Starting OpenIM Route Service...")

	// 加载配置
	config, err := loadConfig()
	if err != nil {
		log.Fatalf("❌ Failed to load config: %v", err)
	}

	// 初始化数据库
	mysqlConfig := db.MySQLConfig{
		Host:        config.MySQL.Host,
		Port:        config.MySQL.Port,
		Username:    config.MySQL.Username,
		Password:    config.MySQL.Password,
		Database:    config.MySQL.Database,
		MaxOpenConn: config.MySQL.MaxOpenConn,
		MaxIdleConn: config.MySQL.MaxIdleConn,
		MaxLifeTime: config.MySQL.MaxLifeTime,
	}

	if err := db.InitMySQL(mysqlConfig); err != nil {
		log.Fatalf("❌ Failed to initialize MySQL: %v", err)
	}
	defer db.Close()

	// 初始化 Redis
	redisConfig := cache.RedisConfig{
		Address:  config.Redis.Address,
		Password: config.Redis.Password,
		DB:       config.Redis.DB,
	}

	if err := cache.InitRedis(redisConfig); err != nil {
		log.Fatalf("❌ Failed to initialize Redis: %v", err)
	}
	defer cache.Close()

	// 设置验证码配置
	verifyConfig := service.VerifyConfig{
		SmsbaoConfig: sms.SmsbaoConfig{
			ApiUrl:   config.VerifyCode.Smsbao.ApiUrl,
			Username: config.VerifyCode.Smsbao.Username,
			Password: config.VerifyCode.Smsbao.Password,
			SignName: config.VerifyCode.Smsbao.SignName,
		},
		CodeLength:  config.VerifyCode.Len,
		ValidTime:   config.VerifyCode.ValidTime,
		SuperCode:   config.VerifyCode.SuperCode,
		ForwardCode: config.VerifyCode.ForwardCode, // 转发验证码
	}

	// 设置路由
	router := api.SetupRouter(verifyConfig)

	// 启动服务器
	addr := fmt.Sprintf(":%d", config.Server.Port)
	log.Printf("✅ Server is running on http://localhost%s", addr)
	log.Println("📖 API Documentation:")
	log.Println("   GET  /api/health                    - 健康检查")
	log.Println("   POST /api/verify/send               - 发送验证码")
	log.Println("   POST /api/verify/check              - 验证验证码")
	log.Println("   POST /api/auth/register             - 注册用户（转发到目标服务器）")
	log.Println("   POST /api/auth/login                - 用户登录（转发到目标服务器）")
	log.Println("   POST /api/auth/reset-password       - 重置密码（转发到目标服务器）")
	log.Println("   GET  /api/route/server?code=xxx     - 根据邀请码获取服务器")
	log.Println("   GET  /api/route/server?user_id=xxx  - 根据用户ID获取服务器")
	log.Println("   POST /api/route/bind                - 绑定用户到服务器")
	log.Println("   GET  /api/route/servers             - 获取所有服务器")

	// 优雅关闭
	go func() {
		if err := router.Run(addr); err != nil {
			log.Fatalf("❌ Failed to start server: %v", err)
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("🛑 Shutting down server...")
	log.Println("✅ Server exited")
}
