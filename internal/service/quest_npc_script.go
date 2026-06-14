package service

import (
	"fmt"

	"mapleStory079/pkg/database"
	"mapleStory079/pkg/npcdata"
)

// rainbowQuestScript 彩虹岛新手 NPC：合并 WZ 提示与任务接取/交付
type rainbowQuestScript struct {
	npcID uint
	tips  []string
	quest *QuestService
}

func (s *rainbowQuestScript) GetNPCID() int { return int(s.npcID) }

func (s *rainbowQuestScript) GetNode(nodeID string, character *database.Character) (*DialogueNode, error) {
	meta := npcdata.Lookup(s.npcID)
	charID := character.ID

	switch nodeID {
	case "start":
		return s.buildStartNode(meta.Name, charID, character), nil
	case "end":
		return &DialogueNode{
			ID: "end", Speaker: meta.Name,
			Text:     "再见，祝你在冒险岛玩得开心！",
			NodeType: "end", Action: "close",
		}, nil
	default:
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
		if def, ok := rainbowQuestDefs[parseQuestNodeID(nodeID)]; ok {
			return s.questDetailNode(meta.Name, def, charID), nil
		}
	}
	return nil, fmt.Errorf("unknown dialogue node: %s", nodeID)
}

func (s *rainbowQuestScript) buildStartNode(npcName string, charID uint, ch *database.Character) *DialogueNode {
	meta := npcdata.Lookup(s.npcID)
	text := meta.Dialogue
	if text == "" {
		text = fmt.Sprintf("你好，冒险者 %s！", ch.Name)
	}

	choices := []DialogueChoice{}

	// 可交付任务
	for _, def := range s.quest.QuestsCompletableAtNPC(s.npcID, charID) {
		choices = append(choices, DialogueChoice{
			Text:   fmt.Sprintf("[完成任务] %s", def.Name),
			NextID: "start",
			Action: "quest_complete",
			Data:   fmt.Sprintf("%d", def.ID),
		})
	}

	// 可接取任务
	for _, def := range s.quest.QuestsOfferedByNPC(s.npcID, charID, ch) {
		choices = append(choices, DialogueChoice{
			Text:   fmt.Sprintf("[任务] %s", def.Name),
			NextID: questNodeID(def.ID),
		})
	}

	// 进行中任务提示
	for _, def := range s.quest.InProgressAtNPC(s.npcID, charID) {
		if s.quest.IsQuestInProgress(charID, def.ID) {
			cq, _ := s.quest.GetCharacterQuest(charID, def.ID)
			progress := ""
			if def.KillMobID > 0 && cq != nil {
				progress = fmt.Sprintf("（%d/%d）", cq.Progress, def.KillCount)
			}
			choices = append(choices, DialogueChoice{
				Text:   fmt.Sprintf("关于「%s」%s", def.Name, progress),
				NextID: questNodeID(def.ID),
			})
		}
	}

	// WZ 提示
	for i := range s.tips {
		choices = append(choices, DialogueChoice{
			Text:   tipLabel(i),
			NextID: tipNodeID(i),
		})
	}

	choices = append(choices, DialogueChoice{Text: "再见", NextID: "end", Action: "close"})

	return &DialogueNode{
		ID: "start", Speaker: npcName, Text: text,
		NodeType: "choice", Choices: choices,
	}
}

func (s *rainbowQuestScript) questDetailNode(npcName string, def QuestDef, charID uint) *DialogueNode {
	text := def.AcceptText
	choices := []DialogueChoice{{Text: "返回", NextID: "start"}}

	if s.quest.IsQuestInProgress(charID, def.ID) {
		text = def.ProgressText
		if def.KillMobID > 0 {
			cq, _ := s.quest.GetCharacterQuest(charID, def.ID)
			if cq != nil {
				text = fmt.Sprintf("%s（进度 %d/%d）", def.ProgressText, cq.Progress, def.KillCount)
			}
		}
		if def.CompleteNPC == s.npcID {
			cq, _ := s.quest.GetCharacterQuest(charID, def.ID)
			if cq != nil && (def.KillMobID == 0 || cq.Progress >= def.KillCount) {
				choices = []DialogueChoice{
					{Text: "完成任务", NextID: "start", Action: "quest_complete", Data: fmt.Sprintf("%d", def.ID)},
					{Text: "返回", NextID: "start"},
				}
			}
		}
	} else if !s.quest.IsQuestCompleted(charID, def.ID) {
		choices = []DialogueChoice{
			{Text: "接受任务", NextID: "start", Action: "quest_accept", Data: fmt.Sprintf("%d", def.ID)},
			{Text: "返回", NextID: "start"},
		}
	} else {
		text = def.CompletedText
	}

	return &DialogueNode{
		ID: questNodeID(def.ID), Speaker: npcName, Text: text,
		NodeType: "choice", Choices: choices,
	}
}

func (s *rainbowQuestScript) ExecuteAction(action string, data string, character *database.Character) (*DialogueEffect, error) {
	var questID uint
	if _, err := fmt.Sscanf(data, "%d", &questID); err != nil {
		return nil, fmt.Errorf("invalid quest id")
	}
	switch action {
	case "quest_accept":
		_, err := s.quest.AcceptQuest(character.ID, questID, character)
		if err != nil {
			return nil, err
		}
		def := rainbowQuestDefs[questID]
		return &DialogueEffect{QuestID: questID, QuestAction: "accepted", Message: fmt.Sprintf("已接取任务：%s", def.Name)}, nil
	case "quest_complete":
		effect, err := s.quest.CompleteQuest(character.ID, questID, character)
		if err != nil {
			return nil, err
		}
		def := rainbowQuestDefs[questID]
		if effect.Message == "" {
			effect.Message = fmt.Sprintf("完成任务：%s！获得 %d 经验、%d 金币", def.Name, def.ExpReward, def.MesosReward)
		}
		return effect, nil
	}
	return nil, nil
}

func questNodeID(questID uint) string {
	return fmt.Sprintf("quest_%d", questID)
}

func parseQuestNodeID(nodeID string) uint {
	var id uint
	fmt.Sscanf(nodeID, "quest_%d", &id)
	return id
}

func registerRainbowQuestScripts(s *NPCService, questSvc *QuestService) {
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
		12100: {
			"战士转职要求：等级10；弓箭手转职要求：等级10；飞侠转职要求：等级10；魔法师转职要求：等级8。",
			"转职后可以学到新的技能同时增加背包容量，但是每次战斗牺牲都会减少一定经验值。",
			"战士转职地点：金银岛勇士部落；弓箭手转职地点：金银岛射手村；飞侠转职地点：金银岛废弃都市；魔法师转职地点：金银岛魔法密林。",
		},
	}
	for id, tips := range scripts {
		s.scripts[int(id)] = &rainbowQuestScript{npcID: id, tips: tips, quest: questSvc}
	}
}
