package utils

import (
	"crypto/rand"
	"encoding/base64"
	"time"
)

func GenerateSecureToken(length int) string {
	b := make([]byte, length)
	if _, err := rand.Read(b); err != nil {
		return GenerateRandomString(length)
	}
	return base64.URLEncoding.EncodeToString(b)[:length]
}

func GenerateSessionIdentifier(userID uint) string {
	return "sess_" + itoa(int(userID)) + "_" + GenerateSecureToken(24) + "_" + itoa(int(time.Now().Unix()))
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	var buf [20]byte
	i := len(buf)
	for n > 0 {
		i--
		buf[i] = byte('0' + n%10)
		n /= 10
	}
	return string(buf[i:])
}

// GenerateRandomString 返回指定长度的随机字符串（仅字母数字）。
// 若无法读取加密随机源，则回退到基于时间戳的伪随机生成。
func GenerateRandomString(length int) string {
	if length <= 0 {
		return ""
	}
	const alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	buf := make([]byte, length)
	if _, err := rand.Read(buf); err == nil {
		for i, b := range buf {
			buf[i] = alphabet[int(b)%len(alphabet)]
		}
		return string(buf)
	}
	// Fallback: 基于纳秒时间戳的简单轮换。
	seed := time.Now().UnixNano()
	for i := 0; i < length; i++ {
		seed = (seed*1103515245 + 12345) & 0x7fffffff
		buf[i] = alphabet[int(seed)%len(alphabet)]
	}
	return string(buf)
}

func itoa_uint(n uint) string {
	if n == 0 {
		return "0"
	}
	var buf [20]byte
	i := len(buf)
	for n > 0 {
		i--
		buf[i] = byte('0' + n%10)
		n /= 10
	}
	return string(buf[i:])
}

func NowTimestamp() int64 {
	return time.Now().Unix()
}

func ExpiresInHours(hours int) int64 {
	return time.Now().Add(time.Duration(hours) * time.Hour).Unix()
}

func IsExpired(expiresAt int64) bool {
	return time.Now().Unix() > expiresAt
}
