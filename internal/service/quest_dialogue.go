package service

import (
	"errors"
	"fmt"

	"mapleStory079/pkg/database"
	"mapleStory079/pkg/npcdata"
)

// rainbowQuestScript 彩虹岛新手任务 NPC（希娜 2101 / 莎丽 2100）。
type rainbowQuestScript struct {
	npcID uint
	tips  []string
	qs    *QuestService
}

func registerRainbowQuestScripts(s *NPCService) {
	qs := DefaultQuestService
	scripts := map[uint][]string{
		2101: {
			"今天的天气真不错～",
			"按左边的 Alt键，就可以跳跃。",
			"用方向键可以移动角色。",
		},
		2100: {
			"要晒的衣服怎么这么多呀～",
			"你见过我妹妹希娜吗？",
			"按↑键，可以爬梯子或吊绳。",
		},
	}
	for id, tips := range scripts {
		s.scripts[int(id)] = &rainbowQuestScript{npcID: id, tips: tips, qs: qs}
	}
}

func (s *rainbowQuestScript) GetNPCID() int { return int(s.npcID) }

func (s *rainbowQuestScript) GetNode(nodeID string, character *database.Character) (*DialogueNode, error) {
	meta := npcdata.Lookup(s.npcID)
	switch nodeID {
	case "start":
		return s.buildStartNode(meta.Name, meta.Dialogue, character), nil
	case "end":
		return &DialogueNode{
			ID: "end", Speaker: meta.Name,
			Text: "再见，祝你在冒险岛玩得开心！", NodeType: "end", Action: "close",
		}, nil
	case "quest_1000_accepted":
		return &DialogueNode{
			ID: "quest_1000_accepted", Speaker: meta.Name,
			Text: "太好了！请去找我姐姐莎丽借镜子，她在村子东边晒衣服呢。",
			NodeType: "choice",
			Choices: []DialogueChoice{
				{Text: "明白了", NextID: "start"},
				{Text: "再见", NextID: "end", Action: "close"},
			},
		}, nil
	case "quest_1000_mirror":
		return &DialogueNode{
			ID: "quest_1000_mirror", Speaker: meta.Name,
			Text: "给，这是镜子～请帮我跟希娜问好哦！",
			NodeType: "choice",
			Choices: []DialogueChoice{
				{Text: "谢谢！", NextID: "start"},
				{Text: "再见", NextID: "end", Action: "close"},
			},
		}, nil
	case "quest_1001_done":
		return &DialogueNode{
			ID: "quest_1001_done", Speaker: meta.Name,
			Text: "谢谢你帮我借到镜子！作为回报，这些经验值和金币请收下～",
			NodeType: "end", Action: "close",
		}, nil
	case "quest_400001_accepted":
		return &DialogueNode{
			ID: "quest_400001_accepted", Speaker: meta.Name,
			Text: "村子外面的蜗牛太多了，请帮我击退 10 只蜗牛吧！",
			NodeType: "choice",
			Choices: []DialogueChoice{
				{Text: "好的", NextID: "start"},
				{Text: "再见", NextID: "end", Action: "close"},
			},
		}, nil
	case "quest_400001_ready":
		return &DialogueNode{
			ID: "quest_400001_ready", Speaker: meta.Name,
			Text: "你已经击退了足够的蜗牛！干得漂亮，冒险者！",
			NodeType: "end", Action: "close",
		}, nil
	default:
		if idx, ok := parseTipNode(nodeID); ok && idx < len(s.tips) {
			return &DialogueNode{
				ID: nodeID, Speaker: meta.Name, Text: s.tips[idx], NodeType: "choice",
				Choices: []DialogueChoice{
					{Text: "明白了", NextID: "start"},
					{Text: "再见", NextID: "end", Action: "close"},
				},
			}, nil
		}
	}
	return nil, errors.New("unknown dialogue node")
}

func (s *rainbowQuestScript) buildStartNode(name, greeting string, character *database.Character) *DialogueNode {
	text := greeting
	choices := []DialogueChoice{}

	if s.npcID == 2101 {
		if !s.qs.IsQuestCompleted(character.ID, 1000) && !s.qs.IsQuestInProgress(character.ID, 1000) {
			choices = append(choices, DialogueChoice{
				Text: "接受任务：借来莎丽的镜子", NextID: "quest_1000_accepted",
				Action: "quest_accept", Data: "1000",
			})
		}
		if s.qs.IsQuestInProgress(character.ID, 1000) {
			text += "\n\n（去找莎丽借镜子吧～）"
		}
		if s.qs.IsQuestInProgress(character.ID, 1001) && s.qs.GetProgress(character.ID, 1001) >= 1 {
			choices = append(choices, DialogueChoice{
				Text: "交给希娜镜子", NextID: "quest_1001_done",
				Action: "quest_complete", Data: "1001",
			})
		}
		if s.qs.IsQuestCompleted(character.ID, 1001) && !s.qs.IsQuestCompleted(character.ID, 400001) && !s.qs.IsQuestInProgress(character.ID, 400001) {
			choices = append(choices, DialogueChoice{
				Text: "接受任务：击退蜗牛", NextID: "quest_400001_accepted",
				Action: "quest_accept", Data: "400001",
			})
		}
		if s.qs.IsQuestInProgress(character.ID, 400001) {
			prog := s.qs.GetProgress(character.ID, 400001)
			need := QuestKillTarget[400001].Need
			text += fmt.Sprintf("\n\n（击退蜗牛进度：%d/%d）", prog, need)
			if prog >= need {
				choices = append(choices, DialogueChoice{
					Text: "报告击退蜗牛任务", NextID: "quest_400001_ready",
					Action: "quest_complete", Data: "400001",
				})
			}
		}
	}

	if s.npcID == 2100 {
		if s.qs.IsQuestInProgress(character.ID, 1000) {
			choices = append(choices, DialogueChoice{
				Text: "向莎丽借镜子", NextID: "quest_1000_mirror",
				Action: "quest_mirror", Data: "1000",
			})
		}
	}

	for i := range s.tips {
		choices = append(choices, DialogueChoice{Text: tipLabel(i), NextID: tipNodeID(i)})
	}
	choices = append(choices, DialogueChoice{Text: "再见", NextID: "end", Action: "close"})

	return &DialogueNode{
		ID: "start", Speaker: name, Text: text, NodeType: "choice", Choices: choices,
	}
}

func (s *rainbowQuestScript) ExecuteAction(action, data string, character *database.Character) (*DialogueEffect, error) {
	switch action {
	case "quest_accept":
		var questID uint
		if _, err := fmt.Sscanf(data, "%d", &questID); err != nil {
			return nil, errors.New("invalid quest id")
		}
		if err := s.qs.AcceptQuest(character.ID, questID); err != nil {
			return nil, err
		}
		return &DialogueEffect{QuestAccepted: int(questID)}, nil
	case "quest_complete":
		var questID uint
		if _, err := fmt.Sscanf(data, "%d", &questID); err != nil {
			return nil, errors.New("invalid quest id")
		}
		return s.qs.CompleteQuest(character.ID, questID)
	case "quest_mirror":
		return s.qs.HandMirrorFromSari(character.ID)
	default:
		return nil, nil
	}
}
