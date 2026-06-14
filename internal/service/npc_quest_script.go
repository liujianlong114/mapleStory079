package service

import (
	"errors"
	"fmt"

	"mapleStory079/pkg/database"
	"mapleStory079/pkg/npcdata"
)

const (
	npcHeina = 2101 // 希娜
	npcShari = 2100 // 莎丽

	questBorrowMirror = 1000 // 借来莎丽的镜子
	questReturnMirror = 1001 // 给希娜弄来镜子
)

func registerQuestScripts(s *NPCService) {
	qs := NewQuestService()
	s.scripts[npcHeina] = &heinaQuestScript{quests: qs}
	s.scripts[npcShari] = &shariQuestScript{quests: qs}
}

// heinaQuestScript — 彩虹村希娜，新手任务 1000/1001
type heinaQuestScript struct {
	quests *QuestService
}

func (s *heinaQuestScript) GetNPCID() int { return npcHeina }

func (s *heinaQuestScript) GetNode(nodeID string, character *database.Character) (*DialogueNode, error) {
	meta := npcdata.Lookup(npcHeina)
	switch nodeID {
	case "start":
		if s.quests.HasCompleted(character.ID, questReturnMirror) {
			return s.tipsNode(meta.Name, "谢谢你帮我借到了镜子！在彩虹村好好探索吧～")
		}
		if s.quests.IsActive(character.ID, questReturnMirror) && s.quests.HasItem(character.ID, QuestMirrorItemID) {
			return &DialogueNode{
				ID:       "start",
				Speaker:  meta.Name,
				Text:     "啊，你把莎丽的镜子借来了吗？太感谢了！",
				NodeType: "choice",
				Choices: []DialogueChoice{
					{Text: "是的，给你镜子", NextID: "complete_1001", Action: "complete_quest", Data: fmt.Sprintf("%d", questReturnMirror)},
					{Text: "稍等一下", NextID: "end", Action: "close"},
				},
			}, nil
		}
		if s.quests.IsActive(character.ID, questBorrowMirror) {
			return s.tipsNode(meta.Name, "请去找我姐姐莎丽借镜子。她应该在村子东边晾衣服的地方。")
		}
		if !s.quests.HasCompleted(character.ID, questBorrowMirror) && !s.quests.IsActive(character.ID, questBorrowMirror) {
			return &DialogueNode{
				ID:       "start",
				Speaker:  meta.Name,
				Text:     "你是第一次到冒险岛来吗？我想向姐姐莎丽借镜子，你能帮我去借一下吗？",
				NodeType: "choice",
				Choices: []DialogueChoice{
					{Text: "好的，我去借", NextID: "accepted_1000", Action: "accept_quest", Data: fmt.Sprintf("%d", questBorrowMirror)},
					{Text: "有什么要告诉我的吗？", NextID: "tip_0"},
					{Text: "再见", NextID: "end", Action: "close"},
				},
			}, nil
		}
		return s.wzTipsStart(meta.Name, meta.Dialogue)
	case "accepted_1000":
		return s.tipsNode(meta.Name, "太好了！莎丽就在村子东边。借到镜子后记得拿回来给我哦～")
	case "complete_1001":
		return s.tipsNode(meta.Name, "任务完成！这是给你的谢礼。")
	case "tip_0":
		return &DialogueNode{
			ID:       "tip_0",
			Speaker:  meta.Name,
			Text:     "按左边的 Alt键，就可以跳跃。用方向键可以移动角色。",
			NodeType: "choice",
			Choices: []DialogueChoice{
				{Text: "明白了", NextID: "start"},
				{Text: "再见", NextID: "end", Action: "close"},
			},
		}, nil
	case "end":
		return &DialogueNode{ID: "end", Speaker: meta.Name, Text: "再见，祝你在冒险岛玩得开心！", NodeType: "end", Action: "close"}, nil
	default:
		return nil, errors.New("unknown dialogue node")
	}
}

func (s *heinaQuestScript) ExecuteAction(action, data string, character *database.Character) (*DialogueEffect, error) {
	switch action {
	case "accept_quest":
		var questID uint
		if _, err := fmt.Sscanf(data, "%d", &questID); err != nil {
			return nil, err
		}
		if _, err := s.quests.AcceptQuest(character.ID, questID); err != nil {
			return nil, err
		}
		return &DialogueEffect{QuestAccepted: questID}, nil
	case "complete_quest":
		var questID uint
		if _, err := fmt.Sscanf(data, "%d", &questID); err != nil {
			return nil, err
		}
		if questID == questReturnMirror {
			if !s.quests.HasItem(character.ID, QuestMirrorItemID) {
				return nil, errors.New("mirror not found")
			}
			if err := s.quests.TakeQuestItem(character.ID, QuestMirrorItemID, 1); err != nil {
				return nil, err
			}
		}
		return s.quests.CompleteQuest(character, questID)
	default:
		return nil, nil
	}
}

