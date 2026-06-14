package database

// 本文件提供 MapleStory 079 版本的默认游戏数据初始化。
// 在服务器启动时会调用 SeedDefaultData()，用 FirstOrCreate 的方式
// 检查并填充地图/NPC/怪物/物品/技能/任务等默认数据。
// 即使数据已存在，也不会报错，因此可以安全地在每次启动时调用。

import (
	"fmt"
	"log"
	"time"
)

// ====================== 种子数据统计 ======================

type SeedReport struct {
	MapCount       int
	NpcCount       int
	MobCount       int
	ItemCount      int
	SkillCount     int
	QuestCount     int
	DropCount      int
	AccountCount   int
	CharacterCount int
	IsFirstTime    bool // 是否为首次初始化
}

// ====================== 总入口 ======================

// SeedDefaultData 服务器启动时调用的默认数据初始化总入口。
// 安全特性：所有插入都使用 FirstOrCreate，已存在的数据不会被覆盖，也不会报错。
func SeedDefaultData() (*SeedReport, error) {
	if DB == nil {
		return nil, fmt.Errorf("database not initialized, call Init() first")
	}
	report := &SeedReport{}

	log.Println("==============================================")
	log.Println("[Seed] 检查并填充 MapleStory 079 默认数据...")

	// 1. 判断是否首次初始化（通过检查地图表是否为空）
	var mapCount int
	if err := DB.Model(&Map{}).Count(&mapCount).Error; err != nil {
		log.Printf("[Seed] Warning: 无法查询地图表: %v", err)
	}
	report.IsFirstTime = mapCount == 0
	if report.IsFirstTime {
		log.Println("[Seed] 检测到数据库为空，开始首次填充默认数据（079版本）...")
	} else {
		log.Println("[Seed] 数据库已有数据，继续检查是否有缺失项...")
	}

	// 2. 分模块插入
	report.MapCount = seedMaps()
	report.NpcCount = seedNpcs()
	report.MobCount = seedMobs()
	report.ItemCount = seedItems()
	report.SkillCount = seedSkills()
	report.QuestCount = seedQuests()
	report.DropCount = seedDrops()
	report.AccountCount, report.CharacterCount = seedDemoAccounts()

	log.Printf("[Seed] 完成！地图:%d 个, NPC:%d 个, 怪物:%d 种, 物品:%d 个, 技能:%d 个, 任务:%d 个, 掉落:%d 条, 演示账号:%d, 演示角色:%d",
		report.MapCount, report.NpcCount, report.MobCount, report.ItemCount, report.SkillCount, report.QuestCount, report.DropCount,
		report.AccountCount, report.CharacterCount)
	log.Println("==============================================")
	return report, nil
}

// ====================== 地图数据（40+ 张经典地图） ======================

func seedMaps() int {
	return firstOrCreateMaps(default079Maps())
}

func firstOrCreateMaps(maps []Map) int {
	for i := range maps {
		if err := DB.FirstOrCreate(&maps[i], Map{ID: maps[i].ID}).Error; err != nil {
			log.Printf("[Seed] 地图插入失败 id=%d: %v", maps[i].ID, err)
		}
	}
	log.Printf("[Seed] 地图数据初始化完成（共 %d 张）", len(maps))
	return len(maps)
}

// ====================== NPC 数据（30+ 个经典NPC） ======================

func seedNpcs() int {
	npcs := default079NPCs()
	for i := range npcs {
		var existing NPC
		err := DB.Where("id = ?", npcs[i].ID).First(&existing).Error
		if err == nil {
			_ = DB.Model(&existing).Updates(map[string]interface{}{
				"name":        npcs[i].Name,
				"description": npcs[i].Description,
				"map_id":      npcs[i].MapID,
				"position_x":  npcs[i].PositionX,
				"position_y":  npcs[i].PositionY,
				"has_shop":    npcs[i].HasShop,
			}).Error
		} else {
			if err := DB.FirstOrCreate(&npcs[i], NPC{ID: npcs[i].ID}).Error; err != nil {
				log.Printf("[Seed] NPC插入失败 id=%d: %v", npcs[i].ID, err)
			}
		}
	}
	// 移除误放在彩虹村(1000000)上的非本图 NPC
	_ = DB.Where("map_id = ? AND id IN ?", 1000000, []uint{12000, 1012112, 1012114}).Delete(&NPC{}).Error
	log.Printf("[Seed] NPC 数据初始化完成（共 %d 个）", len(npcs))
	return len(npcs)
}

