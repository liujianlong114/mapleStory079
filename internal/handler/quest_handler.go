package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/service"
)

type QuestHandler struct {
	qs *service.QuestService
}

func NewQuestHandler() *QuestHandler {
	return &QuestHandler{qs: service.DefaultQuestService}
}

func (h *QuestHandler) ListCharacterQuests(c *gin.Context) {
	charID, err := strconv.ParseUint(c.Param("characterId"), 10, 64)
	if err != nil || charID == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid character id"})
		return
	}
	quests, err := h.qs.ListCharacterQuests(uint(charID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": quests})
}

func (h *QuestHandler) Accept(c *gin.Context) {
	var req struct {
		CharacterID uint `json:"character_id" binding:"required"`
		QuestID     uint `json:"quest_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	if err := h.qs.AcceptQuest(req.CharacterID, req.QuestID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "quest_id": req.QuestID})
}

func (h *QuestHandler) Complete(c *gin.Context) {
	var req struct {
		CharacterID uint `json:"character_id" binding:"required"`
		QuestID     uint `json:"quest_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	effect, err := h.qs.CompleteQuest(req.CharacterID, req.QuestID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "effects": effect})
}
