package service

import (
	"errors"
	"fmt"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
)

// questDialogueScript 彩虹岛新手任务 NPC 对话（对照 seed 任务 1000/1001/400000/400001）
type questDialogueScript struct {
	npcID       uint
	questSvc    *QuestService
	startQuests []uint // 此 NPC 可发布的任务
	turnInQuest []uint // 此 NPC 可交付的任务
}

func registerQuestDialogueScripts(s *NPCService, questSvc *QuestService) {
	add := func(id uint, start, turnIn []uint) {
		sc := &questDialogueScript{
			npcID:       id,
			questSvc:    questSvc,
			startQuests: start,
			turnInQuest: turnIn,
		}
		s.scripts[int(id)] = sc
	}
	add(2101, []uint{1000, 400000}, []uint{1000, 1001})
	add(2100, []uint{}, []uint{})
	add(12100, []uint{400001, 400002}, []uint{400001, 400002})
}

func (s *questDialogueScript) GetNPCID() int { return int(s.npcID) }

func (s *questDialogueScript) GetNode(nodeID string, character *database.Character) (*DialogueNode, error) {
	switch nodeID {
	case "start":
		return s.buildStartNode(character), nil
	case "end":
		return &DialogueNode{
			ID: "end", Speaker: npcName(s.npcID), Text: "再见，祝你在冒险岛玩得开心！",
			NodeType: "end", Action: "close",
		}, nil
	case "quest_list":
		return s.buildQuestListNode(character), nil
	case "quest_done":
		return &DialogueNode{
			ID: "quest_done", Speaker: npcName(s.npcID),
			Text: "做得好！这是给你的奖励，继续加油~",
			NodeType: "end", Action: "close",
		}, nil
	case "mirror_ok":
		return &DialogueNode{
			ID: "mirror_ok", Speaker: npcName(s.npcID),
			Text: "镜子拿去吧！告诉希娜用完记得还我哦~",
			NodeType: "choice",
			Choices: []DialogueChoice{{Text: "谢谢", NextID: "start"}},
		}, nil
	case "quest_1000_hint":
		return &DialogueNode{
			ID: "quest_1000_hint", Speaker: npcName(s.npcID),
			Text: "我姐姐莎丽在村子东边晾衣服，去找她借镜子吧。",
			NodeType: "choice",
			Choices: []DialogueChoice{{Text: "明白了", NextID: "start"}},
		}, nil
	default:
		if qid, ok := parseQuestNode(nodeID); ok {
			return s.buildQuestDetailNode(character, qid)
		}
	}
	return nil, errors.New("unknown dialogue node")
}

func (s *questDialogueScript) ExecuteAction(action string, data string, character *database.Character) (*DialogueEffect, error) {
	switch action {
	case "accept_quest":
		var questID uint
		if _, err := fmt.Sscanf(data, "%d", &questID); err != nil {
			return nil, errors.New("invalid quest id")
		}
		if _, err := s.questSvc.AcceptQuest(character.ID, questID); err != nil {
			return nil, err
		}
		return nil, nil
	case "complete_quest":
		var questID uint
		if _, err := fmt.Sscanf(data, "%d", &questID); err != nil {
			return nil, errors.New("invalid quest id")
		}
		return s.questSvc.CompleteQuest(character.ID, questID)
	case "advance_quest":
		var questID uint
		if _, err := fmt.Sscanf(data, "%d", &questID); err != nil {
			return nil, errors.New("invalid quest id")
		}
		return nil, s.questSvc.AdvanceTalkQuest(character.ID, questID)
	}
	return nil, nil
}

func (s *questDialogueScript) buildStartNode(character *database.Character) *DialogueNode {
	name := npcName(s.npcID)
	choices := []DialogueChoice{}
	// 可交付任务
	for _, qid := range s.turnInQuest {
		if s.questSvc.HasActiveQuest(character.ID, qid) {
			req := questRequirements[qid]
			cq, _ := s.questSvc.GetQuestProgress(character.ID, qid)
			progress := 0
			if cq != nil {
				progress = cq.Progress
			}
			if s.questSvc.isRequirementMet(character.ID, qid, req, cq) {
				quest, _ := repository.GetQuestByID(qid)
				label := "交付任务"
				if quest != nil {
					label = fmt.Sprintf("交付：%s", quest.Name)
				}
				choices = append(choices, DialogueChoice{
					Text: label, NextID: "quest_done", Action: "complete_quest", Data: fmt.Sprintf("%d", qid),
				})
			} else if qid == 1000 && s.questSvc.HasActiveQuest(character.ID, 1000) {
				choices = append(choices, DialogueChoice{
					Text: "关于借镜子的事…", NextID: "quest_1000_hint",
				})
			}
			_ = progress
		}
	}
	// 可接取任务
	hasQuestOption := false
	for _, qid := range s.startQuests {
		if s.questSvc.HasCompletedQuest(character.ID, qid) {
			continue
		}
		if s.questSvc.HasActiveQuest(character.ID, qid) {
			continue
		}
		req := questRequirements[qid]
		if req.PrereqQuestID > 0 && !s.questSvc.HasCompletedQuest(character.ID, req.PrereqQuestID) {
			continue
		}
		hasQuestOption = true
	}
	if hasQuestOption {
		choices = append(choices, DialogueChoice{Text: "有什么任务吗？", NextID: "quest_list"})
	}
	// 莎丽特殊：推进 1000
	if s.npcID == 2100 && s.questSvc.HasActiveQuest(character.ID, 1000) {
		cq, _ := s.questSvc.GetQuestProgress(character.ID, 1000)
		if cq != nil && cq.Progress < 1 {
			choices = append([]DialogueChoice{{
				Text: "希娜让我来借镜子", NextID: "mirror_ok", Action: "advance_quest", Data: "1000",
			}}, choices...)
		}
	}
	choices = append(choices, DialogueChoice{Text: "再见", NextID: "end", Action: "close"})
	text := defaultNpcText(s.npcID)
	return &DialogueNode{
		ID: "start", Speaker: name, Text: text, NodeType: "choice", Choices: choices,
	}
}

