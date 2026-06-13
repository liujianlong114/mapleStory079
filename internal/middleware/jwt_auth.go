package middleware

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/spf13/viper"
	"mapleStory079/pkg/cache"
)

type TokenClaims struct {
	UserID    uint   `json:"user_id"`
	Username  string `json:"username"`
	SessionID string `json:"session_id"`
	IssuedAt  int64  `json:"iat"`
	ExpiresAt int64  `json:"exp"`
}

var defaultSecret = []byte("maplestory_079_default_secret_key_please_change")

func getSecret() []byte {
	secret := viper.GetString("server.tokenSecret")
	if secret == "" {
		return defaultSecret
	}
	return []byte(secret)
}

func generateToken(claims TokenClaims) string {
	payload := strings.Join([]string{
		itoa(int(claims.UserID)),
		claims.Username,
		claims.SessionID,
		itoa(int(claims.IssuedAt)),
		itoa(int(claims.ExpiresAt)),
	}, ".")

	mac := hmac.New(sha256.New, getSecret())
	mac.Write([]byte(payload))
	signature := hex.EncodeToString(mac.Sum(nil))

	return payload + "." + signature
}

func parseToken(token string) (*TokenClaims, bool) {
	parts := strings.Split(token, ".")
	if len(parts) != 6 {
		return nil, false
	}

	signature := parts[5]
	payload := strings.Join(parts[0:5], ".")

	mac := hmac.New(sha256.New, getSecret())
	mac.Write([]byte(payload))
	expected := hex.EncodeToString(mac.Sum(nil))

	if !hmac.Equal([]byte(signature), []byte(expected)) {
		return nil, false
	}

	expiresAt := atoi(parts[4])
	if time.Now().Unix() > int64(expiresAt) {
		return nil, false
	}

	claims := &TokenClaims{
		UserID:    uint(atoi(parts[0])),
		Username:  parts[1],
		SessionID: parts[2],
		IssuedAt:  int64(atoi(parts[3])),
		ExpiresAt: int64(expiresAt),
	}

	// 检查会话是否在黑名单中（登出/禁用）
	sessionKey := "session:blacklist:" + claims.SessionID
	if blocked, _ := cache.Exists(sessionKey); blocked {
		return nil, false
	}

	return claims, true
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	negative := false
	if n < 0 {
		negative = true
		n = -n
	}
	var buf [20]byte
	i := len(buf)
	for n > 0 {
		i--
		buf[i] = byte('0' + n%10)
		n /= 10
	}
	if negative {
		i--
		buf[i] = '-'
	}
	return string(buf[i:])
}

func atoi(s string) int {
	n := 0
	negative := false
	for i, c := range s {
		if i == 0 && c == '-' {
			negative = true
			continue
		}
		if c < '0' || c > '9' {
			return 0
		}
		n = n*10 + int(c-'0')
	}
	if negative {
		n = -n
	}
	return n
}

func JWTRequireMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			// 也支持从 query 参数读取（用于 WebSocket）
			if q := c.Query("token"); q != "" {
				authHeader = "Bearer " + q
			} else {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "authorization required"})
				c.Abort()
				return
			}
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid authorization format"})
			c.Abort()
			return
		}

		token := parts[1]
		claims, valid := parseToken(token)
		if !valid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid or expired token"})
			c.Abort()
			return
		}

		c.Set("user_id", claims.UserID)
		c.Set("username", claims.Username)
		c.Set("session_id", claims.SessionID)
		c.Next()
	}
}

func GenerateAuthToken(userID uint, username, sessionID string, durationSec int) string {
	now := time.Now().Unix()
	return generateToken(TokenClaims{
		UserID:    userID,
		Username:  username,
		SessionID: sessionID,
		IssuedAt:  now,
		ExpiresAt: now + int64(durationSec),
	})
}

func InvalidateToken(sessionID string) error {
	cache.Set("session:blacklist:"+sessionID, "1", 24*time.Hour)
	return nil
}
