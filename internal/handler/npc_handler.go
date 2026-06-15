package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/service"
)

type NPCRequest struct {
	NPCID       uint   `json:"npcId" binding:"required"`
	CharacterID uint   `json:"characterId" binding:"required"`
	NodeID      string `json:"nodeId"`
	ChoiceIndex int    `json:"choiceIndex"`
	NextID      string `json:"nextId"`
}

type NPCInteractRequest struct {
	CharacterID uint   `json:"character_id"`
	Action      string `json:"action"`
}

type NPCHandler struct {
	svc     *service.NPCService
	gameSvc *service.GameService
}

func NewNPCHandler() *NPCHandler {
	return &NPCHandler{
		svc:     service.NewNPCService(),
		gameSvc: service.NewGameService(),
	}
}

func (h *NPCHandler) ListByMap(c *gin.Context) {
	mapID, err := strconv.ParseUint(c.Param("mapId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid map id"})
		return
	}
	npcs, err := h.gameSvc.GetNPCsByMap(uint(mapID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"npcs": npcs})
}

func (h *NPCHandler) GetByID(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid npc id"})
		return
	}
	var req NPCInteractRequest
	_ = c.ShouldBindJSON(&req)
	characterID := req.CharacterID
	if characterID == 0 {
		characterID = 1
	}
	result, err := h.svc.StartDialogue(uint(id), characterID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": result})
}

func (h *NPCHandler) Interact(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid npc id"})
		return
	}
	var req NPCInteractRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.CharacterID == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "character_id required"})
		return
	}
	result, err := h.svc.StartDialogue(uint(id), req.CharacterID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": result, "action": req.Action})
}

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
	result, err := h.svc.ContinueDialogue(req.NPCID, req.CharacterID, req.NodeID, req.ChoiceIndex, req.NextID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": result})
}
