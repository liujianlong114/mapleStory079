package model

import "mapleStory079/pkg/database"

// 本文件将 internal/model 下的类型统一映射到 pkg/database 中的核心数据模型。
// 这样可以消除重复定义，让 service / handler / repository 层通过 model.X 引用，
// 实现与 database 包的解耦。

type (
	Account            = database.Account
	Character          = database.Character
	CharacterStats     = database.CharacterStats
	CharacterInventory = database.CharacterInventory
	Item               = database.Item
	Skill              = database.Skill
	Quest              = database.Quest
	CharacterQuest     = database.CharacterQuest
	Map                = database.Map
	GameMap            = database.Map
	NPC                = database.NPC
	Mob                = database.Mob
	Guild              = database.Guild
	Party              = database.Party
	Friend             = database.Friend
	LoginLog           = database.LoginLog
	TradeLog           = database.TradeLog
	ChatLog            = database.ChatLog
	MobDrop            = database.MobDrop

	// 兼容旧代码：允许在 service / scripts 中引用的别名
	CharacterItem  = database.CharacterInventory
	CharacterSkill = database.Skill
)
