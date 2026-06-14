package service

import (
	"errors"
	"time"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
)

const (
	QuestStatusActive    = "active"
	QuestStatusCompleted = "completed"

	// 彩虹岛新手任务道具：莎丽的镜子（对照 ms079 Quest 1000/1001）
	QuestMirrorItemID = 4031013
)

type QuestService struct {
	inv *InventoryService
}

func NewQuestService() *QuestService {
	return &QuestService{inv: NewInventoryService()}
}

func (s *QuestService) GetCharacterQuest(characterID, questID uint) (*database.CharacterQuest, error) {
	return repository.GetCharacterQuest(characterID, questID)
}

func (s *QuestService) ListCharacterQuests(characterID uint) ([]database.CharacterQuest, error) {
	return repository.ListCharacterQuests(characterID)
}

func (s *QuestService) HasCompleted(characterID, questID uint) bool {
	cq, err := repository.GetCharacterQuest(characterID, questID)
	return err == nil && cq.Status == QuestStatusCompleted
}

func (s *QuestService) IsActive(characterID, questID uint) bool {
	cq, err := repository.GetCharacterQuest(characterID, questID)
	return err == nil && cq.Status == QuestStatusActive
}

func (s *QuestService) AcceptQuest(characterID, questID uint) (*database.CharacterQuest, error) {
	quest, err := repository.GetQuestByID(questID)
	if err != nil {
		return nil, errors.New("quest not found")
	}
	character, err := repository.GetCharacterByID(characterID)
	if err != nil {
		return nil, errors.New("character not found")
	}
	if character.Level < quest.LevelReq {
		return nil, errors.New("level too low")
	}
	if existing, err := repository.GetCharacterQuest(characterID, questID); err == nil {
		if existing.Status == QuestStatusCompleted {
			return nil, errors.New("quest already completed")
		}
		return existing, nil
	}
	cq := &database.CharacterQuest{
		CharacterID: characterID,
		QuestID:     questID,
		Status:      QuestStatusActive,
	}
	if err := repository.CreateCharacterQuest(cq); err != nil {
		return nil, err
	}
	return cq, nil
}

func (s *QuestService) CompleteQuest(character *database.Character, questID uint) (*DialogueEffect, error) {
	cq, err := repository.GetCharacterQuest(character.ID, questID)
	if err != nil || cq.Status != QuestStatusActive {
		return nil, errors.New("quest not active")
	}
	quest, err := repository.GetQuestByID(questID)
	if err != nil {
		return nil, errors.New("quest not found")
	}

	now := time.Now()
	cq.Status = QuestStatusCompleted
	cq.CompletedAt = &now
	if err := repository.UpdateCharacterQuest(cq); err != nil {
		return nil, err
	}

	character.Exp += quest.ExpReward
	character.Mesos += quest.MesosReward
	_ = repository.UpdateCharacter(character)

	effect := &DialogueEffect{
		QuestCompleted: questID,
		ExpGained:      quest.ExpReward,
		NewMesos:       int64(character.Mesos),
	}
	return effect, nil
}

func (s *QuestService) HasItem(characterID uint, itemID int) bool {
	items, err := s.inv.GetInventory(characterID)
	if err != nil {
		return false
	}
	for _, it := range items {
		if it.ItemID == itemID && it.Quantity > 0 {
			return true
		}
	}
	return false
}

func (s *QuestService) GiveQuestItem(characterID uint, itemID, qty int) error {
	return s.inv.AddItem(characterID, itemID, qty)
}

func (s *QuestService) TakeQuestItem(characterID uint, itemID, qty int) error {
	return s.inv.RemoveItem(characterID, itemID, qty)
}
