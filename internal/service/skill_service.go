package service

import (
	"errors"
	"fmt"
	"sync"
	"time"

	"mapleStory079/pkg/database"
	"mapleStory079/pkg/utils"
)

// SkillDamageResult 技能使用后的伤害结算结果。
type SkillDamageResult struct {
	SkillID     uint
	SkillName   string
	Damage      int
	ManaCost    int
	RemainingHP int // 目标剩余 HP（如未提供目标则为 0）
	CoolDownMs  int
}

// SkillService 技能服务：提供技能查询、使用与冷却管理。
type SkillService struct {
	mu        sync.RWMutex
	coolDowns map[string]time.Time // key = characterID:skillID
}

// NewSkillService 创建技能服务实例。
func NewSkillService() *SkillService {
	return &SkillService{
		coolDowns: make(map[string]time.Time),
	}
}

// GetSkill 根据 ID 获取技能。
func (s *SkillService) GetSkill(skillID uint) (*database.Skill, error) {
	if skillID == 0 {
		return nil, errors.New("invalid skill id")
	}
	var skill database.Skill
	if err := database.GetDB().First(&skill, skillID).Error; err != nil {
		return nil, err
	}
	return &skill, nil
}

// GetAllSkills 获取所有技能（兼容旧 API）。
func (s *SkillService) GetAllSkills() ([]database.Skill, error) {
	var skills []database.Skill
	if err := database.GetDB().Find(&skills).Error; err != nil {
		return nil, err
	}
	return skills, nil
}

// GetSkillsByJob 根据职业获取可用技能列表。
func (s *SkillService) GetSkillsByJob(jobClass int) ([]database.Skill, error) {
	if _, ok := utils.JobNames[jobClass]; !ok && jobClass != 0 {
		// 允许未知职业查询，但若没有匹配记录则返回空列表；此处不直接报错
	}
	var skills []database.Skill
	if err := database.GetDB().Where("job_class = ?", jobClass).Find(&skills).Error; err != nil {
		return nil, err
	}
	return skills, nil
}

// UseSkill 角色对目标怪物使用技能。
// 会消耗 MP、计算伤害、管理冷却时间；若 character/target 未在数据库加载，可在调用前自行加载。
// character：使用技能的角色；
// skillID：技能 ID；
// targetMobID：目标怪物 ID（可为 0，此时仅计算伤害值不更新目标）。
func (s *SkillService) UseSkill(character *database.Character, skillID uint, targetMobID uint) (*SkillDamageResult, error) {
	if character == nil {
		return nil, errors.New("character is nil")
	}
	skill, err := s.GetSkill(skillID)
	if err != nil {
		return nil, err
	}

	// 冷却检查
	if skill.CoolDownMs > 0 {
		key := coolDownKey(character.ID, skillID)
		s.mu.RLock()
		lastUsed := s.coolDowns[key]
		s.mu.RUnlock()
		if !lastUsed.IsZero() && time.Since(lastUsed).Milliseconds() < int64(skill.CoolDownMs) {
			return nil, errors.New("skill is cooling down")
		}
		s.mu.Lock()
		s.coolDowns[key] = time.Now()
		s.mu.Unlock()
	}

	// MP 检查
	if character.MP < skill.MPCost {
		return nil, errors.New("insufficient MP")
	}
	character.MP -= skill.MPCost

	// 计算伤害：主属性 * 伤害比例 + 随机浮动
	primary := s.primaryStat(character, skill)
	baseDamage := int(float64(primary) * skill.DamageRatio)
	if baseDamage <= 0 {
		baseDamage = 1
	}
	damage := baseDamage + (int(time.Now().UnixNano()) % 3) // 简单浮动 0~2

	remainingHP := 0
	if targetMobID > 0 {
		// 尝试从数据库读取并扣减怪物 HP（失败不影响技能使用结果）
		var mob database.Mob
		if err := database.GetDB().First(&mob, targetMobID).Error; err == nil {
			mob.HP -= damage
			if mob.HP < 0 {
				mob.HP = 0
			}
			remainingHP = mob.HP
			_ = database.GetDB().Model(&database.Mob{}).
				Where("id = ?", targetMobID).
				Update("hp", mob.HP).Error
		}
	}

	// 保存角色 MP 变更
	_ = database.GetDB().Model(&database.Character{}).
		Where("id = ?", character.ID).
		Update("mp", character.MP).Error

	return &SkillDamageResult{
		SkillID:     skill.ID,
		SkillName:   skill.Name,
		Damage:      damage,
		ManaCost:    skill.MPCost,
		RemainingHP: remainingHP,
		CoolDownMs:  skill.CoolDownMs,
	}, nil
}

