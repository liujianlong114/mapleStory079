package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/repository"
	"mapleStory079/internal/service"
	"mapleStory079/pkg/database"
	"mapleStory079/pkg/utils"
)

type GameHandler struct {
	gameSvc   *service.GameService
	combatSvc *service.CombatService
	lootSvc   *service.LootService
	instances *service.MobInstanceService
	wsHandler *WebSocketHandler
}

func NewGameHandler() *GameHandler {
	return &GameHandler{
		gameSvc:   service.NewGameService(),
		combatSvc: service.NewCombatService(),
		lootSvc:   service.DefaultLootService,
		instances: service.DefaultMobInstanceService,
	}
}

func (h *GameHandler) SetWebSocketHandler(ws *WebSocketHandler) {
	h.wsHandler = ws
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

	// 使用事务统一回写角色和怪物状态
	tx := database.GetDB().Begin()
	if err := tx.Save(ch).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "failed to update character"})
		return
	}
	if err := tx.Save(mob).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "failed to update mob"})
		return
	}
	tx.Commit()

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

// --- Game state ---
func (h *GameHandler) GetGameState(c *gin.Context) {
	charIDStr := c.Query("character_id")
	if charIDStr == "" {
		charIDStr = c.Query("characterId")
	}
	charID, err := strconv.ParseUint(charIDStr, 10, 64)
	if err != nil || charID == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "character_id required"})
		return
	}
	ch, err := repository.GetCharacterByID(uint(charID))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "character not found"})
		return
	}
	gameMap, _ := h.gameSvc.GetMap(ch.MapID)
	stats := h.combatSvc.GetCombatStats(ch)
	requiredExp := h.gameSvc.GetRequiredExp(ch.Level)
	expProgress := 0.0
	if requiredExp > 0 {
		expProgress = float64(ch.Exp) / float64(requiredExp)
	}
	className := "新手"
	if name, ok := utils.JobNames[ch.Class]; ok {
		className = name
	}
	instances := h.instances.EnsureMap(ch.MapID)
	c.JSON(http.StatusOK, gin.H{
		"character": characterJSON(ch),
		"state": gin.H{
			"exp_progress":  expProgress,
			"class_name":    className,
			"hp_percentage": stats["hp_percent"],
			"mp_percentage": stats["mp_percent"],
			"critical_rate": 5.0 + float64(ch.LUK)*0.3,
			"hit_rate":      95.0,
		},
		"map":           gameMap,
		"mob_instances": instances,
	})
}

func characterJSON(ch *database.Character) gin.H {
	return gin.H{
		"id":             ch.ID,
		"account_id":     ch.AccountID,
		"name":           ch.Name,
		"class":          ch.Class,
		"gender":         ch.Gender,
		"level":          ch.Level,
		"exp":            ch.Exp,
		"experience":     ch.Exp,
		"hp":             ch.HP,
		"max_hp":         ch.MaxHP,
		"mp":             ch.MP,
		"max_mp":         ch.MaxMP,
		"str":            ch.STR,
		"dex":            ch.DEX,
		"int":            ch.INT,
		"luk":            ch.LUK,
		"ability_points": ch.AbilityPoint,
		"ability_point":  ch.AbilityPoint,
		"skill_points":   ch.SkillPoint,
		"skill_point":    ch.SkillPoint,
		"mesos":          ch.Mesos,
		"map_id":         ch.MapID,
		"position_x":     ch.PositionX,
		"position_y":     ch.PositionY,
	}
}

func (h *GameHandler) ListMapMobInstances(c *gin.Context) {
	mapIDStr := c.Query("map_id")
	if mapIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "map_id required"})
		return
	}
	mapID, err := strconv.ParseUint(mapIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid map_id"})
		return
	}
	instances := h.instances.EnsureMap(uint(mapID))
	c.JSON(http.StatusOK, gin.H{"mob_instances": instances})
}

type moveCharacterRequest struct {
	CharacterID      uint    `json:"character_id"`
	CharacterIDCamel uint    `json:"characterId"`
	X                float64 `json:"x"`
	Y                float64 `json:"y"`
}

