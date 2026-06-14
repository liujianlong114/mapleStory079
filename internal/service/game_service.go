package service

import (
	"fmt"
	"math/rand"
	"time"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
	"mapleStory079/pkg/maplife"
	"mapleStory079/pkg/npcdata"
	"mapleStory079/pkg/utils"
)

type GameService struct{}

func NewGameService() *GameService { return &GameService{} }

// ========== Maps ==========
func (s *GameService) GetMap(mapID uint) (*database.Map, error) {
	return repository.GetMapByID(mapID)
}

func (s *GameService) GetAllMaps() ([]database.Map, error) {
	return repository.GetAllMaps()
}

func (s *GameService) CreateMap(m *database.Map) error {
	return database.GetDB().Create(m).Error
}

// GetMapsByArea 按地图 ID 范围返回区域地图列表（便于前端分页显示）。
func (s *GameService) GetMapsByArea(startID, endID uint) ([]database.Map, error) {
	var maps []database.Map
	err := database.GetDB().
		Where("id BETWEEN ? AND ?", startID, endID).
		Find(&maps).Error
	return maps, err
}

// ========== NPCs ==========
func (s *GameService) GetNPC(npcID uint) (*database.NPC, error) {
	return repository.GetNPCByID(npcID)
}

func (s *GameService) GetNPCsByMap(mapID uint) ([]database.NPC, error) {
	// 优先使用 WZ maplife 刷点，避免种子库中错配 ID/坐标。
	if ml, err := maplife.Load(mapID); err == nil {
		if npcs := npcdata.NPCsFromMapLife(ml); len(npcs) > 0 {
			return npcs, nil
		}
	}
	return repository.GetNPCsByMapID(mapID)
}

func (s *GameService) InteractWithNPC(npcID uint, _ uint) (string, error) {
	npc, err := repository.GetNPCByID(npcID)
	if err != nil {
		return "", err
	}
	if npc.Scripts == "" {
		return "欢迎来到冒险岛！", nil
	}
	return npc.Scripts, nil
}

// ========== Mobs ==========
func (s *GameService) GetMob(mobID uint) (*database.Mob, error) {
	return repository.GetMobByID(mobID)
}

func (s *GameService) GetAllMobs() ([]database.Mob, error) {
	return repository.GetAllMobs()
}

// DamageMob 对怪物造成伤害，返回剩余 HP；若 HP ≤ 0 视为死亡。
func (s *GameService) DamageMob(mob *database.Mob, damage int) int {
	if mob == nil {
		return 0
	}
	if damage < 0 {
		damage = 0
	}
	mob.HP -= damage
	if mob.HP < 0 {
		mob.HP = 0
	}
	return mob.HP
}

// MobExpReward 返回击杀该怪物后获得的经验。
func (s *GameService) MobExpReward(mob *database.Mob) int {
	if mob == nil {
		return 0
	}
	if mob.ExpReward > 0 {
		return mob.ExpReward
	}
	return mob.Level*4 + 10
}

// MobMesosReward 返回击杀该怪物后获得的金币。
func (s *GameService) MobMesosReward(mob *database.Mob) int {
	if mob == nil {
		return 0
	}
	if mob.MesosReward > 0 {
		return mob.MesosReward
	}
	return mob.Level*2 + rand.Intn(5)
}

// ========== Items ==========
func (s *GameService) GetItem(itemID uint) (*database.Item, error) {
	return repository.GetItemByID(itemID)
}

func (s *GameService) GetAllItems() ([]database.Item, error) {
	return repository.GetAllItems()
}

// ========== Quests ==========
func (s *GameService) GetQuest(questID uint) (*database.Quest, error) {
	return repository.GetQuestByID(questID)
}

func (s *GameService) GetAllQuests() ([]database.Quest, error) {
	return repository.GetAllQuests()
}

// ========== Skills ==========
func (s *GameService) GetSkill(skillID uint) (*database.Skill, error) {
	return repository.GetSkillByID(skillID)
}

func (s *GameService) GetAllSkills() ([]database.Skill, error) {
	return repository.GetAllSkills()
}

// ========== 地图切换 ==========

// ChangeMap 将角色移动到新地图（落点到目标图入口传送门附近）。
func (s *GameService) ChangeMap(ch *database.Character, newMapID uint, portalName string) error {
	if ch == nil {
		return fmt.Errorf("nil character")
	}
	m, err := repository.GetMapByID(newMapID)
	if err != nil {
		return fmt.Errorf("map %d not found: %w", newMapID, err)
	}
	ch.MapID = newMapID
	x, y := spawnForMap(newMapID, portalName)
	ch.PositionX = x
	ch.PositionY = y
	_ = m
	return nil
}

