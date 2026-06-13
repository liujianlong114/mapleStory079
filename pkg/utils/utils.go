package utils

import (
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"math"
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
