package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/service"
)

type InventoryHandler struct {
	svc *service.InventoryService
}

func NewInventoryHandler() *InventoryHandler {
	return &InventoryHandler{svc: service.NewInventoryService()}
}

type inventoryAddRequest struct {
	CharacterID uint `json:"characterId" binding:"required"`
	ItemID      int  `json:"itemId" binding:"required"`
	Quantity    int  `json:"quantity" binding:"required"`
}

func (h *InventoryHandler) Add(c *gin.Context) {
	var req inventoryAddRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	if err := h.svc.AddItem(req.CharacterID, req.ItemID, req.Quantity); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

func (h *InventoryHandler) Remove(c *gin.Context) {
	var req inventoryAddRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	if err := h.svc.RemoveItem(req.CharacterID, req.ItemID, req.Quantity); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

func (h *InventoryHandler) List(c *gin.Context) {
	accountIDStr := c.Query("characterId")
	id, err := strconv.ParseUint(accountIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid character id"})
		return
	}
	items, err := h.svc.GetInventory(uint(id))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": items})
}
