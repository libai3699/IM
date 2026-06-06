package cache

import (
	"context"
	"fmt"
	"time"

	"github.com/go-redis/redis/v8"
)

var RedisClient *redis.Client

type RedisConfig struct {
	Address  string
	Password string
	DB       int
}

// InitRedis 初始化 Redis 连接
func InitRedis(config RedisConfig) error {
	RedisClient = redis.NewClient(&redis.Options{
		Addr:     config.Address,
		Password: config.Password,
		DB:       config.DB,
	})

	// 测试连接
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := RedisClient.Ping(ctx).Err(); err != nil {
		return fmt.Errorf("failed to connect redis: %w", err)
	}

	return nil
}

// SetVerifyCode 存储验证码
func SetVerifyCode(phone string, code string, expiration time.Duration) error {
	key := fmt.Sprintf("verify_code:%s", phone)
	ctx := context.Background()
	return RedisClient.Set(ctx, key, code, expiration).Err()
}

// GetVerifyCode 获取验证码
func GetVerifyCode(phone string) (string, error) {
	key := fmt.Sprintf("verify_code:%s", phone)
	ctx := context.Background()
	return RedisClient.Get(ctx, key).Result()
}

// DeleteVerifyCode 删除验证码
func DeleteVerifyCode(phone string) error {
	key := fmt.Sprintf("verify_code:%s", phone)
	ctx := context.Background()
	return RedisClient.Del(ctx, key).Err()
}

// Close 关闭 Redis 连接
func Close() error {
	if RedisClient != nil {
		return RedisClient.Close()
	}
	return nil
}
