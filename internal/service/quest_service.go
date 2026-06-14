package service

import (
	"errors"
	"fmt"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
	"mapleStory079/pkg/utils"
)

const (
	QuestStatusInProgress = 1
	QuestStatusCompleted  = 2
)

// QuestKillTarget 击杀类任务目标（mob template ID → 需要数量）
var QuestKillTarget = map[uint]struct {
	MobID uint
	Need  int
}{
	400001: {MobID: utils.MobSnail, Need: 10},
	400002: {MobID: utils.MobBlueSnail, Need: 5},
}

// DefaultQuestService 全局任务服务实例。
var DefaultQuestService = NewQuestService()

type QuestService struct{}

func NewQuestService() *QuestService { return &QuestService{} }

func (s *QuestService) GetCharacterQuest(characterID, questID uint) (*database.CharacterQuest, error) {
	return repository.GetCharacterQuest(characterID, questID)
}

func (s *QuestService) IsQuestInProgress(characterID, questID uint) bool {
	cq, err := repository.GetCharacterQuest(characterID, questID)
	return err == nil && cq.Status == QuestStatusInProgress
}

func (s *QuestService) IsQuestCompleted(characterID, questID uint) bool {
	cq, err := repository.GetCharacterQuest(characterID, questID)
	return err == nil && cq.Status == QuestStatusCompleted
}

func (s *QuestService) GetProgress(characterID, questID uint) int {
	cq, err := repository.GetCharacterQuest(characterID, questID)
	if err != nil {
		return 0
	}
	return cq.Progress
}

func (s *QuestService) ListCharacterQuests(characterID uint) ([]database.CharacterQuest, error) {
	return repository.ListCharacterQuests(characterID)
}

// AcceptQuest 接取任务。
func (s *QuestService) AcceptQuest(characterID, questID uint) error {
	if s.IsQuestCompleted(characterID, questID) {
		return fmt.Errorf("任务 %d 已完成", questID)
	}
	if s.IsQuestInProgress(characterID, questID) {
		return nil
	}
	quest, err := repository.GetQuestByID(questID)
	if err != nil {
		return errors.New("任务不存在")
	}
	char, err := repository.GetCharacterByID(characterID)
	if err != nil {
		return errors.New("角色不存在")
	}
	if char.Level < quest.LevelReq {
		return fmt.Errorf("需要等级 %d", quest.LevelReq)
	}
	cq := &database.CharacterQuest{
		CharacterID: characterID,
		QuestID:     questID,
		Status:      QuestStatusInProgress,
		Progress:    0,
	}
	return repository.UpsertCharacterQuest(cq)
}

// SetProgress 更新任务进度值（如持有镜子 flag）。
func (s *QuestService) SetProgress(characterID, questID uint, progress int) error {
	cq, err := repository.GetCharacterQuest(characterID, questID)
	if err != nil {
		return err
	}
	cq.Progress = progress
	return repository.UpsertCharacterQuest(cq)
}

// CompleteQuest 完成任务并发放奖励。
func (s *QuestService) CompleteQuest(characterID, questID uint) (*DialogueEffect, error) {
	cq, err := repository.GetCharacterQuest(characterID, questID)
	if err != nil || cq.Status != QuestStatusInProgress {
		return nil, fmt.Errorf("任务 %d 未在进行中", questID)
	}
	if target, ok := QuestKillTarget[questID]; ok && cq.Progress < target.Need {
		return nil, fmt.Errorf("任务进度不足 (%d/%d)", cq.Progress, target.Need)
	}
	quest, err := repository.GetQuestByID(questID)
	if err != nil {
		return nil, errors.New("任务不存在")
	}
	char, err := repository.GetCharacterByID(characterID)
	if err != nil {
		return nil, errors.New("角色不存在")
	}

	char.Exp += quest.ExpReward
	char.Mesos += quest.MesosReward
	levelUp := LevelUp(char)

	cq.Status = QuestStatusCompleted
	if err := repository.UpsertCharacterQuest(cq); err != nil {
		return nil, err
	}
	if err := repository.UpdateCharacter(char); err != nil {
		return nil, err
	}

	return &DialogueEffect{
		QuestCompleted: int(questID),
		ExpGained:      quest.ExpReward,
		NewMesos:       int64(char.Mesos),
		LevelUp:        levelUp,
	}, nil
}

// HandMirrorFromSari 莎丽借镜子：完成 1000 并开启 1001（已持有镜子）。
func (s *QuestService) HandMirrorFromSari(characterID uint) (*DialogueEffect, error) {
	if !s.IsQuestInProgress(characterID, 1000) {
		return nil, errors.New("尚未接取借镜子任务")
	}
	effect, err := s.CompleteQuest(characterID, 1000)
	if err != nil {
		return nil, err
	}
	if err := s.AcceptQuest(characterID, 1001); err != nil {
		return nil, err
	}
	if err := s.SetProgress(characterID, 1001, 1); err != nil {
		return nil, err
	}
	effect.QuestAccepted = 1001
	return effect, nil
}

// RecordMobKill 击杀怪物时更新击杀类任务进度；若达标则自动标记可交付（仅增 progress）。
func (s *QuestService) RecordMobKill(characterID, mobTemplateID uint) []uint {
	var completed []uint
	quests, err := repository.ListCharacterQuests(characterID)
	if err != nil {
		return nil
	}
	for _, cq := range quests {
		if cq.Status != QuestStatusInProgress {
			continue
		}
		target, ok := QuestKillTarget[cq.QuestID]
		if !ok || target.MobID != mobTemplateID {
			continue
		}
		if cq.Progress >= target.Need {
			continue
		}
		cq.Progress++
		_ = repository.UpsertCharacterQuest(&cq)
		if cq.Progress >= target.Need {
			completed = append(completed, cq.QuestID)
		}
	}
	return completed
}