func (h *GameHandler) MoveCharacter(c *gin.Context) {
	var req moveCharacterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	charID := req.CharacterID
	if charID == 0 {
		charID = req.CharacterIDCamel
	}
	ch, err := repository.GetCharacterByID(charID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "character not found"})
		return
	}
	m, _ := h.gameSvc.GetMap(ch.MapID)
	w, ht := 1600, 900
	if m != nil {
		w, ht = m.Width, m.Height
	}
	x, y := h.gameSvc.MoveCharacter(ch, int(req.X), int(req.Y), w, ht)
	if err := repository.UpdateCharacter(ch); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"position_x": x,
		"position_y": y,
		"map_id":     ch.MapID,
	})
}

type restoreRequest struct {
	CharacterID      uint `json:"character_id"`
	CharacterIDCamel uint `json:"characterId"`
	HP               int  `json:"hp"`
	MP               int  `json:"mp"`
}

func (h *GameHandler) RestoreCharacter(c *gin.Context) {
	var req restoreRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	charID := req.CharacterID
	if charID == 0 {
		charID = req.CharacterIDCamel
	}
	ch, err := repository.GetCharacterByID(charID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "character not found"})
		return
	}
	h.gameSvc.Restore(ch, req.HP, req.MP)
	if err := repository.UpdateCharacter(ch); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"hp": ch.HP, "max_hp": ch.MaxHP,
		"mp": ch.MP, "max_mp": ch.MaxMP,
	})
}

func (h *GameHandler) LevelUpCharacter(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil || id == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid character id"})
		return
	}
	ch, err := repository.GetCharacterByID(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "character not found"})
		return
	}
	result := h.gameSvc.ProcessLevelUp(ch)
	if err := repository.UpdateCharacter(ch); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"level":      ch.Level,
		"experience": ch.Exp,
		"exp":        ch.Exp,
		"hp":         ch.HP,
		"max_hp":     ch.MaxHP,
		"mp":         ch.MP,
		"max_mp":     ch.MaxMP,
		"leveled_up": result.Leveled,
		"old_level":  result.OldLevel,
		"new_level":  result.NewLevel,
	})
}

type addAPRequest struct {
	CharacterID      uint   `json:"character_id"`
	CharacterIDCamel uint   `json:"characterId"`
	Stat             string `json:"stat"`
	Points           int    `json:"points"`
}

func (h *GameHandler) AddAbilityPoints(c *gin.Context) {
	var req addAPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	charID := req.CharacterID
	if charID == 0 {
		charID = req.CharacterIDCamel
	}
	if req.Points <= 0 {
		req.Points = 1
	}
	ch, err := repository.GetCharacterByID(charID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "character not found"})
		return
	}
	if ch.AbilityPoint < req.Points {
		c.JSON(http.StatusBadRequest, gin.H{"error": "insufficient ability points"})
		return
	}
	switch req.Stat {
	case "str", "STR":
		ch.STR += req.Points
	case "dex", "DEX":
		ch.DEX += req.Points
	case "int", "INT":
		ch.INT += req.Points
	case "luk", "LUK":
		ch.LUK += req.Points
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid stat"})
		return
	}
	ch.AbilityPoint -= req.Points
	if err := repository.UpdateCharacter(ch); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"str": ch.STR, "dex": ch.DEX, "int": ch.INT, "luk": ch.LUK,
		"ability_points": ch.AbilityPoint,
	})
}

// --- Gain exp (调试用) ---
type gainExpRequest struct {
	CharacterID      uint `json:"character_id"`
	CharacterIDCamel uint `json:"characterId"`
	Exp              int  `json:"exp"`
}

func (h *GameHandler) GainExp(c *gin.Context) {
	var req gainExpRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}
	charID := req.CharacterID
	if charID == 0 {
		charID = req.CharacterIDCamel
	}
	if charID == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "character_id required"})
		return
	}
	ch, err := repository.GetCharacterByID(charID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "character not found"})
		return
	}
	exp := req.Exp
	if exp <= 0 {
		exp = 100
	}
	result := h.gameSvc.GainExp(ch, exp)
	if err := repository.UpdateCharacter(ch); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"character_id": ch.ID,
			"level":        ch.Level,
			"exp":          ch.Exp,
			"leveled_up":   result.Leveled,
			"old_level":    result.OldLevel,
			"new_level":    result.NewLevel,
		},
	})
}

type calculateDamageRequest struct {
	Str             int     `json:"str"`
	Dex             int     `json:"dex"`
	Def             int     `json:"def"`
	Level           int     `json:"level"`
	UseSkill        bool    `json:"use_skill"`
	SkillMultiplier float64 `json:"skill_multiplier"`
}

