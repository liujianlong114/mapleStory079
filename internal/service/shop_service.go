package service

import (
	"errors"
	"fmt"

	"mapleStory079/internal/repository"
)

// ShopItem 商店可购商品
type ShopItem struct {
	ItemID   int    `json:"item_id"`
	Name     string `json:"name"`
	Price    int    `json:"price"`
	Desc     string `json:"desc,omitempty"`
}

// ShopService NPC 商店（079 彩虹村露比等）
type ShopService struct {
	inv *InventoryService
}

func NewShopService() *ShopService {
	return &ShopService{inv: NewInventoryService()}
}

// 079 经典 NPC 商品表（按 NPC ID，与 ms079-main 商店脚本对齐）
var npcShopCatalog = map[int][]int{
	2101:    {2000000, 2000001, 2000002, 2000003, 2030000}, // 希娜（彩虹村）：红/橙/白/蓝药水 + 回城卷轴
	2100:    {2000000, 2000001, 2000003, 2030000},          // 莎丽（彩虹村）：基础药水
	1032104: {2000000, 2000001, 2000002, 2000003, 2000010, 2000011, 2030000}, // 阿勒斯（射手村药水商）
	1032100: {1302000, 1302010, 1302020}, // 金利（明珠港武器商）：木剑/铁剑/宽刃剑
	1032101: {1040000, 1060000, 1072000, 1082000}, // 皮奥（明珠港防具商）：背心/裤子/鞋/手套
	1032102: {1452000, 1462000, 2060000, 2061000}, // 皮奥（射手村武器商）：木弓/木弩/弓矢/弩矢
	1032103: {1002000, 1040000, 1060000, 1072000, 1082000, 1102000}, // 赛德（射手村防具商）
	1032105: {1382000, 1372000},                // 易德（魔法密林武器商）：木杖/短杖
	1032106: {1302010, 1302020, 1302030, 1402000, 1402010, 1432000, 1432010}, // 比休斯（勇士部落武器商）
	1032107: {1332000, 1472000, 2070000, 2070001}, // 阿勒斯（废弃都市杂货商）
	1020000: {2000000, 2000001, 2000003, 2030000}, // 黑公牛（勇士部落杂货商）
	1021000: {1302010, 1302020, 1402000, 1432000}, // 里弗（勇士部落武器商）
	1021001: {1002000, 1040000, 1060000, 1072000, 1082000}, // 哈利（勇士部落防具商）
	1032000: {1332000, 1472000, 2070000}, // 赫拉（废弃都市武器商）
	1052016: {1040000, 1060000, 1072000, 1082000}, // 马克（废弃都市防具商）
}

func (s *ShopService) ListItems(npcID int) ([]ShopItem, error) {
	ids, ok := npcShopCatalog[npcID]
	if !ok || len(ids) == 0 {
		return nil, errors.New("this npc has no shop")
	}
	out := make([]ShopItem, 0, len(ids))
	for _, id := range ids {
		item, err := repository.GetItemByID(uint(id))
		if err != nil || item == nil {
			continue
		}
		out = append(out, ShopItem{
			ItemID: id,
			Name:   item.Name,
			Price:  item.Price,
			Desc:   item.Description,
		})
	}
	if len(out) == 0 {
		return nil, errors.New("shop items not found")
	}
	return out, nil
}

func (s *ShopService) Buy(characterID uint, npcID int, itemID int, quantity int) (int, error) {
	if quantity < 1 {
		quantity = 1
	}
	allowed, ok := npcShopCatalog[npcID]
	if !ok {
		return 0, errors.New("npc has no shop")
	}
	found := false
	for _, id := range allowed {
		if id == itemID {
			found = true
			break
		}
	}
	if !found {
		return 0, errors.New("item not sold here")
	}
	item, err := repository.GetItemByID(uint(itemID))
	if err != nil || item == nil {
		return 0, errors.New("item not found")
	}
	total := item.Price * quantity
	if total < 0 {
		return 0, errors.New("invalid price")
	}
	character, err := repository.GetCharacterByID(characterID)
	if err != nil {
		return 0, errors.New("character not found")
	}
	if character.Mesos < total {
		return 0, fmt.Errorf("not enough mesos (need %d)", total)
	}
	newMesos := character.Mesos - total
	if err := repository.UpdateCharacterStats(characterID, map[string]interface{}{
		"mesos": newMesos,
	}); err != nil {
		return 0, err
	}
	if err := s.inv.AddItem(characterID, itemID, quantity); err != nil {
		// 回滚金币，避免扣钱但拿不到物品
		_ = repository.UpdateCharacterStats(characterID, map[string]interface{}{
			"mesos": character.Mesos,
		})
		return 0, err
	}
	return newMesos, nil
}
