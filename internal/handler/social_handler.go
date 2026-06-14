package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/service"
)

// SocialHandler 负责公会/组队/好友等社交系统的 HTTP 接口。
//
// 设计目标：
//   - 与 chat_handler / skill_handler 等保持一致的结构风格
//   - 统一请求/响应结构体，避免匿名 struct 散落在 router 注册处
//   - 业务逻辑全部委托给 service 层，handler 只负责参数绑定与响应格式
type SocialHandler struct {
	guildSvc  *service.GuildService
	partySvc  *service.PartyService
	friendSvc *service.FriendService
}

// NewSocialHandler 创建社交系统处理器。
func NewSocialHandler() *SocialHandler {
	return &SocialHandler{
		guildSvc:  service.NewGuildService(),
		partySvc:  service.NewPartyService(),
		friendSvc: service.NewFriendService(),
	}
}

// ==================== 请求结构体 ====================

type guildCreateRequest struct {
	Name     string `json:"name" binding:"required,min=2,max=20"`
	MasterID uint   `json:"master_id" binding:"required,min=1"`
}

type guildJoinRequest struct {
	CharacterID uint `json:"character_id" binding:"required,min=1"`
}

type partyCreateRequest struct {
	LeaderID uint `json:"leader_id" binding:"required,min=1"`
}

type partyMemberRequest struct {
	CharacterID uint `json:"character_id" binding:"required,min=1"`
}

type friendAddRequest struct {
	CharacterID uint   `json:"character_id" binding:"required,min=1"`
	FriendID    uint   `json:"friend_id" binding:"required,min=1"`
	Group       string `json:"group"`
}

type friendRemoveRequest struct {
	FriendID uint `json:"friend_id" binding:"required,min=1"`
}

// ==================== 公会接口 ====================

// CreateGuild 创建公会。
func (h *SocialHandler) CreateGuild(c *gin.Context) {
	var req guildCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	guild, err := h.guildSvc.Create(req.Name, req.MasterID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": guild})
}

// JoinGuild 加入公会。
func (h *SocialHandler) JoinGuild(c *gin.Context) {
	guildID := parseUintOrZero(c.Param("id"))
	var req guildJoinRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	if err := h.guildSvc.Join(uint(guildID), req.CharacterID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

// LeaveGuild 离开公会。
func (h *SocialHandler) LeaveGuild(c *gin.Context) {
	guildID := parseUintOrZero(c.Param("id"))
	var req guildJoinRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	if err := h.guildSvc.Leave(uint(guildID), req.CharacterID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

// ==================== 组队接口 ====================

// CreateParty 创建组队。
func (h *SocialHandler) CreateParty(c *gin.Context) {
	var req partyCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	party, err := h.partySvc.Create(req.LeaderID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": party})
}

// AcceptParty 接受组队邀请。
func (h *SocialHandler) AcceptParty(c *gin.Context) {
	partyID := parseUintOrZero(c.Param("id"))
	var req partyMemberRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	if err := h.partySvc.Accept(uint(partyID), req.CharacterID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

// LeaveParty 离开组队。
func (h *SocialHandler) LeaveParty(c *gin.Context) {
	partyID := parseUintOrZero(c.Param("id"))
	var req partyMemberRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	if err := h.partySvc.Leave(uint(partyID), req.CharacterID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

// ==================== 好友接口 ====================

// AddFriend 添加好友。
func (h *SocialHandler) AddFriend(c *gin.Context) {
	var req friendAddRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	friend, err := h.friendSvc.Add(req.CharacterID, req.FriendID, req.Group)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": friend})
}

// ListFriends 列出好友。
func (h *SocialHandler) ListFriends(c *gin.Context) {
	characterID := parseUintOrZero(c.Param("id"))
	list, err := h.friendSvc.List(uint(characterID))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": list})
}

// RemoveFriend 删除好友。
func (h *SocialHandler) RemoveFriend(c *gin.Context) {
	characterID := parseUintOrZero(c.Param("id"))
	var req friendRemoveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	if err := h.friendSvc.Remove(uint(characterID), req.FriendID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}
