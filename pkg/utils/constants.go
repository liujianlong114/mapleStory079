package utils

// ============================================================
// 冒险岛 079 版核心常量
// ============================================================

// ==================== 职业（进阶系统） ====================
// 层级设计：
//
//	新手: 0
//	1转: 100 / 200 / 300 / 400 / 500
//	2转: 110 / 120 等等
//	3转: 1110 / 1210 等等
//
// 保持十进制的"以 10 为进位"结构，便于通过取模判断转阶。
const (
	JobBeginner       = 0    // 冒险家新手
	JobKnightBeginner = 1000 // 骑士团初心者 ms079
	JobAranBeginner   = 2000 // 战神 ms079

	// ms079 CreateChar JobType 封包字段
	JobTypeKnight     = 0
	JobTypeAdventurer = 1
	JobTypeAran       = 2

	AccountGenderUnset = 10 // ms079 账号未设置性别

	// 1 转
	JobSwordsman = 100 // 战士（1转）
	JobWarrior   = JobSwordsman
	JobMagician  = 200 // 法师（1转）
	JobBowman    = 300 // 弓箭手（1转）
	JobThief     = 400 // 飞侠（1转）
	JobPirate    = 500 // 海盗（1转）

	// 2 转 - 战士分支
	JobFighter  = 110 // 剑客
	JobPage     = 111 // 准骑士
	JobSpearman = 120 // 枪战士

	// 2 转 - 法师分支
	JobFirePoison   = 210 // 火毒法师
	JobIceLightning = 211 // 冰雷法师
	JobCleric       = 212 // 牧师

	// 2 转 - 弓箭手分支
	JobHunter   = 310 // 猎人
	JobCrossbow = 311 // 弩弓手

	// 2 转 - 飞侠分支
	JobAssassin = 410 // 刺客
	JobBandit   = 411 // 侠客

	// 2 转 - 海盗分支
	JobBrawler    = 510 // 拳手
	JobGunslinger = 511 // 火枪手

	// 3 转 - 战士分支
	JobCrusader     = 1110 // 勇士（剑客 3 转）
	JobWhiteKnight  = 1111 // 骑士（准骑士 3 转）
	JobDragonKnight = 1210 // 龙骑（枪战士 3 转）

	// 3 转 - 法师分支
	JobFirePoisonWizard   = 2110 // 火毒巫师
	JobIceLightningWizard = 2111 // 冰雷巫师
	JobPriest             = 2112 // 祭司

	// 3 转 - 弓箭手分支
	JobRanger = 3110 // 射手
	JobSniper = 3111 // 游侠

	// 3 转 - 飞侠分支
	JobHermit      = 4110 // 无影人
	JobChiefBandit = 4111 // 独行客

	// 3 转 - 海盗分支
	JobMarauder = 5110 // 斗士
	JobOutlaw   = 5111 // 神枪手

	// 4 转 - 战士分支
	JobHero       = 1120 // 英雄
	JobPaladin    = 1220 // 圣骑士
	JobDarkKnight = 1320 // 黑骑士

	// 4 转 - 法师分支
	JobFPArchMage = 2120 // 火毒大魔导
	JobILArchMage = 2220 // 冰雷大魔导
	JobBishop     = 2320 // 主教

	// 4 转 - 弓箭手分支
	JobBowmaster = 3120 // 神射手
	JobMarksman  = 3220 // 箭神

	// 4 转 - 飞侠分支
	JobNightLord = 4120 // 隐士
	JobShadower  = 4220 // 侠盗

	// 4 转 - 海盗分支
	JobBuccaneer = 5120 // 冲锋队长
	JobCorsair   = 5220 // 船长
)

// JobAdvanceLevel 各转阶需要的等级
const (
	LevelAdvanceLevel1 = 10  // 1 转等级
	LevelAdvanceLevel2 = 30  // 2 转等级
	LevelAdvanceLevel3 = 70  // 3 转等级
	LevelAdvanceLevel4 = 120 // 4 转等级
)

// JobStats 职业升级 HP/MP 增加值（每次升级时）
// 注意：同一进阶的 HP/MP 成长基本一致，仅法师特殊
type JobLevelUpStats struct {
	HP int
	MP int
}

