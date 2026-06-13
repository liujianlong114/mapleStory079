package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
	"mapleStory079/pkg/utils"
)

type CharacterHandler struct{}

func NewCharacterHandler() *CharacterHandler { return &CharacterHandler{} }

type createCharRequest struct {
	AccountID uint   `json:"accountId" binding:"required"`
	Name      string `json:"name" binding:"required"`
	Class     int    `json:"class"`
	Gender    int    `json:"gender"`
}

func (h *CharacterHandler) Create(c *gin.Context) {
	var req createCharRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	if _, err := repository.GetCharacterByName(req.Name); err == nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "character name already exists"})
		return
	}
	chars, err := repository.GetCharactersByAccount(req.AccountID)
	if err == nil && len(chars) >= 6 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "max character limit reached"})
		return
	}
	base := getClassStats(req.Class)
	ch := &database.Character{
		AccountID: req.AccountID,
		Name:      req.Name,
		Class:     req.Class,
		Gender:    req.Gender,
		Level:     1, Exp: 0,
		MapID: 1,
		HP:    base.hp, MaxHP: base.maxHp,
		MP: base.mp, MaxMP: base.maxMp,
		STR: base.str, DEX: base.dex, INT: base.int_, LUK: base.luk,
	}
	if err := repository.CreateCharacter(ch); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": ch})
}

func (h *CharacterHandler) GetByAccount(c *gin.Context) {
	accountIDStr := c.Query("accountId")
	if accountIDStr == "" {
		var body struct {
			AccountID uint `json:"accountId"`
		}
		if err := c.ShouldBindJSON(&body); err == nil && body.AccountID > 0 {
			chars, err := repository.GetCharactersByAccount(body.AccountID)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
				return
			}
			c.JSON(http.StatusOK, gin.H{"success": true, "data": chars})
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "accountId required"})
		return
	}
	id, _ := strconv.ParseUint(accountIDStr, 10, 64)
	chars, err := repository.GetCharactersByAccount(uint(id))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": chars})
}

func (h *CharacterHandler) GetByID(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid id"})
		return
	}
	ch, err := repository.GetCharacterByID(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "character not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": ch})
}

func (h *CharacterHandler) Update(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid id"})
		return
	}
	ch, err := repository.GetCharacterByID(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "character not found"})
		return
	}
	if err := c.ShouldBindJSON(ch); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	if err := repository.UpdateCharacter(ch); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": ch})
}

func (h *CharacterHandler) Delete(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid id"})
		return
	}
	if err := repository.DeleteCharacter(uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

type classStats struct {
	hp, maxHp, mp, maxMp, str, dex, int_, luk int
}

func getClassStats(class int) classStats {
	switch class {
	case 1:
		return classStats{hp: 50, maxHp: 50, mp: 5, maxMp: 5, str: 12, dex: 5, int_: 4, luk: 4}
	case 2:
		return classStats{hp: 30, maxHp: 30, mp: 15, maxMp: 15, str: 4, dex: 4, int_: 12, luk: 6}
	case 3:
		return classStats{hp: 40, maxHp: 40, mp: 10, maxMp: 10, str: 6, dex: 12, int_: 4, luk: 6}
	case 4:
		return classStats{hp: 40, maxHp: 40, mp: 10, maxMp: 10, str: 4, dex: 8, int_: 4, luk: 12}
	case 5:
		return classStats{hp: 45, maxHp: 45, mp: 8, maxMp: 8, str: 10, dex: 10, int_: 4, luk: 6}
	default:
		return classStats{hp: 40, maxHp: 40, mp: 5, maxMp: 5, str: 10, dex: 6, int_: 4, luk: 4}
	}
}

// utils 占位，用于保持 pkg/utils 的导入依赖。
var _ = utils.GenerateRandomString
