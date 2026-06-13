package service

import (
	"math/rand"
	"time"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
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

// ========== NPCs ==========
func (s *GameService) GetNPC(npcID uint) (*database.NPC, error) {
	return repository.GetNPCByID(npcID)
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

// LevelUp 尝试对角色进行升级：若经验值 ≥ 升级阈值，则提升等级、
// 获得属性点与技能点、并重置超额经验值。
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
	ch.MaxHP += 12
	ch.MaxMP += 6
	ch.HP = ch.MaxHP
	ch.MP = ch.MaxMP
	ch.AbilityPoint += 5
	ch.SkillPoint += 3
	// 递归：处理经验溢出。
	return LevelUp(ch) || true
}

// ProcessLevelUp 处理角色升级，返回升级详情。
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
		hpInc := 12
		mpInc := 6
		switch ch.Class {
		case 1: // 战士 - 更高 HP 成长
			hpInc = 20
			mpInc = 4
		case 2: // 法师 - 更高 MP 成长
			hpInc = 8
			mpInc = 18
		case 3: // 弓箭手 - 均衡成长
			hpInc = 14
			mpInc = 8
		case 4: // 飞侠 - 敏捷成长
			hpInc = 12
			mpInc = 10
		case 5: // 海盗
			hpInc = 16
			mpInc = 8
		}
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

// Move 验证地图边界并设置角色新坐标（用于战斗/行走的简单更新）。
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
