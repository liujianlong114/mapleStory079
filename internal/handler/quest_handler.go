package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/service"
)

type QuestHandler struct {
	quests *service.QuestService
}

func NewQuestHandler() *QuestHandler {
	return &QuestHandler{quests: service.NewQuestService()}
}

func (h *QuestHandler) ListByCharacter(c *gin.Context) {
	charID, err := strconv.ParseUint(c.Param("characterId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid character id"})
		return
	}
	list, err := h.quests.ListCharacterQuests(uint(charID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "quests": list})
}

func (h *QuestHandler) Accept(c *gin.Context) {
	var req struct {
		CharacterID uint `json:"character_id" binding:"required"`
		QuestID     uint `json:"quest_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	cq, err := h.quests.AcceptQuest(req.CharacterID, req.QuestID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "quest": cq})
}
