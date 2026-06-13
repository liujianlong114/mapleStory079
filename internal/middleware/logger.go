package middleware

import (
	"time"

	"github.com/gin-gonic/gin"
)

func LoggerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		method := c.Request.Method

		c.Next()

		latency := time.Since(start)
		statusCode := c.Writer.Status()
		clientIP := c.ClientIP()

		gin.DefaultWriter.Write([]byte(
			"[" + time.Now().Format("2006-01-02 15:04:05") + "] " +
				clientIP + " " + method + " " + path + " " +
				"status=" + itoa(statusCode) + " " +
				"latency=" + latency.String() + "\n",
		))
	}
}

func StructuredLoggerMiddleware() gin.HandlerFunc {
	return gin.Logger()
}