var JobLevelUpStatsMap = map[int]JobLevelUpStats{
	JobBeginner: {HP: 10, MP: 2},
	// 战士线（全部 +20 HP / +4 MP
	JobSwordsman:    {HP: 20, MP: 4},
	JobFighter:      {HP: 20, MP: 4},
	JobPage:         {HP: 20, MP: 4},
	JobSpearman:     {HP: 20, MP: 4},
	JobCrusader:     {HP: 20, MP: 4},
	JobWhiteKnight:  {HP: 20, MP: 4},
	JobDragonKnight: {HP: 22, MP: 4},

	// 法师线
	JobMagician:           {HP: 8, MP: 18},
	JobFirePoison:         {HP: 8, MP: 18},
	JobIceLightning:       {HP: 8, MP: 18},
	JobCleric:             {HP: 8, MP: 18},
	JobFirePoisonWizard:   {HP: 10, MP: 20},
	JobIceLightningWizard: {HP: 10, MP: 20},
	JobPriest:             {HP: 10, MP: 20},

	// 弓箭手线
	JobBowman:   {HP: 14, MP: 8},
	JobHunter:   {HP: 14, MP: 8},
	JobCrossbow: {HP: 14, MP: 8},
	JobRanger:   {HP: 14, MP: 10},
	JobSniper:   {HP: 14, MP: 10},

	// 飞侠线
	JobThief:       {HP: 12, MP: 10},
	JobAssassin:    {HP: 12, MP: 10},
	JobBandit:      {HP: 12, MP: 10},
	JobHermit:      {HP: 14, MP: 12},
	JobChiefBandit: {HP: 14, MP: 12},

	// 海盗线
	JobPirate:     {HP: 16, MP: 8},
	JobBrawler:    {HP: 16, MP: 8},
	JobGunslinger: {HP: 16, MP: 8},
	JobMarauder:   {HP: 18, MP: 10},
	JobOutlaw:     {HP: 18, MP: 10},

	JobHero:       {HP: 22, MP: 6},
	JobPaladin:    {HP: 24, MP: 6},
	JobDarkKnight: {HP: 26, MP: 6},
	JobFPArchMage: {HP: 12, MP: 24},
	JobILArchMage: {HP: 12, MP: 24},
	JobBishop:     {HP: 14, MP: 24},
	JobBowmaster:  {HP: 16, MP: 12},
	JobMarksman:   {HP: 16, MP: 12},
	JobNightLord:  {HP: 16, MP: 14},
	JobShadower:   {HP: 16, MP: 14},
	JobBuccaneer:  {HP: 20, MP: 12},
	JobCorsair:    {HP: 20, MP: 12},
}

// JobInitialStats 各职业的初始 HP/MP/STR/DEX/INT/LUK（转职时赠送的基础属性）
type JobInitialStats struct {
	HP  int
	MP  int
	STR int
	DEX int
	INT int
	LUK int
}

var JobInitialStatsMap = map[int]JobInitialStats{
	JobBeginner:  {HP: 50, MP: 50, STR: 12, DEX: 5, INT: 4, LUK: 4},
	JobSwordsman: {HP: 200, MP: 15, STR: 35, DEX: 10, INT: 4, LUK: 4},
	JobMagician:  {HP: 100, MP: 50, STR: 4, DEX: 4, INT: 35, LUK: 4},
	JobBowman:    {HP: 150, MP: 25, STR: 4, DEX: 35, INT: 4, LUK: 4},
	JobThief:     {HP: 150, MP: 25, STR: 10, DEX: 25, INT: 4, LUK: 4},
	JobPirate:    {HP: 170, MP: 25, STR: 20, DEX: 20, INT: 4, LUK: 4},
}

// JobInfo 职业信息（中文名称 / 转职等级 / 前置职业 / 1转属性要求）
type JobInfo struct {
	Name         string
	AdvanceLevel int
	PreJob       int
	MinSTR       int
	MinDEX       int
	MinINT       int
	MinLUK       int
}

