package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/repository"
	"mapleStory079/internal/service"
)

type QuestHandler struct {
	questSvc *service.QuestService
}

func NewQuestHandler() *QuestHandler {
	return &QuestHandler{questSvc: service.NewQuestService()}
}

func (h *QuestHandler) ListCharacterQuests(c *gin.Context) {
	charID, err := strconv.ParseUint(c.Param("characterId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid character id"})
		return
	}
	quests, err := h.questSvc.ListCharacterQuests(uint(charID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": quests})
}

type questActionRequest struct {
	CharacterID uint `json:"character_id" binding:"required"`
	QuestID     uint `json:"quest_id" binding:"required"`
}

func (h *QuestHandler) Accept(c *gin.Context) {
	var req questActionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	ch, err := repository.GetCharacterByID(req.CharacterID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "character not found"})
		return
	}
	cq, err := h.questSvc.AcceptQuest(req.CharacterID, req.QuestID, ch)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": cq})
}

func (h *QuestHandler) Complete(c *gin.Context) {
	var req questActionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	ch, err := repository.GetCharacterByID(req.CharacterID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "character not found"})
		return
	}
	effect, err := h.questSvc.CompleteQuest(req.CharacterID, req.QuestID, ch)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": effect, "character": ch})
}
