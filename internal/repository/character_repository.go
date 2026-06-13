package repository

import (
	"mapleStory079/pkg/database"
)

type CharacterRepository struct{}

func NewCharacterRepository() *CharacterRepository {
	return &CharacterRepository{}
}

func (r *CharacterRepository) Create(character *database.Character) error {
	return database.DB.Create(character).Error
}

func (r *CharacterRepository) FindByID(id uint) (*database.Character, error) {
	var character database.Character
	err := database.DB.Where("id = ?", id).First(&character).Error
	return &character, err
}

func (r *CharacterRepository) FindByAccountID(accountID uint) ([]database.Character, error) {
	var characters []database.Character
	err := database.DB.Where("account_id = ?", accountID).Find(&characters).Error
	return characters, err
}

func (r *CharacterRepository) FindByName(name string) (*database.Character, error) {
	var character database.Character
	err := database.DB.Where("name = ?", name).First(&character).Error
	return &character, err
}

func (r *CharacterRepository) Update(character *database.Character) error {
	return database.DB.Save(character).Error
}

func (r *CharacterRepository) Delete(id uint) error {
	return database.DB.Delete(&database.Character{}, id).Error
}

func (r *CharacterRepository) UpdatePosition(characterID uint, x, y int) error {
	return database.DB.Model(&database.Character{}).
		Where("id = ?", characterID).
		Updates(map[string]any{
			"position_x": x,
			"position_y": y,
		}).Error
}

func (r *CharacterRepository) AddAbilityPoints(characterID uint, str, dex, int_, luk int) error {
	updates := map[string]any{}
	if str != 0 {
		updates["str"] = database.DB.Raw("str + ?", str)
	}
	if dex != 0 {
		updates["dex"] = database.DB.Raw("dex + ?", dex)
	}
	if int_ != 0 {
		updates["`int`"] = database.DB.Raw("`int` + ?", int_)
	}
	if luk != 0 {
		updates["luk"] = database.DB.Raw("luk + ?", luk)
	}
	return database.DB.Model(&database.Character{}).
		Where("id = ?", characterID).
		Updates(updates).Error
}

// ================== 背包 Inventory 相关 ==================

type InventoryRepository struct{}

func NewInventoryRepository() *InventoryRepository {
	return &InventoryRepository{}
}

func (r *InventoryRepository) FindByCharacterID(characterID uint) ([]database.CharacterInventory, error) {
	var items []database.CharacterInventory
	err := database.DB.Where("character_id = ?", characterID).Find(&items).Error
	return items, err
}

func (r *InventoryRepository) FindBySlot(characterID uint, slot int) (*database.CharacterInventory, error) {
	var item database.CharacterInventory
	err := database.DB.Where("character_id = ? AND slot = ?", characterID, slot).First(&item).Error
	return &item, err
}

func (r *InventoryRepository) FindByItemID(characterID uint, itemID int) (*database.CharacterInventory, error) {
	var item database.CharacterInventory
	err := database.DB.Where("character_id = ? AND item_id = ?", characterID, itemID).First(&item).Error
	return &item, err
}

func (r *InventoryRepository) FindEquipped(characterID uint) ([]database.CharacterInventory, error) {
	var items []database.CharacterInventory
	err := database.DB.Where("character_id = ? AND equipped = ?", characterID, true).Find(&items).Error
	return items, err
}

func (r *InventoryRepository) Create(inv *database.CharacterInventory) error {
	return database.DB.Create(inv).Error
}

func (r *InventoryRepository) Update(inv *database.CharacterInventory) error {
	return database.DB.Save(inv).Error
}

func (r *InventoryRepository) Delete(id uint) error {
	return database.DB.Delete(&database.CharacterInventory{}, id).Error
}

func (r *InventoryRepository) FindNextEmptySlot(characterID uint) (int, error) {
	var items []database.CharacterInventory
	if err := database.DB.Where("character_id = ?", characterID).Find(&items).Error; err != nil {
		return 0, err
	}

	usedSlots := map[int]bool{}
	for _, it := range items {
		usedSlots[it.SlotIndex] = true
	}

	for i := 1; i <= 100; i++ {
		if !usedSlots[i] {
			return i, nil
		}
	}
	return 0, nil
}
