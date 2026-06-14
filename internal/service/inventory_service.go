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
