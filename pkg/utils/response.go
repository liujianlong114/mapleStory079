package utils

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Response 统一响应结构
type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
	Time    int64       `json:"time"`
}

// OK 返回成功响应
func OK(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code:    0,
		Message: "ok",
		Data:    data,
		Time:    NowUnix(),
	})
}

// OKMessage 返回成功响应（带消息）
func OKMessage(c *gin.Context, message string, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code:    0,
		Message: message,
		Data:    data,
		Time:    NowUnix(),
	})
}

// Fail 返回失败响应
func Fail(c *gin.Context, httpCode int, message string) {
	c.JSON(httpCode, Response{
		Code:    httpCode,
		Message: message,
		Time:    NowUnix(),
	})
}

// BadRequest 返回 400 错误
func BadRequest(c *gin.Context, message string) {
	Fail(c, http.StatusBadRequest, message)
}

// NotFound 返回 404 错误
func NotFound(c *gin.Context, message string) {
	if message == "" {
		message = "not found"
	}
	Fail(c, http.StatusNotFound, message)
}

// Unauthorized 返回 401 错误
func Unauthorized(c *gin.Context, message string) {
	if message == "" {
		message = "unauthorized"
	}
	Fail(c, http.StatusUnauthorized, message)
}

// ServerError 返回 500 错误
func ServerError(c *gin.Context, message string) {
	if message == "" {
		message = "internal server error"
	}
	Fail(c, http.StatusInternalServerError, message)
}
