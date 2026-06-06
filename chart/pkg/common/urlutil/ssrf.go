// Package urlutil 提供 URL 安全校验工具，防止 SSRF 攻击。
package urlutil

import (
	"net"
	"net/url"
	"strings"

	"github.com/OpenIMSDK/tools/errs"
)

// privateCIDRs 内网/保留 IP 段列表
var privateCIDRs []*net.IPNet

func init() {
	blocks := []string{
		"0.0.0.0/8",      // 未分配
		"10.0.0.0/8",     // RFC1918 A 类私有
		"100.64.0.0/10",  // Shared Address Space (RFC6598)
		"127.0.0.0/8",    // 回环地址
		"169.254.0.0/16", // 链路本地（AWS/GCP 元数据服务）
		"172.16.0.0/12",  // RFC1918 B 类私有
		"192.168.0.0/16", // RFC1918 C 类私有
		"::1/128",        // IPv6 回环
		"fc00::/7",       // IPv6 唯一本地
		"fe80::/10",      // IPv6 链路本地
	}
	for _, block := range blocks {
		_, cidr, err := net.ParseCIDR(block)
		if err == nil {
			privateCIDRs = append(privateCIDRs, cidr)
		}
	}
}

// isPrivateIP 检查 IP 是否属于内网/保留地址段
func isPrivateIP(ip net.IP) bool {
	for _, cidr := range privateCIDRs {
		if cidr.Contains(ip) {
			return true
		}
	}
	return false
}

// ValidateURL 对外链 URL 做安全校验，防止 SSRF。
// 校验规则：
//  1. 协议必须是 http 或 https
//  2. URL 长度不超过 2048 字符
//  3. 不允许直接使用内网/保留 IP 地址
func ValidateURL(rawURL string) error {
	if rawURL == "" {
		return nil
	}
	if len(rawURL) > 2048 {
		return errs.ErrArgs.Wrap("URL 长度超过限制（最大 2048 字符）")
	}

	u, err := url.Parse(rawURL)
	if err != nil {
		return errs.ErrArgs.Wrap("URL 格式不合法")
	}

	scheme := strings.ToLower(u.Scheme)
	if scheme != "http" && scheme != "https" {
		return errs.ErrArgs.Wrap("URL 仅支持 http 和 https 协议，当前协议：" + u.Scheme)
	}

	host := u.Hostname()
	if host == "" {
		return errs.ErrArgs.Wrap("URL 缺少主机名")
	}

	// 如果 host 是直接的 IP 地址，检查是否为内网 IP
	if ip := net.ParseIP(host); ip != nil {
		if isPrivateIP(ip) {
			return errs.ErrArgs.Wrap("URL 不允许指向内网地址")
		}
	}
	// 域名形式：不在此处做 DNS 解析，依赖域名白名单机制防止进一步 SSRF

	return nil
}

// ExtractHostname 从 URL 中提取主机名（不含端口号），用于白名单比对。
func ExtractHostname(rawURL string) string {
	u, err := url.Parse(rawURL)
	if err != nil {
		return ""
	}
	return u.Hostname()
}
