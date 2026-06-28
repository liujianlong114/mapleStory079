package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/repository"
	"mapleStory079/internal/service"
)

type EquipHandler struct {
	svc *service.EquipService
}

func NewEquipHandler() *EquipHandler {
	return &EquipHandler{svc: service.NewEquipService()}
}

// List 获取角色已装备物品
func (h *EquipHandler) List(c *gin.Context) {
	charID, err := strconv.ParseUint(c.Param("characterId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid character id"})
		return
	}
	items, err := h.svc.GetEquippedWithDetails(uint(charID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "equipped": items, "count": len(items)})
}

type equipRequest struct {
	CharacterID uint `json:"character_id" binding:"required"`
	ItemID      int  `json:"item_id" binding:"required"`
}

// Equip 装备物品
func (h *EquipHandler) Equip(c *gin.Context) {
	var req equipRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	detail, err := h.svc.EquipItem(req.CharacterID, req.ItemID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}

	stats, _ := h.svc.GetEquippedStats(req.CharacterID)
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "装备成功",
		"item":    detail,
		"stats":   stats,
	})
}

// Unequip 卸下装备
func (h *EquipHandler) Unequip(c *gin.Context) {
	var req equipRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	if err := h.svc.UnequipItem(req.CharacterID, req.ItemID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}

	stats, _ := h.svc.GetEquippedStats(req.CharacterID)
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "卸下成功",
		"stats":   stats,
	})
}

// Stats 获取角色总属性（基础 + 装备加成）
func (h *EquipHandler) Stats(c *gin.Context) {
	charID, err := strconv.ParseUint(c.Param("characterId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid character id"})
		return
	}

	character, err := repository.GetCharacterByID(uint(charID))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": err.Error()})
		return
	}

	totalStats, err := h.svc.GetTotalStats(character)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "stats": totalStats})
}

// SlotInfo 获取物品的装备槽位信息
func (h *EquipHandler) SlotInfo(c *gin.Context) {
	itemID, err := strconv.Atoi(c.Param("itemId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid item id"})
		return
	}
	slot := h.svc.GetEquipSlot(itemID)
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"item_id": itemID,
		"slot":    slot,
		"is_equipable": slot != "",
	})
}
