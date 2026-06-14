package service

import (
	"errors"
	"fmt"

	"mapleStory079/pkg/database"
	"mapleStory079/pkg/npcdata"
)

// wzDialogueScript 使用 WZ String.wz 默认台词与提示的多轮对话。
type wzDialogueScript struct {
	npcID uint
	tips  []string
}

func (s *wzDialogueScript) GetNPCID() int { return int(s.npcID) }

func (s *wzDialogueScript) GetNode(nodeID string, _ *database.Character) (*DialogueNode, error) {
	meta := npcdata.Lookup(s.npcID)
	switch nodeID {
	case "start":
		choices := []DialogueChoice{{Text: "再见", NextID: "end", Action: "close"}}
		for i := range s.tips {
			choices = append([]DialogueChoice{{
				Text:   tipLabel(i),
				NextID: tipNodeID(i),
			}}, choices...)
		}
		return &DialogueNode{
			ID:       "start",
			Speaker:  meta.Name,
			Text:     meta.Dialogue,
			NodeType: "choice",
			Choices:  choices,
		}, nil
	case "end":
		return &DialogueNode{
			ID:       "end",
			Speaker:  meta.Name,
			Text:     "再见，祝你在冒险岛玩得开心！",
			NodeType: "end",
			Action:   "close",
		}, nil
	default:
		if idx, ok := parseTipNode(nodeID); ok && idx < len(s.tips) {
			return &DialogueNode{
				ID:       nodeID,
				Speaker:  meta.Name,
				Text:     s.tips[idx],
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

func (s *wzDialogueScript) ExecuteAction(string, string, *database.Character) (*DialogueEffect, error) {
	return nil, nil
}

func tipLabel(i int) string {
	switch i {
	case 0:
		return "有什么要告诉我的吗？"
	case 1:
		return "还有别的提示吗？"
	default:
		return "继续听你说"
	}
}

func tipNodeID(i int) string {
	return fmt.Sprintf("tip_%d", i)
}

func parseTipNode(id string) (int, bool) {
	var idx int
	if _, err := fmt.Sscanf(id, "tip_%d", &idx); err != nil {
		return 0, false
	}
	return idx, true
}

func registerWZDialogueScripts(s *NPCService) {
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
		12000: {
			"增加力量主要提高攻击力，是战士的关键属性；增加敏捷可以提高命中率和手技，也会适当增加攻击力和回避率，是弓箭手的关键属性；",
			"战斗中需要的药水和武器在村落中都可以买到",
			"增加智力可以提高魔法攻击力、魔法防御力和手技，是魔法师关键属性；增加运气可以提高命中率、回避率以及手技，对所有职业都有益处，特别是飞侠。",
		},
		10000: {
			"到处丢掉的都是可以再用的好东西。。你要是捡到了就给我吧。",
		},
		22000: {
			"我就是船长。新手一旦离开彩虹岛就很难返回，外面的世界很危险，务必做好准备再出航~",
			"达到转职等级未转职，以后即使升级也无法获得技能点数。",
		},
		12101: {
			"瑞恩的脑筋急转弯：打开背包的快捷键是什么？（I键）",
			"双击背包里的道具就可以穿到身上。",
			"打开装备窗的快捷键是E!",
		},
		2103: {
			"你能帮我把这封信送给路卡斯长老吗？",
		},
		20100: {
			"什么时候才能离开金银岛看更广阔的世界呢?",
		},
		20001: {
			"彩虹村的皮奥可是我的叔叔哦,从小开始叔叔就教我这些技术.",
		},
	}
	for id, tips := range scripts {
		s.scripts[int(id)] = &wzDialogueScript{npcID: id, tips: tips}
	}
}
