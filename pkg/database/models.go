package database

import (
	"time"

	"github.com/jinzhu/gorm"
)

// ====================== 账号相关 ======================

// Account 账号表
type Account struct {
	ID        uint      `gorm:"primary_key" json:"id"`
	Username  string    `gorm:"size:32;unique_index;not null" json:"username"`
	Password  string    `gorm:"size:128;not null" json:"-"`
	Email     string    `gorm:"size:64" json:"email"`
	Gender    int       `gorm:"default:10" json:"gender"` // 10=未设置 0=男 1=女（ms079 accounts.gender）
	Status    int       `gorm:"default:1" json:"status"` // 1=正常 0=禁用
	LastLogin time.Time `json:"last_login"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// Character 角色表
type Character struct {
	ID           uint      `gorm:"primary_key" json:"id"`
	AccountID    uint      `gorm:"index;not null" json:"account_id"`
	Name         string    `gorm:"size:12;unique_index;not null" json:"name"`
	Class        int       `gorm:"not null;default:0" json:"class"` // 0=新手 1=战士 2=法师 3=弓箭手 4=飞侠 5=海盗
	Gender       int       `gorm:"not null;default:0" json:"gender"`
	Face         int       `gorm:"not null;default:20100" json:"face"`
	Hair         int       `gorm:"not null;default:30000" json:"hair"`
	Skin         int       `gorm:"not null;default:0" json:"skin"`
	Level        int       `gorm:"not null;default:1" json:"level"`
	Exp          int       `gorm:"not null;default:0" json:"exp"`
	HP           int       `gorm:"not null;default:50" json:"hp"`
	MaxHP        int       `gorm:"not null;default:50" json:"max_hp"`
	MP           int       `gorm:"not null;default:50" json:"mp"`
	MaxMP        int       `gorm:"not null;default:50" json:"max_mp"`
	STR          int       `gorm:"not null;default:12" json:"str"`
	DEX          int       `gorm:"not null;default:5" json:"dex"`
	INT          int       `gorm:"not null;default:4" json:"int"`
	LUK          int       `gorm:"not null;default:4" json:"luk"`
	AbilityPoint int       `gorm:"not null;default:0" json:"ability_point"`
	SkillPoint   int       `gorm:"not null;default:0" json:"skill_point"`
	Mesos        int       `gorm:"not null;default:0" json:"mesos"`
	MapID        uint      `gorm:"not null;default:1" json:"map_id"`
	PositionX    int       `gorm:"default:0" json:"position_x"`
	PositionY    int       `gorm:"default:0" json:"position_y"`
	Fame         int       `gorm:"default:0" json:"fame"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// CharacterStats 角色扩展属性表
type CharacterStats struct {
	ID              uint      `gorm:"primary_key" json:"id"`
	CharacterID     uint      `gorm:"index;not null" json:"character_id"`
	PhysicalAttack  int       `gorm:"default:10" json:"physical_attack"`
	MagicAttack     int       `gorm:"default:10" json:"magic_attack"`
	PhysicalDefense int       `gorm:"default:10" json:"physical_defense"`
	MagicDefense    int       `gorm:"default:10" json:"magic_defense"`
	Accuracy        int       `gorm:"default:10" json:"accuracy"`
	Avoidability    int       `gorm:"default:10" json:"avoidability"`
	Speed           int       `gorm:"default:100" json:"speed"`
	Jump            int       `gorm:"default:100" json:"jump"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

// CharacterInventory 角色背包表
type CharacterInventory struct {
	ID          uint      `gorm:"primary_key" json:"id"`
	CharacterID uint      `gorm:"index;not null" json:"character_id"`
	ItemID      int       `gorm:"not null" json:"item_id"`
	SlotIndex   int       `gorm:"not null;default:0" json:"slot_index"`
	Quantity    int       `gorm:"not null;default:1" json:"quantity"`
	IsEquipped  bool      `gorm:"default:false" json:"is_equipped"`
	EquipSlot   string    `gorm:"size:16" json:"equip_slot"`
	Stats       string    `gorm:"type:text" json:"stats"` // JSON 存储
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// ====================== 游戏数据 ======================

// Item 物品表
type Item struct {
	ID          uint      `gorm:"primary_key" json:"id"`
	Name        string    `gorm:"size:64;not null" json:"name"`
	ItemType    int       `gorm:"not null;default:0" json:"item_type"` // 0=消耗 1=装备 2=其他
	Description string    `gorm:"type:text" json:"description"`
	Price       int       `gorm:"default:0" json:"price"`
	LevelReq    int       `gorm:"default:1" json:"level_req"`
	STR         int       `gorm:"default:0" json:"str"`
	DEX         int       `gorm:"default:0" json:"dex"`
	INT         int       `gorm:"default:0" json:"int"`
	LUK         int       `gorm:"default:0" json:"luk"`
	HPRecovery  int       `gorm:"default:0" json:"hp_recovery"`
	MPRecovery  int       `gorm:"default:0" json:"mp_recovery"`
	Stackable   bool      `gorm:"default:true" json:"stackable"`
	Image       string    `gorm:"size:128" json:"image"`
	CreatedAt   time.Time `json:"created_at"`
}

// Skill 技能表
type Skill struct {
	ID          uint      `gorm:"primary_key" json:"id"`
	Name        string    `gorm:"size:64;not null" json:"name"`
	JobClass    int       `gorm:"not null;default:0" json:"job_class"`
	LevelReq    int       `gorm:"default:1" json:"level_req"`
	MaxLevel    int       `gorm:"default:10" json:"max_level"`
	MPCost      int       `gorm:"default:0" json:"mp_cost"`
	DamageRatio float64   `gorm:"default:1.0" json:"damage_ratio"`
	Description string    `gorm:"type:text" json:"description"`
	IsPassive   bool      `gorm:"default:false" json:"is_passive"`
	CoolDownMs  int       `gorm:"default:0" json:"cool_down_ms"`
	CreatedAt   time.Time `json:"created_at"`
}

// Quest 任务表
type Quest struct {
	ID          uint      `gorm:"primary_key" json:"id"`
	Name        string    `gorm:"size:128;not null" json:"name"`
	Description string    `gorm:"type:text" json:"description"`
	NPCID       uint      `gorm:"default:0" json:"npc_id"`
	LevelReq    int       `gorm:"default:1" json:"level_req"`
	ExpReward   int       `gorm:"default:0" json:"exp_reward"`
	MesosReward int       `gorm:"default:0" json:"mesos_reward"`
	ItemRewards string    `gorm:"type:text" json:"item_rewards"`
	CreatedAt   time.Time `json:"created_at"`
}

// CharacterQuest 角色任务进度（status: 0=未接 1=进行中 2=已完成）
type CharacterQuest struct {
	ID          uint      `gorm:"primary_key" json:"id"`
	CharacterID uint      `gorm:"index;not null" json:"character_id"`
	QuestID     uint      `gorm:"index;not null" json:"quest_id"`
	Status      int       `gorm:"not null;default:0" json:"status"`
	Progress    int       `gorm:"not null;default:0" json:"progress"`
	AcceptedAt  time.Time `json:"accepted_at"`
	CompletedAt time.Time `json:"completed_at"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// Map 地图表
type Map struct {
	ID          uint      `gorm:"primary_key" json:"id"`
	Name        string    `gorm:"size:64;not null" json:"name"`
	Description string    `gorm:"type:text" json:"description"`
	Width       int       `gorm:"default:1600" json:"width"`
	Height      int       `gorm:"default:900" json:"height"`
	MonsterPool string    `gorm:"type:text" json:"monster_pool"`
	Background  string    `gorm:"size:128" json:"background"`
	Music       string    `gorm:"size:128" json:"music"`
	CreatedAt   time.Time `json:"created_at"`
}

// NPC NPC 表
type NPC struct {
	ID          uint      `gorm:"primary_key" json:"id"`
	Name        string    `gorm:"size:32;not null" json:"name"`
	Description string    `gorm:"type:text" json:"description"`
	MapID       uint      `gorm:"not null" json:"map_id"`
	PositionX   int       `gorm:"default:0" json:"position_x"`
	PositionY   int       `gorm:"default:0" json:"position_y"`
	Scripts     string    `gorm:"type:text" json:"scripts"` // JSON: [{id, text, next}]
	HasShop     bool      `gorm:"default:false" json:"has_shop"`
	Image       string    `gorm:"size:128" json:"image"`
	CreatedAt   time.Time `json:"created_at"`
}

// Mob 怪物表
type Mob struct {
	ID              uint      `gorm:"primary_key" json:"id"`
	Name            string    `gorm:"size:32;not null" json:"name"`
	Level           int       `gorm:"default:1" json:"level"`
	HP              int       `gorm:"default:10" json:"hp"`
	MaxHP           int       `gorm:"default:10" json:"max_hp"`
	MP              int       `gorm:"default:0" json:"mp"`
	PhysicalAttack  int       `gorm:"default:5" json:"physical_attack"`
	MagicAttack     int       `gorm:"default:5" json:"magic_attack"`
	PhysicalDefense int       `gorm:"default:5" json:"physical_defense"`
	MagicDefense    int       `gorm:"default:5" json:"magic_defense"`
	ExpReward       int       `gorm:"default:0" json:"exp_reward"`
	MesosReward     int       `gorm:"default:0" json:"mesos_reward"`
	Speed           int       `gorm:"default:60" json:"speed"`
	Image           string    `gorm:"size:128" json:"image"`
	CreatedAt       time.Time `json:"created_at"`
}

// MobDrop 怪物掉落表（mob_id + item_id + 概率）
type MobDrop struct {
	ID        uint      `gorm:"primary_key" json:"id"`
	MobID     uint      `gorm:"index;not null" json:"mob_id"`
	ItemID    int       `gorm:"not null" json:"item_id"`
	Chance    float64   `gorm:"default:0.1" json:"chance"` // 0~1
	MinQty    int       `gorm:"default:1" json:"min_qty"`
	MaxQty    int       `gorm:"default:1" json:"max_qty"`
	QuestOnly bool      `gorm:"default:false" json:"quest_only"`
	CreatedAt time.Time `json:"created_at"`
}

// ====================== 社交系统 ======================

// Guild 公会表
type Guild struct {
	ID        uint      `gorm:"primary_key" json:"id"`
	Name      string    `gorm:"size:16;unique_index;not null" json:"name"`
	MasterID  uint      `gorm:"not null" json:"master_id"`
	Members   int       `gorm:"default:1" json:"members"`
	Level     int       `gorm:"default:1" json:"level"`
	Point     int       `gorm:"default:0" json:"point"`
	Notice    string    `gorm:"size:256" json:"notice"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// Party 组队表
type Party struct {
	ID        uint      `gorm:"primary_key" json:"id"`
	LeaderID  uint      `gorm:"not null;unique_index" json:"leader_id"`
	Members   int       `gorm:"default:1" json:"members"`
	MapID     uint      `gorm:"default:0" json:"map_id"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// Friend 好友表
type Friend struct {
	ID          uint      `gorm:"primary_key" json:"id"`
	CharacterID uint      `gorm:"index;not null" json:"character_id"`
	FriendID    uint      `gorm:"index;not null" json:"friend_id"`
	Group       string    `gorm:"size:16;default:''" json:"group"`
	CreatedAt   time.Time `json:"created_at"`
}

// ====================== 日志系统 ======================

// LoginLog 登录日志
type LoginLog struct {
	ID        uint      `gorm:"primary_key" json:"id"`
	AccountID uint      `gorm:"index" json:"account_id"`
	IP        string    `gorm:"size:45" json:"ip"`
	UserAgent string    `gorm:"size:256" json:"user_agent"`
	Status    int       `gorm:"default:1" json:"status"` // 1=成功 0=失败
	CreatedAt time.Time `json:"created_at"`
}

// TradeLog 交易日志
type TradeLog struct {
	ID         uint      `gorm:"primary_key" json:"id"`
	SenderID   uint      `gorm:"index" json:"sender_id"`
	ReceiverID uint      `gorm:"index" json:"receiver_id"`
	ItemID     int       `json:"item_id"`
	Quantity   int       `json:"quantity"`
	Mesos      int       `json:"mesos"`
	CreatedAt  time.Time `json:"created_at"`
}

// ChatLog 聊天日志
type ChatLog struct {
	ID          uint      `gorm:"primary_key" json:"id"`
	CharacterID uint      `gorm:"index" json:"character_id"`
	ReceiverID  uint      `gorm:"index" json:"receiver_id"`
	Channel     int       `gorm:"default:0" json:"channel"`
	Message     string    `gorm:"size:256;not null" json:"message"`
	CreatedAt   time.Time `json:"created_at"`
}

// ====================== 辅助方法 ======================

// BeforeCreate GORM 钩子：创建前自动设置创建/更新时间
func (a *Account) BeforeCreate(scope *gorm.Scope) error {
	now := time.Now()
	scope.SetColumn("CreatedAt", now)
	scope.SetColumn("UpdatedAt", now)
	return nil
}

// BeforeUpdate 更新前更新时间
func (a *Account) BeforeUpdate(scope *gorm.Scope) error {
	return scope.SetColumn("UpdatedAt", time.Now())
}

// ClassName 根据职业编号返回中文名称
func (c *Character) ClassName() string {
	names := map[int]string{
		0: "新手",
		1: "战士",
		2: "法师",
		3: "弓箭手",
		4: "飞侠",
		5: "海盗",
	}
	if name, ok := names[c.Class]; ok {
		return name
	}
	return "未知"
}

// RequiredExp 计算升级所需经验
func (c *Character) RequiredExp() int {
	if c.Level < 1 {
		return 10
	}
	// 经典冒险岛式曲线
	return 10 + c.Level*c.Level*8
}

// ExpProgress 计算当前经验百分比
func (c *Character) ExpProgress() float64 {
	req := c.RequiredExp()
	if req <= 0 {
		return 0.0
	}
	progress := float64(c.Exp) / float64(req)
	if progress > 1.0 {
		progress = 1.0
	}
	if progress < 0 {
		progress = 0.0
	}
	return progress
}

// HPPercent HP 百分比
func (c *Character) HPPercent() float64 {
	if c.MaxHP <= 0 {
		return 0.0
	}
	return float64(c.HP) / float64(c.MaxHP) * 100.0
}

// MPPercent MP 百分比
func (c *Character) MPPercent() float64 {
	if c.MaxMP <= 0 {
		return 0.0
	}
	return float64(c.MP) / float64(c.MaxMP) * 100.0
}
