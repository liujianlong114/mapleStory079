package service

import (
	"errors"
	"fmt"
	"sync"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
	"mapleStory079/pkg/utils"
)

// ================ NPC 对话系统 ================

// DialogueChoice 对话选项
type DialogueChoice struct {
	Text   string `json:"text"`
	NextID string `json:"next_id"` // 下一个对话节点ID
	Action string `json:"action"`  // 特殊动作：job_change, teleport, trade, close
	Data   string `json:"data"`    // 动作附加数据
}

// DialogueNode 对话节点（开始/选择/结束三态合一）
type DialogueNode struct {
	ID       string           `json:"id"`
	Speaker  string           `json:"speaker"`
	Text     string           `json:"text"`
	NodeType string           `json:"node_type"` // "start" | "choice" | "end"
	Choices  []DialogueChoice `json:"choices,omitempty"`
	NextID   string           `json:"next_id,omitempty"`
	Action   string           `json:"action,omitempty"`
	Data     string           `json:"data,omitempty"`
}

// DialogueResult 对话返回结果
type DialogueResult struct {
	NPCID   uint            `json:"npc_id"`
	NPCName string          `json:"npc_name"`
	Node    *DialogueNode   `json:"node"`
	Message string          `json:"message,omitempty"`
	Effects *DialogueEffect `json:"effects,omitempty"`
}

// DialogueEffect 对话执行的副作用
type DialogueEffect struct {
	NewClass   int    `json:"new_class,omitempty"`
	NewMapID   int    `json:"new_map_id,omitempty"`
	NewHP      int    `json:"new_hp,omitempty"`
	NewMP      int    `json:"new_mp,omitempty"`
	NewMesos   int64  `json:"new_mesos,omitempty"`
	ItemGained string `json:"item_gained,omitempty"`
}

// NPCScript 已注册的NPC脚本接口
type NPCScript interface {
	GetNPCID() int
	GetNode(nodeID string, character *database.Character) (*DialogueNode, error)
	ExecuteAction(action string, data string, character *database.Character) (*DialogueEffect, error)
}

// ============ NPC 对话服务 ============

type NPCService struct {
	scripts map[int]NPCScript
	mu      sync.RWMutex
}

func NewNPCService() *NPCService {
	svc := &NPCService{scripts: make(map[int]NPCScript)}
	svc.registerDefaultScripts()
	return svc
}

// 注册内置的默认NPC脚本（转职官、传送门、商人等）
func (s *NPCService) registerDefaultScripts() {
	s.scripts[1010000] = &JobChangeScript{}
	s.scripts[1010001] = &JobChangeScript{}
	s.scripts[1010002] = &JobChangeScript{}
	s.scripts[1010003] = &JobChangeScript{}
	s.scripts[1010004] = &JobChangeScript{}
	s.scripts[9900001] = &PortalScript{}
	s.scripts[9900002] = &MerchantScript{}
}

// ================ 核心交互方法 ================

// StartDialogue 开启与NPC的对话
func (s *NPCService) StartDialogue(npcID uint, characterID uint) (*DialogueResult, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	npc, err := repository.GetNPCByID(npcID)
	if err != nil {
		return nil, errors.New("npc not found")
	}

	character, err := repository.GetCharacterByID(characterID)
	if err != nil {
		return nil, errors.New("character not found")
	}

	// 查找已注册的脚本
	if script, ok := s.scripts[int(npcID)]; ok {
		node, err := script.GetNode("start", character)
		if err != nil {
			return nil, err
		}
		return &DialogueResult{
			NPCID:   npcID,
			NPCName: npc.Name,
			Node:    node,
		}, nil
	}

	// 默认对话（未注册脚本的NPC）
	return &DialogueResult{
		NPCID:   npcID,
		NPCName: npc.Name,
		Node: &DialogueNode{
			ID:       "start",
			Speaker:  npc.Name,
			Text:     fmt.Sprintf("你好，冒险者 %s！欢迎来到枫叶世界。", character.Name),
			NodeType: "choice",
			Choices: []DialogueChoice{
				{Text: "再见", NextID: "end", Action: "close"},
			},
		},
	}, nil
}

