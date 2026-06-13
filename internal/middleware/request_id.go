package middleware

import (
	"time"

	"github.com/gin-gonic/gin"
	"mapleStory079/pkg/utils"
)

func RequestIDMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetHeader("X-Request-ID")
		if requestID == "" {
			requestID = "req_" + time.Now().Format("20060102150405") + "_" + utils.GenerateRandomString(8)
		}
		c.Set("request_id", requestID)
		c.Writer.Header().Set("X-Request-ID", requestID)
		c.Next()
	}
}
