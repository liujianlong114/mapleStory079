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

func (s *InventoryService) EquipItem(characterID uint, itemID int, slot string) error {
	items, err := repository.GetCharacterInventory(characterID, "")
	if err != nil {
		return err
	}
	for i := range items {
		if items[i].ItemID == itemID {
			items[i].IsEquipped = true
			items[i].EquipSlot = slot
			return repository.UpdateCharacterItem(&items[i])
		}
	}
	return errors.New("item not found")
}

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