// ContinueDialogue 继续对话（根据选择进入下一节点）
func (s *NPCService) ContinueDialogue(npcID uint, characterID uint, nodeID string, choiceIndex int) (*DialogueResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	npc, err := repository.GetNPCByID(npcID)
	if err != nil {
		return nil, errors.New("npc not found")
	}

	character, err := repository.GetCharacterByID(characterID)
	if err != nil {
		return nil, errors.New("character not found")
	}

	if nodeID == "end" {
		return &DialogueResult{
			NPCID:   npcID,
			NPCName: npc.Name,
			Node: &DialogueNode{
				ID:       "end",
				Speaker:  npc.Name,
				Text:     "期待下次再见，祝你好运！",
				NodeType: "end",
				Action:   "close",
			},
			Message: "对话结束",
		}, nil
	}

	script, ok := s.scripts[int(npcID)]
	if !ok {
		return &DialogueResult{
			NPCID:   npcID,
			NPCName: npc.Name,
			Node: &DialogueNode{
				ID:       "end",
				Speaker:  npc.Name,
				Text:     "再见，冒险者！",
				NodeType: "end",
				Action:   "close",
			},
		}, nil
	}

	node, err := script.GetNode(nodeID, character)
	if err != nil {
		return nil, err
	}

	// 如果是 choice 节点，读取对应选项
	var nextNodeID, action, data string
	if node.NodeType == "choice" && choiceIndex >= 0 && choiceIndex < len(node.Choices) {
		choice := node.Choices[choiceIndex]
		nextNodeID = choice.NextID
		action = choice.Action
		data = choice.Data
	} else {
		nextNodeID = node.NextID
		action = node.Action
		data = node.Data
	}

	// 执行动作
	var effect *DialogueEffect
	if action != "" && action != "close" {
		effect, err = script.ExecuteAction(action, data, character)
		if err != nil {
			return nil, err
		}
		if effect != nil {
			// 持久化角色修改
			_ = repository.UpdateCharacter(character)
		}
	}

	// 获取下一个节点
	nextNode, err := script.GetNode(nextNodeID, character)
	if err != nil {
		nextNode = &DialogueNode{
			ID:       "end",
			Speaker:  npc.Name,
			Text:     "对话结束。",
			NodeType: "end",
		}
	}

	result := &DialogueResult{
		NPCID:   npcID,
		NPCName: npc.Name,
		Node:    nextNode,
		Effects: effect,
	}
	if nextNode.NodeType == "end" {
		result.Message = "对话结束"
	}
	return result, nil
}

// ================ 具体脚本实现 ================

// --------- 转职官脚本 ---------
type JobChangeScript struct{}

func (s *JobChangeScript) GetNPCID() int { return 1010000 }

