package service

import (
	"errors"
	"fmt"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
)

// EquippedStats 从装备中获得的总属性加成
type EquippedStats struct {
	STR         int `json:"str"`
	DEX         int `json:"dex"`
	INT         int `json:"int"`
	LUK         int `json:"luk"`
	MaxHP       int `json:"max_hp"`
	MaxMP       int `json:"max_mp"`
	PAD         int `json:"pad"`  // 物理攻击力
	MAD         int `json:"mad"`  // 魔法攻击力
	PDD         int `json:"pdd"`  // 物理防御力
	MDD         int `json:"mdd"`  // 魔法防御力
	ACC         int `json:"acc"`  // 命中率
	EVA         int `json:"eva"`  // 回避率
	Speed       int `json:"speed"`
	Jump        int `json:"jump"`
}

// EquippedItemDetail 已装备物品详情
type EquippedItemDetail struct {
	database.CharacterInventory
	ItemName  string `json:"item_name"`
	ItemType  int    `json:"item_type"`
	ItemStats EquippedStats `json:"item_stats"`
}

type EquipService struct{}

func NewEquipService() *EquipService { return &EquipService{} }

// Slot映射表：物品ID前缀 → 装备槽位
var slotPrefixMap = []struct {
	Min  int
	Max  int
	Slot string
}{
	{100, 100, "hat"},      // 帽子
	{101, 101, "face"},     // 脸饰
	{102, 102, "eye"},      // 眼饰
	{103, 103, "earring"},  // 耳环
	{104, 105, "top"},      // 上衣
	{106, 106, "bottom"},   // 下衣
	{107, 107, "shoes"},    // 鞋子
	{108, 108, "gloves"},   // 手套
	{109, 109, "shield"},   // 盾牌
	{110, 110, "cape"},     // 披风
	{130, 132, "weapon"},   // 单手剑/斧/钝器
	{133, 133, "weapon"},   // 短剑/匕首
	{134, 134, "weapon"},   // 双手剑
	{135, 137, "weapon"},   // 双手武器
	{138, 138, "weapon"},   // 法杖
	{139, 139, "weapon"},   // 双手武器
	{140, 142, "weapon"},   // 矛/枪/双手斧
	{143, 143, "weapon"},   // 双手钝器
	{144, 145, "weapon"},   // 弓
	{146, 146, "weapon"},   // 弩
	{147, 147, "weapon"},   // 拳套
	{148, 148, "weapon"},   // 指节
	{149, 149, "weapon"},   // 手枪
	{150, 151, "weapon"},   // 其他武器
	{112, 112, "weapon"},   // 特殊
}

// GetEquipSlot 根据物品ID判断装备槽位
func (s *EquipService) GetEquipSlot(itemID int) string {
	prefix := itemID / 10000
	for _, m := range slotPrefixMap {
		if prefix >= m.Min && prefix <= m.Max {
			return m.Slot
		}
	}
	return ""
}

// IsEquipable 判断物品是否可以装备
func (s *EquipService) IsEquipable(itemID int) bool {
	return s.GetEquipSlot(itemID) != ""
}

// GetEquippedStats 计算角色所有已装备物品的总属性加成
func (s *EquipService) GetEquippedStats(characterID uint) (*EquippedStats, error) {
	items, err := repository.GetCharacterInventory(characterID, "")
	if err != nil {
		return nil, err
	}

	stats := &EquippedStats{}
	for _, inv := range items {
		if !inv.IsEquipped {
			continue
		}
		item, err := repository.GetItemByID(uint(inv.ItemID))
		if err != nil || item == nil {
			continue
		}
		stats.STR += item.STR
		stats.DEX += item.DEX
		stats.INT += item.INT
		stats.LUK += item.LUK
		stats.PAD += item.PAD
		stats.MAD += item.MAD
		stats.PDD += item.PDD
		stats.MDD += item.MDD
		stats.ACC += item.ACC
		stats.EVA += item.EVA
		stats.Speed += item.Speed
		stats.Jump += item.Jump
	}
	return stats, nil
}

// ApplyEquipBonuses 将装备加成应用到角色属性上
// 返回更新后的角色对象
func (s *EquipService) ApplyEquipBonuses(character *database.Character) (*EquippedStats, error) {
	if character == nil {
		return nil, errors.New("nil character")
	}
	stats, err := s.GetEquippedStats(character.ID)
	if err != nil {
		return nil, err
	}
	// 装备加成不直接修改角色基础属性，而是通过 GetTotalStats 查询时叠加
	return stats, nil
}

