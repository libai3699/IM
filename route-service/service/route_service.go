package service

import (
	"errors"
	"openim-route-service/db"
	"openim-route-service/model"
	"strings"
	"time"
)

type RouteService struct{}

func NewRouteService() *RouteService {
	return &RouteService{}
}

// GetServerByInviteCode 根据邀请码获取服务器配置（邀请码为空时返回默认服务器）
func (s *RouteService) GetServerByInviteCode(code string) (*model.RouteResponse, error) {
	var serverConfig model.ServerConfig

	// 如果邀请码为空，返回默认服务器
	if code == "" {
		if err := db.DB.Where("is_default = 1 AND status = 1").First(&serverConfig).Error; err != nil {
			return nil, errors.New("未配置默认服务器")
		}
	} else {
		// 查询邀请码
		var inviteCode model.InviteCode
		if err := db.DB.Where("code = ? AND status = 1", code).First(&inviteCode).Error; err != nil {
			return nil, errors.New("邀请码不存在或已禁用")
		}

		// 检查是否过期
		if inviteCode.ExpireTime != nil && inviteCode.ExpireTime.Before(time.Now()) {
			return nil, errors.New("邀请码已过期")
		}

		// 检查使用次数
		if inviteCode.MaxUseCount > 0 && inviteCode.UsedCount >= inviteCode.MaxUseCount {
			return nil, errors.New("邀请码已达到最大使用次数")
		}

		// 查询服务器配置
		if err := db.DB.Where("server_id = ? AND status = 1", inviteCode.ServerID).First(&serverConfig).Error; err != nil {
			return nil, errors.New("服务器配置不存在或已禁用")
		}

		// 检查服务器用户数限制
		if serverConfig.MaxUsers > 0 && serverConfig.CurrentUsers >= serverConfig.MaxUsers {
			return nil, errors.New("服务器已达到最大用户数")
		}
	}

	// 解析逗号分隔的域名并清理
	domains := parseDomains(serverConfig.Domains)
	if len(domains) == 0 {
		return nil, errors.New("服务器配置错误：没有可用域名")
	}

	return &model.RouteResponse{
		ServerID:   serverConfig.ServerID,
		ServerName: serverConfig.ServerName,
		Domains:    domains,
	}, nil
}

// GetServerByUserID 根据用户ID获取服务器配置
func (s *RouteService) GetServerByUserID(userID string) (*model.RouteResponse, error) {
	var binding model.UserServerBinding
	
	// 查询用户绑定
	if err := db.DB.Where("user_id = ?", userID).First(&binding).Error; err != nil {
		return nil, errors.New("用户未绑定服务器")
	}

	// 更新最后登录时间
	now := time.Now()
	db.DB.Model(&binding).Update("last_login_time", now)

	// 查询服务器配置
	var serverConfig model.ServerConfig
	if err := db.DB.Where("server_id = ? AND status = 1", binding.ServerID).First(&serverConfig).Error; err != nil {
		return nil, errors.New("服务器配置不存在或已禁用")
	}

	// 解析逗号分隔的域名并清理
	domains := parseDomains(serverConfig.Domains)
	if len(domains) == 0 {
		return nil, errors.New("服务器配置错误：没有可用域名")
	}

	return &model.RouteResponse{
		ServerID:   serverConfig.ServerID,
		ServerName: serverConfig.ServerName,
		Domains:    domains,
	}, nil
}

// BindUserToServer 绑定用户到服务器
func (s *RouteService) BindUserToServer(userID, serverID, inviteCode string) error {
	// 检查是否已绑定
	var count int64
	db.DB.Model(&model.UserServerBinding{}).Where("user_id = ?", userID).Count(&count)
	if count > 0 {
		return errors.New("用户已绑定服务器")
	}

	// 创建绑定记录
	binding := model.UserServerBinding{
		UserID:     userID,
		ServerID:   serverID,
		InviteCode: inviteCode,
		BindTime:   time.Now(),
	}

	if err := db.DB.Create(&binding).Error; err != nil {
		return errors.New("绑定失败")
	}

	// 更新邀请码使用次数
	if inviteCode != "" {
		db.DB.Model(&model.InviteCode{}).
			Where("code = ?", inviteCode).
			Update("used_count", db.DB.Raw("used_count + 1"))
	}

	// 更新服务器当前用户数
	db.DB.Model(&model.ServerConfig{}).
		Where("server_id = ?", serverID).
		Update("current_users", db.DB.Raw("current_users + 1"))

	return nil
}

// GetAllServers 获取所有可用服务器
func (s *RouteService) GetAllServers() ([]model.ServerConfig, error) {
	var servers []model.ServerConfig
	if err := db.DB.Where("status = 1").Find(&servers).Error; err != nil {
		return nil, err
	}
	return servers, nil
}

// parseDomains 解析逗号分隔的域名字符串
func parseDomains(domainsStr string) []string {
	if domainsStr == "" {
		return []string{}
	}

	// 按逗号分隔
	parts := strings.Split(domainsStr, ",")
	domains := make([]string, 0, len(parts))

	for _, part := range parts {
		// 去除空格和协议前缀
		domain := strings.TrimSpace(part)
		domain = stripProtocol(domain)
		
		if domain != "" {
			domains = append(domains, domain)
		}
	}

	return domains
}

// stripProtocol 去掉域名的协议前缀
func stripProtocol(domain string) string {
	domain = strings.TrimPrefix(domain, "https://")
	domain = strings.TrimPrefix(domain, "http://")
	domain = strings.TrimSuffix(domain, "/")
	return domain
}