func (s *JobChangeScript) GetNode(nodeID string, character *database.Character) (*DialogueNode, error) {
	switch nodeID {
	case "start":
		if character.Class != 0 && character.Class != utils.JobBeginner {
			return &DialogueNode{
				ID:       "already_job",
				Speaker:  "转职官",
				Text:     fmt.Sprintf("你已经是%s了，不需要再次转职。", classNameByClass(character.Class)),
				NodeType: "choice",
				Choices: []DialogueChoice{
					{Text: "好的，再见", NextID: "end", Action: "close"},
				},
			}, nil
		}
		if character.Level < 10 {
			return &DialogueNode{
				ID:       "level_low",
				Speaker:  "转职官",
				Text:     fmt.Sprintf("你当前等级为 %d，需要达到 10 级才能进行转职。", character.Level),
				NodeType: "choice",
				Choices: []DialogueChoice{
					{Text: "好的，我会努力升级", NextID: "end", Action: "close"},
				},
			}, nil
		}
		return &DialogueNode{
			ID:       "start",
			Speaker:  "转职官",
			Text:     "欢迎，年轻的冒险者！你想要选择哪个职业开启你的冒险之旅？",
			NodeType: "choice",
			Choices: []DialogueChoice{
				{Text: "战士（崇尚力量）", NextID: "confirm_warrior", Action: "job_change", Data: fmt.Sprintf("%d", utils.JobWarrior)},
				{Text: "法师（掌控魔法）", NextID: "confirm_mage", Action: "job_change", Data: fmt.Sprintf("%d", utils.JobMagician)},
				{Text: "弓箭手（精准射击）", NextID: "confirm_archer", Action: "job_change", Data: fmt.Sprintf("%d", utils.JobBowman)},
				{Text: "飞侠（敏捷与幸运）", NextID: "confirm_thief", Action: "job_change", Data: fmt.Sprintf("%d", utils.JobThief)},
				{Text: "海盗（力量与敏捷）", NextID: "confirm_pirate", Action: "job_change", Data: fmt.Sprintf("%d", utils.JobPirate)},
				{Text: "再想想…", NextID: "end", Action: "close"},
			},
		}, nil
	case "confirm_warrior":
		return simpleConfirmNode("你确定要成为战士吗？", utils.JobWarrior), nil
	case "confirm_mage":
		return simpleConfirmNode("你确定要成为法师吗？", utils.JobMagician), nil
	case "confirm_archer":
		return simpleConfirmNode("你确定要成为弓箭手吗？", utils.JobBowman), nil
	case "confirm_thief":
		return simpleConfirmNode("你确定要成为飞侠吗？", utils.JobThief), nil
	case "confirm_pirate":
		return simpleConfirmNode("你确定要成为海盗吗？", utils.JobPirate), nil
	case "success":
		return &DialogueNode{
			ID:       "success",
			Speaker:  "转职官",
			Text:     fmt.Sprintf("恭喜！你已成功转职为%s，愿你在冒险的道路上一帆风顺！", classNameByClass(character.Class)),
			NodeType: "end",
			Action:   "close",
		}, nil
	case "decline":
		return &DialogueNode{
			ID:       "decline",
			Speaker:  "转职官",
			Text:     "好的，当你准备好时再来找我。",
			NodeType: "end",
			Action:   "close",
		}, nil
	case "end":
		return &DialogueNode{
			ID:       "end",
			Speaker:  "转职官",
			Text:     "再见，冒险者！",
			NodeType: "end",
			Action:   "close",
		}, nil
	}
	return nil, errors.New("unknown dialogue node")
}

func (s *JobChangeScript) ExecuteAction(action string, data string, character *database.Character) (*DialogueEffect, error) {
	if action == "job_change" {
		var newClass int
		_, err := fmt.Sscanf(data, "%d", &newClass)
		if err != nil {
			return nil, errors.New("invalid job data")
		}
		if _, ok := utils.JobNames[newClass]; !ok {
			return nil, errors.New("invalid job class")
		}
		character.Class = newClass
		applyJobInitialStats(character, newClass)
		return &DialogueEffect{NewClass: newClass}, nil
	}
	return nil, nil
}

func simpleConfirmNode(text string, classData int) *DialogueNode {
	return &DialogueNode{
		ID:       "confirm",
		Speaker:  "转职官",
		Text:     text,
		NodeType: "choice",
		Choices: []DialogueChoice{
			{Text: "是的，我确定", NextID: "success", Action: "job_change", Data: fmt.Sprintf("%d", classData)},
			{Text: "不，我再想想", NextID: "decline", Action: "close"},
		},
	}
}

func applyJobInitialStats(character *database.Character, class int) {
	stats, ok := utils.JobInitialStatsMap[class]
	if !ok {
		return
	}
	character.STR = stats.STR
	character.DEX = stats.DEX
	character.INT = stats.INT
	character.LUK = stats.LUK
	character.MaxHP = stats.HP
	character.MaxMP = stats.MP
	character.HP = stats.HP
	character.MP = stats.MP
}

// --------- 传送门脚本 ---------
type PortalScript struct{}

func (s *PortalScript) GetNPCID() int { return 9900001 }