// ====================== 怪物数据（30+ 种经典怪物） ======================

func seedMobs() int {
	mobs := []Mob{
		// 新手 / 低级怪物（Lv 1-10）
		{ID: 100100, Name: "蜗牛", Level: 1, HP: 15, MaxHP: 15, PhysicalAttack: 8, PhysicalDefense: 0, MagicAttack: 5, MagicDefense: 0, Speed: 100, ExpReward: 3, MesosReward: 3, CreatedAt: time.Now()},
		{ID: 100101, Name: "蓝蜗牛", Level: 3, HP: 35, MaxHP: 35, PhysicalAttack: 12, PhysicalDefense: 2, MagicAttack: 8, MagicDefense: 1, Speed: 100, ExpReward: 8, MesosReward: 7, CreatedAt: time.Now()},
		{ID: 100102, Name: "红蜗牛", Level: 4, HP: 50, MaxHP: 50, PhysicalAttack: 15, PhysicalDefense: 3, MagicAttack: 10, MagicDefense: 1, Speed: 100, ExpReward: 10, MesosReward: 10, CreatedAt: time.Now()},
		{ID: 100200, Name: "蘑菇仔", Level: 5, HP: 60, MaxHP: 60, PhysicalAttack: 18, PhysicalDefense: 4, MagicAttack: 12, MagicDefense: 2, Speed: 100, ExpReward: 12, MesosReward: 10, CreatedAt: time.Now()},
		{ID: 100201, Name: "绿蘑菇", Level: 7, HP: 85, MaxHP: 85, PhysicalAttack: 22, PhysicalDefense: 6, MagicAttack: 15, MagicDefense: 3, Speed: 100, ExpReward: 18, MesosReward: 14, CreatedAt: time.Now()},
		{ID: 100202, Name: "蓝蘑菇", Level: 9, HP: 120, MaxHP: 120, PhysicalAttack: 28, PhysicalDefense: 8, MagicAttack: 18, MagicDefense: 4, Speed: 100, ExpReward: 24, MesosReward: 18, CreatedAt: time.Now()},
		{ID: 100203, Name: "花蘑菇", Level: 10, HP: 150, MaxHP: 150, PhysicalAttack: 32, PhysicalDefense: 10, MagicAttack: 22, MagicDefense: 5, Speed: 100, ExpReward: 28, MesosReward: 20, CreatedAt: time.Now()},
		{ID: 100300, Name: "绿水灵", Level: 8, HP: 100, MaxHP: 100, PhysicalAttack: 25, PhysicalDefense: 5, MagicAttack: 20, MagicDefense: 5, Speed: 100, ExpReward: 20, MesosReward: 15, CreatedAt: time.Now()},

		// 中级怪物（Lv 10-30）
		{ID: 100301, Name: "蓝水灵", Level: 12, HP: 200, MaxHP: 200, PhysicalAttack: 40, PhysicalDefense: 10, MagicAttack: 30, MagicDefense: 8, Speed: 100, ExpReward: 38, MesosReward: 28, CreatedAt: time.Now()},
		{ID: 100400, Name: "猪猪", Level: 10, HP: 180, MaxHP: 180, PhysicalAttack: 35, PhysicalDefense: 10, MagicAttack: 20, MagicDefense: 5, Speed: 100, ExpReward: 30, MesosReward: 25, CreatedAt: time.Now()},
		{ID: 100401, Name: "火野猪", Level: 15, HP: 350, MaxHP: 350, PhysicalAttack: 55, PhysicalDefense: 18, MagicAttack: 35, MagicDefense: 10, Speed: 100, ExpReward: 55, MesosReward: 40, CreatedAt: time.Now()},
		{ID: 100500, Name: "小白雪鬼", Level: 18, HP: 500, MaxHP: 500, PhysicalAttack: 65, PhysicalDefense: 22, MagicAttack: 45, MagicDefense: 15, Speed: 100, ExpReward: 75, MesosReward: 55, CreatedAt: time.Now()},
		{ID: 100600, Name: "章鱼", Level: 14, HP: 280, MaxHP: 280, PhysicalAttack: 50, PhysicalDefense: 12, MagicAttack: 30, MagicDefense: 8, Speed: 100, ExpReward: 48, MesosReward: 35, CreatedAt: time.Now()},
		{ID: 100700, Name: "野猪", Level: 18, HP: 500, MaxHP: 500, PhysicalAttack: 65, PhysicalDefense: 20, MagicAttack: 40, MagicDefense: 12, Speed: 100, ExpReward: 70, MesosReward: 50, CreatedAt: time.Now()},
		{ID: 100800, Name: "僵尸蘑菇", Level: 20, HP: 700, MaxHP: 700, PhysicalAttack: 75, PhysicalDefense: 25, MagicAttack: 55, MagicDefense: 18, Speed: 100, ExpReward: 90, MesosReward: 65, CreatedAt: time.Now()},
		{ID: 100801, Name: "刺蘑菇", Level: 22, HP: 900, MaxHP: 900, PhysicalAttack: 85, PhysicalDefense: 30, MagicAttack: 65, MagicDefense: 20, Speed: 100, ExpReward: 110, MesosReward: 80, CreatedAt: time.Now()},
		{ID: 100900, Name: "石头人", Level: 25, HP: 1500, MaxHP: 1500, PhysicalAttack: 100, PhysicalDefense: 40, MagicAttack: 70, MagicDefense: 25, Speed: 80, ExpReward: 150, MesosReward: 100, CreatedAt: time.Now()},

		// 高级怪物（Lv 30-70）
		{ID: 101000, Name: "冰独眼兽", Level: 30, HP: 2500, MaxHP: 2500, PhysicalAttack: 130, PhysicalDefense: 50, MagicAttack: 100, MagicDefense: 35, Speed: 100, ExpReward: 220, MesosReward: 150, CreatedAt: time.Now()},
		{ID: 101100, Name: "黑鳄鱼", Level: 28, HP: 2000, MaxHP: 2000, PhysicalAttack: 120, PhysicalDefense: 45, MagicAttack: 85, MagicDefense: 30, Speed: 100, ExpReward: 180, MesosReward: 130, CreatedAt: time.Now()},
		{ID: 101200, Name: "小企鹅王", Level: 35, HP: 3500, MaxHP: 3500, PhysicalAttack: 160, PhysicalDefense: 60, MagicAttack: 130, MagicDefense: 45, Speed: 110, ExpReward: 280, MesosReward: 180, CreatedAt: time.Now()},
		{ID: 101300, Name: "月亮蜗牛", Level: 40, HP: 5000, MaxHP: 5000, PhysicalAttack: 200, PhysicalDefense: 75, MagicAttack: 160, MagicDefense: 55, Speed: 100, ExpReward: 380, MesosReward: 250, CreatedAt: time.Now()},
		{ID: 101400, Name: "月光精灵", Level: 45, HP: 6500, MaxHP: 6500, PhysicalAttack: 240, PhysicalDefense: 85, MagicAttack: 200, MagicDefense: 70, Speed: 120, ExpReward: 480, MesosReward: 320, CreatedAt: time.Now()},
		{ID: 101500, Name: "幼狮", Level: 50, HP: 8000, MaxHP: 8000, PhysicalAttack: 280, PhysicalDefense: 100, MagicAttack: 230, MagicDefense: 85, Speed: 120, ExpReward: 600, MesosReward: 400, CreatedAt: time.Now()},
		{ID: 101600, Name: "大立钟", Level: 55, HP: 10000, MaxHP: 10000, PhysicalAttack: 330, PhysicalDefense: 120, MagicAttack: 280, MagicDefense: 100, Speed: 90, ExpReward: 750, MesosReward: 500, CreatedAt: time.Now()},
		{ID: 101700, Name: "战甲吹泡泡鱼", Level: 60, HP: 13000, MaxHP: 13000, PhysicalAttack: 380, PhysicalDefense: 140, MagicAttack: 330, MagicDefense: 120, Speed: 100, ExpReward: 900, MesosReward: 600, CreatedAt: time.Now()},
		{ID: 101800, Name: "骷髅士兵", Level: 65, HP: 16000, MaxHP: 16000, PhysicalAttack: 440, PhysicalDefense: 160, MagicAttack: 380, MagicDefense: 140, Speed: 100, ExpReward: 1100, MesosReward: 750, CreatedAt: time.Now()},
		{ID: 101900, Name: "僵尸", Level: 70, HP: 20000, MaxHP: 20000, PhysicalAttack: 500, PhysicalDefense: 180, MagicAttack: 440, MagicDefense: 160, Speed: 80, ExpReward: 1400, MesosReward: 900, CreatedAt: time.Now()},

		// BOSS 怪物
		{ID: 109000, Name: "蘑菇王", Level: 40, HP: 200000, MaxHP: 200000, PhysicalAttack: 500, PhysicalDefense: 200, MagicAttack: 400, MagicDefense: 150, Speed: 100, ExpReward: 10000, MesosReward: 50000, CreatedAt: time.Now()},
		{ID: 109100, Name: "扎昆树", Level: 80, HP: 1000000, MaxHP: 1000000, PhysicalAttack: 2000, PhysicalDefense: 800, MagicAttack: 1500, MagicDefense: 600, Speed: 100, ExpReward: 50000, MesosReward: 500000, CreatedAt: time.Now()},
		{ID: 109200, Name: "皮亚努斯", Level: 75, HP: 800000, MaxHP: 800000, PhysicalAttack: 1800, PhysicalDefense: 700, MagicAttack: 1300, MagicDefense: 500, Speed: 100, ExpReward: 40000, MesosReward: 400000, CreatedAt: time.Now()},
	}
	for i := range mobs {
		if err := DB.FirstOrCreate(&mobs[i], Mob{ID: mobs[i].ID}).Error; err != nil {
			log.Printf("[Seed] 怪物插入失败 id=%d: %v", mobs[i].ID, err)
		}
	}
	log.Printf("[Seed] 怪物数据初始化完成（共 %d 种）", len(mobs))
	return len(mobs)
}