func spawnForMap(mapID uint, portalName string) (int, int) {
	// 079 彩虹村 / 南门外道等 — 与 client/assets/maps/*.json spawn 对齐
	switch mapID {
	case 1000000:
		return 400, 605
	case 20000:
		if portalName == "in00" {
			return -140, 273
		}
		return 400, 65
	default:
		return 400, 605
	}
}

// ========== Gameplay Helpers ==========

// LevelUpResult 表示升级的结果详情。
type LevelUpResult struct {
	Leveled  bool
	NewLevel int
	HPBonus  int
	MPBonus  int
	APBonus  int
	SPBonus  int
	OldLevel int
}

// GetRequiredExp 返回升级到指定等级所需的经验值。
func GetRequiredExp(level int) int {
	if level <= 0 {
		return 10
	}
	return 10 + level*level*8
}

func (s *GameService) GetRequiredExp(level int) int {
	return GetRequiredExp(level)
}

// getLevelUpHPMP 根据职业获取每次升级增加的 HP / MP。
func getLevelUpHPMP(jobClass int) (int, int) {
	if stats, ok := utils.JobLevelUpStatsMap[jobClass]; ok {
		return stats.HP, stats.MP
	}
	// 默认新手
	return 10, 2
}

// LevelUp 尝试对角色进行升级：若经验值 ≥ 升级阈值，则提升等级、
// 获得属性点与技能点、并重置超额经验值。
// 使用职业对应的 HP/MP 加成。
func LevelUp(ch *database.Character) bool {
	if ch.Level <= 0 {
		ch.Level = 1
	}
	threshold := GetRequiredExp(ch.Level)
	if ch.Exp < threshold {
		return false
	}
	ch.Exp -= threshold
	ch.Level++
	hpInc, mpInc := getLevelUpHPMP(ch.Class)
	ch.MaxHP += hpInc
	ch.MaxMP += mpInc
	ch.HP = ch.MaxHP
	ch.MP = ch.MaxMP
	ch.AbilityPoint += 5
	ch.SkillPoint += 3
	// 递归：处理经验溢出。
	return LevelUp(ch) || true
}

// ProcessLevelUp 处理角色升级，返回升级详情（职业差异化 HP/MP）。
func (s *GameService) ProcessLevelUp(ch *database.Character) LevelUpResult {
	oldLevel := ch.Level
	hpBonus := 0
	mpBonus := 0
	apBonus := 0
	spBonus := 0
	leveled := false
	for ch.Exp >= GetRequiredExp(ch.Level) {
		ch.Exp -= GetRequiredExp(ch.Level)
		ch.Level++
		hpInc, mpInc := getLevelUpHPMP(ch.Class)
		ch.MaxHP += hpInc
		ch.MaxMP += mpInc
		ch.HP = ch.MaxHP
		ch.MP = ch.MaxMP
		ch.AbilityPoint += 5
		ch.SkillPoint += 3
		hpBonus += hpInc
		mpBonus += mpInc
		apBonus += 5
		spBonus += 3
		leveled = true
	}
	return LevelUpResult{
		Leveled:  leveled,
		NewLevel: ch.Level,
		HPBonus:  hpBonus,
		MPBonus:  mpBonus,
		APBonus:  apBonus,
		SPBonus:  spBonus,
		OldLevel: oldLevel,
	}
}

// GainExp 给角色增加经验值，并自动处理升级。
func (s *GameService) GainExp(ch *database.Character, exp int) LevelUpResult {
	ch.Exp += exp
	return s.ProcessLevelUp(ch)
}

// Restore 恢复角色 HP/MP。
func (s *GameService) Restore(ch *database.Character, hp, mp int) {
	if hp > 0 {
		ch.HP += hp
		if ch.HP > ch.MaxHP {
			ch.HP = ch.MaxHP
		}
	}
	if mp > 0 {
		ch.MP += mp
		if ch.MP > ch.MaxMP {
			ch.MP = ch.MaxMP
		}
	}
}

// MoveCharacter 设置角色新坐标（带边界校验）。
func (s *GameService) MoveCharacter(ch *database.Character, newX, newY int, width, height int) (int, int) {
	return Move(ch, newX, newY, width, height)
}

// Move 验证地图边界并设置角色新坐标。
func Move(ch *database.Character, newX, newY int, width, height int) (int, int) {
	if newX < 0 {
		newX = 0
	}
	if newY < 0 {
		newY = 0
	}
	if width > 0 && newX > width {
		newX = width
	}
	if height > 0 && newY > height {
		newY = height
	}
	ch.PositionX = newX
	ch.PositionY = newY
	return ch.PositionX, ch.PositionY
}