var JobInfoMap = map[int]JobInfo{
	JobBeginner: {Name: "新手", AdvanceLevel: 0, PreJob: -1},

	// 1 转
	JobSwordsman: {Name: "战士", AdvanceLevel: LevelAdvanceLevel1, PreJob: JobBeginner, MinSTR: 35},
	JobMagician:  {Name: "法师", AdvanceLevel: LevelAdvanceLevel1, PreJob: JobBeginner, MinINT: 20},
	JobBowman:    {Name: "弓箭手", AdvanceLevel: LevelAdvanceLevel1, PreJob: JobBeginner, MinDEX: 25},
	JobThief:     {Name: "飞侠", AdvanceLevel: LevelAdvanceLevel1, PreJob: JobBeginner, MinDEX: 25},
	JobPirate:    {Name: "海盗", AdvanceLevel: LevelAdvanceLevel1, PreJob: JobBeginner, MinDEX: 20, MinSTR: 20},

	// 2 转 - 战士
	JobFighter:  {Name: "剑客", AdvanceLevel: LevelAdvanceLevel2, PreJob: JobSwordsman},
	JobPage:     {Name: "准骑士", AdvanceLevel: LevelAdvanceLevel2, PreJob: JobSwordsman},
	JobSpearman: {Name: "枪战士", AdvanceLevel: LevelAdvanceLevel2, PreJob: JobSwordsman},

	// 2 转 - 法师
	JobFirePoison:   {Name: "火毒法师", AdvanceLevel: LevelAdvanceLevel2, PreJob: JobMagician},
	JobIceLightning: {Name: "冰雷法师", AdvanceLevel: LevelAdvanceLevel2, PreJob: JobMagician},
	JobCleric:       {Name: "牧师", AdvanceLevel: LevelAdvanceLevel2, PreJob: JobMagician},

	// 2 转 - 弓箭手
	JobHunter:   {Name: "猎人", AdvanceLevel: LevelAdvanceLevel2, PreJob: JobBowman},
	JobCrossbow: {Name: "弩弓手", AdvanceLevel: LevelAdvanceLevel2, PreJob: JobBowman},

	// 2 转 - 飞侠
	JobAssassin: {Name: "刺客", AdvanceLevel: LevelAdvanceLevel2, PreJob: JobThief},
	JobBandit:   {Name: "侠客", AdvanceLevel: LevelAdvanceLevel2, PreJob: JobThief},

	// 2 转 - 海盗
	JobBrawler:    {Name: "拳手", AdvanceLevel: LevelAdvanceLevel2, PreJob: JobPirate},
	JobGunslinger: {Name: "火枪手", AdvanceLevel: LevelAdvanceLevel2, PreJob: JobPirate},

	// 3 转
	JobCrusader:     {Name: "勇士", AdvanceLevel: LevelAdvanceLevel3, PreJob: JobFighter},
	JobWhiteKnight:  {Name: "骑士", AdvanceLevel: LevelAdvanceLevel3, PreJob: JobPage},
	JobDragonKnight: {Name: "龙骑", AdvanceLevel: LevelAdvanceLevel3, PreJob: JobSpearman},

	JobFirePoisonWizard:   {Name: "火毒巫师", AdvanceLevel: LevelAdvanceLevel3, PreJob: JobFirePoison},
	JobIceLightningWizard: {Name: "冰雷巫师", AdvanceLevel: LevelAdvanceLevel3, PreJob: JobIceLightning},
	JobPriest:             {Name: "祭司", AdvanceLevel: LevelAdvanceLevel3, PreJob: JobCleric},

	JobRanger: {Name: "射手", AdvanceLevel: LevelAdvanceLevel3, PreJob: JobHunter},
	JobSniper: {Name: "游侠", AdvanceLevel: LevelAdvanceLevel3, PreJob: JobCrossbow},

	JobHermit:      {Name: "无影人", AdvanceLevel: LevelAdvanceLevel3, PreJob: JobAssassin},
	JobChiefBandit: {Name: "独行客", AdvanceLevel: LevelAdvanceLevel3, PreJob: JobBandit},

	JobMarauder: {Name: "斗士", AdvanceLevel: LevelAdvanceLevel3, PreJob: JobBrawler},
	JobOutlaw:   {Name: "神枪手", AdvanceLevel: LevelAdvanceLevel3, PreJob: JobGunslinger},

	// 4 转
	JobHero:       {Name: "英雄", AdvanceLevel: LevelAdvanceLevel4, PreJob: JobCrusader},
	JobPaladin:    {Name: "圣骑士", AdvanceLevel: LevelAdvanceLevel4, PreJob: JobWhiteKnight},
	JobDarkKnight: {Name: "黑骑士", AdvanceLevel: LevelAdvanceLevel4, PreJob: JobDragonKnight},
	JobFPArchMage: {Name: "火毒大魔导", AdvanceLevel: LevelAdvanceLevel4, PreJob: JobFirePoisonWizard},
	JobILArchMage: {Name: "冰雷大魔导", AdvanceLevel: LevelAdvanceLevel4, PreJob: JobIceLightningWizard},
	JobBishop:     {Name: "主教", AdvanceLevel: LevelAdvanceLevel4, PreJob: JobPriest},
	JobBowmaster:  {Name: "神射手", AdvanceLevel: LevelAdvanceLevel4, PreJob: JobRanger},
	JobMarksman:   {Name: "箭神", AdvanceLevel: LevelAdvanceLevel4, PreJob: JobSniper},
	JobNightLord:  {Name: "隐士", AdvanceLevel: LevelAdvanceLevel4, PreJob: JobHermit},
	JobShadower:   {Name: "侠盗", AdvanceLevel: LevelAdvanceLevel4, PreJob: JobChiefBandit},
	JobBuccaneer:  {Name: "冲锋队长", AdvanceLevel: LevelAdvanceLevel4, PreJob: JobMarauder},
	JobCorsair:    {Name: "船长", AdvanceLevel: LevelAdvanceLevel4, PreJob: JobOutlaw},
}