func (s *questDialogueScript) buildQuestListNode(character *database.Character) *DialogueNode {
	choices := []DialogueChoice{}
	for _, qid := range s.startQuests {
		if s.questSvc.HasCompletedQuest(character.ID, qid) || s.questSvc.HasActiveQuest(character.ID, qid) {
			continue
		}
		req := questRequirements[qid]
		if req.PrereqQuestID > 0 && !s.questSvc.HasCompletedQuest(character.ID, req.PrereqQuestID) {
			continue
		}
		quest, err := repository.GetQuestByID(qid)
		if err != nil {
			continue
		}
		choices = append(choices, DialogueChoice{
			Text: quest.Name, NextID: questNodeID(qid),
		})
	}
	if len(choices) == 0 {
		return &DialogueNode{
			ID: "quest_list", Speaker: npcName(s.npcID), Text: "现在没有适合你的任务。",
			NodeType: "choice",
			Choices: []DialogueChoice{{Text: "明白了", NextID: "start"}},
		}
	}
	choices = append(choices, DialogueChoice{Text: "下次再说", NextID: "start"})
	return &DialogueNode{
		ID: "quest_list", Speaker: npcName(s.npcID), Text: "这些是我能交给你的事：",
		NodeType: "choice", Choices: choices,
	}
}

func (s *questDialogueScript) buildQuestDetailNode(character *database.Character, questID uint) (*DialogueNode, error) {
	quest, err := repository.GetQuestByID(questID)
	if err != nil {
		return nil, err
	}
	choices := []DialogueChoice{
		{Text: "接受任务", NextID: "start", Action: "accept_quest", Data: fmt.Sprintf("%d", questID)},
		{Text: "再想想", NextID: "quest_list"},
	}
	// 交付节点
	for _, qid := range s.turnInQuest {
		if qid == questID {
			choices = []DialogueChoice{
				{Text: "完成任务", NextID: "quest_done", Action: "complete_quest", Data: fmt.Sprintf("%d", questID)},
				{Text: "还没准备好", NextID: "start"},
			}
		}
	}
	text := fmt.Sprintf("【%s】\n%s\n奖励：经验 %d / 金币 %d",
		quest.Name, quest.Description, quest.ExpReward, quest.MesosReward)
	if s.questSvc.HasActiveQuest(character.ID, questID) {
		cq, _ := s.questSvc.GetQuestProgress(character.ID, questID)
		if cq != nil {
			text += "\n进度 " + s.questSvc.QuestProgressText(questID, cq.Progress)
		}
	}
	return &DialogueNode{
		ID: questNodeID(questID), Speaker: npcName(s.npcID), Text: text,
		NodeType: "choice", Choices: choices,
	}, nil
}

func npcName(npcID uint) string {
	switch npcID {
	case 2101:
		return "希娜"
	case 2100:
		return "莎丽"
	case 12100:
		return "武术教练"
	default:
		return "NPC"
	}
}

func defaultNpcText(npcID uint) string {
	switch npcID {
	case 2101:
		return "你是第一次到冒险岛来吗？怎么样？虽然还很陌生，不过很漂亮吧？"
	case 2100:
		return "真是个晒衣服的好天气~ 你不觉得吗？"
	case 12100:
		return "呜呼。。。不要在那里逛来逛去的，来接受我的修炼怎么样？"
	default:
		return "你好，冒险者！"
	}
}

func questNodeID(qid uint) string  { return fmt.Sprintf("quest_%d", qid) }
func parseQuestNode(id string) (uint, bool) {
	var qid uint
	if _, err := fmt.Sscanf(id, "quest_%d", &qid); err != nil {
		return 0, false
	}
	return qid, true
}
