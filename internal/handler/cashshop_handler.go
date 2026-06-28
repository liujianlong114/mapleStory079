package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/service"
)

type CashShopHandler struct {
	svc *service.CashShopService
}

func NewCashShopHandler() *CashShopHandler {
	return &CashShopHandler{svc: service.NewCashShopService()}
}

// List 获取商城物品列表
func (h *CashShopHandler) List(c *gin.Context) {
	category := c.DefaultQuery("category", "all")
	charIDStr := c.Query("character_id")

	items, err := h.svc.ListItems(category, 0)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	// 获取角色枫叶点
	balance := 0
	if charIDStr != "" {
		charID, _ := strconv.Atoi(charIDStr)
		if charID > 0 {
			bal, err := h.svc.GetBalance(uint(charID))
			if err == nil {
				balance = bal
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"success":     true,
		"items":       items,
		"balance":     balance,
		"total_count": len(items),
	})
}

type purchaseRequest struct {
	CharacterID uint `json:"character_id" binding:"required"`
	ItemID      uint `json:"item_id" binding:"required"`
	Quantity    int  `json:"quantity"`
}

// Purchase 购买商城物品
func (h *CashShopHandler) Purchase(c *gin.Context) {
	var req purchaseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	qty := req.Quantity
	if qty < 1 {
		qty = 1
	}
	if err := h.svc.Purchase(req.CharacterID, req.ItemID, qty); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	// 返回最新余额
	balance, _ := h.svc.GetBalance(req.CharacterID)
	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"message":  "购买成功！",
		"balance":  balance,
	})
}

// Balance 获取枫叶点余额
func (h *CashShopHandler) Balance(c *gin.Context) {
	charIDStr := c.Param("characterId")
	charID, err := strconv.Atoi(charIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid character id"})
		return
	}
	balance, err := h.svc.GetBalance(uint(charID))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "balance": balance})
}
