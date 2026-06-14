package handler

import (
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/middleware"
	"mapleStory079/internal/service"
	"mapleStory079/pkg/utils"
)

type AuthHandler struct {
	svc *service.AuthService
}

func NewAuthHandler() *AuthHandler {
	return &AuthHandler{svc: service.NewAuthService()}
}

type registerRequest struct {
	Username string `json:"username" binding:"required,min=3,max=32"`
	Password string `json:"password" binding:"required,min=6,max=64"`
	Email    string `json:"email"`
}

type loginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req registerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "参数错误: "+err.Error())
		return
	}
	if !utils.IsValidUsername(req.Username) {
		utils.BadRequest(c, "用户名格式不正确")
		return
	}
	if err := h.svc.Register(req.Username, req.Password, req.Email); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.OKMessage(c, "注册成功", gin.H{"username": req.Username})
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req loginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "参数错误: "+err.Error())
		return
	}
	acc, err := h.svc.Login(req.Username, req.Password)
	if err != nil {
		utils.Unauthorized(c, err.Error())
		return
	}
	// 生成会话 token 并返回
	sessionID := "sess_" + utils.GenerateRandomString(16)
	token := middleware.GenerateAuthToken(acc.ID, acc.Username, sessionID, 24*3600)

	utils.OK(c, gin.H{
		"account": gin.H{
			"id":       acc.ID,
			"username": acc.Username,
			"email":    acc.Email,
			"gender":   acc.Gender,
			"status":   acc.Status,
		},
		"token":      token,
		"session_id": sessionID,
		"expires_in": 24 * 3600,
	})
}

type setGenderRequest struct {
	AccountID uint `json:"accountId" binding:"required,min=1"`
	Gender    int  `json:"gender" binding:"required"`
}

func (h *AuthHandler) SetGender(c *gin.Context) {
	var req setGenderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "参数错误: "+err.Error())
		return
	}
	acc, err := h.svc.SetGender(req.AccountID, req.Gender)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.OK(c, gin.H{
		"account": gin.H{
			"id":       acc.ID,
			"username": acc.Username,
			"gender":   acc.Gender,
		},
	})
}

func (h *AuthHandler) Logout(c *gin.Context) {
	// 从 Authorization Header 或 token 参数中解析 sessionID 并加入黑名单
	auth := c.GetHeader("Authorization")
	if idx := strings.Index(auth, " "); idx > 0 {
		auth = auth[idx+1:]
	}
	if auth == "" {
		auth = c.Query("token")
	}
	if auth == "" {
		utils.BadRequest(c, "未提供 token")
		return
	}
	sessionID := c.GetString("session_id")
	if sessionID == "" {
		sessionID = "logout_" + utils.GenerateRandomString(12)
	}
	if err := middleware.InvalidateToken(sessionID); err != nil {
		utils.ServerError(c, "登出失败: "+err.Error())
		return
	}
	utils.OKMessage(c, "已登出", nil)
}

func (h *AuthHandler) Me(c *gin.Context) {
	userID, _ := c.Get("user_id")
	username, _ := c.Get("username")
	id, _ := strconv.Atoi(utils.FirstNotEmpty(utils.ToString(userID), "0"))
	utils.OK(c, gin.H{
		"user_id":  id,
		"username": username,
	})
}