func (h *GameHandler) CalculateDamage(c *gin.Context) {
	var req calculateDamageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.Level <= 0 {
		req.Level = 1
	}
	atk := req.Str + req.Dex/2 + req.Level*2
	damage := utils.CalculateDamage(atk, req.Def, 0)
	if req.UseSkill && req.SkillMultiplier > 0 {
		damage = int(float64(damage) * req.SkillMultiplier)
	}
	if damage < 1 {
		damage = 1
	}
	c.JSON(http.StatusOK, gin.H{"damage": damage, "missed": false})
}

type playerAttackMobRequest struct {
	CharacterID uint    `json:"character_id" binding:"required"`
	MobID       uint    `json:"mob_id"`
	InstanceID  uint    `json:"instance_id"`
	SkillID     *int    `json:"skill_id"`
	MapID       uint    `json:"map_id"`
	X           float64 `json:"x"`
	Y           float64 `json:"y"`
}

func (h *GameHandler) PlayerAttackMob(c *gin.Context) {
	var req playerAttackMobRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	ch, err := repository.GetCharacterByID(req.CharacterID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "character not found"})
		return
	}

	var mob *database.Mob
	var saveMobTemplate bool
	if req.InstanceID > 0 {
		inst, err := h.instances.Get(req.InstanceID)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "mob instance not found"})
			return
		}
		tmpl, err := repository.GetMobByID(inst.TemplateID)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "mob template not found"})
			return
		}
		mobCopy := *tmpl
		mobCopy.HP = inst.HP
		mob = &mobCopy
		if req.X == 0 && req.Y == 0 {
			req.X, req.Y = inst.X, inst.Y
		}
		if req.MobID == 0 {
			req.MobID = inst.TemplateID
		}
	} else {
		if req.MobID == 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "mob_id or instance_id required"})
			return
		}
		mob, err = repository.GetMobByID(req.MobID)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "mob not found"})
			return
		}
		saveMobTemplate = true
	}

	result, err := h.combatSvc.PlayerAttackMob(ch, mob)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if req.InstanceID > 0 {
		updated, err := h.instances.SetHP(req.InstanceID, mob.HP)
		if err == nil && updated != nil {
			result.TargetHP = updated.HP
			result.TargetDead = updated.HP <= 0
		}
	}

	if err := repository.UpdateCharacter(ch); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update character"})
		return
	}
	if saveMobTemplate {
		if err := repository.UpdateMob(mob); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update mob"})
			return
		}
	}

	groundLoots := []service.GroundLoot(nil)
	if result.TargetDead && len(result.ItemsDropped) > 0 {
		mapID := req.MapID
		if mapID == 0 {
			mapID = ch.MapID
		}
		x, y := req.X, req.Y
		if x == 0 && y == 0 {
			x, y = float64(ch.PositionX), float64(ch.PositionY)
		}
		groundLoots = h.lootSvc.SpawnFromRolls(mapID, ch.ID, x, y, result.ItemsDropped)
		h.broadcastLootSpawns(mapID, groundLoots)
	}

	c.JSON(http.StatusOK, gin.H{
		"damage":       result.Damage,
		"is_critical":  result.IsCritical,
		"is_hit":       result.IsHit,
		"mob_killed":   result.TargetDead,
		"target_hp":    result.TargetHP,
		"exp_gained":   result.ExpGained,
		"mesos_gained": result.MesosGained,
		"level_up":     result.LevelUp,
		"message":      result.Message,
		"ground_loots": groundLoots,
		"instance_id":  req.InstanceID,
	})
}

type mobAttackPlayerRequest struct {
	CharacterID uint `json:"character_id" binding:"required"`
	MobID       uint `json:"mob_id" binding:"required"`
}

func (h *GameHandler) MobAttackPlayer(c *gin.Context) {
	var req mobAttackPlayerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	ch, err := repository.GetCharacterByID(req.CharacterID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "character not found"})
		return
	}
	mob, err := repository.GetMobByID(req.MobID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "mob not found"})
		return
	}
	result, err := h.combatSvc.MobAttackPlayer(ch, mob)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if err := repository.UpdateCharacter(ch); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"damage":  result.Damage,
		"missed":  !result.IsHit,
		"is_hit":  result.IsHit,
		"hp":      result.TargetHP,
		"is_dead": result.TargetDead,
		"message": result.Message,
	})
}