// JobNames 便于反向查询名称
var JobNames = map[int]string{
	JobBeginner:           "新手",
	JobSwordsman:          "战士",
	JobFighter:            "剑客",
	JobPage:               "准骑士",
	JobSpearman:           "枪战士",
	JobCrusader:           "勇士",
	JobWhiteKnight:        "骑士",
	JobDragonKnight:       "龙骑",
	JobMagician:           "法师",
	JobFirePoison:         "火毒法师",
	JobIceLightning:       "冰雷法师",
	JobCleric:             "牧师",
	JobFirePoisonWizard:   "火毒巫师",
	JobIceLightningWizard: "冰雷巫师",
	JobPriest:             "祭司",
	JobBowman:             "弓箭手",
	JobHunter:             "猎人",
	JobCrossbow:           "弩弓手",
	JobRanger:             "射手",
	JobSniper:             "游侠",
	JobThief:              "飞侠",
	JobAssassin:           "刺客",
	JobBandit:             "侠客",
	JobHermit:             "无影人",
	JobChiefBandit:        "独行客",
	JobPirate:             "海盗",
	JobBrawler:            "拳手",
	JobGunslinger:         "火枪手",
	JobMarauder:           "斗士",
	JobOutlaw:             "神枪手",
	JobHero:               "英雄",
	JobPaladin:            "圣骑士",
	JobDarkKnight:         "黑骑士",
	JobFPArchMage:         "火毒大魔导",
	JobILArchMage:         "冰雷大魔导",
	JobBishop:             "主教",
	JobBowmaster:          "神射手",
	JobMarksman:           "箭神",
	JobNightLord:          "隐士",
	JobShadower:           "侠盗",
	JobBuccaneer:          "冲锋队长",
	JobCorsair:            "船长",
}

// ==================== 聊天频道 ====================
const (
	ChannelWorld   = 0 // 世界频道
	ChannelGuild   = 1 // 公会频道
	ChannelParty   = 2 // 组队频道
	ChannelWhisper = 3 // 私聊频道
)

var ChannelNames = map[int]string{
	ChannelWorld:   "世界",
	ChannelGuild:   "公会",
	ChannelParty:   "组队",
	ChannelWhisper: "私聊",
}

