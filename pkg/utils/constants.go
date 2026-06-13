package utils

// ==================== 职业常量 ====================
// 对应 Character.Class / Skill.JobClass 字段
const (
	JobBeginner = 0 // 新手
	JobWarrior  = 1 // 战士
	JobMagician = 2 // 法师
	JobBowman   = 3 // 弓箭手
	JobThief    = 4 // 飞侠
	JobPirate   = 5 // 海盗
)

// JobNames 职业中文名称映射
var JobNames = map[int]string{
	JobBeginner: "新手",
	JobWarrior:  "战士",
	JobMagician: "法师",
	JobBowman:   "弓箭手",
	JobThief:    "飞侠",
	JobPirate:   "海盗",
}

// ==================== 聊天频道常量 ====================
// 对应 ChatLog.Channel 字段
const (
	ChannelWorld   = 0 // 世界频道
	ChannelGuild   = 1 // 公会频道
	ChannelParty   = 2 // 组队频道
	ChannelWhisper = 3 // 私聊频道
)

// ChannelNames 频道中文名称映射
var ChannelNames = map[int]string{
	ChannelWorld:   "世界",
	ChannelGuild:   "公会",
	ChannelParty:   "组队",
	ChannelWhisper: "私聊",
}

// ==================== 地图ID常量 ====================
// 与 init_data.go 中默认插入的地图保持一致
const (
	MapSouthHenesys    = 1 // 南港
	MapTrainingGroundI = 2 // 训练场I
	MapMushroomForest  = 3 // 蘑菇林
)

// MapNames 地图中文名称映射
var MapNames = map[uint]string{
	MapSouthHenesys:    "南港",
	MapTrainingGroundI: "训练场I",
	MapMushroomForest:  "蘑菇林",
}

// ==================== 倍率常量 ====================
// 默认经验/金币获取倍率（可在配置中覆盖）
const (
	DefaultExpRate       = 1.0 // 经验倍率
	DefaultMesosRate     = 1.0 // 金币倍率
	DefaultDropRate      = 1.0 // 掉落倍率
	DefaultStatPointRate = 1   // 属性点倍率
)

// ==================== 聊天内容限制 ====================
const (
	ChatMessageMaxLength = 256 // 单条聊天消息最大长度（与数据库 ChatLog.message 长度一致）
)

// SensitiveWords 默认敏感词列表（可在运行时扩展）
var SensitiveWords = []string{
	"外挂", "作弊", "外挂", "脚本",
	"垃圾", "废物", "傻逼", "笨蛋",
	"充值", "赌博", "色情",
}
