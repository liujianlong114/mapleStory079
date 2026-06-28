package service

import (
	"errors"
	"fmt"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
	"mapleStory079/pkg/utils"
)

// JobAdvancementScript 转职脚本 — 处理 1~4 转所有职业的对话与属性调整
type JobAdvancementScript struct {
	npcID   int
	npcName string
}

// NewJobAdvancementScript 创建转职脚本实例
func NewJobAdvancementScript(npcID int, npcName string) *JobAdvancementScript {
	return &JobAdvancementScript{npcID: npcID, npcName: npcName}
}

func (s *JobAdvancementScript) GetNPCID() int { return s.npcID }

// getAvailableAdvancements 返回角色当前可进行的转职列表
func (s *JobAdvancementScript) getAvailableAdvancements(character *database.Character) []struct {
	JobID   int
	JobName string
	Info    string
} {
	var result []struct {
		JobID   int
		JobName string
		Info    string
	}
	level := character.Level

	// 检查各转职阶段
	if info, ok := utils.JobInfoMap[utils.JobSwordsman]; ok {
		if level >= info.AdvanceLevel && character.Class == utils.JobBeginner {
			result = append(result, struct {
				JobID   int
				JobName string
				Info    string
			}{utils.JobSwordsman, info.Name, fmt.Sprintf("需要等级 %d，力量 %d", info.AdvanceLevel, info.MinSTR)})
		}
	}
	if info, ok := utils.JobInfoMap[utils.JobMagician]; ok {
		if level >= info.AdvanceLevel && character.Class == utils.JobBeginner {
			result = append(result, struct {
				JobID   int
				JobName string
				Info    string
			}{utils.JobMagician, info.Name, fmt.Sprintf("需要等级 %d，智力 %d", info.AdvanceLevel, info.MinINT)})
		}
	}
	if info, ok := utils.JobInfoMap[utils.JobBowman]; ok {
		if level >= info.AdvanceLevel && character.Class == utils.JobBeginner {
			result = append(result, struct {
				JobID   int
				JobName string
				Info    string
			}{utils.JobBowman, info.Name, fmt.Sprintf("需要等级 %d，敏捷 %d", info.AdvanceLevel, info.MinDEX)})
		}
	}
	if info, ok := utils.JobInfoMap[utils.JobThief]; ok {
		if level >= info.AdvanceLevel && character.Class == utils.JobBeginner {
			result = append(result, struct {
				JobID   int
				JobName string
				Info    string
			}{utils.JobThief, info.Name, fmt.Sprintf("需要等级 %d，敏捷 %d", info.AdvanceLevel, info.MinDEX)})
		}
	}
	if info, ok := utils.JobInfoMap[utils.JobPirate]; ok {
		if level >= info.AdvanceLevel && character.Class == utils.JobBeginner {
			result = append(result, struct {
				JobID   int
				JobName string
				Info    string
			}{utils.JobPirate, info.Name, fmt.Sprintf("需要等级 %d，力量 %d 敏捷 %d", info.AdvanceLevel, info.MinSTR, info.MinDEX)})
		}
	}

	// 2 转：当前职业为 1 转职业（100/200/300/400/500），等级 >= 30
	if level >= 30 {
		switch character.Class {
		case utils.JobSwordsman: // 战士 1转 → 2转分支
			result = append(result,
				struct { JobID int; JobName string; Info string }{utils.JobFighter, "剑客", "战士2转分支，力量型"},
				struct { JobID int; JobName string; Info string }{utils.JobPage, "准骑士", "战士2转分支，力量+敏捷"},
				struct { JobID int; JobName string; Info string }{utils.JobSpearman, "枪战士", "战士2转分支，力量型长武器"})
		case utils.JobMagician: // 法师 1转 → 2转分支
			result = append(result,
				struct { JobID int; JobName string; Info string }{utils.JobFirePoison, "火毒法师", "法师2转，火毒属性"},
				struct { JobID int; JobName string; Info string }{utils.JobIceLightning, "冰雷法师", "法师2转，冰雷属性"},
				struct { JobID int; JobName string; Info string }{utils.JobCleric, "牧师", "法师2转，治愈辅助"})
		case utils.JobBowman: // 弓箭手 1转 → 2转分支
			result = append(result,
				struct { JobID int; JobName string; Info string }{utils.JobHunter, "猎人", "弓箭手2转，弓"},
				struct { JobID int; JobName string; Info string }{utils.JobCrossbow, "弩弓手", "弓箭手2转，弩"})
		case utils.JobThief: // 飞侠 1转 → 2转分支
			result = append(result,
				struct { JobID int; JobName string; Info string }{utils.JobAssassin, "刺客", "飞侠2转，暗器"},
				struct { JobID int; JobName string; Info string }{utils.JobBandit, "侠客", "飞侠2转，短刀"})
		case utils.JobPirate: // 海盗 1转 → 2转分支
			result = append(result,
				struct { JobID int; JobName string; Info string }{utils.JobBrawler, "拳手", "海盗2转，近战"},
				struct { JobID int; JobName string; Info string }{utils.JobGunslinger, "火枪手", "海盗2转，远程"})
		}
	}

	// 3 转：当前职业为 2 转，等级 >= 70
	if level >= 70 {
		switch character.Class {
		case utils.JobFighter:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobCrusader, "勇士", "剑客3转"})
		case utils.JobPage:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobWhiteKnight, "骑士", "准骑士3转"})
		case utils.JobSpearman:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobDragonKnight, "龙骑", "枪战士3转"})
		case utils.JobFirePoison:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobFirePoisonWizard, "火毒巫师", "火毒法师3转"})
		case utils.JobIceLightning:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobIceLightningWizard, "冰雷巫师", "冰雷法师3转"})
		case utils.JobCleric:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobPriest, "祭司", "牧师3转"})
		case utils.JobHunter:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobRanger, "射手", "猎人3转"})
		case utils.JobCrossbow:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobSniper, "游侠", "弩弓手3转"})
		case utils.JobAssassin:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobHermit, "无影人", "刺客3转"})
		case utils.JobBandit:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobChiefBandit, "独行客", "侠客3转"})
		case utils.JobBrawler:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobMarauder, "斗士", "拳手3转"})
		case utils.JobGunslinger:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobOutlaw, "神枪手", "火枪手3转"})
		}
	}

	// 4 转：当前职业为 3 转，等级 >= 120
	if level >= 120 {
		switch character.Class {
		case utils.JobCrusader:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobHero, "英雄", "战士终极之路"})
		case utils.JobWhiteKnight:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobPaladin, "圣骑士", "战士终极之路"})
		case utils.JobDragonKnight:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobDarkKnight, "黑骑士", "战士终极之路"})
		case utils.JobFirePoisonWizard:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobFPArchMage, "火毒大魔导", "法师终极之路"})
		case utils.JobIceLightningWizard:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobILArchMage, "冰雷大魔导", "法师终极之路"})
		case utils.JobPriest:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobBishop, "主教", "法师终极之路"})
		case utils.JobRanger:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobBowmaster, "神射手", "弓箭手终极之路"})
		case utils.JobSniper:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobMarksman, "箭神", "弓箭手终极之路"})
		case utils.JobHermit:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobNightLord, "隐士", "飞侠终极之路"})
		case utils.JobChiefBandit:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobShadower, "侠盗", "飞侠终极之路"})
		case utils.JobMarauder:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobBuccaneer, "冲锋队长", "海盗终极之路"})
		case utils.JobOutlaw:
			result = append(result, struct { JobID int; JobName string; Info string }{utils.JobCorsair, "船长", "海盗终极之路"})
		}
	}

	return result
}

