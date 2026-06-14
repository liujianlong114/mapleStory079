package utils

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// ========== 业务错误码 ==========
// 通用：0 成功，100xx 客户端参数，200xx 鉴权，300xx 业务，500xx 服务端。
const (
	CodeOK               = 0
	CodeBadRequest       = 400
	CodeUnauthorized     = 401
	CodeForbidden        = 403
	CodeNotFound         = 404
	CodeInternalError    = 500
	CodeInvalidParameter = 10001
	CodeCharacterBanned  = 30001
	CodeInventoryFull    = 30002
	CodeSkillOnCooldown  = 30003
	CodeChatSensitive    = 30004
)

// Response 统一响应结构
type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
	Time    int64       `json:"time"`
}

// PageResponse 带分页信息的响应结构
type PageResponse struct {
	Total   int64       `json:"total"`
	Page    int         `json:"page"`
	Size    int         `json:"size"`
	Records interface{} `json:"records"`
}

// OK 返回成功响应
func OK(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code:    CodeOK,
		Message: "ok",
		Data:    data,
		Time:    NowUnix(),
	})
}

// OKMessage 返回成功响应（带消息）
func OKMessage(c *gin.Context, message string, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code:    CodeOK,
		Message: message,
		Data:    data,
		Time:    NowUnix(),
	})
}

// OKPage 返回分页列表
func OKPage(c *gin.Context, records interface{}, total int64, page, size int) {
	if page < 1 {
		page = 1
	}
	if size <= 0 {
		size = 20
	}
	c.JSON(http.StatusOK, Response{
		Code:    CodeOK,
		Message: "ok",
		Data: PageResponse{
			Total:   total,
			Page:    page,
			Size:    size,
			Records: records,
		},
		Time: NowUnix(),
	})
}

// Fail 返回失败响应（通用）
func Fail(c *gin.Context, httpCode int, message string) {
	c.JSON(httpCode, Response{
		Code:    httpCode,
		Message: message,
		Time:    NowUnix(),
	})
}

// FailWithCode 返回指定业务错误码
func FailWithCode(c *gin.Context, httpCode int, code int, message string) {
	c.JSON(httpCode, Response{
		Code:    code,
		Message: message,
		Time:    NowUnix(),
	})
}

// BadRequest 返回 400 错误
func BadRequest(c *gin.Context, message string) {
	FailWithCode(c, http.StatusBadRequest, CodeBadRequest, message)
}

// NotFound 返回 404 错误
func NotFound(c *gin.Context, message string) {
	if message == "" {
		message = "not found"
	}
	FailWithCode(c, http.StatusNotFound, CodeNotFound, message)
}

// Unauthorized 返回 401 错误
func Unauthorized(c *gin.Context, message string) {
	if message == "" {
		message = "unauthorized"
	}
	FailWithCode(c, http.StatusUnauthorized, CodeUnauthorized, message)
}

// Forbidden 返回 403 错误
func Forbidden(c *gin.Context, message string) {
	if message == "" {
		message = "forbidden"
	}
	FailWithCode(c, http.StatusForbidden, CodeForbidden, message)
}

// ServerError 返回 500 错误
func ServerError(c *gin.Context, message string) {
	if message == "" {
		message = "internal server error"
	}
	FailWithCode(c, http.StatusInternalServerError, CodeInternalError, message)
}