// ==================== 物品类型常量 ====================
const (
	// 大类
	ItemTypeConsumable = 0 // 消耗品
	ItemTypeEquip      = 1 // 装备
	ItemTypeEtc        = 2 // 其他
	ItemTypeCash       = 3 // 装备 / 道具

	// 武器细分（Weapon 子类）
	ItemWeaponOneHandedSword = 10 // 单手剑
	ItemWeaponTwoHandedSword = 11 // 双手剑
	ItemWeaponOneHandedAxe   = 12 // 单手斧
	ItemWeaponTwoHandedAxe   = 13 // 双手斧
	ItemWeaponOneHandedMace  = 14 // 单手钝器
	ItemWeaponTwoHandedMace  = 15 // 双手钝器
	ItemWeaponSpear          = 16 // 枪
	ItemWeaponPoleArm        = 17 // 矛
	ItemWeaponBow            = 18 // 弓
	ItemWeaponCrossbow       = 19 // 弩
	ItemWeaponClaw           = 20 // 拳套
	ItemWeaponStaff          = 21 // 短杖
	ItemWeaponWand           = 22 // 长杖
	ItemWeaponKnuckle        = 23 // 指节
	ItemWeaponGun            = 24 // 手枪

	// 防具细分
	ItemEquipHat      = 30 // 帽子
	ItemEquipTop      = 31 // 上衣
	ItemEquipPants    = 32 // 裤子
	ItemEquipShoes    = 33 // 鞋子
	ItemEquipGloves   = 34 // 手套
	ItemEquipCape     = 35 // 披风
	ItemEquipShield   = 36 // 盾牌
	ItemEquipRing     = 37 // 戒指
	ItemEquipEarring  = 38 // 耳环
	ItemEquipNecklace = 39 // 项链
	ItemEquipBelt     = 40 // 腰带

	// 消耗品细分
	ItemConsumePotion = 50 // 药水
	ItemConsumeScroll = 51 // 卷轴
	ItemConsumeFood   = 52 // 食物
	ItemConsumeEtc    = 53 // 其他消耗

	// 其他物品
	ItemEtcGeneral     = 60 // 杂物
	ItemEtcScroll      = 61 // 卷轴 / 工艺
	ItemEtcMonsterCard = 62 // 怪物卡
	ItemEtcRecipe      = 63 // 配方
)

// ==================== 经典地图 ID ====================
// 参考经典冒险岛命名，使用与原版相近的整数 ID
const (
	// ms079 创建角色出生地图（MapleCharacter.saveNewCharToDB L876）
	// 冒险家新手出生：彩虹村（Maple Island Amherst）
	MapTutorialStart = 1000000
	MapKnightStart   = 130030000 // 骑士团
	MapAranStart     = 914000000 // 战神

	// 新手村（彩虹村）— 冒险家 returnMap
	MapMapleIsland         = 10000 // 彩虹村中心
	MapMapleIslandBeach    = 10100 // 明珠港沙滩
	MapMapleIslandTraining = 10200 // 新手训练场

	// 明珠港（坐船离开彩虹村后的港口）
	MapSouthPerry = 10300 // 明珠港（离开港口）
	MapPerryDock  = 10400 // 明珠港码头

	// 射手村
	MapHenesys               = 10500 // 射手村主镇
	MapHenesysPark           = 10501 // 射手村公园
	MapHenesysMushroomPark   = 10502 // 蘑菇公园
	MapHenesysHuntingGround1 = 10600 // 猪猪公园 I
	MapHenesysHuntingGround2 = 10700 // 猪猪公园 II

	// 魔法密林
	MapEllinia              = 10800 // 魔法密林主镇
	MapElliniaForest1       = 10900 // 幽暗森林 I
	MapElliniaForest2       = 11000 // 幽暗森林 II
	MapElliniaGolem         = 11100 // 石巨人森林
	MapElliniaGreenMushroom = 11200 // 绿蘑菇森林

	// 勇士部落
	MapPerion          = 11300 // 勇士部落主镇
	MapPerionMountain1 = 11400 // 岩石山脉 I
	MapPerionDangerous = 11500 // 危险峡谷
	MapPerionCave      = 11600 // 勇士部落洞穴

	// 废弃都市
	MapKerningCity         = 11700 // 废弃都市主镇
	MapKerningConstruction = 11800 // 建筑工地
	MapKerningSubway1      = 11900 // 地铁 1 号线

	// 冰峰雪域
	MapElNath           = 12000 // 冰峰雪域主镇
	MapElNathSnowField1 = 12100 // 雪原 I
	MapElNathIceCave    = 12200 // 冰洞穴
	MapElNathDeadForest = 12300 // 死亡森林

	// 玩具城
	MapLudibrium      = 12400 // 玩具城
	MapLudiClocktower = 12500 // 玩具塔
	MapLudiMaze       = 12600 // 玩具迷宫

	// 天空之城
	MapOrbis      = 12700 // 天空之城主镇
	MapOrbisTower = 12800 // 天空之塔
	MapOrbisPark  = 12900 // 天空花园

	// 蚂蚁洞 / 林中之城
	MapAntTunnel1     = 13000 // 蚂蚁洞广场 I
	MapAntTunnel2     = 13100 // 蚂蚁洞广场 II
	MapLithHarbor     = 13200 // 林中之城
	MapLithHarborJail = 13300 // 林中之城监狱

	// 蘑菇森林
	MapMushroomForest1 = 14000 // 蘑菇森林 I
	MapMushroomForest2 = 14100 // 蘑菇森林 II

	// 训练场
	MapTrainingGroundI  = 15000 // 训练场 I
	MapTrainingGroundII = 15100 // 训练场 II

	// 副本 / BOSS
	MapBossZakum     = 20000 // 扎昆祭坛
	MapBossPapulatus = 20100 // 皮亚努斯
	MapBossPianus    = 20200 // 皮亚纳斯（深海）
	MapBossBalrog    = 20300 // 巴洛古
)

