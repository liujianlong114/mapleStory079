package service

import (
	"errors"
	"fmt"

	"mapleStory079/pkg/database"
	"mapleStory079/pkg/npcdata"
)

// beginnerQuestScript 彩虹岛新手任务 NPC 脚本（希娜/莎丽/麦加/船长）
type beginnerQuestScript struct {
	npcID     uint
	questSvc  *QuestService
	tips      []string
	quests    []uint // 此 NPC 可接/交的任务
}

func (s *beginnerQuestScript) GetNPCID() int { return int(s.npcID) }

func (s *beginnerQuestScript) GetNode(nodeID string, character *database.Character) (*DialogueNode, error) {
	meta := npcdata.Lookup(s.npcID)
	switch nodeID {
	case "start":
		return s.buildStartNode(meta.Name, character), nil
	case "end":
		return &DialogueNode{
			ID: "end", Speaker: meta.Name,
			Text:     "再见，祝你在冒险岛玩得开心！",
			NodeType: "end", Action: "close",
		}, nil
	case "tips":
		return s.buildTipsNode(meta.Name), nil
	default:
		if node, ok := s.questNode(nodeID, meta.Name, character); ok {
			return node, nil
		}
		if idx, ok := parseTipNode(nodeID); ok && idx < len(s.tips) {
			return &DialogueNode{
				ID: nodeID, Speaker: meta.Name, Text: s.tips[idx],
				NodeType: "choice",
				Choices: []DialogueChoice{
					{Text: "明白了", NextID: "start"},
					{Text: "再见", NextID: "end", Action: "close"},
				},
			}, nil
		}
	}
	return nil, errors.New("unknown dialogue node")
}

func (s *beginnerQuestScript) buildStartNode(speaker string, character *database.Character) *DialogueNode {
	choices := []DialogueChoice{}
	text := npcdata.Lookup(s.npcID).Dialogue

	switch s.npcID {
	case 2101: // 希娜
		if s.questSvc.IsQuestInProgress(character.ID, 1001) && s.questSvc.hasItem(character.ID, ItemSallyMirror) {
			choices = append(choices, DialogueChoice{
				Text: "我把镜子带来了", NextID: "deliver_1001", Action: "complete_quest", Data: "1001",
			})
		} else if !s.questSvc.IsQuestCompleted(character.ID, 1000) && !s.questSvc.IsQuestInProgress(character.ID, 1000) {
			choices = append(choices, DialogueChoice{
				Text: "有什么需要帮忙的吗？", NextID: "accept_1000", Action: "accept_quest", Data: "1000",
			})
		} else if s.questSvc.IsQuestInProgress(character.ID, 1000) {
			text = "我姐姐莎丽正在晾衣服，能帮我去借一下镜子吗？她在村子东边。"
		} else if s.questSvc.IsQuestInProgress(character.ID, 1001) {
			text = "快去莎丽那里借镜子，然后拿给我吧！"
		}
		if !s.questSvc.IsQuestCompleted(character.ID, 400000) {
			choices = append(choices, DialogueChoice{
				Text: "我是新来的冒险家", NextID: "complete_400000", Action: "complete_quest", Data: "400000",
			})
		}
	case 2100: // 莎丽
		if s.questSvc.IsQuestInProgress(character.ID, 1000) {
			choices = append(choices, DialogueChoice{
				Text: "希娜需要借镜子", NextID: "borrow_mirror", Action: "borrow_mirror",
			})
		} else if s.questSvc.IsQuestCompleted(character.ID, 1000) {
			text = "镜子已经借出去了，快拿给希娜吧！"
		}
	case 12100: // 麦加
		if !s.questSvc.IsQuestCompleted(character.ID, 400001) {
			if s.questSvc.IsQuestInProgress(character.ID, 400001) {
				cq, _ := s.questSvc.GetCharacterQuest(character.ID, 400001)
				progress := 0
				if cq != nil {
					progress = cq.Progress
				}
				text = fmt.Sprintf("继续去击败蜗牛吧！当前进度：%d/10", progress)
				if progress >= 10 {
					choices = append(choices, DialogueChoice{
						Text: "我完成了修炼", NextID: "complete_400001", Action: "complete_quest", Data: "400001",
					})
				}
			} else {
				choices = append(choices, DialogueChoice{
					Text: "接受修炼", NextID: "accept_400001", Action: "accept_quest", Data: "400001",
				})
			}
		}
	case 22000: // 桑克斯船长
		if character.Level >= 5 && !s.questSvc.IsQuestCompleted(character.ID, 400003) {
			choices = append(choices, DialogueChoice{
				Text: "我想出航去金银岛", NextID: "complete_400003", Action: "complete_quest", Data: "400003",
			})
		}
	}

	for i := range s.tips {
		choices = append(choices, DialogueChoice{
			Text: tipLabel(i), NextID: tipNodeID(i),
		})
	}
	choices = append(choices, DialogueChoice{Text: "再见", NextID: "end", Action: "close"})

	return &DialogueNode{
		ID: "start", Speaker: speaker, Text: text,
		NodeType: "choice", Choices: choices,
	}
}

