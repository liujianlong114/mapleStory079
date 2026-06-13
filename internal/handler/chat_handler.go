package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/service"
)

type ChatHandler struct {
	svc *service.ChatService
}

func NewChatHandler() *ChatHandler { return &ChatHandler{svc: service.NewChatService()} }

type chatSendRequest struct {
	Channel string `json:"channel" binding:"required,oneof=world guild party private"`
	From    string `json:"from" binding:"required"`
	To      string `json:"to"`
	Content string `json:"content" binding:"required,max=255"`
}

func (h *ChatHandler) Send(c *gin.Context) {
	var req chatSendRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	msg := service.ChatMessage{
		Channel: req.Channel,
		From:    req.From,
		To:      req.To,
		Content: req.Content,
	}
	if err := h.svc.SendMessage(msg); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": msg})
}

func (h *ChatHandler) List(c *gin.Context) {
	channel := c.Query("channel")
	limit := 50
	if raw := c.Query("limit"); raw != "" {
		if n, err := parseInt(raw); err == nil && n > 0 && n <= 200 {
			limit = n
		}
	}
	msgs := h.svc.GetRecent(limit, channel)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": msgs})
}

func parseInt(s string) (int, error) {
	n := 0
	for _, r := range s {
		if r < '0' || r > '9' {
			return 0, nil
		}
		n = n*10 + int(r-'0')
	}
	return n, nil
}