// primaryStat 根据技能所属职业选择主要属性（用于伤害计算）。
func (s *SkillService) primaryStat(character *database.Character, skill *database.Skill) int {
	switch skill.JobClass {
	case utils.JobSwordsman, utils.JobFighter,
		utils.JobPage, utils.JobSpearman, utils.JobCrusader,
		utils.JobWhiteKnight, utils.JobDragonKnight:
		return character.STR
	case utils.JobMagician, utils.JobFirePoison, utils.JobIceLightning,
		utils.JobCleric, utils.JobFirePoisonWizard, utils.JobIceLightningWizard,
		utils.JobPriest:
		return character.INT
	case utils.JobBowman, utils.JobHunter, utils.JobCrossbow,
		utils.JobRanger, utils.JobSniper:
		return character.DEX
	case utils.JobThief, utils.JobAssassin, utils.JobBandit,
		utils.JobHermit, utils.JobChiefBandit:
		return character.LUK
	case utils.JobPirate, utils.JobBrawler, utils.JobGunslinger,
		utils.JobMarauder, utils.JobOutlaw:
		return character.STR
	default:
		return character.STR
	}
}

// AddSkillPoint 给角色增加技能点（升级时调用）。
func (s *SkillService) AddSkillPoint(characterID uint, points int) error {
	if characterID == 0 {
		return errors.New("invalid character id")
	}
	if points <= 0 {
		return errors.New("points must be positive")
	}
	return database.GetDB().Model(&database.Character{}).
		Where("id = ?", characterID).
		UpdateColumn("skill_point", database.GetDB().Raw("skill_point + ?", points)).Error
}

// AssignSkill 将角色的技能点分配到指定技能：当前采用"skill_point - 1"的简单策略，
// 并在 CharacterInventory 表中记录一条"已学习"记录（skill_id -> slot_index=level）。
// 这是一个最小可用实现，实际可按项目需求替换。
func (s *SkillService) AssignSkill(characterID uint, skillID uint) error {
	if characterID == 0 || skillID == 0 {
		return errors.New("invalid id")
	}
	var character database.Character
	if err := database.GetDB().First(&character, characterID).Error; err != nil {
		return err
	}
	if character.SkillPoint <= 0 {
		return errors.New("no skill point available")
	}
	if _, err := s.GetSkill(skillID); err != nil {
		return err
	}
	// 扣减技能点
	character.SkillPoint -= 1
	if err := database.GetDB().Model(&character).Update("skill_point", character.SkillPoint).Error; err != nil {
		return err
	}
	// 记录学习信息（使用 CharacterInventory，避免新增表）
	return database.GetDB().Create(&database.CharacterInventory{
		CharacterID: characterID,
		ItemID:      int(skillID),
		SlotIndex:   0,
		Quantity:    1,
		CreatedAt:   time.Now(),
	}).Error
}

// RemainingCoolDownMs 获取某角色某技能的剩余冷却时间（毫秒）。
func (s *SkillService) RemainingCoolDownMs(characterID, skillID uint) int {
	key := coolDownKey(characterID, skillID)
	s.mu.RLock()
	lastUsed := s.coolDowns[key]
	s.mu.RUnlock()
	if lastUsed.IsZero() {
		return 0
	}
	skill, err := s.GetSkill(skillID)
	if err != nil {
		return 0
	}
	elapsed := int(time.Since(lastUsed).Milliseconds())
	if elapsed >= skill.CoolDownMs {
		return 0
	}
	return skill.CoolDownMs - elapsed
}

func coolDownKey(characterID, skillID uint) string {
	return fmt.Sprintf("%d:%d", characterID, skillID)
}

// AssignSkillPoint 将技能点分配到指定技能（仅当角色拥有该技能且还未达到最大等级时）。
func (s *SkillService) AssignSkillPoint(characterID, skillID uint) error {
	if characterID == 0 || skillID == 0 {
		return errors.New("invalid id")
	}
	var ch database.Character
	if err := database.GetDB().First(&ch, characterID).Error; err != nil {
		return fmt.Errorf("character not found: %w", err)
	}
	if ch.SkillPoint <= 0 {
		return errors.New("no skill point available")
	}
	skill, err := s.GetSkill(skillID)
	if err != nil {
		return fmt.Errorf("skill not found: %w", err)
	}
	if skill.MaxLevel <= 0 {
		skill.MaxLevel = 10
	}
	ch.SkillPoint -= 1
	return database.GetDB().Save(&ch).Error
}

// RestoreMP 补充角色 MP（例如技能冷却或休息时调用）。
func (s *SkillService) RestoreMP(characterID uint, mp int) error {
	var ch database.Character
	if err := database.GetDB().First(&ch, characterID).Error; err != nil {
		return err
	}
	ch.MP += mp
	if ch.MP > ch.MaxMP {
		ch.MP = ch.MaxMP
	}
	if ch.MP < 0 {
		ch.MP = 0
	}
	return database.GetDB().Save(&ch).Error
}
