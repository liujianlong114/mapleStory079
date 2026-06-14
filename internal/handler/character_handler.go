package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/service"
	"mapleStory079/pkg/database"
	"mapleStory079/pkg/utils"
)

type WorldHandler struct{}

func NewWorldHandler() *WorldHandler { return &WorldHandler{} }

// List ms079 LoginPacket.getServerList 简化版（单区多频道）
func (h *WorldHandler) List(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": []gin.H{
			{
				"id":           0,
				"name":         "蓝蜗牛",
				"flag":         0,
				"eventMessage": "",
				"channels": []gin.H{
					{"id": 1, "name": "频道1", "load": 0},
					{"id": 2, "name": "频道2", "load": 0},
					{"id": 3, "name": "频道3", "load": 1},
				},
			},
		},
	})
}

type CharacterHandler struct {
	svc     *service.CharacterService
	authSvc *service.AuthService
}

func NewCharacterHandler() *CharacterHandler {
	return &CharacterHandler{
		svc:     service.NewCharacterService(),
		authSvc: service.NewAuthService(),
	}
}

type createCharRequest struct {
	AccountID uint   `json:"accountId" binding:"required,min=1"`
	Name      string `json:"name" binding:"required,min=2,max=12"`
	JobType   int    `json:"jobType"`
	Class     int    `json:"class"`
	Gender    int    `json:"gender"`
	Face      int    `json:"face"`
	Hair      int    `json:"hair"`
	HairColor int    `json:"hairColor"`
	Skin      int    `json:"skin"`
	Top       int    `json:"top"`
	Bottom    int    `json:"bottom"`
	Shoes     int    `json:"shoes"`
	Weapon    int    `json:"weapon"`
}

func (h *CharacterHandler) Create(c *gin.Context) {
	var req createCharRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	jobType := req.JobType
	if jobType == 0 && req.Class == 0 {
		jobType = utils.JobTypeAdventurer
	}
	acc, err := h.authSvc.GetAccountByID(req.AccountID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "账号不存在"})
		return
	}
	gender := acc.Gender
	if gender == utils.AccountGenderUnset {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请先设置账号性别"})
		return
	}
	look := utils.BeginnerLook{
		Face: req.Face, Hair: req.Hair, HairColor: 0, Skin: 0,
		Top: req.Top, Bottom: req.Bottom, Shoes: req.Shoes, Weapon: req.Weapon,
	}
	ch, err := h.svc.CreateCharacter(req.AccountID, req.Name, jobType, gender, look)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": ch})
}

func (h *CharacterHandler) CheckName(c *gin.Context) {
	name := c.Query("name")
	ok, msg := h.svc.CheckCharacterName(name)
	c.JSON(http.StatusOK, gin.H{"success": true, "available": ok, "message": msg})
}

func (h *CharacterHandler) GetByAccount(c *gin.Context) {
	accountIDStr := c.Query("accountId")
	var body struct {
		AccountID uint `json:"accountId"`
	}
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

var _ = &database.Character{}
