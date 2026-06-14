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

// 079 经典 NPC 商品表（按 NPC ID）
var npcShopCatalog = map[int][]int{
	1012114: {2000000, 2000001, 2000003}, // 露比：红/橙/蓝药水
	1032100: {1302000, 1302007, 1322005}, // 金利：武器
	1032101: {1040002, 1060002, 1072001}, // 皮奥：防具
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
	if total <= 0 {
		return 0, errors.New("invalid price")
	}
	character, err := repository.GetCharacterByID(characterID)
	if err != nil {
		return 0, errors.New("character not found")
	}
	if character.Mesos < total {
		return 0, fmt.Errorf("not enough mesos (need %d)", total)
	}
	if err := repository.UpdateCharacterStats(characterID, map[string]interface{}{
		"mesos": character.Mesos - total,
	}); err != nil {
		return 0, err
	}
	if err := s.inv.AddItem(characterID, itemID, quantity); err != nil {
		_ = repository.UpdateCharacterStats(characterID, map[string]interface{}{
			"mesos": character.Mesos,
		})
		return 0, err
	}
	return character.Mesos - total, nil
}
