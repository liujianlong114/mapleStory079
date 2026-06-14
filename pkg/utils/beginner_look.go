package utils

import "errors"

// BeginnerLook 079 冒险家新手外观。
// 封包结构参考 HeavenMS CreateCharHandler.java:54-66（face, hair, haircolor, skincolor, top, bottom, shoes, weapon, gender）
// 合法 ID 参考 ms079-main CharLoginHandler.java:240-318 与 ZLHSS2 CharLoginHandler.java:371-409
type BeginnerLook struct {
	Face      int
	Hair      int // 发型基底（不含发色偏移）
	HairColor int // 发色偏移，最终 hair = Hair + HairColor
	Skin      int // skincolor 0~3
	Top       int
	Bottom    int
	Shoes     int
	Weapon    int
}

var (
	maleFaces       = []int{20100, 20401, 20402}
	maleHairs       = []int{30030, 30027, 30000}
	maleTops        = []int{1040002, 1040006, 1040010, 1042167}
	maleBottoms     = []int{1060002, 1060006, 1062115}
	femaleFaces     = []int{21002, 21700, 21201}
	femaleHairs     = []int{31002, 31047, 31057}
	femaleTops      = []int{1041002, 1041006, 1041010, 1041011, 1042167}
	femaleBottoms   = []int{1061002, 1061008, 1062115}
	beginnerShoes   = []int{1072001, 1072005, 1072037, 1072038, 1072383}
	beginnerWeapons = []int{1302000, 1322005, 1312004, 1442079}
)

// DefaultBeginnerLook 返回指定性别的默认新手外观
func DefaultBeginnerLook(gender int) BeginnerLook {
	if gender == 1 {
		return BeginnerLook{
			Face: femaleFaces[0], Hair: femaleHairs[0], HairColor: 0, Skin: 0,
			Top: femaleTops[0], Bottom: femaleBottoms[0],
			Shoes: beginnerShoes[0], Weapon: beginnerWeapons[0],
		}
	}
	return BeginnerLook{
		Face: maleFaces[0], Hair: maleHairs[0], HairColor: 0, Skin: 0,
		Top: maleTops[0], Bottom: maleBottoms[0],
		Shoes: beginnerShoes[0], Weapon: beginnerWeapons[0],
	}
}

// CombinedHair 返回写入数据库的完整发型 ID
func (l BeginnerLook) CombinedHair() int {
	return l.Hair + l.HairColor
}

// ValidateBeginnerLook 校验 ms079 CharLoginHandler.CreateChar 外观（hairColor/skin 固定 0）
func ValidateBeginnerLook(gender int, look BeginnerLook) error {
	if gender != 0 && gender != 1 {
		return errors.New("invalid gender")
	}
	if look.Skin != 0 {
		return errors.New("invalid skin")
	}
	if look.HairColor != 0 {
		return errors.New("invalid hair color")
	}
	if !intInList(beginnerShoes, look.Shoes) {
		return errors.New("invalid shoes")
	}
	if !intInList(beginnerWeapons, look.Weapon) {
		return errors.New("invalid weapon")
	}
	if gender == 0 {
		if !intInList(maleFaces, look.Face) {
			return errors.New("invalid face")
		}
		if !intInList(maleHairs, look.Hair) {
			return errors.New("invalid hair")
		}
		if !intInList(maleTops, look.Top) {
			return errors.New("invalid top")
		}
		if !intInList(maleBottoms, look.Bottom) {
			return errors.New("invalid bottom")
		}
		return nil
	}
	if !intInList(femaleFaces, look.Face) {
		return errors.New("invalid face")
	}
	if !intInList(femaleHairs, look.Hair) {
		return errors.New("invalid hair")
	}
	if !intInList(femaleTops, look.Top) {
		return errors.New("invalid top")
	}
	if !intInList(femaleBottoms, look.Bottom) {
		return errors.New("invalid bottom")
	}
	return nil
}

// CanCreateCharacterName ms079 MapleCharacterUtil.canCreateChar（2~15，本项目 DB 限制 12）
func CanCreateCharacterName(name string) bool {
	if len(name) < 2 || len(name) > 12 {
		return false
	}
	if IsForbiddenName(name) {
		return false
	}
	for _, r := range name {
		if r >= 0x4e00 && r <= 0x9fff {
			continue // 中文
		}
		if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') || r == '_' || r == '-' {
			continue
		}
		return false
	}
	return true
}

func intInList(list []int, v int) bool {
	for _, x := range list {
		if x == v {
			return true
		}
	}
	return false
}
