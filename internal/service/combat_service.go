package service

import (
	"fmt"
	"math"
	"math/rand"
	"time"

	"mapleStory079/pkg/database"
	"mapleStory079/pkg/utils"
)

type CombatService struct {
	drops *DropService
}

func NewCombatService() *CombatService {
	return &CombatService{drops: NewDropService()}
}

type CombatResult struct {
	PlayerDamage int
	MobDamage    int
	ExpGained    int
	MesosGained  int
	LevelUp      bool
	MobDead      bool
	Message      string
}

// BattleResult 用于命中/暴击/伤害详情与目标状态返回。
type BattleResult struct {
	IsHit        bool
	IsCritical   bool
	Damage       int
	TargetHP     int
	TargetDead   bool
	ExpGained    int
	MesosGained  int
	LevelUp      bool
	ItemsDropped []DroppedItem
	Message      string
}

// Attack 玩家对怪物发起一次普通攻击。
func (s *CombatService) Attack(player *database.Character, mob *database.Mob) CombatResult {
	rand.Seed(time.Now().UnixNano())
	// 玩家伤害 = (STR + 基础攻击) * 系数 - 怪物物理防御
	atk := player.STR + 10
	mobDef := mob.PhysicalDefense
	playerDamage := int(float64(atk)*(1.0+rand.Float64()*0.2)) - mobDef
	if playerDamage < 1 {
		playerDamage = 1
	}
	mob.HP -= playerDamage

	result := CombatResult{PlayerDamage: playerDamage}
	if mob.HP <= 0 {
		result.MobDead = true
		player.Exp += mob.ExpReward
		player.Mesos += mob.MesosReward
		result.ExpGained = mob.ExpReward
		result.MesosGained = mob.MesosReward
		if LevelUp(player) {
			result.LevelUp = true
			result.Message = "击败怪物并升级！"
		} else {
			result.Message = "击败怪物！"
		}
		return result
	}
	// 怪物反击：基于物理攻击、玩家敏捷提供闪避。
	mobAtk := mob.PhysicalAttack
	avoidance := math.Min(0.4, float64(player.DEX)/400)
	if rand.Float64() < avoidance {
		result.MobDamage = 0
		result.Message = "你完美闪避了攻击！"
		return result
	}
	dmg := mobAtk - player.DEX/5
	if dmg < 1 {
		dmg = 1
	}
	player.HP -= dmg
	result.MobDamage = dmg
	return result
}

// PlayerAttackMob 玩家攻击怪物，返回是否命中、暴击、伤害与怪物状态。
func (s *CombatService) PlayerAttackMob(player *database.Character, mob *database.Mob) (*BattleResult, error) {
	result := &BattleResult{Message: "攻击完成"}

	// 命中率：基于角色 DEX 与怪物等级差。
	levelDiff := float64(mob.Level - player.Level)
	baseHit := 0.85 + float64(player.DEX)/400.0
	hitRate := math.Max(0.2, math.Min(0.98, baseHit-levelDiff*0.02))
	if rand.Float64() > hitRate {
		result.IsHit = false
		result.Message = "MISS！"
		return result, nil
	}
	result.IsHit = true

	// 暴击判定：LUK 越高暴击率越高，飞侠额外加成（与 constants 中 crit 常量对齐）。
	critBase := 0.03 + float64(player.LUK)/200.0
	if player.Class == utils.JobThief {
		critBase += 0.08
	}
	critBase += float64(player.Level) * 0.002
	critRate := math.Min(0.7, critBase)
	isCrit := rand.Float64() < critRate
	result.IsCritical = isCrit

	// 伤害计算（按职业偏向：战士→力量，法师→智力，弓→敏捷，飞侠→运气）。
	var baseAtk float64
	switch player.Class {
	case utils.JobWarrior:
		baseAtk = float64(player.STR)*1.2 + float64(player.DEX)*0.3
	case utils.JobMagician:
		baseAtk = float64(player.INT)*1.3 + float64(player.LUK)*0.2
	case utils.JobBowman:
		baseAtk = float64(player.DEX)*1.25 + float64(player.STR)*0.3
	case utils.JobThief:
		baseAtk = float64(player.LUK)*1.2 + float64(player.DEX)*0.4
	default: // 新手/海盗/未知
		baseAtk = float64(player.STR) + 10
	}

	// 基础伤害 = (攻击力 * 随机波动) - 怪物防御（与 constants.Factor 对齐）。
	fluctuation := utils.DamageBaseFactor + rand.Float64()*(utils.DamageCeilingFactor-utils.DamageBaseFactor)
	damage := int(baseAtk*fluctuation) - mob.PhysicalDefense
	if damage < 1 {
		damage = 1
	}
	if isCrit {
		critMul := utils.CritMultiplierDefault
		if player.Class == utils.JobThief {
			critMul = utils.CritMultiplierThief
		}
		damage = int(float64(damage) * critMul)
	}
	result.Damage = damage

	mob.HP -= damage
	if mob.HP < 0 {
		mob.HP = 0
	}
	result.TargetHP = mob.HP
	if mob.HP <= 0 {
		result.TargetDead = true
		result.ExpGained = mob.ExpReward
		result.MesosGained = mob.MesosReward
		player.Exp += mob.ExpReward
		player.Mesos += mob.MesosReward
		result.ItemsDropped = s.drops.RollMobDrops(mob.ID, utils.DefaultDropRate)
		if LevelUp(player) {
			result.LevelUp = true
			result.Message = "击败怪物，升级了！"
		} else {
			result.Message = "击败怪物！"
		}
	} else {
		result.Message = "命中！"
	}
	return result, nil
}

