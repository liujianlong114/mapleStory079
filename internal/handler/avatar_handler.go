package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/service"
	"mapleStory079/pkg/look"
)

type AvatarHandler struct {
	svc *service.AvatarService
}

func NewAvatarHandler() *AvatarHandler {
	return &AvatarHandler{svc: service.NewAvatarService()}
}

func parseLookQuery(c *gin.Context) look.CharLook {
	parseInt := func(key string) int {
		v, _ := strconv.Atoi(c.Query(key))
		return v
	}
	return look.CharLook{
		Gender:   parseInt("gender"),
		Face:     parseInt("face"),
		Hair:     parseInt("hair"),
		Skin:     parseInt("skin"),
		Top:      parseInt("top"),
		Bottom:   parseInt("bottom"),
		Longcoat: parseInt("longcoat"),
		Shoes:    parseInt("shoes"),
		Cap:      parseInt("cap"),
		Cape:     parseInt("cape"),
		Glove:    parseInt("glove"),
		Shield:   parseInt("shield"),
		Weapon:   parseInt("weapon"),
		FaceAcc:  parseInt("face_acc"),
		EyeAcc:   parseInt("eye_acc"),
		Earring:  parseInt("earring"),
	}
}

// Compose GET /api/v1/look/compose.png — 完整 CharLook 运行时合成
func (h *AvatarHandler) Compose(c *gin.Context) {
	l := parseLookQuery(c)
	if l.Face == 0 && l.Hair == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "face and hair required"})
		return
	}
	pose := c.DefaultQuery("pose", "stand1")
	frame, _ := strconv.Atoi(c.DefaultQuery("frame", "0"))
	scale, _ := strconv.Atoi(c.DefaultQuery("scale", "1"))
	if scale < 1 {
		scale = 1
	}
	if scale > 8 {
		scale = 8
	}
	pad, _ := strconv.Atoi(c.DefaultQuery("pad", "12"))
	if pad < 0 {
		pad = 0
	}
	if pad > 32 {
		pad = 32
	}

	png, err := h.svc.ComposePNG(l, pose, frame, scale, pad)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.Header("Cache-Control", "public, max-age=86400")
	c.Data(http.StatusOK, "image/png", png)
}
