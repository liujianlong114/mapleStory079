package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/service"
)

type NPCRequest struct {
	NPCID       uint   `json:"npcId" binding:"required"`
	CharacterID uint   `json:"characterId" binding:"required"`
	NodeID      string `json:"nodeId"`
	ChoiceIndex int    `json:"choiceIndex"`
}

type NPCHandler struct {
	svc *service.NPCService
}

func NewNPCHandler() *NPCHandler { return &NPCHandler{svc: service.NewNPCService()} }

func (h *NPCHandler) Start(c *gin.Context) {
	var req NPCRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	result, err := h.svc.StartDialogue(req.NPCID, req.CharacterID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": result})
}

func (h *NPCHandler) Continue(c *gin.Context) {
	var req NPCRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	result, err := h.svc.ContinueDialogue(req.NPCID, req.CharacterID, req.NodeID, req.ChoiceIndex)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": result})
}