// MobAttackPlayer 怪物攻击玩家，返回伤害与玩家状态。
func (s *CombatService) MobAttackPlayer(player *database.Character, mob *database.Mob) (*BattleResult, error) {
	result := &BattleResult{Message: "怪物攻击完成"}

	// 玩家闪避：基于 DEX。
	dodgeRate := math.Min(0.5, float64(player.DEX)/300.0)
	if rand.Float64() < dodgeRate {
		result.IsHit = false
		result.TargetHP = player.HP
		result.Message = "你闪避了攻击！"
		return result, nil
	}
	result.IsHit = true

	// 伤害 = 怪物攻击 - 玩家防御（简化为 DEX/5 + STR/10）。
	defense := player.DEX/5 + player.STR/10
	damage := mob.PhysicalAttack - defense
	if damage < 1 {
		damage = 1
	}
	result.Damage = damage

	player.HP -= damage
	if player.HP < 0 {
		player.HP = 0
	}
	result.TargetHP = player.HP
	if player.HP <= 0 {
		result.TargetDead = true
		result.Message = "你被击败了..."
	} else {
		result.Message = "受到伤害！"
	}
	return result, nil
}

// GetCombatStats 返回角色战斗属性（攻击力、防御、HP百分比等）。
func (s *CombatService) GetCombatStats(player *database.Character) map[string]interface{} {
	attack := player.STR + player.DEX/2 + player.Level*2
	defense := player.DEX/5 + player.STR/10
	hpPercent := 0.0
	if player.MaxHP > 0 {
		hpPercent = float64(player.HP) / float64(player.MaxHP) * 100
	}
	mpPercent := 0.0
	if player.MaxMP > 0 {
		mpPercent = float64(player.MP) / float64(player.MaxMP) * 100
	}
	return map[string]interface{}{
		"attack":     attack,
		"defense":    defense,
		"hp":         player.HP,
		"max_hp":     player.MaxHP,
		"mp":         player.MP,
		"max_mp":     player.MaxMP,
		"hp_percent": hpPercent,
		"mp_percent": mpPercent,
		"level":      player.Level,
		"class":      player.Class,
	}
}

// ReviveCharacter 复活角色，HP/MP 恢复为最大值的一半，位置重置为 (0,0)。
func (s *CombatService) ReviveCharacter(player *database.Character) {
	player.HP = int(math.Max(1, float64(player.MaxHP)/2))
	player.MP = int(math.Max(1, float64(player.MaxMP)/2))
	player.PositionX = 0
	player.PositionY = 0
}

// DamagePlayer 直接对玩家造成伤害（用于陷阱/环境）。
func (s *CombatService) DamagePlayer(player *database.Character, dmg int) CombatResult {
	if dmg < 0 {
		dmg = 0
	}
	player.HP -= dmg
	if player.HP < 0 {
		player.HP = 0
	}
	return CombatResult{MobDamage: dmg}
}