func (s *PortalScript) GetNode(nodeID string, character *database.Character) (*DialogueNode, error) {
	switch nodeID {
	case "start":
		return &DialogueNode{
			ID:       "start",
			Speaker:  "传送门",
			Text:     fmt.Sprintf("你现在位于地图 %d，选择要前往的目的地：", character.MapID),
			NodeType: "choice",
			Choices: []DialogueChoice{
				{Text: "前往新手村", NextID: "teleport", Action: "teleport", Data: fmt.Sprintf("%d", utils.MapMapleIsland)},
				{Text: "前往明珠港", NextID: "teleport", Action: "teleport", Data: fmt.Sprintf("%d", utils.MapSouthPerry)},
				{Text: "前往魔法密林", NextID: "teleport", Action: "teleport", Data: fmt.Sprintf("%d", utils.MapEllinia)},
				{Text: "前往射手村", NextID: "teleport", Action: "teleport", Data: fmt.Sprintf("%d", utils.MapHenesys)},
				{Text: "不去了", NextID: "end", Action: "close"},
			},
		}, nil
	case "teleport":
		return &DialogueNode{
			ID:       "teleport",
			Speaker:  "传送门",
			Text:     fmt.Sprintf("已成功将你传送到地图 %d。", character.MapID),
			NodeType: "end",
			Action:   "close",
		}, nil
	case "end":
		return &DialogueNode{
			ID:       "end",
			Speaker:  "传送门",
			Text:     "再见！",
			NodeType: "end",
			Action:   "close",
		}, nil
	}
	return nil, errors.New("unknown dialogue node")
}

func (s *PortalScript) ExecuteAction(action string, data string, character *database.Character) (*DialogueEffect, error) {
	if action == "teleport" {
		var mapID int
		_, err := fmt.Sscanf(data, "%d", &mapID)
		if err != nil {
			return nil, errors.New("invalid map id")
		}
		character.MapID = uint(mapID)
		character.PositionX = 0
		character.PositionY = 0
		return &DialogueEffect{NewMapID: mapID}, nil
	}
	return nil, nil
}

// --------- 商人脚本（简单示例） ---------
type MerchantScript struct{}

func (s *MerchantScript) GetNPCID() int { return 9900002 }

func (s *MerchantScript) GetNode(nodeID string, character *database.Character) (*DialogueNode, error) {
	switch nodeID {
	case "start":
		return &DialogueNode{
			ID:       "start",
			Speaker:  "商人",
			Text:     fmt.Sprintf("欢迎！你当前拥有 %d 金币。需要什么服务？", character.Mesos),
			NodeType: "choice",
			Choices: []DialogueChoice{
				{Text: "恢复HP/MP", NextID: "healed", Action: "heal"},
				{Text: "再见", NextID: "end", Action: "close"},
			},
		}, nil
	case "healed":
		return &DialogueNode{
			ID:       "healed",
			Speaker:  "商人",
			Text:     "已为你恢复HP和MP，祝你冒险顺利！",
			NodeType: "end",
			Action:   "close",
		}, nil
	case "end":
		return &DialogueNode{
			ID:       "end",
			Speaker:  "商人",
			Text:     "再见，欢迎下次光临！",
			NodeType: "end",
			Action:   "close",
		}, nil
	}
	return nil, errors.New("unknown dialogue node")
}

func (s *MerchantScript) ExecuteAction(action string, data string, character *database.Character) (*DialogueEffect, error) {
	if action == "heal" {
		character.HP = character.MaxHP
		character.MP = character.MaxMP
		return &DialogueEffect{
			NewHP: character.HP,
			NewMP: character.MP,
		}, nil
	}
	return nil, nil
}

// ================ 对外工具方法 ================

// classNameByClass 将职业 ID 映射为中文名称。
func classNameByClass(class int) string {
	if name, ok := utils.JobNames[class]; ok {
		return name
	}
	return "未知"
}

// GetAvailableNPCs 返回可用的NPC列表（便于前端展示）。
func (s *NPCService) GetAvailableNPCs() []int {
	s.mu.RLock()
	defer s.mu.RUnlock()
	ids := make([]int, 0, len(s.scripts))
	for id := range s.scripts {
		ids = append(ids, id)
	}
	return ids
}
