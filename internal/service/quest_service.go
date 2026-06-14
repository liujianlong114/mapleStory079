package service

import (
	"errors"
	"fmt"
	"time"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
)

const (
	QuestStatusNone       = 0
	QuestStatusInProgress = 1
	QuestStatusCompleted  = 2
)

// 彩虹岛新手任务道具（对照 Item.wz Etc/4031.img）
const (
	ItemSallyMirror = 4031013 // 莎丽的镜子
)

// QuestProgressDef 任务完成条件（简化版，对照 ms079 Quest 链）
type QuestProgressDef struct {
	QuestID           uint
	PrerequisiteQuest uint
	RequiredItem      int
	RequiredKills     int
	RequiredMobID     uint
}

var beginnerQuestDefs = map[uint]QuestProgressDef{
	1000:     {QuestID: 1000},
	1001:     {QuestID: 1001, PrerequisiteQuest: 1000, RequiredItem: ItemSallyMirror},
	400000:   {QuestID: 400000},
	400001:   {QuestID: 400001, RequiredKills: 10, RequiredMobID: 100100},
	400003:   {QuestID: 400003},
}

type QuestService struct {
	gameSvc *GameService
	invSvc  *InventoryService
}

func NewQuestService() *QuestService {
	return &QuestService{
		gameSvc: NewGameService(),
		invSvc:  NewInventoryService(),
	}
}

func (s *QuestService) GetCharacterQuest(characterID, questID uint) (*database.CharacterQuest, error) {
	return repository.GetCharacterQuest(characterID, questID)
}

func (s *QuestService) ListCharacterQuests(characterID uint) ([]database.CharacterQuest, error) {
	return repository.ListCharacterQuests(characterID)
}

func (s *QuestService) IsQuestCompleted(characterID, questID uint) bool {
	cq, err := repository.GetCharacterQuest(characterID, questID)
	return err == nil && cq.Status == QuestStatusCompleted
}

func (s *QuestService) IsQuestInProgress(characterID, questID uint) bool {
	cq, err := repository.GetCharacterQuest(characterID, questID)
	return err == nil && cq.Status == QuestStatusInProgress
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

	existing, err := repository.GetCharacterQuest(characterID, questID)
	if err == nil {
		if existing.Status == QuestStatusCompleted {
			return nil, errors.New("任务已完成")
		}
		if existing.Status == QuestStatusInProgress {
			return existing, nil
		}
	}

	def, ok := beginnerQuestDefs[questID]
	if ok && def.PrerequisiteQuest > 0 {
		if !s.IsQuestCompleted(characterID, def.PrerequisiteQuest) {
			return nil, errors.New("需要先完成前置任务")
		}
	}

	now := time.Now()
	cq := &database.CharacterQuest{
		CharacterID: characterID,
		QuestID:     questID,
		Status:      QuestStatusInProgress,
		Progress:    0,
		AcceptedAt:  now,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	if existing != nil {
		cq.ID = existing.ID
	}
	if err := repository.UpsertCharacterQuest(cq); err != nil {
		return nil, err
	}
	return cq, nil
}

// CompleteQuest 完成任务并发放奖励
func (s *QuestService) CompleteQuest(characterID, questID uint) (*DialogueEffect, error) {
	quest, err := repository.GetQuestByID(questID)
	if err != nil {
		return nil, errors.New("quest not found")
	}
	cq, err := repository.GetCharacterQuest(characterID, questID)
	if err != nil || cq.Status != QuestStatusInProgress {
		return nil, errors.New("任务未进行中")
	}

	def, _ := beginnerQuestDefs[questID]
	if def.RequiredItem > 0 {
		if !s.hasItem(characterID, def.RequiredItem) {
			return nil, errors.New("缺少任务道具")
		}
		if err := s.invSvc.RemoveItem(characterID, def.RequiredItem, 1); err != nil {
			return nil, err
		}
	}
	if def.RequiredKills > 0 && cq.Progress < def.RequiredKills {
		return nil, fmt.Errorf("进度不足 (%d/%d)", cq.Progress, def.RequiredKills)
	}

	character, err := repository.GetCharacterByID(characterID)
	if err != nil {
		return nil, err
	}

	now := time.Now()
	cq.Status = QuestStatusCompleted
	cq.CompletedAt = now
	cq.UpdatedAt = now
	if err := repository.UpsertCharacterQuest(cq); err != nil {
		return nil, err
	}

	character.Mesos += quest.MesosReward
	levelResult := s.gameSvc.GainExp(character, quest.ExpReward)
	if err := repository.UpdateCharacter(character); err != nil {
		return nil, err
	}

	effect := &DialogueEffect{
		QuestCompleted: questID,
		NewMesos:       int64(character.Mesos),
		ExpGained:      quest.ExpReward,
	}
	if levelResult.Leveled {
		effect.NewHP = character.HP
		effect.NewMP = character.MP
	}
	return effect, nil
}

// GiveQuestItem 给予任务道具（莎丽借镜子等）
func (s *QuestService) GiveQuestItem(characterID uint, itemID int) error {
	return s.invSvc.AddItem(characterID, itemID, 1)
}

// OnMobKilled 击杀怪物时更新任务进度
func (s *QuestService) OnMobKilled(characterID, mobID uint) []uint {
	var completed []uint
	quests, err := repository.ListCharacterQuests(characterID)
	if err != nil {
		return nil
	}
	for i := range quests {
		if quests[i].Status != QuestStatusInProgress {
			continue
		}
		def, ok := beginnerQuestDefs[quests[i].QuestID]
		if !ok || def.RequiredKills == 0 || def.RequiredMobID != mobID {
			continue
		}
		quests[i].Progress++
		quests[i].UpdatedAt = time.Now()
		_ = repository.UpsertCharacterQuest(&quests[i])
		if quests[i].Progress >= def.RequiredKills {
			completed = append(completed, quests[i].QuestID)
		}
	}
	return completed
}

func (s *QuestService) hasItem(characterID uint, itemID int) bool {
	items, err := repository.GetCharacterInventory(characterID, "")
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
