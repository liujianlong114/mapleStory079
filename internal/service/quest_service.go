package service

import (
	"errors"
	"fmt"
	"time"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
)

const (
	QuestStatusActive    = 1
	QuestStatusCompleted = 2
)

// QuestRequirement 任务完成条件（对照 ms079 彩虹岛新手链简化）
type QuestRequirement struct {
	KillMobIDs    []uint
	KillCount     int
	CollectItemID int
	CollectCount  int
	PrereqQuestID uint
	TurnInNPCID   uint
	AutoComplete  bool // 接取即完成（教程类）
}

var questRequirements = map[uint]QuestRequirement{
	1000: {TurnInNPCID: 2101}, // 借镜子：莎丽处推进 → 希娜交付
	1001: {PrereqQuestID: 1000, TurnInNPCID: 2101},
	400000: {AutoComplete: true},
	400001: {KillMobIDs: []uint{100100, 100101, 100102}, KillCount: 10, TurnInNPCID: 12100},
	400002: {CollectItemID: 4000000, CollectCount: 5, TurnInNPCID: 12100},
}

type QuestService struct{}

func NewQuestService() *QuestService { return &QuestService{} }

func (s *QuestService) GetCharacterQuests(characterID uint) ([]database.CharacterQuest, error) {
	return repository.FindCharacterQuests(characterID)
}

func (s *QuestService) GetQuestProgress(characterID, questID uint) (*database.CharacterQuest, error) {
	return repository.FindCharacterQuest(characterID, questID)
}

func (s *QuestService) HasCompletedQuest(characterID, questID uint) bool {
	cq, err := repository.FindCharacterQuest(characterID, questID)
	return err == nil && cq != nil && cq.Status == QuestStatusCompleted
}

func (s *QuestService) HasActiveQuest(characterID, questID uint) bool {
	cq, err := repository.FindCharacterQuest(characterID, questID)
	return err == nil && cq != nil && cq.Status == QuestStatusActive
}

// AcceptQuest 接取任务
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
		return nil, fmt.Errorf("需要等级 %d", quest.LevelReq)
	}
	req := questRequirements[questID]
	if req.PrereqQuestID > 0 && !s.HasCompletedQuest(characterID, req.PrereqQuestID) {
		return nil, fmt.Errorf("需要先完成任务 %d", req.PrereqQuestID)
	}
	if existing, err := repository.FindCharacterQuest(characterID, questID); err == nil && existing != nil {
		if existing.Status == QuestStatusCompleted {
			return nil, errors.New("任务已完成")
		}
		return existing, nil
	}
	now := time.Now()
	cq := &database.CharacterQuest{
		CharacterID: characterID,
		QuestID:     questID,
		Status:      QuestStatusActive,
		Progress:    0,
		AcceptedAt:  now,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	if err := repository.CreateCharacterQuest(cq); err != nil {
		return nil, err
	}
	if req.AutoComplete {
		_, _ = s.CompleteQuest(characterID, questID)
		cq, _ = repository.FindCharacterQuest(characterID, questID)
	}
	return cq, nil
}

// CompleteQuest 交付任务并发放奖励
func (s *QuestService) CompleteQuest(characterID, questID uint) (*DialogueEffect, error) {
	cq, err := repository.FindCharacterQuest(characterID, questID)
	if err != nil || cq == nil {
		return nil, errors.New("未接取该任务")
	}
	if cq.Status == QuestStatusCompleted {
		return nil, errors.New("任务已完成")
	}
	req := questRequirements[questID]
	if !s.isRequirementMet(characterID, questID, req, cq) {
		return nil, errors.New("任务条件尚未满足")
	}
	quest, err := repository.GetQuestByID(questID)
	if err != nil {
		return nil, err
	}
	character, err := repository.GetCharacterByID(characterID)
	if err != nil {
		return nil, err
	}
	now := time.Now()
	cq.Status = QuestStatusCompleted
	cq.CompletedAt = &now
	cq.UpdatedAt = now
	if err := repository.UpdateCharacterQuest(cq); err != nil {
		return nil, err
	}
	character.Exp += quest.ExpReward
	character.Mesos += quest.MesosReward
	levelUp := LevelUp(character)
	if err := repository.UpdateCharacter(character); err != nil {
		return nil, err
	}
	effect := &DialogueEffect{
		NewMesos: int64(character.Mesos),
	}
	if levelUp {
		effect.NewHP = character.HP
		effect.NewMP = character.MP
	}
	return effect, nil
}

func (s *QuestService) isRequirementMet(_ uint, questID uint, req QuestRequirement, cq *database.CharacterQuest) bool {
	if req.AutoComplete {
		return cq.Status == QuestStatusActive
	}
	if req.KillCount > 0 {
		return cq.Progress >= req.KillCount
	}
	if req.CollectCount > 0 {
		return cq.Progress >= req.CollectCount
	}
	// 对话链任务：进行中即可在 turn-in NPC 交付
	switch questID {
	case 1000:
		return cq.Progress >= 1 // 已与莎丽对话
	case 1001:
		return cq.Status == QuestStatusActive
	default:
		return cq.Status == QuestStatusActive
	}
}

// OnMobKilled 击杀怪物时更新任务进度
func (s *QuestService) OnMobKilled(characterID, mobID uint) {
	quests, err := repository.FindActiveCharacterQuests(characterID)
	if err != nil {
		return
	}
	for _, cq := range quests {
		req, ok := questRequirements[cq.QuestID]
		if !ok || req.KillCount == 0 {
			continue
		}
		for _, id := range req.KillMobIDs {
			if id == mobID {
				if cq.Progress < req.KillCount {
					cq.Progress++
					cq.UpdatedAt = time.Now()
					_ = repository.UpdateCharacterQuest(&cq)
				}
				break
			}
		}
	}
}

// OnItemCollected 拾取物品时更新收集类任务
func (s *QuestService) OnItemCollected(characterID uint, itemID int, qty int) {
	quests, err := repository.FindActiveCharacterQuests(characterID)
	if err != nil {
		return
	}
	for _, cq := range quests {
		req, ok := questRequirements[cq.QuestID]
		if !ok || req.CollectItemID != itemID {
			continue
		}
		cq.Progress += qty
		if cq.Progress > req.CollectCount {
			cq.Progress = req.CollectCount
		}
		cq.UpdatedAt = time.Now()
		_ = repository.UpdateCharacterQuest(&cq)
	}
}

// AdvanceTalkQuest 对话链任务推进一步（如 1000 找到莎丽）
func (s *QuestService) AdvanceTalkQuest(characterID, questID uint) error {
	cq, err := repository.FindCharacterQuest(characterID, questID)
	if err != nil || cq == nil || cq.Status != QuestStatusActive {
		return errors.New("任务未进行中")
	}
	cq.Progress++
	cq.UpdatedAt = time.Now()
	return repository.UpdateCharacterQuest(cq)
}

// QuestProgressText 返回任务进度描述
func (s *QuestService) QuestProgressText(questID uint, progress int) string {
	req, ok := questRequirements[questID]
	if !ok {
		return ""
	}
	if req.KillCount > 0 {
		return fmt.Sprintf("(%d/%d)", progress, req.KillCount)
	}
	if req.CollectCount > 0 {
		return fmt.Sprintf("(%d/%d)", progress, req.CollectCount)
	}
	return ""
}
