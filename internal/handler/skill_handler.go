package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/service"
)

type SkillHandler struct {
	svc *service.SkillService
}

func NewSkillHandler() *SkillHandler { return &SkillHandler{svc: service.NewSkillService()} }

func (h *SkillHandler) List(c *gin.Context) {
	skills, err := h.svc.GetAllSkills()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": skills})
}

func (h *SkillHandler) Get(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid id"})
		return
	}
	skill, err := h.svc.GetSkill(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "skill not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": skill})
}
