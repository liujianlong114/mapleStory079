package repository

import (
	"mapleStory079/pkg/database"
)

type QuestRepository struct{}

func NewQuestRepository() *QuestRepository {
	return &QuestRepository{}
}

func (r *QuestRepository) Create(quest *database.Quest) error {
	return database.DB.Create(quest).Error
}

func (r *QuestRepository) FindByID(id uint) (*database.Quest, error) {
	var quest database.Quest
	err := database.DB.Where("id = ?", id).First(&quest).Error
	return &quest, err
}

func (r *QuestRepository) FindAll() ([]database.Quest, error) {
	var quests []database.Quest
	err := database.DB.Find(&quests).Error
	return quests, err
}

func (r *QuestRepository) FindByStartNPC(npcID int) ([]database.Quest, error) {
	var quests []database.Quest
	err := database.DB.Where("npc_id = ?", npcID).Find(&quests).Error
	return quests, err
}

func (r *QuestRepository) FindByLevelReq(level int) ([]database.Quest, error) {
	var quests []database.Quest
	err := database.DB.Where("level_req <= ?", level).Find(&quests).Error
	return quests, err
}

func (r *QuestRepository) FindByName(name string) (*database.Quest, error) {
	var quest database.Quest
	err := database.DB.Where("name LIKE ?", "%"+name+"%").First(&quest).Error
	return &quest, err
}

func (r *QuestRepository) Update(quest *database.Quest) error {
	return database.DB.Save(quest).Error
}

func (r *QuestRepository) Delete(id uint) error {
	return database.DB.Delete(database.Quest{}, id).Error
}

func (r *QuestRepository) Count() (int64, error) {
	var count int64
	err := database.DB.Model(&database.Quest{}).Count(&count).Error
	return count, err
}