func (s *JobAdvancementScript) GetNode(nodeID string, character *database.Character) (*DialogueNode, error) {
	switch nodeID {
	case "start":
		// 检查是否有可用的转职
		avail := s.getAvailableAdvancements(character)
		choices := make([]DialogueChoice, 0)

		if len(avail) == 0 {
			// 判断是哪个阶段不能转
			curName := classNameByClass(character.Class)
			level := character.Level
			msg := ""
			if character.Class == utils.JobBeginner && level < 10 {
				msg = "你还需要更多的修炼。先去打倒怪物提升到10级吧！"
			} else if character.Class >= 100 && character.Class < 1000 && level < 30 {
				msg = fmt.Sprintf("你已经转职为%s，还需要继续努力。达到30级时可以来找我进行2转。", curName)
			} else if character.Class >= 1000 && character.Class < 10000 && level < 70 {
				msg = fmt.Sprintf("你已经是%s了，需要达到70级才能进行3转。", curName)
			} else if character.Class >= 10000 && level < 120 {
				msg = fmt.Sprintf("你已是%s，需要达到120级才能进行4转。", curName)
			} else if character.Class >= 100000 {
				msg = "你已经达到了冒险的巅峰，不需要再进行转职了。"
			} else {
				msg = "欢迎，冒险者！但你现在还没有可进行的转职。"
			}
			return &DialogueNode{
				ID: "no_advance", Speaker: s.npcName, Text: msg,
				NodeType: "choice",
				Choices:  []DialogueChoice{{Text: "好的", NextID: "end", Action: "close"}},
			}, nil
		}

		// 构建选项
		for _, a := range avail {
			choices = append(choices, DialogueChoice{
				Text:   fmt.Sprintf("转职为 %s", a.JobName),
				NextID: fmt.Sprintf("confirm_%d", a.JobID),
				Action: "show_info",
				Data:   fmt.Sprintf("%d", a.JobID),
			})
		}
		choices = append(choices, DialogueChoice{Text: "我再想想", NextID: "end", Action: "close"})

		return &DialogueNode{
			ID: "start", Speaker: s.npcName,
			Text:    fmt.Sprintf("年轻的冒险者 %s，你已经准备好迎接新的挑战了！请选择你要转职的方向：", character.Name),
			NodeType: "choice",
			Choices:  choices,
		}, nil

	case "end":
		return &DialogueNode{
			ID: "end", Speaker: s.npcName, Text: "期待你下次光临！", NodeType: "end", Action: "close",
		}, nil

	default:
		// 检查是否以 "confirm_" 开头
		if len(nodeID) > 8 && nodeID[:8] == "confirm_" {
			jobID := 0
			fmt.Sscanf(nodeID, "confirm_%d", &jobID)
			if jobID <= 0 {
				return nil, errors.New("未知的转职选项")
			}
			info, ok := utils.JobInfoMap[jobID]
			if !ok {
				return nil, errors.New("未知的职业")
			}

			// 检查等级
			if character.Level < info.AdvanceLevel {
				return &DialogueNode{
					ID: "level_low", Speaker: s.npcName,
					Text:    fmt.Sprintf("你的等级还不够。需要达到 %d 级才能转职为 %s。", info.AdvanceLevel, info.Name),
					NodeType: "end", Action: "close",
				}, nil
			}

			// 检查前置职业
			if info.PreJob >= 0 && character.Class != info.PreJob {
				curName := classNameByClass(character.Class)
				preName := classNameByClass(info.PreJob)
				return &DialogueNode{
					ID: "wrong_job", Speaker: s.npcName,
					Text:    fmt.Sprintf("你当前是%s，需要先转职为%s才能继续。", curName, preName),
					NodeType: "end", Action: "close",
				}, nil
			}

			// 检查属性要求（仅1转）
			if character.Class == utils.JobBeginner {
				if info.MinSTR > 0 && character.STR < info.MinSTR {
					return &DialogueNode{
						ID: "stat_low", Speaker: s.npcName,
						Text:    fmt.Sprintf("你的力量还不够（需要 %d）。先去提升能力值吧！", info.MinSTR),
						NodeType: "end", Action: "close",
					}, nil
				}
				if info.MinDEX > 0 && character.DEX < info.MinDEX {
					return &DialogueNode{
						ID: "stat_low", Speaker: s.npcName,
						Text:    fmt.Sprintf("你的敏捷还不够（需要 %d）。先去提升能力值吧！", info.MinDEX),
						NodeType: "end", Action: "close",
					}, nil
				}
				if info.MinINT > 0 && character.INT < info.MinINT {
					return &DialogueNode{
						ID: "stat_low", Speaker: s.npcName,
						Text:    fmt.Sprintf("你的智力还不够（需要 %d）。先去提升能力值吧！", info.MinINT),
						NodeType: "end", Action: "close",
					}, nil
				}
				if info.MinLUK > 0 && character.LUK < info.MinLUK {
					return &DialogueNode{
						ID: "stat_low", Speaker: s.npcName,
						Text:    fmt.Sprintf("你的幸运还不够（需要 %d）。先去提升能力值吧！", info.MinLUK),
						NodeType: "end", Action: "close",
					}, nil
				}
			}

			// 确认对话
			return &DialogueNode{
				ID: nodeID, Speaker: s.npcName,
				Text:    fmt.Sprintf("你想成为%s吗？这是一条充满挑战的道路，你确定吗？", info.Name),
				NodeType: "choice",
				Choices: []DialogueChoice{
					{Text: "是的，我准备好了！", NextID: "success", Action: "job_advance", Data: fmt.Sprintf("%d", jobID)},
					{Text: "不，我再想想", NextID: "end", Action: "close"},
				},
			}, nil
		}

		if nodeID == "success" {
			return &DialogueNode{
				ID: "success", Speaker: s.npcName,
				Text:    fmt.Sprintf("恭喜！你已成功转职为%s。愿你成为伟大的冒险家！", classNameByClass(character.Class)),
				NodeType: "end", Action: "close",
			}, nil
		}

		// 检查是否以 "no_advance" 开头
		if nodeID == "no_advance" {
			return &DialogueNode{
				ID: "no_advance", Speaker: s.npcName, Text: "好的，等你准备好了再来找我。",
				NodeType: "end", Action: "close",
			}, nil
		}

		return nil, errors.New("未知的对话节点")
	}
}

