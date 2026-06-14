package utils

import (
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"math"
	"math/rand"
)

// MD5 返回字符串的 32 位小写 MD5 摘要。
func MD5(s string) string {
	h := md5.New()
	h.Write([]byte(s))
	return hex.EncodeToString(h.Sum(nil))
}

// HashPassword 使用可选的 salt 进行密码哈希。
// 为兼容既有代码，当仅传入一个参数时，会使用默认 salt。
func HashPassword(password string, salt ...string) string {
	s := "mapleStory079"
	if len(salt) > 0 && salt[0] != "" {
		s = salt[0]
	}
	return MD5(password + s)
}

// ==================== 经验与等级 ====================

// GetRequiredExp 根据等级返回升级所需经验（冒险岛风格的二次曲线）。
func GetRequiredExp(level int) int {
	if level <= 0 {
		return 10
	}
	return 10 + level*level*8
}

// GetRequiredExpUint64 返回 int64 版本，适配部分调用方使用 int64 累加。
func GetRequiredExpUint64(level int) int64 {
	return int64(GetRequiredExp(level))
}

// LevelFromExp 将当前等级与累计经验换算为新等级与剩余经验。
// 经验不够升级时，newLevel = currentLevel，leveledUp = false。
func LevelFromExp(currentLevel int, exp int64) (newLevel int, remaining int64, leveledUp bool) {
	newLevel, remaining, leveledUp = currentLevel, exp, false
	for newLevel < MaxLevel && remaining >= int64(GetRequiredExp(newLevel+1)) {
		remaining -= int64(GetRequiredExp(newLevel + 1))
		newLevel++
		leveledUp = true
	}
	return newLevel, remaining, leveledUp
}

// ==================== 攻击 / 伤害 公式 ====================

// CalculateDamage 基础伤害计算。
func CalculateDamage(atk, def, levelDiff int) int {
	if atk <= 0 {
		return 1
	}
	base := math.Pow(float64(atk), 1.2)
	if levelDiff > 0 {
		base *= 1.0 + float64(levelDiff)*0.05
	}
	if def > 0 {
		base -= float64(def) * 0.6
	}
	if base < 1 {
		base = 1
	}
	return int(base)
}

// DamageByJob 按职业与 STR/DEX/INT/LUK 计算玩家攻击。
//
// 与客户端 game_world.dart 中 _doMeleeHit 的职业主属性对齐：
//
//	战士 -> (str*1.2+level)
//	法师 -> (int*1.3+level)
//	弓箭 -> (dex*1.25+level)
//	飞侠 -> (luk*1.4+level)
//	海盗 -> (str*1.1+dex*0.8+level)
//	新手 -> (str*1.0+level)
func DamageByJob(job int, str, dex, intl, luk, level int) int {
	switch job {
	case JobWarrior:
		return int(float64(str)*1.2) + level
	case JobMagician:
		return int(float64(intl)*1.3) + level
	case JobBowman:
		return int(float64(dex)*1.25) + level
	case JobThief:
		return int(float64(luk)*1.4) + level
	case JobPirate:
		return int(float64(str)*1.1+float64(dex)*0.8) + level
	default: // JobBeginner / 未知
		return str + level
	}
}

// RollDamage 将基础攻击 base 随机浮动 [DamageBaseFactor, DamageCeilingFactor]。
func RollDamage(base int) int {
	if base <= 0 {
		return 1
	}
	f := DamageBaseFactor + rand.Float64()*(DamageCeilingFactor-DamageBaseFactor)
	v := float64(base) * f
	if v < 1 {
		return 1
	}
	return int(v)
}

// RollCritical 根据职业与幸运计算暴击倍率（飞侠更高倍率）。
// critChance 为 0~1 之间；命中则伤害 * critMul。
func RollCritical(base int, job int, luk int) (damage int, critical bool) {
	chance := 0.05 + float64(luk)*0.003
	if job == JobThief {
		chance += 0.1
	}
	critChance := math.Max(HitRateMinThreshold, math.Min(DodgeRateThreshold, chance))
	if rand.Float64() < critChance {
		mul := CritMultiplierDefault
		if job == JobThief {
			mul = CritMultiplierThief
		}
		return int(float64(base) * mul), true
	}
	return base, false
}

// HitRate 命中率：按等级差与 DEX 估算。
// attackerLevel / defenderLevel / attackerDex。
func HitRate(attackerLevel, defenderLevel, attackerDex int) float64 {
	if defenderLevel <= 0 {
		return 0.95
	}
	base := 0.9 - float64(defenderLevel-attackerLevel)*0.02
	// DEX 带来的命中加成
	base += math.Min(0.15, float64(attackerDex)*0.002)
	if base < HitRateMinThreshold {
		base = HitRateMinThreshold
	}
	if base > 1.0 {
		base = 0.99
	}
	return base
}

// RollHit 根据命中率返回是否命中。
func RollHit(hitRate float64) bool {
	return rand.Float64() < hitRate
}

// ==================== 金币 / 经验 ====================

// RollMesos 根据怪物等级返回随机金币掉落。
func RollMesos(mobLevel int, rate float64) int {
	if rate <= 0 {
		rate = DefaultMesosRate
	}
	base := MesosDropBase + mobLevel*2
	f := DamageBaseFactor + rand.Float64()*(DamageCeilingFactor-DamageBaseFactor)
	return int(float64(base) * f * rate)
}

// RollExpGained 根据怪物等级 / 经验倍率返回实际经验奖励。
func RollExpGained(mobLevel int, rate float64) int {
	if rate <= 0 {
		rate = DefaultExpRate
	}
	base := mobLevel*4 + 10
	return int(float64(base) * rate)
}

// ==================== 职业加成 ====================

// ClassBonus 按职业名称返回力量/敏捷/智力/幸运的加成系数。
func ClassBonus(class string) (strMul, dexMul, intMul, lukMul float64) {
	strMul, dexMul, intMul, lukMul = 1.0, 1.0, 1.0, 1.0
	switch class {
	case "warrior", "战士", "1":
		strMul = 1.2
	case "magician", "法师", "魔法师", "2":
		intMul = 1.2
	case "bowman", "弓箭手", "3":
		dexMul = 1.2
	case "thief", "盗贼", "飞侠", "4":
		lukMul = 1.2
	case "pirate", "海盗", "5":
		strMul = 1.1
		dexMul = 1.1
	}
	return
}

// ClassPrimaryStat 返回某职业的"主属性"名称（用于 UI / 统计）。
func ClassPrimaryStat(job int) string {
	switch job {
	case JobWarrior, JobPirate:
		return "STR"
	case JobMagician:
		return "INT"
	case JobBowman:
		return "DEX"
	case JobThief:
		return "LUK"
	default:
		return "STR"
	}
}

// ==================== 格式化 ====================

// FormatExp 将经验数值格式化为千分位展示。
func FormatExp(n int64) string {
	negative := n < 0
	if negative {
		n = -n
	}
	s := fmt.Sprintf("%d", n)
	buf := make([]byte, 0, len(s)+len(s)/3)
	for i, c := range s {
		if i > 0 && (len(s)-i)%3 == 0 {
			buf = append(buf, ',')
		}
		buf = append(buf, byte(c))
	}
	out := string(buf)
	if negative {
		out = "-" + out
	}
	return out
}

// FormatNumber 通用数字千分位。
func FormatNumber(n int64) string {
	return FormatExp(n)
}

// ClampInt 将值夹在 [lo, hi] 区间内。
func ClampInt(v, lo, hi int) int {
	if v < lo {
		return lo
	}
	if v > hi {
		return hi
	}
	return v
}
