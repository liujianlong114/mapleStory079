package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/repository"
	"mapleStory079/internal/service"
)

type GameHandler struct {
	gameSvc   *service.GameService
	combatSvc *service.CombatService
}

func NewGameHandler() *GameHandler {
	return &GameHandler{
		gameSvc:   service.NewGameService(),
		combatSvc: service.NewCombatService(),
	}
}

// --- Maps ---
func (h *GameHandler) ListMaps(c *gin.Context) {
	maps, err := h.gameSvc.GetAllMaps()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": maps})
}

func (h *GameHandler) GetMap(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid map id"})
		return
	}
	m, err := h.gameSvc.GetMap(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "map not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": m})
}

// --- Mobs ---
func (h *GameHandler) ListMobs(c *gin.Context) {
	mobs, err := h.gameSvc.GetAllMobs()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": mobs})
}

func (h *GameHandler) GetMob(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid mob id"})
		return
	}
	mob, err := h.gameSvc.GetMob(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "mob not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": mob})
}

// --- Combat ---
type combatRequest struct {
	CharacterID uint `json:"characterId" binding:"required"`
	MobID       uint `json:"mobId" binding:"required"`
}

func (h *GameHandler) Attack(c *gin.Context) {
	var req combatRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	ch, err := repository.GetCharacterByID(req.CharacterID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "character not found"})
		return
	}
	mob, err := repository.GetMobByID(req.MobID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "mob not found"})
		return
	}
	result := h.combatSvc.Attack(ch, mob)
	_ = repository.UpdateCharacter(ch)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": result})
}

// --- Quests / Skills ---
func (h *GameHandler) ListQuests(c *gin.Context) {
	quests, err := repository.GetAllQuests()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": quests})
}

func (h *GameHandler) ListSkills(c *gin.Context) {
	skills, err := repository.GetAllSkills()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": skills})
}
