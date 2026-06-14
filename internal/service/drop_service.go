package service

import (
	"math/rand"

	"mapleStory079/pkg/database"
	"mapleStory079/pkg/utils"
)

type DropService struct{}

func NewDropService() *DropService { return &DropService{} }

// DroppedItem 单次掉落结果
type DroppedItem struct {
	ItemID   int `json:"item_id"`
	Quantity int `json:"quantity"`
}

// RollMobDrops 根据怪物掉落表随机生成掉落物
func (s *DropService) RollMobDrops(mobID uint, dropRateMultiplier float64) []DroppedItem {
	if database.DB == nil {
		return nil
	}
	if dropRateMultiplier <= 0 {
		dropRateMultiplier = utils.DefaultDropRate
	}
	var rows []database.MobDrop
	if err := database.DB.Where("mob_id = ?", mobID).Find(&rows).Error; err != nil || len(rows) == 0 {
		return nil
	}
	out := make([]DroppedItem, 0, 4)
	for _, row := range rows {
		chance := row.Chance * dropRateMultiplier
		if chance > 1 {
			chance = 1
		}
		if rand.Float64() > chance {
			continue
		}
		qty := row.MinQty
		if row.MaxQty > row.MinQty {
			qty += rand.Intn(row.MaxQty - row.MinQty + 1)
		}
		if qty < 1 {
			qty = 1
		}
		out = append(out, DroppedItem{ItemID: row.ItemID, Quantity: qty})
	}
	return out
}

// AddDropsToInventory 将掉落物加入角色背包（简化：自动拾取）
func (s *DropService) AddDropsToInventory(characterID uint, drops []DroppedItem) error {
	if len(drops) == 0 {
		return nil
	}
	inv := NewInventoryService()
	for _, d := range drops {
		if err := inv.AddItem(characterID, d.ItemID, d.Quantity); err != nil {
			return err
		}
	}
	return nil
}
