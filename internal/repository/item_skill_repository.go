package repository

import (
	"mapleStory079/pkg/database"
)

// legacyItemRepository 是历史遗留实现，以 legacy 前缀避免与 item_repository.go 冲突。
// 新项目请使用 ItemRepository。
type legacyItemRepository struct{}

func (r *legacyItemRepository) Create(item *database.Item) error {
	return database.DB.Create(item).Error
}

func (r *legacyItemRepository) FindByID(id uint) (*database.Item, error) {
	var item database.Item
	err := database.DB.Where("id = ?", id).First(&item).Error
	return &item, err
}

func (r *legacyItemRepository) FindAll() ([]database.Item, error) {
	var items []database.Item
	err := database.DB.Find(&items).Error
	return items, err
}

func (r *legacyItemRepository) FindByType(itemType int) ([]database.Item, error) {
	var items []database.Item
	err := database.DB.Where("type = ?", itemType).Find(&items).Error
	return items, err
}

func (r *legacyItemRepository) Update(item *database.Item) error {
	return database.DB.Save(item).Error
}

func (r *legacyItemRepository) Delete(id uint) error {
	return database.DB.Delete(&database.Item{}, id).Error
}

// legacySkillRepository 是历史遗留实现，避免与 skill_repository.go 冲突。
type legacySkillRepository struct{}

func (r *legacySkillRepository) Create(skill *database.Skill) error {
	return database.DB.Create(skill).Error
}

func (r *legacySkillRepository) FindByID(id uint) (*database.Skill, error) {
	var skill database.Skill
	err := database.DB.Where("id = ?", id).First(&skill).Error
	return &skill, err
}

func (r *legacySkillRepository) FindAll() ([]database.Skill, error) {
	var skills []database.Skill
	err := database.DB.Find(&skills).Error
	return skills, err
}

func (r *legacySkillRepository) Update(skill *database.Skill) error {
	return database.DB.Save(skill).Error
}

func (r *legacySkillRepository) Delete(id uint) error {
	return database.DB.Delete(&database.Skill{}, id).Error
}

// legacyQuestRepository 是历史遗留实现，避免与 quest_repository.go 冲突。
type legacyQuestRepository struct{}

func (r *legacyQuestRepository) Create(quest *database.Quest) error {
	return database.DB.Create(quest).Error
}

func (r *legacyQuestRepository) FindByID(id uint) (*database.Quest, error) {
	var quest database.Quest
	err := database.DB.Where("id = ?", id).First(&quest).Error
	return &quest, err
}

func (r *legacyQuestRepository) FindAll() ([]database.Quest, error) {
	var quests []database.Quest
	err := database.DB.Find(&quests).Error
	return quests, err
}

func (r *legacyQuestRepository) FindByStartNPC(npcID int) ([]database.Quest, error) {
	var quests []database.Quest
	err := database.DB.Where("start_npc = ?", npcID).Find(&quests).Error
	return quests, err
}

func (r *legacyQuestRepository) Update(quest *database.Quest) error {
	return database.DB.Save(quest).Error
}

func (r *legacyQuestRepository) Delete(id uint) error {
	return database.DB.Delete(&database.Quest{}, id).Error
}
