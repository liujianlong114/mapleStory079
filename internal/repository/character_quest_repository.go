package repository

import (
	"mapleStory079/pkg/database"
)

func GetCharacterQuest(characterID, questID uint) (*database.CharacterQuest, error) {
	var cq database.CharacterQuest
	err := database.DB.Where("character_id = ? AND quest_id = ?", characterID, questID).First(&cq).Error
	if err != nil {
		return nil, err
	}
	return &cq, nil
}

func ListCharacterQuests(characterID uint) ([]database.CharacterQuest, error) {
	var list []database.CharacterQuest
	err := database.DB.Where("character_id = ?", characterID).Find(&list).Error
	return list, err
}

func CreateCharacterQuest(cq *database.CharacterQuest) error {
	return database.DB.Create(cq).Error
}

func UpdateCharacterQuest(cq *database.CharacterQuest) error {
	return database.DB.Save(cq).Error
}
