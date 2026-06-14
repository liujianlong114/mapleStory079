package middleware

import (
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

type rateLimiter struct {
	mu       sync.Mutex
	requests map[string][]time.Time
	limit    int
	window   time.Duration
}

var globalLimiter = newRateLimiter(60, time.Minute)
var authLimiter = newRateLimiter(10, time.Minute)

func newRateLimiter(limit int, window time.Duration) *rateLimiter {
	return &rateLimiter{
		requests: make(map[string][]time.Time),
		limit:    limit,
		window:   window,
	}
}

func (rl *rateLimiter) allow(key string) (bool, int, time.Duration) {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	windowStart := now.Add(-rl.window)

	// 清理过期的请求记录
	requests := rl.requests[key]
	valid := make([]time.Time, 0, len(requests))
	for _, t := range requests {
		if t.After(windowStart) {
			valid = append(valid, t)
		}
	}
	rl.requests[key] = valid

	remaining := rl.limit - len(valid)
	if remaining <= 0 {
		// 计算下一次允许请求的时间
		if len(valid) > 0 {
			retryAfter := valid[0].Add(rl.window).Sub(now)
			return false, 0, retryAfter
		}
		return false, 0, rl.window
	}

	rl.requests[key] = append(valid, now)
	return true, remaining - 1, 0
}

func RateLimitMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		key := c.ClientIP()
		allowed, remaining, retryAfter := globalLimiter.allow(key)

		c.Header("X-RateLimit-Limit", "60")
		c.Header("X-RateLimit-Remaining", strconv.Itoa(remaining))
		c.Header("X-RateLimit-Reset", time.Now().Add(time.Minute).Format(time.RFC3339))

		if !allowed {
			c.Header("Retry-After", retryAfter.Truncate(time.Second).String())
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":       "rate limit exceeded",
				"message":     "请求过于频繁，请稍后再试",
				"retry_after": retryAfter.Truncate(time.Second).Seconds(),
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

func AuthRateLimitMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		key := c.ClientIP() + ":" + c.Request.URL.Path
		allowed, remaining, retryAfter := authLimiter.allow(key)

		if !allowed {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":       "auth rate limit exceeded",
				"message":     "登录/注册请求过于频繁，请稍后再试",
				"retry_after": retryAfter.Truncate(time.Second).Seconds(),
			})
			c.Abort()
			return
		}

		_ = remaining
		c.Next()
	}
}

func StrictRateLimitMiddleware(limit int, window time.Duration) gin.HandlerFunc {
	limiter := newRateLimiter(limit, window)
	return func(c *gin.Context) {
		key := c.ClientIP()
		allowed, _, retryAfter := limiter.allow(key)
		if !allowed {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":       "too many requests",
				"retry_after": retryAfter.Truncate(time.Second).Seconds(),
			})
			c.Abort()
			return
		}
		c.Next()
	}
}