// RandomEvent 每 N 步有小概率触发奇遇：随机掉落少量金币或经验。
func RandomEvent(ch *database.Character) (string, int) {
	rand.Seed(time.Now().UnixNano())
	if rand.Intn(20) != 0 {
		return "", 0
	}
	reward := rand.Intn(50) + 1
	ch.Mesos += reward
	return "你在地上发现了一些金币！", reward
}

// ========== 职业 / 转职 ==========

// GetJobInfo 返回指定职业的中文名称、转职等级、前置职业与属性要求。
// 若职业未定义则返回错误。
func (s *GameService) GetJobInfo(jobClass int) (utils.JobInfo, error) {
	info, ok := utils.JobInfoMap[jobClass]
	if !ok {
		return utils.JobInfo{}, fmt.Errorf("未知职业编号: %d", jobClass)
	}
	return info, nil
}

// GetInitialStatsByJob 返回指定职业的初始 HP/MP/STR/DEX/INT/LUK。
// 若职业未定义则回退到新手默认值。
func (s *GameService) GetInitialStatsByJob(jobClass int) utils.JobInitialStats {
	if stats, ok := utils.JobInitialStatsMap[jobClass]; ok {
		return stats
	}
	// 回退：使用新手默认值
	return utils.JobInitialStatsMap[utils.JobBeginner]
}

// AdvanceJob 对角色执行转职：
//   - 验证等级是否达到目标职业的转职等级
//   - 验证前置职业是否正确
//   - 验证属性是否达到 1 转要求
//   - 设置新职业编号、重置技能点、并为新职业赠送初始 HP/MP/STR/DEX/INT/LUK 增量
func (s *GameService) AdvanceJob(ch *database.Character, targetJobClass int) error {
	info, err := s.GetJobInfo(targetJobClass)
	if err != nil {
		return err
	}

	// 等级验证
	if ch.Level < info.AdvanceLevel {
		return fmt.Errorf("等级不足：需要 %d 级，当前 %d 级", info.AdvanceLevel, ch.Level)
	}

	// 前置职业验证
	if info.PreJob >= 0 && ch.Class != info.PreJob {
		curName, _ := utils.JobNames[ch.Class]
		preName, _ := utils.JobNames[info.PreJob]
		return fmt.Errorf("前置职业不符：需要 %s，当前 %s", preName, curName)
	}

	// 属性验证（仅 1 转有要求，2/3 转一般不要求）
	if info.MinSTR > 0 && ch.STR < info.MinSTR {
		return fmt.Errorf("力量不足：需要 %d，当前 %d", info.MinSTR, ch.STR)
	}
	if info.MinDEX > 0 && ch.DEX < info.MinDEX {
		return fmt.Errorf("敏捷不足：需要 %d，当前 %d", info.MinDEX, ch.DEX)
	}
	if info.MinINT > 0 && ch.INT < info.MinINT {
		return fmt.Errorf("智力不足：需要 %d，当前 %d", info.MinINT, ch.INT)
	}
	if info.MinLUK > 0 && ch.LUK < info.MinLUK {
		return fmt.Errorf("幸运不足：需要 %d，当前 %d", info.MinLUK, ch.LUK)
	}

	// 执行转职
	// 1) 设置新职业
	ch.Class = targetJobClass

	// 2) 重置技能点（转职后技能点重置，供新职业技能分配）
	ch.SkillPoint = 0

	// 3) 按职业赠送初始 HP/MP/属性（仅在 1 转时为角色补齐初始上限）
	if initStats, ok := utils.JobInitialStatsMap[targetJobClass]; ok {
		// 仅在 MaxHP/MaxMP 低于新职业推荐值时，向上补齐
		if ch.MaxHP < initStats.HP {
			ch.MaxHP = initStats.HP
		}
		if ch.MaxMP < initStats.MP {
			ch.MaxMP = initStats.MP
		}
		// HP/MP 自动满血满蓝
		ch.HP = ch.MaxHP
		ch.MP = ch.MaxMP
		// 属性按差值补齐（避免重复叠加）
		if ch.STR < initStats.STR {
			ch.STR = initStats.STR
		}
		if ch.DEX < initStats.DEX {
			ch.DEX = initStats.DEX
		}
		if ch.INT < initStats.INT {
			ch.INT = initStats.INT
		}
		if ch.LUK < initStats.LUK {
			ch.LUK = initStats.LUK
		}
	}

	return nil
}