// ====================== 物品数据（60+ 个经典物品） ======================

func seedItems() int {
	items := default079Items()
	for i := range items {
		if err := DB.FirstOrCreate(&items[i], Item{ID: items[i].ID}).Error; err != nil {
			log.Printf("[Seed] 物品插入失败 id=%d: %v", items[i].ID, err)
		}
	}
	log.Printf("[Seed] 物品数据初始化完成（共 %d 个）", len(items))
	return len(items)
}

// ====================== 技能数据（079 全职业 1~3 转） ======================

func seedSkills() int {
	skills := default079Skills()
	for i := range skills {
		if err := DB.FirstOrCreate(&skills[i], Skill{ID: skills[i].ID}).Error; err != nil {
			log.Printf("[Seed] 技能插入失败 id=%d: %v", skills[i].ID, err)
		}
	}
	log.Printf("[Seed] 技能数据初始化完成（共 %d 个）", len(skills))
	return len(skills)
}

// ====================== 任务数据（15+ 个经典任务） ======================

func seedQuests() int {
	quests := []Quest{
		// 彩虹岛新手任务链（079 官方 Quest ID）
		{ID: 1000, Name: "借来莎丽的镜子", Description: "去找希娜。她需要从姐姐莎丽那里借镜子。", NPCID: 2101, LevelReq: 1, ExpReward: 10, MesosReward: 50, CreatedAt: time.Now()},
		{ID: 1001, Name: "给希娜弄来镜子", Description: "找到正在晾衣的莎丽借到镜子，拿给希娜。", NPCID: 2100, LevelReq: 1, ExpReward: 20, MesosReward: 100, CreatedAt: time.Now()},
		{ID: 1005, Name: "传递信件", Description: "蘑菇村的玛利亚需要你把信送给彩虹村的路卡斯长老。", NPCID: 2103, LevelReq: 3, ExpReward: 50, MesosReward: 200, CreatedAt: time.Now()},
		{ID: 1006, Name: "长老的回信", Description: "把路卡斯的回信交给玛利亚。", NPCID: 12000, LevelReq: 3, ExpReward: 80, MesosReward: 300, CreatedAt: time.Now()},
		{ID: 1008, Name: "皮奥的垃圾回收", Description: "帮彩虹村的皮奥收集还可以用的垃圾。", NPCID: 10000, LevelReq: 5, ExpReward: 100, MesosReward: 500, CreatedAt: time.Now()},
		{ID: 1009, Name: "瑞恩的冒险岛问答1", Description: "回答瑞恩的问题：打开背包的快捷键是什么？", NPCID: 12101, LevelReq: 6, ExpReward: 50, MesosReward: 200, CreatedAt: time.Now()},
		// 兼容旧自定义任务 ID（修正 NPC 指向）
		{ID: 400000, Name: "初来乍到", Description: "与希娜对话，了解彩虹村。", NPCID: 2101, LevelReq: 1, ExpReward: 15, MesosReward: 100, CreatedAt: time.Now()},
		{ID: 400001, Name: "击退蜗牛", Description: "击败10只蜗牛", NPCID: 12100, LevelReq: 1, ExpReward: 50, MesosReward: 300, CreatedAt: time.Now()},
		{ID: 400002, Name: "蓝蜗牛的秘密", Description: "收集5个蓝蜗牛壳", NPCID: 12100, LevelReq: 3, ExpReward: 150, MesosReward: 500, CreatedAt: time.Now()},
		{ID: 400003, Name: "前往明珠港", Description: "前往明珠港与船长桑克斯对话", NPCID: 22000, LevelReq: 5, ExpReward: 200, MesosReward: 800, CreatedAt: time.Now()},
		{ID: 400004, Name: "长老斯坦的信", Description: "将信送到射手村斯坦族长处", NPCID: 1012008, LevelReq: 8, ExpReward: 300, MesosReward: 1000, CreatedAt: time.Now()},

		// 1转转职任务
		{ID: 400100, Name: "1转 - 战士", Description: "前往战士圣殿找武术教练转职为战士", NPCID: 1022000, LevelReq: 10, ExpReward: 1000, MesosReward: 5000, CreatedAt: time.Now()},
		{ID: 400101, Name: "1转 - 法师", Description: "前往魔法密林图书馆找汉斯转职为法师", NPCID: 1032001, LevelReq: 10, ExpReward: 1000, MesosReward: 5000, CreatedAt: time.Now()},
		{ID: 400102, Name: "1转 - 弓箭手", Description: "前往弓箭手训练场找赫丽娜转职", NPCID: 1012100, LevelReq: 10, ExpReward: 1000, MesosReward: 5000, CreatedAt: time.Now()},
		{ID: 400103, Name: "1转 - 飞侠", Description: "前往飞侠秘密基地找达克鲁转职", NPCID: 1052001, LevelReq: 10, ExpReward: 1000, MesosReward: 5000, CreatedAt: time.Now()},
		{ID: 400104, Name: "1转 - 海盗", Description: "前往诺特勒斯号找凯琳转职为海盗", NPCID: 1090000, LevelReq: 10, ExpReward: 1000, MesosReward: 5000, CreatedAt: time.Now()},

		// 2转任务
		{ID: 400200, Name: "2转 - 战士", Description: "完成战士2转转职任务", NPCID: 1072000, LevelReq: 30, ExpReward: 5000, MesosReward: 20000, CreatedAt: time.Now()},
		{ID: 400201, Name: "2转 - 法师", Description: "完成法师2转转职任务", NPCID: 1072001, LevelReq: 30, ExpReward: 5000, MesosReward: 20000, CreatedAt: time.Now()},
		{ID: 400202, Name: "2转 - 弓箭手", Description: "完成弓箭手2转转职任务", NPCID: 1072002, LevelReq: 30, ExpReward: 5000, MesosReward: 20000, CreatedAt: time.Now()},
		{ID: 400203, Name: "2转 - 飞侠", Description: "完成飞侠2转转职任务", NPCID: 1072003, LevelReq: 30, ExpReward: 5000, MesosReward: 20000, CreatedAt: time.Now()},
		{ID: 400204, Name: "2转 - 海盗", Description: "完成海盗2转转职任务", NPCID: 1072008, LevelReq: 30, ExpReward: 5000, MesosReward: 20000, CreatedAt: time.Now()},

		// 3转任务
		{ID: 400250, Name: "3转 - 战士", Description: "完成战士3转转职试炼", NPCID: 1072004, LevelReq: 70, ExpReward: 20000, MesosReward: 50000, CreatedAt: time.Now()},
		{ID: 400251, Name: "3转 - 法师", Description: "完成法师3转转职试炼", NPCID: 1072005, LevelReq: 70, ExpReward: 20000, MesosReward: 50000, CreatedAt: time.Now()},
		{ID: 400252, Name: "3转 - 弓箭手", Description: "完成弓箭手3转转职试炼", NPCID: 1072006, LevelReq: 70, ExpReward: 20000, MesosReward: 50000, CreatedAt: time.Now()},
		{ID: 400253, Name: "3转 - 飞侠", Description: "完成飞侠3转转职试炼", NPCID: 1072007, LevelReq: 70, ExpReward: 20000, MesosReward: 50000, CreatedAt: time.Now()},
		{ID: 400254, Name: "3转 - 海盗", Description: "完成海盗3转转职试炼", NPCID: 1072009, LevelReq: 70, ExpReward: 20000, MesosReward: 50000, CreatedAt: time.Now()},

		// 中级任务
		// 中级任务
		{ID: 400300, Name: "猪猪牧场的危机", Description: "帮助射手村训练场的猎人", NPCID: 1012008, LevelReq: 12, ExpReward: 800, MesosReward: 2000, CreatedAt: time.Now()},
		{ID: 400301, Name: "蘑菇王的威胁", Description: "调查蘑菇王森林", NPCID: 1061000, LevelReq: 35, ExpReward: 3000, MesosReward: 15000, CreatedAt: time.Now()},
		{ID: 400302, Name: "石头人的碎片", Description: "收集石头人的碎片", NPCID: 1022002, LevelReq: 25, ExpReward: 2000, MesosReward: 8000, CreatedAt: time.Now()},

		// 4转任务
		{ID: 400400, Name: "4转 - 战士", Description: "120级完成战士4转试炼", NPCID: 1072004, LevelReq: 120, ExpReward: 50000, MesosReward: 100000, CreatedAt: time.Now()},
		{ID: 400401, Name: "4转 - 法师", Description: "120级完成法师4转试炼", NPCID: 1072005, LevelReq: 120, ExpReward: 50000, MesosReward: 100000, CreatedAt: time.Now()},
		{ID: 400402, Name: "4转 - 弓箭手", Description: "120级完成弓箭手4转试炼", NPCID: 1072006, LevelReq: 120, ExpReward: 50000, MesosReward: 100000, CreatedAt: time.Now()},
		{ID: 400403, Name: "4转 - 飞侠", Description: "120级完成飞侠4转试炼", NPCID: 1072007, LevelReq: 120, ExpReward: 50000, MesosReward: 100000, CreatedAt: time.Now()},
		{ID: 400404, Name: "4转 - 海盗", Description: "120级完成海盗4转试炼", NPCID: 1072009, LevelReq: 120, ExpReward: 50000, MesosReward: 100000, CreatedAt: time.Now()},
	}
	for i := range quests {
		var existing Quest
		err := DB.Where("id = ?", quests[i].ID).First(&existing).Error
		if err == nil {
			_ = DB.Model(&existing).Updates(map[string]interface{}{
				"name":        quests[i].Name,
				"description": quests[i].Description,
				"npc_id":      quests[i].NPCID,
				"level_req":   quests[i].LevelReq,
				"exp_reward":  quests[i].ExpReward,
				"mesos_reward": quests[i].MesosReward,
			}).Error
		} else if err := DB.FirstOrCreate(&quests[i], Quest{ID: quests[i].ID}).Error; err != nil {
			log.Printf("[Seed] 任务插入失败 id=%d: %v", quests[i].ID, err)
		}
	}
	log.Printf("[Seed] 任务数据初始化完成（共 %d 个）", len(quests))
	return len(quests)
}

func seedDrops() int {
	drops := default079Drops()
	for i := range drops {
		key := MobDrop{MobID: drops[i].MobID, ItemID: drops[i].ItemID}
		if err := DB.FirstOrCreate(&drops[i], key).Error; err != nil {
			log.Printf("[Seed] 掉落插入失败 mob=%d item=%d: %v", drops[i].MobID, drops[i].ItemID, err)
		}
	}
	log.Printf("[Seed] 掉落数据初始化完成（共 %d 条）", len(drops))
	return len(drops)
}

// TruncateSeedTables 清空种子数据表（供 init_data --reset 使用）
func TruncateSeedTables() {
	tables := []interface{}{
		&Map{}, &NPC{}, &Mob{}, &Item{}, &Skill{}, &Quest{}, &MobDrop{},
	}
	for _, t := range tables {
		if err := DB.Delete(t).Error; err != nil {
			log.Printf("[Seed] 清空表失败: %v", err)
		}
	}
	log.Println("[Seed] 旧数据已清空")
}