func (s *beginnerQuestScript) buildTipsNode(speaker string) *DialogueNode {
	choices := []DialogueChoice{{Text: "返回", NextID: "start"}}
	for i := range s.tips {
		choices = append([]DialogueChoice{{
			Text: s.tips[i], NextID: tipNodeID(i),
		}}, choices...)
	}
	return &DialogueNode{
		ID: "tips", Speaker: speaker, Text: "还有什么想知道的吗？",
		NodeType: "choice", Choices: choices,
	}
}

func (s *beginnerQuestScript) questNode(nodeID, speaker string, character *database.Character) (*DialogueNode, bool) {
	switch nodeID {
	case "accept_1000", "accept_400001":
		return &DialogueNode{
			ID: nodeID, Speaker: speaker,
			Text:     "太好了！请帮我完成这个任务。",
			NodeType: "end", Action: "accept_quest", Data: nodeIDData(nodeID),
		}, true
	case "deliver_1001", "complete_400000", "complete_400001", "complete_400003":
		return &DialogueNode{
			ID: nodeID, Speaker: speaker,
			Text:     "辛苦你了！这是给你的奖励。",
			NodeType: "end", Action: "complete_quest", Data: nodeIDData(nodeID),
		}, true
	case "borrow_mirror":
		return &DialogueNode{
			ID: nodeID, Speaker: speaker,
			Text:     "原来是希娜要借镜子啊，拿去吧！",
			NodeType: "end", Action: "borrow_mirror",
		}, true
	}
	return nil, false
}

func nodeIDData(nodeID string) string {
	switch nodeID {
	case "accept_1000":
		return "1000"
	case "accept_400001":
		return "400001"
	case "deliver_1001", "complete_1001":
		return "1001"
	case "complete_400000":
		return "400000"
	case "complete_400001":
		return "400001"
	case "complete_400003":
		return "400003"
	}
	return ""
}

func (s *beginnerQuestScript) ExecuteAction(action, data string, character *database.Character) (*DialogueEffect, error) {
	switch action {
	case "accept_quest":
		var questID uint
		if _, err := fmt.Sscanf(data, "%d", &questID); err != nil {
			return nil, errors.New("invalid quest id")
		}
		if questID == 400000 {
			_, err := s.questSvc.AcceptQuest(character.ID, questID)
			if err != nil {
				return nil, err
			}
			return s.questSvc.CompleteQuest(character.ID, questID)
		}
		_, err := s.questSvc.AcceptQuest(character.ID, questID)
		if err != nil {
			return nil, err
		}
		return &DialogueEffect{QuestAccepted: questID}, nil

	case "complete_quest":
		var questID uint
		if _, err := fmt.Sscanf(data, "%d", &questID); err != nil {
			return nil, errors.New("invalid quest id")
		}
		if !s.questSvc.IsQuestInProgress(character.ID, questID) {
			if _, err := s.questSvc.AcceptQuest(character.ID, questID); err != nil {
				return nil, err
			}
		}
		return s.questSvc.CompleteQuest(character.ID, questID)

	case "borrow_mirror":
		if !s.questSvc.IsQuestInProgress(character.ID, 1000) {
			return nil, errors.New("未接取借镜子任务")
		}
		if err := s.questSvc.GiveQuestItem(character.ID, ItemSallyMirror); err != nil {
			return nil, err
		}
		if _, err := s.questSvc.CompleteQuest(character.ID, 1000); err != nil {
			return nil, err
		}
		if _, err := s.questSvc.AcceptQuest(character.ID, 1001); err != nil {
			return nil, err
		}
		return &DialogueEffect{
			ItemGained:     fmt.Sprintf("%d", ItemSallyMirror),
			QuestCompleted: 1000,
			QuestAccepted:  1001,
		}, nil
	}
	return nil, nil
}

func registerBeginnerQuestScripts(s *NPCService) {
	questSvc := NewQuestService()
	scripts := []beginnerQuestScript{
		{
			npcID: 2101, questSvc: questSvc,
			tips: []string{
				"今天的天气真不错～",
				"按左边的 Alt键，就可以跳跃。",
				"用方向键可以移动角色。",
			},
		},
		{
			npcID: 2100, questSvc: questSvc,
			tips: []string{
				"要晒的衣服怎么这么多呀～",
				"你见过我妹妹希娜吗？",
				"按↑键，可以爬梯子或吊绳。",
			},
		},
		{
			npcID: 12100, questSvc: questSvc,
			tips: []string{
				"战士转职要求：等级10；弓箭手转职要求：等级10；飞侠转职要求：等级10；魔法师转职要求：等级8。",
				"转职后可以学到新的技能同时增加背包容量。",
			},
		},
		{
			npcID: 22000, questSvc: questSvc,
			tips: []string{
				"我就是船长。新手一旦离开彩虹岛就很难返回，外面的世界很危险，务必做好准备再出航~",
				"达到转职等级未转职，以后即使升级也无法获得技能点数。",
			},
		},
	}
	for i := range scripts {
		sc := &scripts[i]
		s.scripts[int(sc.npcID)] = sc
	}
}