// GetTotalStats 获取角色的总属性（基础属性 + 装备加成）
func (s *EquipService) GetTotalStats(character *database.Character) (map[string]interface{}, error) {
	if character == nil {
		return nil, errors.New("nil character")
	}
	equipStats, err := s.GetEquippedStats(character.ID)
	if err != nil {
		return nil, err
	}

	total := map[string]interface{}{
		"base_str":  character.STR,
		"base_dex":  character.DEX,
		"base_int":  character.INT,
		"base_luk":  character.LUK,
		"str":       character.STR + equipStats.STR,
		"dex":       character.DEX + equipStats.DEX,
		"int":       character.INT + equipStats.INT,
		"luk":       character.LUK + equipStats.LUK,
		"max_hp":    character.MaxHP + equipStats.MaxHP,
		"max_mp":    character.MaxMP + equipStats.MaxMP,
		"pad":       equipStats.PAD,
		"mad":       equipStats.MAD,
		"pdd":       equipStats.PDD,
		"mdd":       equipStats.MDD,
		"acc":       equipStats.ACC,
		"eva":       equipStats.EVA,
		"speed":     equipStats.Speed + 100, // 基础速度100
		"jump":      equipStats.Jump + 100,  // 基础跳跃100
		"equip_str": equipStats.STR,
		"equip_dex": equipStats.DEX,
		"equip_int": equipStats.INT,
		"equip_luk": equipStats.LUK,
		"equip_pad": equipStats.PAD,
		"equip_mad": equipStats.MAD,
		"equip_pdd": equipStats.PDD,
		"equip_mdd": equipStats.MDD,
	}
	return total, nil
}

// EquipItem 装备物品：验证槽位、卸下同槽旧装备、标记新装备
func (s *EquipService) EquipItem(characterID uint, itemID int) (*EquippedItemDetail, error) {
	slot := s.GetEquipSlot(itemID)
	if slot == "" {
		return nil, fmt.Errorf("物品 %d 不是可装备物品", itemID)
	}

	// 检查物品是否在背包中
	items, err := repository.GetCharacterInventory(characterID, "")
	if err != nil {
		return nil, err
	}

	var target *database.CharacterInventory
	for i := range items {
		if items[i].ItemID == itemID {
			target = &items[i]
			break
		}
	}
	if target == nil {
		return nil, errors.New("背包中没有该物品")
	}

	// 卸下同槽位已装备的旧物品
	for i := range items {
		if items[i].IsEquipped && items[i].EquipSlot == slot && items[i].ItemID != itemID {
			items[i].IsEquipped = false
			items[i].EquipSlot = ""
			repository.UpdateCharacterItem(&items[i])
		}
	}

	// 装备新物品
	target.IsEquipped = true
	target.EquipSlot = slot
	if err := repository.UpdateCharacterItem(target); err != nil {
		return nil, err
	}

	// 获取物品详情
	item, _ := repository.GetItemByID(uint(itemID))
	detail := &EquippedItemDetail{
		CharacterInventory: *target,
	}
	if item != nil {
		detail.ItemName = item.Name
		detail.ItemType = item.ItemType
		detail.ItemStats = EquippedStats{
			STR: item.STR, DEX: item.DEX, INT: item.INT, LUK: item.LUK,
			PAD: item.PAD, MAD: item.MAD,
			PDD: item.PDD, MDD: item.MDD,
			ACC: item.ACC, EVA: item.EVA,
			Speed: item.Speed, Jump: item.Jump,
		}
	}

	return detail, nil
}

// UnequipItem 卸下装备
func (s *EquipService) UnequipItem(characterID uint, itemID int) error {
	items, err := repository.GetCharacterInventory(characterID, "")
	if err != nil {
		return err
	}
	for i := range items {
		if items[i].ItemID == itemID && items[i].IsEquipped {
			items[i].IsEquipped = false
			items[i].EquipSlot = ""
			return repository.UpdateCharacterItem(&items[i])
		}
	}
	return errors.New("未装备该物品")
}

// GetEquippedWithDetails 获取已装备物品的详细信息
func (s *EquipService) GetEquippedWithDetails(characterID uint) ([]EquippedItemDetail, error) {
	items, err := repository.GetCharacterInventory(characterID, "")
	if err != nil {
		return nil, err
	}

	result := make([]EquippedItemDetail, 0)
	for _, inv := range items {
		if !inv.IsEquipped {
			continue
		}
		detail := EquippedItemDetail{
			CharacterInventory: inv,
		}
		item, _ := repository.GetItemByID(uint(inv.ItemID))
		if item != nil {
			detail.ItemName = item.Name
			detail.ItemType = item.ItemType
			detail.ItemStats = EquippedStats{
				STR: item.STR, DEX: item.DEX, INT: item.INT, LUK: item.LUK,
				PAD: item.PAD, MAD: item.MAD,
				PDD: item.PDD, MDD: item.MDD,
				ACC: item.ACC, EVA: item.EVA,
				Speed: item.Speed, Jump: item.Jump,
			}
		}
		result = append(result, detail)
	}
	return result, nil
}
