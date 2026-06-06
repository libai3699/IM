package model

import "time"

// ServerConfig 服务器配置
type ServerConfig struct {
	ID           int64     `json:"id" gorm:"primaryKey;autoIncrement"`
	ServerID     string    `json:"server_id" gorm:"uniqueIndex;size:50;not null"`
	ServerName   string    `json:"server_name" gorm:"size:100;not null"`
	Domains      string    `json:"domains" gorm:"type:text;not null"` // 主域名列表（逗号分隔）
	IsDefault    int8      `json:"is_default" gorm:"default:0;index"` // 是否默认服务器
	Status       int8      `json:"status" gorm:"default:1;index"`
	MaxUsers     int       `json:"max_users" gorm:"default:0"`
	CurrentUsers int       `json:"current_users" gorm:"default:0"`
	Description  string    `json:"description" gorm:"size:500"`
	CreatedAt    time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt    time.Time `json:"updated_at" gorm:"autoUpdateTime"`
}

func (ServerConfig) TableName() string {
	return "server_config"
}

// InviteCode 邀请码
type InviteCode struct {
	ID          int64      `json:"id" gorm:"primaryKey;autoIncrement"`
	Code        string     `json:"code" gorm:"uniqueIndex;size:50;not null"`
	ServerID    string     `json:"server_id" gorm:"index;size:50;not null"`
	MaxUseCount int        `json:"max_use_count" gorm:"default:0"`
	UsedCount   int        `json:"used_count" gorm:"default:0"`
	ExpireTime  *time.Time `json:"expire_time"`
	Status      int8       `json:"status" gorm:"default:1;index"`
	CreatedBy   string     `json:"created_by" gorm:"size:50"`
	Remark      string     `json:"remark" gorm:"size:500"`
	CreatedAt   time.Time  `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt   time.Time  `json:"updated_at" gorm:"autoUpdateTime"`
}

func (InviteCode) TableName() string {
	return "invite_code"
}

// UserServerBinding 用户服务器绑定
type UserServerBinding struct {
	ID            int64      `json:"id" gorm:"primaryKey;autoIncrement"`
	UserID        string     `json:"user_id" gorm:"uniqueIndex;size:50;not null"`
	ServerID      string     `json:"server_id" gorm:"index;size:50;not null"`
	InviteCode    string     `json:"invite_code" gorm:"index;size:50"`
	BindTime      time.Time  `json:"bind_time" gorm:"autoCreateTime"`
	LastLoginTime *time.Time `json:"last_login_time"`
	CreatedAt     time.Time  `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt     time.Time  `json:"updated_at" gorm:"autoUpdateTime"`
}

func (UserServerBinding) TableName() string {
	return "user_server_binding"
}

// RouteResponse 路由响应
type RouteResponse struct {
	ServerID   string   `json:"server_id"`
	ServerName string   `json:"server_name"`
	Domains    []string `json:"domains"` // 主域名列表，前端自行拼接路径
}
