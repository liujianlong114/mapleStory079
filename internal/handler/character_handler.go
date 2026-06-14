package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/service"
	"mapleStory079/pkg/database"
)

type CharacterHandler struct {
	svc *service.CharacterService
}

func NewCharacterHandler() *CharacterHandler {
	return &CharacterHandler{svc: service.NewCharacterService()}
}

type createCharRequest struct {
	AccountID uint   `json:"accountId" binding:"required,min=1"`
	Name      string `json:"name" binding:"required,min=2,max=12"`
	Class     int    `json:"class" binding:"required,min=0"`
	Gender    int    `json:"gender"`
}

func (h *CharacterHandler) Create(c *gin.Context) {
	var req createCharRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	ch, err := h.svc.CreateCharacter(req.AccountID, req.Name, req.Class, req.Gender)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": ch})
}

func (h *CharacterHandler) GetByAccount(c *gin.Context) {
	accountIDStr := c.Query("accountId")
	var body struct {
		AccountID uint `json:"accountId"`
	}
	// 兼容：优先从 query 参数读取，其次从 JSON body
	if accountIDStr == "" {
		if err := c.ShouldBindJSON(&body); err != nil || body.AccountID == 0 {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "accountId required"})
			return
		}
	} else {
		parsed, err := strconv.ParseUint(accountIDStr, 10, 64)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid accountId"})
			return
		}
		body.AccountID = uint(parsed)
	}
	chars, err := h.svc.GetCharactersByAccountID(body.AccountID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": chars})
}

func (h *CharacterHandler) GetByID(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil || id == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid id"})
		return
	}
	ch, err := h.svc.GetCharacterByID(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "character not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": ch})
}

func (h *CharacterHandler) Update(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil || id == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid id"})
		return
	}
	ch, err := h.svc.GetCharacterByID(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "character not found"})
		return
	}
	if err := c.ShouldBindJSON(ch); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	if err := h.svc.UpdateCharacter(ch); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": ch})
}

func (h *CharacterHandler) Delete(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil || id == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid id"})
		return
	}
	if err := h.svc.DeleteCharacter(uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

// 保留 database 的导入，避免因后续扩展而需要反复修改
var _ = &database.Character{}
