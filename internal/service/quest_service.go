package service

import (
	"errors"
	"fmt"
	"time"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
)

const (
	QuestStatusInProgress = 1
	QuestStatusCompleted  = 2
)

// QuestDef 彩虹岛新手任务定义（对照 ms079 Quest ID）
type QuestDef struct {
	ID            uint
	Name          string
	StartNPC      uint
	CompleteNPC   uint
	PrevQuestID   uint
	LevelReq      int
	KillMobID     uint // 0 = 非击杀任务
	KillCount     int
	ExpReward     int
	MesosReward   int
	AcceptText    string
	ProgressText  string
	CompleteText  string
	CompletedText string
}

var rainbowQuestDefs = map[uint]QuestDef{
	1000: {
		ID: 1000, Name: "借来莎丽的镜子",
		StartNPC: 2101, CompleteNPC: 2100, LevelReq: 1,
		ExpReward: 10, MesosReward: 50,
		AcceptText:   "你能帮我去找姐姐莎丽借一面镜子吗？她在村子东边晾衣服。",
		ProgressText: "莎丽应该在村子东边，请帮我把镜子借来。",
		CompleteText: "谢谢你！这面镜子对我很重要。",
		CompletedText: "你已经帮我借到镜子了，真是太感谢了！",
	},
	1001: {
		ID: 1001, Name: "给希娜弄来镜子",
		StartNPC: 2100, CompleteNPC: 2101, PrevQuestID: 1000, LevelReq: 1,
		ExpReward: 20, MesosReward: 100,
		AcceptText:   "我妹妹希娜需要镜子，你能帮我把这面镜子送给她吗？",
		ProgressText: "希娜在村子西边，请把镜子交给她。",
		CompleteText: "镜子收到了！谢谢你，冒险者。",
		CompletedText: "镜子的事已经解决了，你真是个可靠的冒险者！",
	},
	400001: {
		ID: 400001, Name: "击退蜗牛",
		StartNPC: 12100, CompleteNPC: 12100, LevelReq: 1,
		KillMobID: 100100, KillCount: 10,
		ExpReward: 50, MesosReward: 300,
		AcceptText:   "彩虹村附近有很多蜗牛，能帮我击退10只蜗牛吗？",
		ProgressText: "继续加油！还需要击败更多蜗牛。",
		CompleteText: "太棒了！你真是勇敢的冒险者。",
		CompletedText: "蜗牛已经被你赶跑了，村子安全多了！",
	},
}

// QuestService 角色任务进度管理
type QuestService struct{}

func NewQuestService() *QuestService { return &QuestService{} }

func (s *QuestService) GetDef(questID uint) (QuestDef, bool) {
	def, ok := rainbowQuestDefs[questID]
	return def, ok
}

func (s *QuestService) GetCharacterQuest(characterID, questID uint) (*database.CharacterQuest, error) {
	return repository.GetCharacterQuest(characterID, questID)
}

func (s *QuestService) ListCharacterQuests(characterID uint) ([]database.CharacterQuest, error) {
	return repository.ListCharacterQuests(characterID)
}

func (s *QuestService) IsQuestCompleted(characterID, questID uint) bool {
	cq, err := repository.GetCharacterQuest(characterID, questID)
	return err == nil && cq != nil && cq.Status == QuestStatusCompleted
}

func (s *QuestService) IsQuestInProgress(characterID, questID uint) bool {
	cq, err := repository.GetCharacterQuest(characterID, questID)
	return err == nil && cq != nil && cq.Status == QuestStatusInProgress
}

func (s *QuestService) CanAccept(characterID uint, def QuestDef, ch *database.Character) error {
	if ch.Level < def.LevelReq {
		return fmt.Errorf("需要等级 %d 才能接取任务", def.LevelReq)
	}
	if def.PrevQuestID > 0 && !s.IsQuestCompleted(characterID, def.PrevQuestID) {
		return errors.New("需要先完成前置任务")
	}
	if cq, err := repository.GetCharacterQuest(characterID, def.ID); err == nil && cq != nil {
		if cq.Status == QuestStatusCompleted {
			return errors.New("任务已完成")
		}
		if cq.Status == QuestStatusInProgress {
			return errors.New("任务已在进行中")
		}
	}
	return nil
}