// MapNames 地图中文名称
var MapNames = map[uint]string{
	MapMapleIsland:           "彩虹村",
	MapMapleIslandBeach:      "明珠港沙滩",
	MapMapleIslandTraining:   "新手训练场",
	MapSouthPerry:            "明珠港",
	MapPerryDock:             "明珠港码头",
	MapHenesys:               "射手村",
	MapHenesysPark:           "射手村公园",
	MapHenesysMushroomPark:   "蘑菇公园",
	MapHenesysHuntingGround1: "猪猪公园 I",
	MapHenesysHuntingGround2: "猪猪公园 II",
	MapEllinia:               "魔法密林",
	MapElliniaForest1:        "幽暗森林 I",
	MapElliniaForest2:        "幽暗森林 II",
	MapElliniaGolem:          "石巨人森林",
	MapElliniaGreenMushroom:  "绿蘑菇森林",
	MapPerion:                "勇士部落",
	MapPerionMountain1:       "岩石山脉 I",
	MapPerionDangerous:       "危险峡谷",
	MapPerionCave:            "勇士部落洞穴",
	MapKerningCity:           "废弃都市",
	MapKerningConstruction:   "建筑工地",
	MapKerningSubway1:        "地铁 1 号线",
	MapElNath:                "冰峰雪域",
	MapElNathSnowField1:      "雪原 I",
	MapElNathIceCave:         "冰洞穴",
	MapElNathDeadForest:      "死亡森林",
	MapLudibrium:             "玩具城",
	MapLudiClocktower:        "玩具塔",
	MapLudiMaze:              "玩具迷宫",
	MapOrbis:                 "天空之城",
	MapOrbisTower:            "天空之塔",
	MapOrbisPark:             "天空花园",
	MapAntTunnel1:            "蚂蚁洞广场 I",
	MapAntTunnel2:            "蚂蚁洞广场 II",
	MapLithHarbor:            "林中之城",
	MapLithHarborJail:        "林中之城监狱",
	MapMushroomForest1:       "蘑菇森林 I",
	MapMushroomForest2:       "蘑菇森林 II",
	MapTrainingGroundI:       "训练场 I",
	MapTrainingGroundII:      "训练场 II",
	MapBossZakum:             "扎昆祭坛",
	MapBossPapulatus:         "时空裂缝",
	MapBossPianus:            "深海峡谷",
	MapBossBalrog:            "巴洛古",
}

// MapTheme 地图主题（用于客户端程序化生成背景色）
var MapTheme = map[uint]string{
	MapMapleIsland:           "island",
	MapMapleIslandBeach:      "beach",
	MapMapleIslandTraining:   "training",
	MapSouthPerry:            "harbor",
	MapPerryDock:             "harbor",
	MapHenesys:               "town",
	MapHenesysPark:           "park",
	MapHenesysMushroomPark:   "park",
	MapHenesysHuntingGround1: "grass",
	MapHenesysHuntingGround2: "grass",
	MapEllinia:               "forest",
	MapElliniaForest1:        "forest",
	MapElliniaForest2:        "forest",
	MapElliniaGolem:          "forest",
	MapElliniaGreenMushroom:  "forest",
	MapPerion:                "rock",
	MapPerionMountain1:       "rock",
	MapPerionDangerous:       "rock",
	MapPerionCave:            "cave",
	MapKerningCity:           "city",
	MapKerningConstruction:   "city",
	MapKerningSubway1:        "subway",
	MapElNath:                "snow",
	MapElNathSnowField1:      "snow",
	MapElNathIceCave:         "ice",
	MapElNathDeadForest:      "forest",
	MapLudibrium:             "toy",
	MapLudiClocktower:        "toy",
	MapLudiMaze:              "toy",
	MapOrbis:                 "cloud",
	MapOrbisTower:            "cloud",
	MapOrbisPark:             "cloud",
	MapAntTunnel1:            "cave",
	MapAntTunnel2:            "cave",
	MapLithHarbor:            "town",
	MapLithHarborJail:        "cave",
	MapMushroomForest1:       "forest",
	MapMushroomForest2:       "forest",
	MapTrainingGroundI:       "training",
	MapTrainingGroundII:      "training",
	MapBossZakum:             "boss",
	MapBossPapulatus:         "boss",
	MapBossPianus:            "boss",
	MapBossBalrog:            "boss",
}