// IsDead 判断角色是否死亡。
func (s *CombatService) IsDead(ch *database.Character) bool {
	return ch.HP <= 0
}

// Respawn 将角色在指定地图复活，HP/MP 恢复为最大值的一半。
func (s *CombatService) Respawn(ch *database.Character, mapID uint, x, y int) {
	ch.HP = int(math.Max(1, float64(ch.MaxHP)/2))
	ch.MP = int(math.Max(1, float64(ch.MaxMP)/2))
	ch.MapID = mapID
	ch.PositionX = x
	ch.PositionY = y
}

// FullAttack 一次完整战斗：玩家攻击怪物，命中判定+暴击+伤害，
// 若怪物未死亡则怪物反击。返回详细战斗结果。
func (s *CombatService) FullAttack(player *database.Character, mob *database.Mob) (*BattleResult, error) {
	result := &BattleResult{Message: "攻击完成"}
	levelDiff := float64(mob.Level - player.Level)
	baseHit := 0.85 + float64(player.DEX)/400.0
	hitRate := math.Max(0.2, math.Min(0.98, baseHit-levelDiff*0.02))
	if rand.Float64() > hitRate {
		result.IsHit = false
		result.Message = "MISS！"
		return result, nil
	}
	result.IsHit = true

	critBase := 0.03 + float64(player.LUK)/200.0
	if player.Class == utils.JobThief {
		critBase += 0.08
	}
	critBase += float64(player.Level) * 0.002
	critRate := math.Min(0.7, critBase)
	isCrit := rand.Float64() < critRate
	result.IsCritical = isCrit

	var baseAtk float64
	switch player.Class {
	case utils.JobWarrior:
		baseAtk = float64(player.STR)*1.2 + float64(player.DEX)*0.3
	case utils.JobMagician:
		baseAtk = float64(player.INT)*1.3 + float64(player.LUK)*0.2
	case utils.JobBowman:
		baseAtk = float64(player.DEX)*1.25 + float64(player.STR)*0.3
	case utils.JobThief:
		baseAtk = float64(player.LUK)*1.2 + float64(player.DEX)*0.4
	default:
		baseAtk = float64(player.STR) + 10
	}

	fluctuation := utils.DamageBaseFactor +
		rand.Float64()*(utils.DamageCeilingFactor-utils.DamageBaseFactor)
	damage := int(baseAtk*fluctuation) - mob.PhysicalDefense
	if damage < 1 {
		damage = 1
	}
	if isCrit {
		critMul := utils.CritMultiplierDefault
		if player.Class == utils.JobThief {
			critMul = utils.CritMultiplierThief
		}
		damage = int(float64(damage) * critMul)
	}
	result.Damage = damage
	mob.HP -= damage
	if mob.HP < 0 {
		mob.HP = 0
	}
	result.TargetHP = mob.HP

	if mob.HP <= 0 {
		result.TargetDead = true
		expReward := mob.ExpReward
		if expReward <= 0 {
			expReward = mob.Level*4 + 10
		}
		mesosReward := mob.MesosReward
		if mesosReward <= 0 {
			mesosReward = mob.Level*2 + rand.Intn(5)
		}
		player.Exp += expReward
		player.Mesos += mesosReward
		result.ExpGained = expReward
		result.MesosGained = mesosReward
		if LevelUp(player) {
			result.LevelUp = true
			result.Message = "击败怪物并升级！"
		} else {
			result.Message = "击败怪物！"
		}
		return result, nil
	}

	// 怪物反击
	dodgeRate := math.Min(0.5, float64(player.DEX)/300.0)
	if rand.Float64() < dodgeRate {
		result.Message = "命中！玩家闪避了反击"
		return result, nil
	}
	mobAtk := mob.PhysicalAttack
	if mobAtk <= 0 {
		mobAtk = mob.Level + 2
	}
	playerDef := player.DEX/5 + player.STR/10
	playerDmg := mobAtk - playerDef
	if playerDmg < 1 {
		playerDmg = 1
	}
	player.HP -= playerDmg
	if player.HP < 0 {
		player.HP = 0
	}
	result.Message = fmt.Sprintf("命中！怪物反击造成 %d 点伤害", playerDmg)
	return result, nil
}