func (s *heinaQuestScript) tipsNode(speaker, text string) (*DialogueNode, error) {
	return &DialogueNode{
		ID: speaker + "_tips", Speaker: speaker, Text: text, NodeType: "choice",
		Choices: []DialogueChoice{{Text: "明白了", NextID: "start"}, {Text: "再见", NextID: "end", Action: "close"}},
	}, nil
}

func (s *heinaQuestScript) wzTipsStart(name, dialogue string) (*DialogueNode, error) {
	return &DialogueNode{
		ID: "start", Speaker: name, Text: dialogue, NodeType: "choice",
		Choices: []DialogueChoice{
			{Text: "有什么要告诉我的吗？", NextID: "tip_0"},
			{Text: "再见", NextID: "end", Action: "close"},
		},
	}, nil
}

// shariQuestScript — 彩虹村莎丽，交付镜子
type shariQuestScript struct {
	quests *QuestService
}

func (s *shariQuestScript) GetNPCID() int { return npcShari }

func (s *shariQuestScript) GetNode(nodeID string, character *database.Character) (*DialogueNode, error) {
	meta := npcdata.Lookup(npcShari)
	switch nodeID {
	case "start":
		if s.quests.IsActive(character.ID, questBorrowMirror) && !s.quests.HasItem(character.ID, QuestMirrorItemID) {
			return &DialogueNode{
				ID:       "start",
				Speaker:  meta.Name,
				Text:     "哦？希娜让你来借镜子吗？好吧，拿去吧，记得还给她哦～",
				NodeType: "choice",
				Choices: []DialogueChoice{
					{Text: "谢谢，我这就拿给希娜", NextID: "give_mirror", Action: "give_mirror"},
					{Text: "稍等一下", NextID: "end", Action: "close"},
				},
			}, nil
		}
		if s.quests.HasItem(character.ID, QuestMirrorItemID) {
			return s.tipsNode(meta.Name, "快把镜子拿给希娜吧，她在村子中央。")
		}
		return s.wzTipsStart(meta.Name, meta.Dialogue)
	case "give_mirror":
		return s.tipsNode(meta.Name, "镜子给你了。快拿给希娜吧！")
	case "tip_0":
		return &DialogueNode{
			ID: "tip_0", Speaker: meta.Name,
			Text:     "按↑键，可以爬梯子或吊绳。",
			NodeType: "choice",
			Choices:  []DialogueChoice{{Text: "明白了", NextID: "start"}, {Text: "再见", NextID: "end", Action: "close"}},
		}, nil
	case "end":
		return &DialogueNode{ID: "end", Speaker: meta.Name, Text: "再见～", NodeType: "end", Action: "close"}, nil
	default:
		return nil, errors.New("unknown dialogue node")
	}
}

func (s *shariQuestScript) ExecuteAction(action, data string, character *database.Character) (*DialogueEffect, error) {
	switch action {
	case "give_mirror":
		if !s.quests.IsActive(character.ID, questBorrowMirror) {
			return nil, errors.New("quest not active")
		}
		if err := s.quests.GiveQuestItem(character.ID, QuestMirrorItemID, 1); err != nil {
			return nil, err
		}
		if _, err := s.quests.CompleteQuest(character, questBorrowMirror); err != nil {
			return nil, err
		}
		if _, err := s.quests.AcceptQuest(character.ID, questReturnMirror); err != nil {
			return nil, err
		}
		return &DialogueEffect{
			QuestCompleted: questBorrowMirror,
			QuestAccepted:  questReturnMirror,
			ItemGainedID:   QuestMirrorItemID,
			ItemGained:     "莎丽的镜子",
		}, nil
	default:
		return nil, nil
	}
}

func (s *shariQuestScript) tipsNode(speaker, text string) (*DialogueNode, error) {
	return &DialogueNode{
		ID: speaker + "_tips", Speaker: speaker, Text: text, NodeType: "choice",
		Choices: []DialogueChoice{{Text: "明白了", NextID: "start"}, {Text: "再见", NextID: "end", Action: "close"}},
	}, nil
}

func (s *shariQuestScript) wzTipsStart(name, dialogue string) (*DialogueNode, error) {
	return &DialogueNode{
		ID: "start", Speaker: name, Text: dialogue, NodeType: "choice",
		Choices: []DialogueChoice{
			{Text: "有什么要告诉我的吗？", NextID: "tip_0"},
			{Text: "再见", NextID: "end", Action: "close"},
		},
	}, nil
}