func (s *JobAdvancementScript) ExecuteAction(action string, data string, character *database.Character) (*DialogueEffect, error) {
	switch action {
	case "job_advance":
		var newClass int
		if _, err := fmt.Sscanf(data, "%d", &newClass); err != nil || newClass <= 0 {
			return nil, errors.New("无效的职业数据")
		}
		return performJobAdvancement(character, newClass)

	case "show_info":
		return nil, nil // 仅前端展示，无副作用

	default:
		return nil, nil
	}
}

// performJobAdvancement 执行转职操作
func performJobAdvancement(character *database.Character, newClass int) (*DialogueEffect, error) {
	if _, ok := utils.JobNames[newClass]; !ok {
		return nil, errors.New("无效的职业编号")
	}

	oldClass := character.Class
	oldLevel := character.Level

	// 1转：应用初始属性
	if newClass%100 == 0 && oldClass == utils.JobBeginner {
		if stats, ok := utils.JobInitialStatsMap[newClass]; ok {
			character.STR = stats.STR
			character.DEX = stats.DEX
			character.INT = stats.INT
			character.LUK = stats.LUK
			if character.MaxHP < stats.HP {
				character.MaxHP = stats.HP
			}
			if character.MaxMP < stats.MP {
				character.MaxMP = stats.MP
			}
			character.HP = character.MaxHP
			character.MP = character.MaxMP
		}
	}

	// 2转及以上：赠送部分初始 HP/MP 并重置技能点
	if newClass >= 100 && newClass < 10000 {
		// 按职业赠送额外 HP/MP
		if hpmp, ok := utils.JobLevelUpStatsMap[newClass]; ok {
			character.MaxHP += hpmp.HP * 3 // 转职赠送血量
			character.MaxMP += hpmp.MP * 3 // 转职赠送蓝量
			character.HP = character.MaxHP
			character.MP = character.MaxMP
		}
	}

	// 设置新职业
	character.Class = newClass

	// SP 补偿：1转时若等级 > 10，每超过1级补偿 3 SP
	spCompensation := 0
	if oldClass == utils.JobBeginner && oldLevel > 10 {
		spCompensation = (oldLevel - 10) * 3
	}
	character.SkillPoint = spCompensation

	// 保存到数据库
	if err := repository.UpdateCharacter(character); err != nil {
		return nil, err
	}

	return &DialogueEffect{
		NewClass: newClass,
		NewMaxHP: character.MaxHP,
		NewMaxMP: character.MaxMP,
		NewHP:    character.HP,
		NewMP:    character.MP,
		NewSP:    character.SkillPoint,
	}, nil
}