func (s *QuestService) AcceptQuest(characterID uint, questID uint, ch *database.Character) (*database.CharacterQuest, error) {
	def, ok := rainbowQuestDefs[questID]
	if !ok {
		return nil, errors.New("未知任务")
	}
	if err := s.CanAccept(characterID, def, ch); err != nil {
		return nil, err
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
	if err := repository.CreateCharacterQuest(cq); err != nil {
		return nil, err
	}
	return cq, nil
}

func (s *QuestService) CompleteQuest(characterID uint, questID uint, ch *database.Character) (*DialogueEffect, error) {
	def, ok := rainbowQuestDefs[questID]
	if !ok {
		return nil, errors.New("未知任务")
	}
	cq, err := repository.GetCharacterQuest(characterID, questID)
	if err != nil || cq == nil || cq.Status != QuestStatusInProgress {
		return nil, errors.New("没有进行中的该任务")
	}
	if def.KillMobID > 0 && cq.Progress < def.KillCount {
		return nil, fmt.Errorf("任务进度不足（%d/%d）", cq.Progress, def.KillCount)
	}
	now := time.Now()
	cq.Status = QuestStatusCompleted
	cq.CompletedAt = &now
	cq.UpdatedAt = now
	if err := repository.UpdateCharacterQuest(cq); err != nil {
		return nil, err
	}
	ch.Exp += def.ExpReward
	ch.Mesos += def.MesosReward
	LevelUp(ch)
	if err := repository.UpdateCharacter(ch); err != nil {
		return nil, err
	}
	return &DialogueEffect{
		ExpGained:   def.ExpReward,
		NewMesos:    int64(ch.Mesos),
		QuestID:     questID,
		QuestAction: "completed",
	}, nil
}

func (s *QuestService) RecordMobKill(characterID uint, mobTemplateID uint) []uint {
	var completed []uint
	for questID, def := range rainbowQuestDefs {
		if def.KillMobID == 0 || def.KillMobID != mobTemplateID {
			continue
		}
		cq, err := repository.GetCharacterQuest(characterID, questID)
		if err != nil || cq == nil || cq.Status != QuestStatusInProgress {
			continue
		}
		if cq.Progress >= def.KillCount {
			continue
		}
		cq.Progress++
		cq.UpdatedAt = time.Now()
		_ = repository.UpdateCharacterQuest(cq)
		if cq.Progress >= def.KillCount {
			completed = append(completed, questID)
		}
	}
	return completed
}

func (s *QuestService) QuestsOfferedByNPC(npcID uint, characterID uint, ch *database.Character) []QuestDef {
	var offered []QuestDef
	for _, def := range rainbowQuestDefs {
		if def.StartNPC != npcID {
			continue
		}
		if s.IsQuestCompleted(characterID, def.ID) {
			continue
		}
		if s.IsQuestInProgress(characterID, def.ID) {
			continue
		}
		if err := s.CanAccept(characterID, def, ch); err == nil {
			offered = append(offered, def)
		}
	}
	return offered
}

func (s *QuestService) QuestsCompletableAtNPC(npcID uint, characterID uint) []QuestDef {
	var completable []QuestDef
	for _, def := range rainbowQuestDefs {
		if def.CompleteNPC != npcID {
			continue
		}
		cq, err := repository.GetCharacterQuest(characterID, def.ID)
		if err != nil || cq == nil || cq.Status != QuestStatusInProgress {
			continue
		}
		if def.KillMobID > 0 && cq.Progress < def.KillCount {
			continue
		}
		completable = append(completable, def)
	}
	return completable
}

func (s *QuestService) InProgressAtNPC(npcID uint, characterID uint) []QuestDef {
	var active []QuestDef
	for _, def := range rainbowQuestDefs {
		if !s.IsQuestInProgress(characterID, def.ID) {
			continue
		}
		if def.StartNPC == npcID || def.CompleteNPC == npcID {
			active = append(active, def)
		}
	}
	return active
}
