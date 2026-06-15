package service

import (
	"errors"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
)

type InventoryService struct{}

func NewInventoryService() *InventoryService { return &InventoryService{} }

func (s *InventoryService) AddItem(characterID uint, itemID int, quantity int) error {
	if quantity <= 0 {
		return errors.New("quantity must be positive")
	}
	items, err := repository.GetCharacterInventory(characterID, "")
	if err != nil {
		return err
	}
	for i := range items {
		if items[i].ItemID == itemID {
			items[i].Quantity += quantity
			return repository.UpdateCharacterItem(&items[i])
		}
	}
	inventory := &database.CharacterInventory{
		CharacterID: characterID,
		ItemID:      itemID,
		Quantity:    quantity,
	}
	return repository.AddCharacterItem(inventory)
}

func (s *InventoryService) RemoveItem(characterID uint, itemID int, quantity int) error {
	if quantity <= 0 {
		return errors.New("quantity must be positive")
	}
	items, err := repository.GetCharacterInventory(characterID, "")
	if err != nil {
		return err
	}
	for i := range items {
		if items[i].ItemID == itemID {
			if items[i].Quantity <= quantity {
				return repository.DeleteCharacterItem(items[i].ID)
			}
			items[i].Quantity -= quantity
			return repository.UpdateCharacterItem(&items[i])
		}
	}
	return errors.New("item not found")
}

func (s *InventoryService) GetInventory(characterID uint) ([]database.CharacterInventory, error) {
	return repository.GetCharacterInventory(characterID, "")
}

// EquipItem 换装：找到背包中的目标物品，标记已装备并记录槽位；
// 若槽位已经存在其他装备，会自动卸下旧装备。
func (s *InventoryService) EquipItem(characterID uint, itemID int, slot string) error {
	items, err := repository.GetCharacterInventory(characterID, "")
	if err != nil {
		return err
	}
	var targetIdx int = -1
	for i := range items {
		// 先处理同槽位上已装备的其他物品
		if items[i].IsEquipped && items[i].EquipSlot == slot && items[i].ItemID != itemID {
			items[i].IsEquipped = false
			items[i].EquipSlot = ""
			if err := repository.UpdateCharacterItem(&items[i]); err != nil {
				return err
			}
		}
		if items[i].ItemID == itemID {
			targetIdx = i
		}
	}
	if targetIdx < 0 {
		return errors.New("item not found")
	}
	items[targetIdx].IsEquipped = true
	items[targetIdx].EquipSlot = slot
	return repository.UpdateCharacterItem(&items[targetIdx])
}

// UnequipItem 卸下装备。
func (s *InventoryService) UnequipItem(characterID uint, itemID int) error {
	items, err := repository.GetCharacterInventory(characterID, "")
	if err != nil {
		return err
	}
	for i := range items {
		if items[i].ItemID == itemID {
			items[i].IsEquipped = false
			items[i].EquipSlot = ""
			return repository.UpdateCharacterItem(&items[i])
		}
	}
	return errors.New("item not found")
}

// GetEquipped 返回角色当前装备列表（含装备属性）。
func (s *InventoryService) GetEquipped(characterID uint) ([]database.CharacterInventory, error) {
	items, err := repository.GetCharacterInventory(characterID, "")
	if err != nil {
		return nil, err
	}
	equipped := make([]database.CharacterInventory, 0, len(items))
	for i := range items {
		if items[i].IsEquipped {
			equipped = append(equipped, items[i])
		}
	}
	return equipped, nil
}

// UseItemResult 消耗类道具使用结果。
type UseItemResult struct {
	ItemID     int `json:"item_id"`
	Quantity   int `json:"quantity"`
	HPRecovery int `json:"hp_recovery"`
	MPRecovery int `json:"mp_recovery"`
}

// UseItem 使用一个消耗类道具：查找角色背包中的目标物品，扣除 1 个数量，
// 并返回该道具的 HP/MP 恢复值（从 Item 元数据读取）。
// 若物品不存在、数量不足或非消耗品则返回错误。
func (s *InventoryService) UseItem(characterID uint, itemID int) (*UseItemResult, error) {
	items, err := repository.GetCharacterInventory(characterID, "")
	if err != nil {
		return nil, err
	}
	var targetIdx int = -1
	for i := range items {
		if items[i].ItemID == itemID {
			targetIdx = i
			break
		}
	}
	if targetIdx < 0 {
		return nil, errors.New("item not found in inventory")
	}
	if items[targetIdx].Quantity <= 0 {
		return nil, errors.New("item quantity is zero")
	}

	// 读取道具元数据获取恢复值
	itemMeta, err := repository.GetItemByID(uint(itemID))
	if err != nil {
		return nil, err
	}
	hpRec := 0
	mpRec := 0
	if itemMeta != nil {
		// 消耗品（ItemType == 0）才有恢复值
		if itemMeta.ItemType == 0 || itemMeta.ItemType == 2 {
			hpRec = itemMeta.HPRecovery
			mpRec = itemMeta.MPRecovery
		}
	}

	// 扣除 1 个
	items[targetIdx].Quantity -= 1
	if items[targetIdx].Quantity <= 0 {
		if err := repository.DeleteCharacterItem(items[targetIdx].ID); err != nil {
			return nil, err
		}
	} else {
		if err := repository.UpdateCharacterItem(&items[targetIdx]); err != nil {
			return nil, err
		}
	}

	return &UseItemResult{
		ItemID:     itemID,
		Quantity:   1,
		HPRecovery: hpRec,
		MPRecovery: mpRec,
	}, nil
}
