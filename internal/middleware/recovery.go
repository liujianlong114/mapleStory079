package middleware

import (
	"fmt"
	"log"
	"net/http"
	"runtime/debug"

	"github.com/gin-gonic/gin"
)

// RecoveryMiddleware 捕获 handler 中可能出现的 panic，避免整个服务进程被拉倒。
//
// 在 handler panic 时，记录错误日志与堆栈，然后向客户端返回 500。
//
// 使用方式：
//
//	r := gin.New()
//	r.Use(middleware.RecoveryMiddleware())
func RecoveryMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if r := recover(); r != nil {
				stack := debug.Stack()
				log.Printf("[PANIC RECOVERED] path=%s method=%s error=%v\n%s",
					c.Request.URL.Path, c.Request.Method, r, stack)
				c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
					"error":   "Internal Server Error",
					"message": fmt.Sprintf("%v", r),
				})
			}
		}()
		c.Next()
	}
}