// ==================== 经典怪物 ID ====================
// 经典冒险岛怪物编号（参考 079 版）
const (
	// 新手 / 低等级怪物
	MobSnail              = 100100 // 蜗牛
	MobBlueSnail          = 100101 // 蓝蜗牛
	MobRedSnail           = 100102 // 红蜗牛
	MobMushroom           = 100200 // 蘑菇仔
	MobGreenMushroom      = 100201 // 绿蘑菇
	MobBlueMushroom       = 100202 // 蓝蘑菇
	MobYellowMushroom     = 100203 // 黄蘑菇
	MobGreenSlime         = 100300 // 绿水灵
	MobSlime              = 100301 // 蓝水灵
	MobOrangeMushroom     = 100302 // 花蘑菇
	MobPig                = 100400 // 猪
	MobOrangeMushroomBaby = 100401 // 花蘑菇仔
	MobBluePig            = 100402 // 漂漂猪
	MobOctopus            = 100700 // 章鱼
	MobLupi               = 100701 // 蓝水灵 2
	MobWildBoar           = 100800 // 野猪
	MobFireBoar           = 100801 // 火野猪
	MobColdEye            = 100802 // 冰独眼兽
	MobStoneGolem         = 110100 // 石头人
	MobDarkStoneGolem     = 110101 // 黑石头人
	MobColdEye2           = 110200 // 冰独眼兽 2
	MobBlueFireBoar       = 110300 // 蓝火野猪
	MobYellowLeprechaun   = 110400 // 黄水灵
	MobBlueStoneGolem     = 110500 // 蓝石头人
	MobHarpy              = 110600 // 火独眼兽
	MobCockroach          = 110700 // 蟑螂
	MobMushmom            = 110800 // 蘑菇王
	MobZombieMushroom     = 110900 // 僵尸蘑菇
	MobBossZakumEntrance  = 120000 // 扎昆入口
	MobBossPapulatus      = 120100 // 皮亚努斯
	MobBossPianus         = 120200 // 皮亚纳斯
	MobBossBalrog         = 120300 // 巴洛古
)

// MobNames 怪物中文名称
var MobNames = map[int]string{
	MobSnail:              "蜗牛",
	MobBlueSnail:          "蓝蜗牛",
	MobRedSnail:           "红蜗牛",
	MobMushroom:           "蘑菇仔",
	MobGreenMushroom:      "绿蘑菇",
	MobBlueMushroom:       "蓝蘑菇",
	MobYellowMushroom:     "黄蘑菇",
	MobGreenSlime:         "绿水灵",
	MobSlime:              "蓝水灵",
	MobOrangeMushroom:     "花蘑菇",
	MobPig:                "猪",
	MobOrangeMushroomBaby: "花蘑菇仔",
	MobBluePig:            "漂漂猪",
	MobOctopus:            "章鱼",
	MobLupi:               "蓝水灵 II",
	MobWildBoar:           "野猪",
	MobFireBoar:           "火野猪",
	MobColdEye:            "冰独眼兽",
	MobStoneGolem:         "石头人",
	MobDarkStoneGolem:     "黑石头人",
	MobColdEye2:           "冰独眼兽 II",
	MobBlueFireBoar:       "蓝火野猪",
	MobYellowLeprechaun:   "黄水灵",
	MobBlueStoneGolem:     "蓝石头人",
	MobHarpy:              "火独眼兽",
	MobCockroach:          "蟑螂",
	MobMushmom:            "蘑菇王",
	MobZombieMushroom:     "僵尸蘑菇",
	MobBossZakumEntrance:  "扎昆",
	MobBossPapulatus:      "皮亚努斯",
	MobBossPianus:         "皮亚纳斯",
	MobBossBalrog:         "巴洛古",
}

