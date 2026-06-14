package repository

import (
	"mapleStory079/internal/model"
	"mapleStory079/pkg/database"
)

// CreateAccount 创建账号
func CreateAccount(acc *model.Account) error {
	return database.GetDB().Create(acc).Error
}

func GetAccountByUsername(username string) (*model.Account, error) {
	var acc model.Account
	err := database.GetDB().Where("username = ?", username).First(&acc).Error
	if err != nil {
		return nil, err
	}
	return &acc, nil
}

func GetAccountByID(id uint) (*model.Account, error) {
	var acc model.Account
	err := database.GetDB().First(&acc, id).Error
	if err != nil {
		return nil, err
	}
	return &acc, nil
}

func UpdateAccount(acc *model.Account) error {
	return database.GetDB().Save(acc).Error
}

// Character 角色 CRUD
func CreateCharacter(ch *model.Character) error {
	return database.GetDB().Create(ch).Error
}

func GetCharacterByID(id uint) (*model.Character, error) {
	var ch model.Character
	err := database.GetDB().First(&ch, id).Error
	if err != nil {
		return nil, err
	}
	return &ch, nil
}

func GetCharactersByAccount(accountID uint) ([]model.Character, error) {
	var chars []model.Character
	err := database.GetDB().Where("account_id = ?", accountID).Find(&chars).Error
	return chars, err
}

func UpdateCharacter(ch *model.Character) error {
	return database.GetDB().Save(ch).Error
}

func DeleteCharacter(id uint) error {
	return database.GetDB().Delete(&model.Character{}, id).Error
}

func GetCharacterByName(name string) (*model.Character, error) {
	var ch model.Character
	err := database.GetDB().Where("name = ?", name).First(&ch).Error
	if err != nil {
		return nil, err
	}
	return &ch, nil
}

// GameMap
func GetAllMaps() ([]model.GameMap, error) {
	var maps []model.GameMap
	err := database.GetDB().Find(&maps).Error
	return maps, err
}

func GetMapByID(id uint) (*model.GameMap, error) {
	var m model.GameMap
	err := database.GetDB().First(&m, id).Error
	if err != nil {
		return nil, err
	}
	return &m, nil
}

func CreateMap(m *model.GameMap) error {
	return database.GetDB().Create(m).Error
}

// Mob
func GetAllMobs() ([]model.Mob, error) {
	var mobs []model.Mob
	err := database.GetDB().Find(&mobs).Error
	return mobs, err
}

func GetMobByID(id uint) (*model.Mob, error) {
	var m model.Mob
	err := database.GetDB().First(&m, id).Error
	if err != nil {
		return nil, err
	}
	return &m, nil
}

func UpdateMob(m *model.Mob) error {
	return database.GetDB().Save(m).Error
}

// NPC
func GetNPCByID(id uint) (*model.NPC, error) {
	var n model.NPC
	err := database.GetDB().First(&n, id).Error
	if err != nil {
		return nil, err
	}
	return &n, nil
}

func GetNPCsByMap(mapID uint) ([]model.NPC, error) {
	var npcs []model.NPC
	err := database.GetDB().Where("map_id = ?", mapID).Find(&npcs).Error
	return npcs, err
}

// Items
func GetAllItems() ([]model.Item, error) {
	var items []model.Item
	err := database.GetDB().Find(&items).Error
	return items, err
}

func GetItemByID(id uint) (*model.Item, error) {
	var i model.Item
	err := database.GetDB().First(&i, id).Error
	if err != nil {
		return nil, err
	}
	return &i, nil
}

// Skills
func GetAllSkills() ([]model.Skill, error) {
	var skills []model.Skill
	err := database.GetDB().Find(&skills).Error
	return skills, err
}

func GetSkillByID(id uint) (*model.Skill, error) {
	var s model.Skill
	err := database.GetDB().First(&s, id).Error
	if err != nil {
		return nil, err
	}
	return &s, nil
}

// Quests
func GetAllQuests() ([]model.Quest, error) {
	var qs []model.Quest
	err := database.GetDB().Find(&qs).Error
	return qs, err
}

func GetQuestByID(id uint) (*model.Quest, error) {
	var q model.Quest
	err := database.GetDB().First(&q, id).Error
	if err != nil {
		return nil, err
	}
	return &q, nil
}

// Inventory
func GetCharacterInventory(characterID uint, inventory string) ([]model.CharacterItem, error) {
	var items []model.CharacterItem
	db := database.GetDB().Where("character_id = ?", characterID)
	if inventory != "" && inventory != "all" {
		db = db.Where("inventory = ?", inventory)
	}
	err := db.Find(&items).Error
	return items, err
}

func GetEquippedItems(characterID uint) ([]model.CharacterItem, error) {
	var items []model.CharacterItem
	err := database.GetDB().Where("character_id = ? AND is_equipped = ?", characterID, true).Find(&items).Error
	return items, err
}

func AddCharacterItem(item *model.CharacterItem) error {
	return database.GetDB().Create(item).Error
}

func UpdateCharacterItem(item *model.CharacterItem) error {
	return database.GetDB().Save(item).Error
}

func DeleteCharacterItem(id uint) error {
	return database.GetDB().Delete(&model.CharacterItem{}, id).Error
}

func GetCharacterSkill(characterID, skillID uint) (*model.CharacterSkill, error) {
	var cs model.CharacterSkill
	err := database.GetDB().Where("character_id = ? AND skill_id = ?", characterID, skillID).First(&cs).Error
	if err != nil {
		return nil, err
	}
	return &cs, nil
}

func GetCharacterSkills(characterID uint) ([]model.CharacterSkill, error) {
	var cs []model.CharacterSkill
	err := database.GetDB().Where("character_id = ?", characterID).Find(&cs).Error
	return cs, err
}

func UpdateCharacterPosition(characterID uint, mapID, x, y int) error {
	return database.GetDB().Model(&database.Character{}).
		Where("id = ?", characterID).
		Updates(map[string]interface{}{
			"map_id":     mapID,
			"position_x": x,
			"position_y": y,
		}).Error
}

func UpdateCharacterStats(characterID uint, stats map[string]interface{}) error {
	if len(stats) == 0 {
		return nil
	}
	return database.GetDB().Model(&database.Character{}).
		Where("id = ?", characterID).
		Updates(stats).Error
}

func AddCharacterExp(characterID uint, exp int) error {
	return database.GetDB().Model(&database.Character{}).
		Where("id = ?", characterID).
		Update("exp", database.GetDB().Raw("exp + ?", exp)).Error
}

func AddCharacterMesos(characterID uint, mesos int) error {
	return database.GetDB().Model(&database.Character{}).
		Where("id = ?", characterID).
		Update("mesos", database.GetDB().Raw("mesos + ?", mesos)).Error
}

func GetNPCsByMapID(mapID uint) ([]model.NPC, error) {
	var npcs []model.NPC
	err := database.GetDB().Where("map_id = ?", mapID).Find(&npcs).Error
	return npcs, err
}
