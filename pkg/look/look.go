package look

import (
	"fmt"
	"sort"
	"strconv"
	"strings"
)

// CharLook 079 完整外观（Phase 1 CharLook：含全部可见装备槽）
type CharLook struct {
	Gender   int `json:"gender"`
	Face     int `json:"face"`
	Hair     int `json:"hair"`
	Skin     int `json:"skin"`
	Top      int `json:"top"`
	Bottom   int `json:"bottom"`
	Longcoat int `json:"longcoat"`
	Shoes    int `json:"shoes"`
	Cap      int `json:"cap"`
	Cape     int `json:"cape"`
	Glove    int `json:"glove"`
	Shield   int `json:"shield"`
	Weapon   int `json:"weapon"`
	FaceAcc  int `json:"face_acc"`
	EyeAcc   int `json:"eye_acc"`
	Earring  int `json:"earring"`
}

// BodyID 性别对应 Body 部件（0000200x）
func (l CharLook) BodyID() int {
	if l.Gender == 1 {
		return 2001
	}
	return 2000
}

// HeadID 光头/脸型基底（0001200x），HeavenClient Body.cpp 与 Body 成对加载。
// 缺此部件时脸/发会悬空，只剩眼睛和鞋。
func (l CharLook) HeadID() int {
	return l.BodyID() + 10000
}

// EquipIDs 传给 CharacterRenderer.compose 的装备 ID 列表（8 位字符串）
func (l CharLook) EquipIDs() []string {
	ids := []int{l.BodyID(), l.HeadID(), l.Face, l.Hair}
	if l.Longcoat != 0 {
		ids = append(ids, l.Longcoat)
	} else {
		if l.Top != 0 {
			ids = append(ids, l.Top)
		}
		if l.Bottom != 0 {
			ids = append(ids, l.Bottom)
		}
	}
	for _, id := range []int{l.Shoes, l.Glove, l.Cap, l.Cape, l.Shield, l.Weapon, l.FaceAcc, l.EyeAcc, l.Earring} {
		if id != 0 {
			ids = append(ids, id)
		}
	}
	out := make([]string, 0, len(ids))
	seen := make(map[int]struct{}, len(ids))
	for _, id := range ids {
		if id == 0 {
			continue
		}
		if _, ok := seen[id]; ok {
			continue
		}
		seen[id] = struct{}{}
		out = append(out, fmt.Sprintf("%08d", id))
	}
	return out
}

// CacheKey 合成图缓存文件名（v2 含 Head 0001200x）
func (l CharLook) CacheKey() string {
	parts := []string{
		"v2",
		strconv.Itoa(l.Gender),
		strconv.Itoa(l.Face),
		strconv.Itoa(l.Hair),
		strconv.Itoa(l.Skin),
		slotKey(l.Top),
		slotKey(l.Bottom),
		slotKey(l.Longcoat),
		slotKey(l.Shoes),
		slotKey(l.Cap),
		slotKey(l.Cape),
		slotKey(l.Glove),
		slotKey(l.Shield),
		slotKey(l.Weapon),
		slotKey(l.FaceAcc),
		slotKey(l.EyeAcc),
		slotKey(l.Earring),
	}
	return strings.Join(parts, "_")
}

func slotKey(id int) string {
	if id == 0 {
		return "0"
	}
	return strconv.Itoa(id)
}

// FromEquipMap 从背包 equip_slot → item_id 构建外观
func FromEquipMap(gender, face, hair, skin int, equips map[string]int) CharLook {
	l := CharLook{Gender: gender, Face: face, Hair: hair, Skin: skin}
	for slot, id := range equips {
		switch strings.ToLower(slot) {
		case "coat", "top":
			l.Top = id
		case "pants", "bottom":
			l.Bottom = id
		case "longcoat":
			l.Longcoat = id
		case "shoes":
			l.Shoes = id
		case "hat", "cap":
			l.Cap = id
		case "cape":
			l.Cape = id
		case "glove", "gloves":
			l.Glove = id
		case "shield":
			l.Shield = id
		case "weapon":
			l.Weapon = id
		case "faceacc", "face_acc":
			l.FaceAcc = id
		case "eyeacc", "eye_acc", "glass":
			l.EyeAcc = id
		case "earring", "earacc":
			l.Earring = id
		}
	}
	return l
}

// SortEquipIDsForDebug 稳定排序（测试用）
func SortEquipIDsForDebug(ids []string) []string {
	cp := append([]string(nil), ids...)
	sort.Strings(cp)
	return cp
}