// ==================== 游戏数值阈值 ====================
const (
	MaxLevel          = 200       // 最高等级（与官服 079 保持一致）
	MaxCharacterSlots = 6         // 每账号最多创建角色
	MaxInventorySize  = 96        // 每栏物品槽（消耗/装备/其他/设置）
	MaxMesos          = 999999999 // 金币上限（9.99亿）
	MaxHP             = 99999     // 单次战斗最大 HP
	MaxMP             = 99999     // 单次战斗最大 MP
	DefaultStartHP    = 50        // 新手初始 HP
	DefaultStartMP    = 5         // 新手初始 MP
	DefaultStartSTR   = 12        // 初始力量
	DefaultStartDEX   = 5         // 初始敏捷
	DefaultStartINT   = 4         // 初始智力
	DefaultStartLUK   = 4         // 初始幸运
	DefaultLevelUpAP  = 5         // 每级升级获得属性点
	DefaultLevelUpSP  = 3         // 每级升级获得技能点（1转后）
)

// ==================== 倍率常量 ====================
const (
	DefaultExpRate       = 1.0 // 经验倍率
	DefaultMesosRate     = 1.0 // 金币倍率
	DefaultDropRate      = 1.0 // 掉落倍率
	DefaultStatPointRate = 1   // 属性点倍率
)

// ==================== 聊天内容限制 ====================
const (
	ChatMessageMaxLength = 256 // 单条聊天消息最大长度
)

// SensitiveWords 默认敏感词列表
var SensitiveWords = []string{
	"外挂", "作弊", "脚本",
	"垃圾", "废物", "傻逼", "笨蛋",
	"充值", "赌博", "色情",
}

// ==================== WebSocket 消息类型常量 ====================
const (
	WSMessageTypeChat     = "chat"     // 聊天消息
	WSMessageTypePosition = "position" // 坐标同步
	WSMessageTypeMove     = "move"     // 玩家移动请求
	WSMessageTypeAttack   = "attack"   // 玩家攻击
	WSMessageTypeDamage   = "damage"   // 伤害飘字广播
	WSMessageTypeExp      = "exp"      // 经验获取
	WSMessageTypeLoot     = "loot"     // 拾取
	WSMessageTypeDead     = "dead"     // 玩家/怪物死亡
	WSMessageTypeRevive   = "revive"   // 复活
	WSMessageTypeMobSpawn   = "mob_spawn"   // 怪物刷出/快照
	WSMessageTypeMobMove    = "mob_move"    // 怪物位置同步
	WSMessageTypeMobDead    = "mob_dead"    // 怪物死亡
	WSMessageTypeMobRespawn = "mob_respawn" // 怪物重生
	WSMessageTypeSystem   = "system"   // 系统公告
	WSMessageTypePing     = "ping"     // 心跳
	WSMessageTypePong     = "pong"     // 心跳响应
)

var WSMessageTypes = map[string]bool{
	WSMessageTypeChat:     true,
	WSMessageTypePosition: true,
	WSMessageTypeMove:     true,
	WSMessageTypeAttack:   true,
	WSMessageTypeDamage:   true,
	WSMessageTypeExp:      true,
	WSMessageTypeLoot:     true,
	WSMessageTypeDead:     true,
	WSMessageTypeRevive:   true,
	WSMessageTypeMobSpawn:   true,
	WSMessageTypeMobMove:    true,
	WSMessageTypeMobDead:    true,
	WSMessageTypeMobRespawn: true,
	WSMessageTypeSystem:   true,
	WSMessageTypePing:     true,
	WSMessageTypePong:     true,
}

// ==================== 攻击 / 伤害常量 ====================
const (
	DamageBaseFactor      = 0.8  // 伤害基础浮动下限
	DamageCeilingFactor   = 1.2  // 伤害基础浮动上限
	CritMultiplierDefault = 1.5  // 默认暴击倍率
	CritMultiplierThief   = 2.0  // 飞侠暴击倍率
	HitRateMinThreshold   = 0.15 // 最低命中率 15%
	DodgeRateThreshold    = 0.75 // 最高闪避率 75%
	MesosDropBase         = 5    // 基础金币掉落
)

// ==================== 经验等级公式相关 ====================
const ExpBaseFormula = "10 + level^2 * 8"

// ==================== 系统公告等级 ====================
const (
	SystemLevelInfo    = "info"    // 普通系统消息
	SystemLevelSuccess = "success" // 成功 / 升级
	SystemLevelWarning = "warning" // 警告 / 频道消息
	SystemLevelError   = "error"   // 错误 / 被踢
	SystemLevelBoss    = "boss"    // BOSS 相关（大字体）
)
