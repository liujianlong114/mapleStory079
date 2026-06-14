package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/repository"
	"mapleStory079/internal/service"
)

type ShopHandler struct {
	svc *service.ShopService
}

func NewShopHandler() *ShopHandler {
	return &ShopHandler{svc: service.NewShopService()}
}

func (h *ShopHandler) List(c *gin.Context) {
	npcID, err := strconv.Atoi(c.Param("npcId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid npc id"})
		return
	}
	npc, err := repository.GetNPCByID(uint(npcID))
	if err != nil || !npc.HasShop {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "npc shop not found"})
		return
	}
	items, err := h.svc.ListItems(npcID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"npc_id":  npcID,
		"name":    npc.Name,
		"items":   items,
	})
}

type shopBuyRequest struct {
	CharacterID uint `json:"character_id" binding:"required"`
	ItemID      int  `json:"item_id" binding:"required"`
	Quantity    int  `json:"quantity"`
}

func (h *ShopHandler) Buy(c *gin.Context) {
	npcID, err := strconv.Atoi(c.Param("npcId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid npc id"})
		return
	}
	var req shopBuyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	qty := req.Quantity
	if qty < 1 {
		qty = 1
	}
	mesos, err := h.svc.Buy(req.CharacterID, npcID, req.ItemID, qty)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "mesos": mesos})
}