func (h *GameHandler) GetCombatStats(c *gin.Context) {
	characterIDStr := c.Query("character_id")
	id, err := strconv.ParseUint(characterIDStr, 10, 64)
	if err != nil || id == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "character_id required"})
		return
	}
	ch, err := repository.GetCharacterByID(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "character not found"})
		return
	}
	stats := h.combatSvc.GetCombatStats(ch)
	stats["str"] = ch.STR
	stats["dex"] = ch.DEX
	stats["int"] = ch.INT
	stats["luk"] = ch.LUK
	stats["critical_rate"] = 5.0 + float64(ch.LUK)*0.3
	c.JSON(http.StatusOK, stats)
}

type reviveRequest struct {
	CharacterID uint `json:"character_id" binding:"required"`
}

func (h *GameHandler) ReviveCharacter(c *gin.Context) {
	var req reviveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	ch, err := repository.GetCharacterByID(req.CharacterID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "character not found"})
		return
	}
	h.combatSvc.ReviveCharacter(ch)
	if err := repository.UpdateCharacter(ch); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"revived": true,
		"hp":      ch.HP,
		"mp":      ch.MP,
		"x":       ch.PositionX,
		"y":       ch.PositionY,
	})
}

func (h *GameHandler) ListItems(c *gin.Context) {
	items, err := h.gameSvc.GetAllItems()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items})
}

func (h *GameHandler) GetItem(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid item id"})
		return
	}
	item, err := h.gameSvc.GetItem(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "item not found"})
		return
	}
	c.JSON(http.StatusOK, item)
}

type pickupLootRequest struct {
	CharacterID uint    `json:"character_id" binding:"required"`
	DropID      string  `json:"drop_id" binding:"required"`
	X           float64 `json:"x"`
	Y           float64 `json:"y"`
}

func (h *GameHandler) PickupLoot(c *gin.Context) {
	var req pickupLootRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	ch, err := repository.GetCharacterByID(req.CharacterID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "character not found"})
		return
	}
	x, y := req.X, req.Y
	if x == 0 && y == 0 {
		x, y = float64(ch.PositionX), float64(ch.PositionY)
	}
	loot, err := h.lootSvc.Pickup(req.DropID, ch.ID, x, y)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	h.broadcastLootPickup(ch.MapID, ch.ID, loot)
	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"drop_id":  loot.ID,
		"item_id":  loot.ItemID,
		"quantity": loot.Quantity,
		"mesos":    loot.Mesos,
	})
}

func (h *GameHandler) ListGroundLoot(c *gin.Context) {
	mapIDStr := c.Query("map_id")
	if mapIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "map_id required"})
		return
	}
	mapID, err := strconv.ParseUint(mapIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid map_id"})
		return
	}
	loots := h.lootSvc.ListByMap(uint(mapID))
	c.JSON(http.StatusOK, gin.H{"ground_loots": loots})
}

func (h *GameHandler) broadcastLootSpawns(mapID uint, loots []service.GroundLoot) {
	if h.wsHandler == nil || len(loots) == 0 {
		return
	}
	channel := mapChannel(mapID)
	for _, loot := range loots {
		h.wsHandler.BroadcastLoot(channel, &WSMessage{
			Type:        utils.WSMessageTypeLoot,
			Channel:     channel,
			Action:      "spawn",
			DropID:      loot.ID,
			MapID:       int(mapID),
			ItemID:      loot.ItemID,
			Quantity:    loot.Quantity,
			Mesos:       loot.Mesos,
			X:           loot.X,
			Y:           loot.Y,
			CharacterID: int(loot.OwnerID),
		})
	}
}

func (h *GameHandler) broadcastLootPickup(mapID, characterID uint, loot *service.GroundLoot) {
	if h.wsHandler == nil || loot == nil {
		return
	}
	channel := mapChannel(mapID)
	h.wsHandler.BroadcastLoot(channel, &WSMessage{
		Type:        utils.WSMessageTypeLoot,
		Channel:     channel,
		Action:      "pickup",
		DropID:      loot.ID,
		MapID:       int(mapID),
		ItemID:      loot.ItemID,
		Quantity:    loot.Quantity,
		Mesos:       loot.Mesos,
		X:           loot.X,
		Y:           loot.Y,
		CharacterID: int(characterID),
	})
}

func mapChannel(mapID uint) string {
	return "map_" + strconv.FormatUint(uint64(mapID), 10)
}
