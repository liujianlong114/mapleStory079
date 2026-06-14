package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"mapleStory079/pkg/database"
)

// init_data 工具：向数据库插入初始地图/怪物/物品/技能/NPC/任务数据。
// 用法示例：
//
//	./bin/init_data --config ./config/config.yaml
//	./bin/init_data --reset
//	./bin/init_data --config config.yaml --reset
func main() {
	var configPath string
	var reset bool
	var showHelp bool

	flag.StringVar(&configPath, "config", "", "配置文件路径（viper 会查找该文件）")
	flag.BoolVar(&reset, "reset", false, "清空已有数据后重新插入")
	flag.BoolVar(&showHelp, "help", false, "显示帮助信息")
	flag.Parse()

	if showHelp {
		printUsage()
		return
	}

	fmt.Println("==============================================")
	fmt.Println(" MapleStory 079 - 数据初始化工具")
	fmt.Println("==============================================")
	fmt.Printf("  配置文件: %s\n", valueOrDefault(configPath, "(使用默认路径 ./config/config.yaml)"))
	fmt.Printf("  重置模式: %t\n", reset)
	fmt.Println()

	if err := database.Init(); err != nil {
		log.Printf("数据库初始化失败（可能是无 MySQL 连接）：%v", err)
		fmt.Println()
		fmt.Println("⚠️  无法连接到数据库，以下是将要插入的示例数据预览：")
		printSeedData()
		os.Exit(1)
	}

	if err := database.AutoMigrate(
		&database.Account{},
		&database.Character{},
		&database.CharacterStats{},
		&database.CharacterInventory{},
		&database.Item{},
		&database.Skill{},
		&database.Quest{},
		&database.Map{},
		&database.NPC{},
		&database.Mob{},
		&database.Guild{},
		&database.Party{},
		&database.Friend{},
		&database.LoginLog{},
		&database.TradeLog{},
		&database.ChatLog{},
	); err != nil {
		log.Fatalf("自动迁移失败: %v", err)
	}
	fmt.Println("✅ 数据表迁移完成")

	if reset {
		fmt.Println("🧹 执行 --reset：清空已有游戏数据")
		truncateSeedTables()
	}

	seedMaps()
	seedNPCs()
	seedMobs()
	seedItems()
	seedSkills()
	seedQuests()

	fmt.Println()
	fmt.Println("🎉 全部初始数据插入完成")
	fmt.Println("==============================================")
}

func printUsage() {
	fmt.Println("用法: init_data [options]")
	fmt.Println()
	fmt.Println("选项:")
	flag.PrintDefaults()
	fmt.Println()
	fmt.Println("示例:")
	fmt.Println("  init_data --config config.yaml")
	fmt.Println("  init_data --reset")
	fmt.Println("  init_data --config config.yaml --reset")
}

func valueOrDefault(v, def string) string {
	if v == "" {
		return def
	}
	return v
}

func truncateSeedTables() {
	tables := []interface{}{
		&database.Map{},
		&database.NPC{},
		&database.Mob{},
		&database.Item{},
		&database.Skill{},
		&database.Quest{},
	}
	for _, t := range tables {
		if err := database.GetDB().Delete(t).Error; err != nil {
			log.Printf("清空表失败: %v", err)
		}
	}
	fmt.Println("✅ 旧数据已清空")
}

// ==================== 地图数据（MapleStory 079 经典地图）====================
func seedMaps() {
	maps := []database.Map{
		// 彩虹村 / 新手村（Maple Island）
		{ID: 10000, Name: "彩虹村", Description: "冒险开始的村庄", Width: 1600, Height: 900, Music: "Bgm00.mapleisland", CreatedAt: time.Now()},
		{ID: 10100, Name: "彩虹村海滩", Description: "通往明珠港的海滩", Width: 1600, Height: 900, Music: "Bgm00.mapleisland", CreatedAt: time.Now()},
		{ID: 10200, Name: "蘑菇森林", Description: "蘑菇与蜗牛出没的森林", Width: 1600, Height: 900, Music: "Bgm00.mapleisland", CreatedAt: time.Now()},
		{ID: 10201, Name: "蘑菇森林II", Description: "蘑菇森林的深处", Width: 1600, Height: 900, Music: "Bgm00.mapleisland", CreatedAt: time.Now()},
		{ID: 10300, Name: "明珠港", Description: "连接彩虹村和大陆的港口小镇", Width: 1600, Height: 900, Music: "Bgm00.southperry", CreatedAt: time.Now()},
		{ID: 10400, Name: "通往射手村的路", Description: "从明珠港前往射手村的大路", Width: 1600, Height: 900, Music: "Bgm00.henesys", CreatedAt: time.Now()},

		// 射手村（Henesys）
		{ID: 10500, Name: "射手村", Description: "弓箭手的故乡，宁静的村庄", Width: 1600, Height: 900, Music: "Bgm00.henesys", CreatedAt: time.Now()},
		{ID: 10600, Name: "射手村公园", Description: "射手村中心广场", Width: 1600, Height: 900, Music: "Bgm00.henesys", CreatedAt: time.Now()},
		{ID: 10700, Name: "猪猪农场", Description: "养猪场，有大量猪猪出没", Width: 1600, Height: 900, Music: "Bgm00.pigpark", CreatedAt: time.Now()},
		{ID: 10800, Name: "蘑菇王的领地", Description: "蘑菇王的栖息地", Width: 1600, Height: 900, Music: "Bgm00.boss", CreatedAt: time.Now()},
		{ID: 10801, Name: "蘑菇洞穴", Description: "蘑菇王领地的入口", Width: 1600, Height: 900, Music: "Bgm00.boss", CreatedAt: time.Now()},

		// 魔法密林（Ellinia）
		{ID: 11000, Name: "魔法密林", Description: "魔法师的故乡，神秘森林", Width: 1600, Height: 900, Music: "Bgm00.ellinia", CreatedAt: time.Now()},
		{ID: 11100, Name: "魔法密林北郊", Description: "魔法密林北方的森林", Width: 1600, Height: 900, Music: "Bgm00.ellinia", CreatedAt: time.Now()},
		{ID: 11200, Name: "绿蘑菇森林", Description: "绿蘑菇聚集的森林", Width: 1600, Height: 900, Music: "Bgm00.ellinia", CreatedAt: time.Now()},
		{ID: 11201, Name: "绿蘑菇森林II", Description: "绿蘑菇森林的深处", Width: 1600, Height: 900, Music: "Bgm00.ellinia", CreatedAt: time.Now()},

		// 勇士部落（Perion）
		{ID: 11500, Name: "勇士部落", Description: "战士的故乡，高山要塞", Width: 1600, Height: 900, Music: "Bgm00.perion", CreatedAt: time.Now()},
		{ID: 11600, Name: "勇士部落东入口", Description: "勇士部落东边的入口", Width: 1600, Height: 900, Music: "Bgm00.perion", CreatedAt: time.Now()},
		{ID: 11700, Name: "岩石山", Description: "布满岩石的山脉", Width: 1600, Height: 900, Music: "Bgm00.perion", CreatedAt: time.Now()},
		{ID: 11701, Name: "岩石山II", Description: "岩石山的深处", Width: 1600, Height: 900, Music: "Bgm00.perion", CreatedAt: time.Now()},

		// 废弃都市（Kerning City）
		{ID: 12000, Name: "废弃都市", Description: "飞侠的故乡，阴暗城市", Width: 1600, Height: 900, Music: "Bgm00.kerning", CreatedAt: time.Now()},
		{ID: 12100, Name: "地铁1号线", Description: "废弃都市的地下通道", Width: 1600, Height: 900, Music: "Bgm00.subway", CreatedAt: time.Now()},
		{ID: 12101, Name: "地铁2号线", Description: "更深处的地铁线路", Width: 1600, Height: 900, Music: "Bgm00.subway", CreatedAt: time.Now()},
		{ID: 12200, Name: "建筑工地", Description: "废弃的建筑工地", Width: 1600, Height: 900, Music: "Bgm00.kerning", CreatedAt: time.Now()},

		// 林中之城（Sleepywood）
		{ID: 12500, Name: "林中之城", Description: "森林深处的村庄", Width: 1600, Height: 900, Music: "Bgm00.sleepywood", CreatedAt: time.Now()},
		{ID: 12600, Name: "蚂蚁洞1", Description: "地下洞穴", Width: 1600, Height: 900, Music: "Bgm00.anttunnel", CreatedAt: time.Now()},
		{ID: 12700, Name: "蚂蚁洞2", Description: "更深的蚂蚁洞", Width: 1600, Height: 900, Music: "Bgm00.anttunnel", CreatedAt: time.Now()},
		{ID: 12800, Name: "黑暗战场", Description: "黑暗中战斗的场地", Width: 1600, Height: 900, Music: "Bgm00.dungeon", CreatedAt: time.Now()},
		{ID: 12801, Name: "最终战场", Description: "最强的战士训练的地方", Width: 1600, Height: 900, Music: "Bgm00.dungeon", CreatedAt: time.Now()},

		// 冰峰雪域（El Nath）
		{ID: 13000, Name: "冰峰雪域", Description: "被冰雪覆盖的寒冷地区", Width: 1600, Height: 900, Music: "Bgm00.elnath", CreatedAt: time.Now()},
		{ID: 13100, Name: "冰雪峡谷1", Description: "被冰雪覆盖的峡谷", Width: 1600, Height: 900, Music: "Bgm00.elnath", CreatedAt: time.Now()},
		{ID: 13200, Name: "冰雪峡谷2", Description: "更深的冰雪峡谷", Width: 1600, Height: 900, Music: "Bgm00.elnath", CreatedAt: time.Now()},

		// 天空之城（Orbis）
		{ID: 14000, Name: "天空之城", Description: "漂浮在云端的城市", Width: 1600, Height: 900, Music: "Bgm00.orbis", CreatedAt: time.Now()},
		{ID: 14100, Name: "天空楼梯1", Description: "通往天空之塔的楼梯", Width: 1600, Height: 900, Music: "Bgm00.orbis", CreatedAt: time.Now()},
		{ID: 14101, Name: "天空楼梯2", Description: "天空之塔上层", Width: 1600, Height: 900, Music: "Bgm00.orbis", CreatedAt: time.Now()},

		// 训练场系列
		{ID: 15000, Name: "训练场1", Description: "新手训练场地", Width: 1600, Height: 900, Music: "Bgm00.training", CreatedAt: time.Now()},
		{ID: 15100, Name: "训练场2", Description: "中级训练场地", Width: 1600, Height: 900, Music: "Bgm00.training", CreatedAt: time.Now()},
		{ID: 15200, Name: "训练场3", Description: "高级训练场地", Width: 1600, Height: 900, Music: "Bgm00.training", CreatedAt: time.Now()},
		{ID: 15300, Name: "训练场4", Description: "专家级训练场地", Width: 1600, Height: 900, Music: "Bgm00.training", CreatedAt: time.Now()},

		// 玩具城（Ludibrium）
		{ID: 16000, Name: "玩具城", Description: "充满玩具的梦幻城市", Width: 1600, Height: 900, Music: "Bgm00.ludibrium", CreatedAt: time.Now()},
		{ID: 16100, Name: "玩具塔1层", Description: "玩具塔底层", Width: 1600, Height: 900, Music: "Bgm00.ludibrium", CreatedAt: time.Now()},
		{ID: 16200, Name: "玩具塔100层", Description: "玩具塔顶层", Width: 1600, Height: 900, Music: "Bgm00.ludibrium", CreatedAt: time.Now()},

		// BOSS 地图
		{ID: 17000, Name: "蘑菇王祭坛", Description: "蘑菇王的BOSS房间", Width: 1600, Height: 900, Music: "Bgm00.boss", CreatedAt: time.Now()},
		{ID: 17100, Name: "扎昆祭坛", Description: "扎昆的BOSS房间", Width: 1600, Height: 900, Music: "Bgm00.boss", CreatedAt: time.Now()},
	}
	for i := range maps {
		if err := database.GetDB().FirstOrCreate(&maps[i], database.Map{ID: maps[i].ID}).Error; err != nil {
			log.Printf("地图插入失败 id=%d: %v", maps[i].ID, err)
		}
	}
	fmt.Printf("✅ 地图数据初始化完成（共 %d 张）\n", len(maps))
}

// ==================== NPC 数据（MapleStory 079 经典NPC）====================
func seedNPCs() {
	npcs := []database.NPC{
		// 彩虹村（新手村）
		{ID: 10100, Name: "希娜", Description: "彩虹村的村长", MapID: 10000, PositionX: 400, PositionY: 400, Scripts: "欢迎来到彩虹村，冒险者！这里是冒险的起点。", CreatedAt: time.Now()},
		{ID: 10101, Name: "奥斌", Description: "新手向导", MapID: 10000, PositionX: 800, PositionY: 400, Scripts: "如果想离开彩虹村前往明珠港，就来找我吧。", CreatedAt: time.Now()},
		{ID: 10102, Name: "露比", Description: "彩虹村杂货店", MapID: 10000, PositionX: 600, PositionY: 400, Scripts: "需要药水或回城卷轴吗？", HasShop: true, CreatedAt: time.Now()},

		// 明珠港
		{ID: 10200, Name: "露西娅", Description: "明珠港村长", MapID: 10300, PositionX: 500, PositionY: 400, Scripts: "欢迎来到明珠港！这里是连接彩虹村和大陆的交通要道。", CreatedAt: time.Now()},
		{ID: 10201, Name: "船长", Description: "明珠港的船长", MapID: 10300, PositionX: 1200, PositionY: 400, Scripts: "我可以带你去彩虹村或其他港口。", CreatedAt: time.Now()},
		{ID: 10202, Name: "武器店老板", Description: "明珠港武器店", MapID: 10300, PositionX: 700, PositionY: 400, Scripts: "选购一把好武器吧，冒险者！", HasShop: true, CreatedAt: time.Now()},
		{ID: 10203, Name: "药水店老板", Description: "明珠港药水店", MapID: 10300, PositionX: 900, PositionY: 400, Scripts: "红药水、蓝药水都有，来看看吧！", HasShop: true, CreatedAt: time.Now()},
		{ID: 10204, Name: "杂货店老板", Description: "明珠港杂货店", MapID: 10300, PositionX: 1000, PositionY: 400, Scripts: "回城卷轴和各种杂物都有卖。", HasShop: true, CreatedAt: time.Now()},

		// 射手村
		{ID: 10300, Name: "长老斯坦", Description: "射手村长", MapID: 10500, PositionX: 500, PositionY: 400, Scripts: "欢迎来到射手村，这里是弓箭手的故乡。", CreatedAt: time.Now()},
		{ID: 10301, Name: "赫丽娜", Description: "弓箭手转职教官", MapID: 10500, PositionX: 800, PositionY: 400, Scripts: "你想转职为弓箭手吗？需要等级达到10级且敏捷达到25。欢迎转职为弓箭手！", CreatedAt: time.Now()},
		{ID: 10302, Name: "武器店老板", Description: "射手村武器店", MapID: 10600, PositionX: 400, PositionY: 400, Scripts: "弓箭和弓都在这里！", HasShop: true, CreatedAt: time.Now()},
		{ID: 10303, Name: "防具店老板", Description: "射手村防具店", MapID: 10600, PositionX: 600, PositionY: 400, Scripts: "皮甲、棉帽，防护装备齐全！", HasShop: true, CreatedAt: time.Now()},
		{ID: 10304, Name: "药水店老板", Description: "射手村药水店", MapID: 10600, PositionX: 800, PositionY: 400, Scripts: "药水补给站！", HasShop: true, CreatedAt: time.Now()},

		// 魔法密林
		{ID: 10400, Name: "长老汉斯", Description: "魔法密林长老", MapID: 11000, PositionX: 500, PositionY: 400, Scripts: "欢迎来到魔法密林，神秘的魔法之都。", CreatedAt: time.Now()},
		{ID: 10401, Name: "魔法师教练", Description: "魔法师转职教官", MapID: 11000, PositionX: 800, PositionY: 400, Scripts: "你想转职为魔法师吗？需要等级达到10级且智力达到20。欢迎转职为魔法师！", CreatedAt: time.Now()},
		{ID: 10402, Name: "武器店老板", Description: "魔法密林武器店", MapID: 11000, PositionX: 1000, PositionY: 400, Scripts: "法杖和魔法书都在这里！", HasShop: true, CreatedAt: time.Now()},

		// 勇士部落
		{ID: 10500, Name: "酋长", Description: "勇士部落酋长", MapID: 11500, PositionX: 500, PositionY: 400, Scripts: "欢迎来到勇士部落！这里是战士的故乡。", CreatedAt: time.Now()},
		{ID: 10501, Name: "武术教练", Description: "战士转职教官", MapID: 11500, PositionX: 800, PositionY: 400, Scripts: "你想转职为战士吗？需要等级达到10级且力量达到35。欢迎转职为战士！", CreatedAt: time.Now()},
		{ID: 10502, Name: "武器店老板", Description: "勇士部落武器店", MapID: 11500, PositionX: 1000, PositionY: 400, Scripts: "双手剑、枪、矛，武器应有尽有！", HasShop: true, CreatedAt: time.Now()},
		{ID: 10503, Name: "防具店老板", Description: "勇士部落防具店", MapID: 11500, PositionX: 700, PositionY: 400, Scripts: "铠甲、铁盾，防护装备！", HasShop: true, CreatedAt: time.Now()},
		{ID: 10504, Name: "药水店老板", Description: "勇士部落药水店", MapID: 11500, PositionX: 900, PositionY: 400, Scripts: "大量红药水和蓝药水！", HasShop: true, CreatedAt: time.Now()},

		// 废弃都市
		{ID: 10600, Name: "达克鲁", Description: "飞侠转职教官", MapID: 12000, PositionX: 800, PositionY: 400, Scripts: "你想转职为飞侠吗？需要等级达到10级且敏捷达到25。欢迎转职为飞侠！", CreatedAt: time.Now()},
		{ID: 10601, Name: "贝尔", Description: "废弃都市向导", MapID: 12000, PositionX: 500, PositionY: 400, Scripts: "欢迎来到废弃都市，这里是飞侠的地盘。", CreatedAt: time.Now()},
		{ID: 10602, Name: "杂货店老板", Description: "废弃都市杂货店", MapID: 12000, PositionX: 1000, PositionY: 400, Scripts: "各种飞侠装备和杂物！", HasShop: true, CreatedAt: time.Now()},

		// 林中之城
		{ID: 10700, Name: "记忆者", Description: "林中之城的神秘人物", MapID: 12500, PositionX: 500, PositionY: 400, Scripts: "欢迎来到林中之城，冒险者。地下洞穴藏着许多危险。", CreatedAt: time.Now()},
		{ID: 10701, Name: "铁匠", Description: "林中之城铁匠", MapID: 12500, PositionX: 800, PositionY: 400, Scripts: "打造和强化装备，来找我吧！", HasShop: true, CreatedAt: time.Now()},

		// 海盗相关
		{ID: 10800, Name: "凯琳", Description: "海盗转职教官", MapID: 14000, PositionX: 800, PositionY: 400, Scripts: "你想转职为海盗吗？需要等级达到10级且敏捷达到20。欢迎转职为海盗！", CreatedAt: time.Now()},
		{ID: 10801, Name: "诺特勒斯号船长", Description: "海盗船船长", MapID: 14000, PositionX: 500, PositionY: 400, Scripts: "欢迎登上诺特勒斯号！", CreatedAt: time.Now()},

		// 冰峰雪域
		{ID: 10900, Name: "长老阿尔卡斯特", Description: "冰峰雪域长老", MapID: 13000, PositionX: 500, PositionY: 400, Scripts: "欢迎来到冰峰雪域，注意保暖！", CreatedAt: time.Now()},

		// 玩具城
		{ID: 11000, Name: "玩具城管理者", Description: "玩具城NPC", MapID: 16000, PositionX: 500, PositionY: 400, Scripts: "欢迎来到玩具城！", CreatedAt: time.Now()},
	}
	for i := range npcs {
		if err := database.GetDB().FirstOrCreate(&npcs[i], database.NPC{ID: npcs[i].ID}).Error; err != nil {
			log.Printf("NPC 插入失败 id=%d: %v", npcs[i].ID, err)
		}
	}
	fmt.Printf("✅ NPC 数据初始化完成（共 %d 个）\n", len(npcs))
}

// ==================== 怪物数据（MapleStory 079 经典怪物）====================
func seedMobs() {
	mobs := []database.Mob{
		// 新手 / 低级怪物
		{ID: 100100, Name: "蜗牛", Level: 1, HP: 15, MaxHP: 15, PhysicalAttack: 8, PhysicalDefense: 0, MagicAttack: 5, MagicDefense: 0, Speed: 100, ExpReward: 3, MesosReward: 3, CreatedAt: time.Now()},
		{ID: 100101, Name: "蓝蜗牛", Level: 3, HP: 35, MaxHP: 35, PhysicalAttack: 12, PhysicalDefense: 2, MagicAttack: 8, MagicDefense: 1, Speed: 100, ExpReward: 8, MesosReward: 7, CreatedAt: time.Now()},
		{ID: 100102, Name: "红蜗牛", Level: 4, HP: 50, MaxHP: 50, PhysicalAttack: 15, PhysicalDefense: 3, MagicAttack: 10, MagicDefense: 1, Speed: 100, ExpReward: 10, MesosReward: 10, CreatedAt: time.Now()},
		{ID: 100200, Name: "蘑菇仔", Level: 5, HP: 60, MaxHP: 60, PhysicalAttack: 18, PhysicalDefense: 4, MagicAttack: 12, MagicDefense: 2, Speed: 100, ExpReward: 12, MesosReward: 10, CreatedAt: time.Now()},
		{ID: 100201, Name: "绿蘑菇", Level: 7, HP: 85, MaxHP: 85, PhysicalAttack: 22, PhysicalDefense: 6, MagicAttack: 15, MagicDefense: 3, Speed: 100, ExpReward: 18, MesosReward: 14, CreatedAt: time.Now()},
		{ID: 100202, Name: "蓝蘑菇", Level: 9, HP: 120, MaxHP: 120, PhysicalAttack: 28, PhysicalDefense: 8, MagicAttack: 18, MagicDefense: 4, Speed: 100, ExpReward: 24, MesosReward: 18, CreatedAt: time.Now()},
		{ID: 100203, Name: "花蘑菇", Level: 10, HP: 150, MaxHP: 150, PhysicalAttack: 32, PhysicalDefense: 10, MagicAttack: 22, MagicDefense: 5, Speed: 100, ExpReward: 28, MesosReward: 20, CreatedAt: time.Now()},
		{ID: 100300, Name: "绿水灵", Level: 8, HP: 100, MaxHP: 100, PhysicalAttack: 25, PhysicalDefense: 5, MagicAttack: 20, MagicDefense: 5, Speed: 100, ExpReward: 20, MesosReward: 15, CreatedAt: time.Now()},
		{ID: 100301, Name: "蓝水灵", Level: 12, HP: 200, MaxHP: 200, PhysicalAttack: 40, PhysicalDefense: 10, MagicAttack: 30, MagicDefense: 8, Speed: 100, ExpReward: 38, MesosReward: 28, CreatedAt: time.Now()},
		{ID: 100400, Name: "猪猪", Level: 10, HP: 180, MaxHP: 180, PhysicalAttack: 35, PhysicalDefense: 10, MagicAttack: 20, MagicDefense: 5, Speed: 100, ExpReward: 30, MesosReward: 25, CreatedAt: time.Now()},
		{ID: 100401, Name: "火野猪", Level: 15, HP: 350, MaxHP: 350, PhysicalAttack: 55, PhysicalDefense: 18, MagicAttack: 35, MagicDefense: 10, Speed: 100, ExpReward: 55, MesosReward: 40, CreatedAt: time.Now()},

		// 中级怪物
		{ID: 100500, Name: "小白雪鬼", Level: 18, HP: 500, MaxHP: 500, PhysicalAttack: 65, PhysicalDefense: 22, MagicAttack: 45, MagicDefense: 15, Speed: 100, ExpReward: 75, MesosReward: 55, CreatedAt: time.Now()},
		{ID: 100600, Name: "章鱼", Level: 14, HP: 280, MaxHP: 280, PhysicalAttack: 50, PhysicalDefense: 12, MagicAttack: 30, MagicDefense: 8, Speed: 100, ExpReward: 48, MesosReward: 35, CreatedAt: time.Now()},
		{ID: 100700, Name: "野猪", Level: 18, HP: 500, MaxHP: 500, PhysicalAttack: 65, PhysicalDefense: 20, MagicAttack: 40, MagicDefense: 12, Speed: 100, ExpReward: 70, MesosReward: 50, CreatedAt: time.Now()},
		{ID: 100800, Name: "僵尸蘑菇", Level: 20, HP: 700, MaxHP: 700, PhysicalAttack: 75, PhysicalDefense: 25, MagicAttack: 55, MagicDefense: 18, Speed: 100, ExpReward: 90, MesosReward: 65, CreatedAt: time.Now()},
		{ID: 100801, Name: "刺蘑菇", Level: 22, HP: 900, MaxHP: 900, PhysicalAttack: 85, PhysicalDefense: 30, MagicAttack: 65, MagicDefense: 20, Speed: 100, ExpReward: 110, MesosReward: 80, CreatedAt: time.Now()},
		{ID: 100900, Name: "石头人", Level: 25, HP: 1500, MaxHP: 1500, PhysicalAttack: 100, PhysicalDefense: 40, MagicAttack: 70, MagicDefense: 25, Speed: 80, ExpReward: 150, MesosReward: 100, CreatedAt: time.Now()},
		{ID: 101000, Name: "冰独眼兽", Level: 30, HP: 2500, MaxHP: 2500, PhysicalAttack: 130, PhysicalDefense: 50, MagicAttack: 100, MagicDefense: 35, Speed: 100, ExpReward: 220, MesosReward: 150, CreatedAt: time.Now()},
		{ID: 101100, Name: "黑鳄鱼", Level: 28, HP: 2000, MaxHP: 2000, PhysicalAttack: 120, PhysicalDefense: 45, MagicAttack: 85, MagicDefense: 30, Speed: 100, ExpReward: 180, MesosReward: 130, CreatedAt: time.Now()},

		// 高级怪物
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
		if err := database.GetDB().FirstOrCreate(&mobs[i], database.Mob{ID: mobs[i].ID}).Error; err != nil {
			log.Printf("怪物插入失败 id=%d: %v", mobs[i].ID, err)
		}
	}
	fmt.Printf("✅ 怪物数据初始化完成（共 %d 个）\n", len(mobs))
}

// ==================== 物品数据（MapleStory 079 经典物品）====================
func seedItems() {
	items := []database.Item{
		// ==================== 消耗品 ====================
		{ID: 200000, Name: "红色药水", Description: "恢复 50 HP", ItemType: 0, HPRecovery: 50, Price: 50, LevelReq: 1, Stackable: true, CreatedAt: time.Now()},
		{ID: 200001, Name: "橙色药水", Description: "恢复 150 HP", ItemType: 0, HPRecovery: 150, Price: 150, LevelReq: 1, Stackable: true, CreatedAt: time.Now()},
		{ID: 200002, Name: "黄色药水", Description: "恢复 300 HP", ItemType: 0, HPRecovery: 300, Price: 300, LevelReq: 10, Stackable: true, CreatedAt: time.Now()},
		{ID: 200003, Name: "白色药水", Description: "恢复 500 HP", ItemType: 0, HPRecovery: 500, Price: 500, LevelReq: 20, Stackable: true, CreatedAt: time.Now()},
		{ID: 200004, Name: "超级药水", Description: "恢复全 HP / MP", ItemType: 0, HPRecovery: 99999, MPRecovery: 99999, Price: 5000, LevelReq: 30, Stackable: true, CreatedAt: time.Now()},

		{ID: 200100, Name: "蓝色药水", Description: "恢复 50 MP", ItemType: 0, MPRecovery: 50, Price: 80, LevelReq: 1, Stackable: true, CreatedAt: time.Now()},
		{ID: 200101, Name: "紫色药水", Description: "恢复 200 MP", ItemType: 0, MPRecovery: 200, Price: 250, LevelReq: 10, Stackable: true, CreatedAt: time.Now()},
		{ID: 200102, Name: "黑色药水", Description: "恢复 500 MP", ItemType: 0, MPRecovery: 500, Price: 600, LevelReq: 20, Stackable: true, CreatedAt: time.Now()},

		{ID: 200200, Name: "特殊药水", Description: "恢复全部 HP 和 MP", ItemType: 0, HPRecovery: 99999, MPRecovery: 99999, Price: 3000, LevelReq: 1, Stackable: true, CreatedAt: time.Now()},

		{ID: 200300, Name: "回城卷轴", Description: "返回当前地区的城镇", ItemType: 0, Price: 500, LevelReq: 1, Stackable: true, CreatedAt: time.Now()},
		{ID: 200301, Name: "射手村回城卷轴", Description: "返回射手村", ItemType: 0, Price: 1000, LevelReq: 1, Stackable: true, CreatedAt: time.Now()},
		{ID: 200302, Name: "魔法密林回城卷轴", Description: "返回魔法密林", ItemType: 0, Price: 1000, LevelReq: 1, Stackable: true, CreatedAt: time.Now()},
		{ID: 200303, Name: "勇士部落回城卷轴", Description: "返回勇士部落", ItemType: 0, Price: 1000, LevelReq: 1, Stackable: true, CreatedAt: time.Now()},
		{ID: 200304, Name: "废弃都市回城卷轴", Description: "返回废弃都市", ItemType: 0, Price: 1000, LevelReq: 1, Stackable: true, CreatedAt: time.Now()},

		{ID: 200400, Name: "宠物饲料", Description: "恢复宠物饥饿度", ItemType: 0, Price: 30, LevelReq: 1, Stackable: true, CreatedAt: time.Now()},

		{ID: 200500, Name: "烤鳗鱼", Description: "恢复 300 HP", ItemType: 0, HPRecovery: 300, Price: 400, LevelReq: 1, Stackable: true, CreatedAt: time.Now()},
		{ID: 200501, Name: "刨冰", Description: "恢复 300 MP", ItemType: 0, MPRecovery: 300, Price: 500, LevelReq: 10, Stackable: true, CreatedAt: time.Now()},
		{ID: 200502, Name: "西瓜", Description: "恢复 500 HP 和 300 MP", ItemType: 0, HPRecovery: 500, MPRecovery: 300, Price: 800, LevelReq: 15, Stackable: true, CreatedAt: time.Now()},

		// ==================== 武器 ====================
		{ID: 210000, Name: "新手剑", Description: "新手专用的剑", ItemType: 1, STR: 5, Price: 500, LevelReq: 1, CreatedAt: time.Now()},
		{ID: 210100, Name: "短剑", Description: "飞侠用短剑", ItemType: 1, DEX: 5, STR: 3, Price: 3000, LevelReq: 10, CreatedAt: time.Now()},
		{ID: 210101, Name: "钢铁短剑", Description: "强化的短剑", ItemType: 1, DEX: 8, STR: 5, Price: 8000, LevelReq: 15, CreatedAt: time.Now()},
		{ID: 210200, Name: "双手剑", Description: "战士用双手剑", ItemType: 1, STR: 15, Price: 10000, LevelReq: 15, CreatedAt: time.Now()},
		{ID: 210201, Name: "巨剑", Description: "强大的双手剑", ItemType: 1, STR: 25, Price: 30000, LevelReq: 30, CreatedAt: time.Now()},
		{ID: 210300, Name: "枪", Description: "战士用长枪", ItemType: 1, STR: 12, DEX: 3, Price: 8000, LevelReq: 15, CreatedAt: time.Now()},
		{ID: 210301, Name: "矛", Description: "战士用长矛", ItemType: 1, STR: 18, DEX: 2, Price: 12000, LevelReq: 20, CreatedAt: time.Now()},
		{ID: 210400, Name: "弓", Description: "弓箭手用弓", ItemType: 1, DEX: 10, STR: 3, Price: 7000, LevelReq: 10, CreatedAt: time.Now()},
		{ID: 210401, Name: "弩", Description: "弓箭手用弩", ItemType: 1, DEX: 12, STR: 5, Price: 9000, LevelReq: 15, CreatedAt: time.Now()},
		{ID: 210500, Name: "短杖", Description: "法师用短杖", ItemType: 1, INT: 8, LUK: 2, Price: 6000, LevelReq: 10, CreatedAt: time.Now()},
		{ID: 210501, Name: "长杖", Description: "法师用长杖", ItemType: 1, INT: 12, LUK: 3, Price: 10000, LevelReq: 15, CreatedAt: time.Now()},
		{ID: 210600, Name: "拳套", Description: "飞侠用拳套", ItemType: 1, DEX: 10, LUK: 5, Price: 8000, LevelReq: 15, CreatedAt: time.Now()},
		{ID: 210700, Name: "指节", Description: "海盗用指节", ItemType: 1, STR: 10, DEX: 5, Price: 9000, LevelReq: 15, CreatedAt: time.Now()},
		{ID: 210701, Name: "手枪", Description: "海盗用手枪", ItemType: 1, DEX: 12, STR: 3, Price: 10000, LevelReq: 15, CreatedAt: time.Now()},

		// ==================== 防具 ====================
		{ID: 220000, Name: "棉帽", Description: "棉质帽子", ItemType: 1, DEX: 2, Price: 800, LevelReq: 1, CreatedAt: time.Now()},
		{ID: 220001, Name: "皮帽", Description: "皮革帽子", ItemType: 1, DEX: 3, STR: 2, Price: 2000, LevelReq: 10, CreatedAt: time.Now()},
		{ID: 220100, Name: "皮甲", Description: "皮革护甲", ItemType: 1, STR: 3, DEX: 2, Price: 2500, LevelReq: 10, CreatedAt: time.Now()},
		{ID: 220101, Name: "铠甲", Description: "金属铠甲", ItemType: 1, STR: 8, DEX: 3, Price: 8000, LevelReq: 20, CreatedAt: time.Now()},
		{ID: 220200, Name: "皮裤", Description: "皮革裤子", ItemType: 1, STR: 2, DEX: 2, Price: 1500, LevelReq: 10, CreatedAt: time.Now()},
		{ID: 220300, Name: "棉鞋", Description: "棉质鞋子", ItemType: 1, DEX: 2, Price: 600, LevelReq: 1, CreatedAt: time.Now()},
		{ID: 220301, Name: "皮靴", Description: "皮革靴子", ItemType: 1, DEX: 3, STR: 2, Price: 2000, LevelReq: 15, CreatedAt: time.Now()},
		{ID: 220400, Name: "皮手套", Description: "皮革手套", ItemType: 1, DEX: 3, Price: 1500, LevelReq: 10, CreatedAt: time.Now()},
		{ID: 220500, Name: "铁盾", Description: "铁制盾牌", ItemType: 1, STR: 5, Price: 5000, LevelReq: 15, CreatedAt: time.Now()},
		{ID: 220600, Name: "披风", Description: "普通披风", ItemType: 1, DEX: 3, LUK: 2, Price: 3000, LevelReq: 10, CreatedAt: time.Now()},

		// ==================== 卷轴 ====================
		{ID: 230000, Name: "武器卷轴10%", Description: "10% 成功率强化武器", ItemType: 2, Price: 100000, LevelReq: 1, Stackable: true, CreatedAt: time.Now()},
		{ID: 230001, Name: "武器卷轴30%", Description: "30% 成功率强化武器", ItemType: 2, Price: 50000, LevelReq: 1, Stackable: true, CreatedAt: time.Now()},
		{ID: 230002, Name: "防具卷轴10%", Description: "10% 成功率强化防具", ItemType: 2, Price: 80000, LevelReq: 1, Stackable: true, CreatedAt: time.Now()},
		{ID: 230003, Name: "防具卷轴30%", Description: "30% 成功率强化防具", ItemType: 2, Price: 40000, LevelReq: 1, Stackable: true, CreatedAt: time.Now()},
		{ID: 230004, Name: "饰品卷轴60%", Description: "60% 成功率强化饰品", ItemType: 2, Price: 30000, LevelReq: 1, Stackable: true, CreatedAt: time.Now()},

		// ==================== 其他 / 任务道具 ====================
		{ID: 240000, Name: "蜗牛壳", Description: "蜗牛掉落的壳", ItemType: 2, Price: 5, Stackable: true, CreatedAt: time.Now()},
		{ID: 240001, Name: "蓝蜗牛壳", Description: "蓝蜗牛掉落的壳", ItemType: 2, Price: 10, Stackable: true, CreatedAt: time.Now()},
		{ID: 240002, Name: "蘑菇盖", Description: "蘑菇的盖子", ItemType: 2, Price: 8, Stackable: true, CreatedAt: time.Now()},
		{ID: 240003, Name: "绿水灵珠", Description: "绿水灵的核心", ItemType: 2, Price: 20, Stackable: true, CreatedAt: time.Now()},
		{ID: 240004, Name: "猪猪尾巴", Description: "猪猪的尾巴", ItemType: 2, Price: 15, Stackable: true, CreatedAt: time.Now()},
		{ID: 240005, Name: "火野猪牙齿", Description: "火野猪的牙齿", ItemType: 2, Price: 30, Stackable: true, CreatedAt: time.Now()},
		{ID: 240006, Name: "僵尸蘑菇盖", Description: "僵尸蘑菇的盖子", ItemType: 2, Price: 50, Stackable: true, CreatedAt: time.Now()},
		{ID: 240007, Name: "石头碎片", Description: "石头人掉落的碎片", ItemType: 2, Price: 80, Stackable: true, CreatedAt: time.Now()},
	}
	for i := range items {
		if err := database.GetDB().FirstOrCreate(&items[i], database.Item{ID: items[i].ID}).Error; err != nil {
			log.Printf("物品插入失败 id=%d: %v", items[i].ID, err)
		}
	}
	fmt.Printf("✅ 物品数据初始化完成（共 %d 个）\n", len(items))
}

// ==================== 技能数据（MapleStory 079 五职业经典技能）====================
func seedSkills() {
	skills := []database.Skill{
		// 通用被动
		{ID: 300000, Name: "HP 增加", JobClass: 0, Description: "永久增加最大 HP", IsPassive: true, MaxLevel: 10, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300001, Name: "MP 增加", JobClass: 0, Description: "永久增加最大 MP", IsPassive: true, MaxLevel: 10, CoolDownMs: 0, CreatedAt: time.Now()},

		// ========== 战士 1转（JobClass=1）==========
		{ID: 300100, Name: "生命恢复", JobClass: 1, Description: "提高 HP 恢复速度", IsPassive: true, MaxLevel: 10, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300101, Name: "生命强化", JobClass: 1, Description: "永久增加最大 HP", IsPassive: true, MaxLevel: 10, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300102, Name: "强力攻击", JobClass: 1, Description: "对单个敌人造成强力伤害", MaxLevel: 20, MPCost: 8, DamageRatio: 2.0, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300103, Name: "群体攻击", JobClass: 1, Description: "对多个敌人造成伤害", MaxLevel: 20, MPCost: 15, DamageRatio: 1.5, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300104, Name: "铁壁", JobClass: 1, Description: "增加物理防御", IsPassive: true, MaxLevel: 10, CoolDownMs: 0, CreatedAt: time.Now()},

		// ========== 法师 1转（JobClass=2）==========
		{ID: 300200, Name: "魔法弹", JobClass: 2, Description: "发射魔法弹攻击敌人", MaxLevel: 20, MPCost: 5, DamageRatio: 1.5, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300201, Name: "魔力强化", JobClass: 2, Description: "永久增加最大 MP", IsPassive: true, MaxLevel: 10, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300202, Name: "魔法双击", JobClass: 2, Description: "发射两枚魔法弹", MaxLevel: 20, MPCost: 12, DamageRatio: 1.2, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300203, Name: "魔法盾", JobClass: 2, Description: "用 MP 代替受到的伤害", MaxLevel: 20, MPCost: 20, CoolDownMs: 1000, CreatedAt: time.Now()},
		{ID: 300204, Name: "魔法铠甲", JobClass: 2, Description: "增加物理防御力", MaxLevel: 20, MPCost: 15, CoolDownMs: 10000, CreatedAt: time.Now()},

		// ========== 弓箭手 1转（JobClass=3）==========
		{ID: 300300, Name: "远程箭", JobClass: 3, Description: "增加弓箭射程", IsPassive: true, MaxLevel: 8, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300301, Name: "精准箭", JobClass: 3, Description: "增加命中率", IsPassive: true, MaxLevel: 20, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300302, Name: "强力箭", JobClass: 3, Description: "增加攻击力", IsPassive: true, MaxLevel: 20, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300303, Name: "断魂箭", JobClass: 3, Description: "对单个敌人造成强力伤害", MaxLevel: 20, MPCost: 10, DamageRatio: 2.0, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300304, Name: "二连射", JobClass: 3, Description: "连射两箭", MaxLevel: 20, MPCost: 15, DamageRatio: 1.3, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300305, Name: "集中术", JobClass: 3, Description: "增加命中率和回避率", MaxLevel: 20, MPCost: 15, CoolDownMs: 10000, CreatedAt: time.Now()},

		// ========== 飞侠 1转（JobClass=4）==========
		{ID: 300400, Name: "远程暗器", JobClass: 4, Description: "增加飞镖射程", IsPassive: true, MaxLevel: 8, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300401, Name: "精准暗器", JobClass: 4, Description: "增加暗器命中率", IsPassive: true, MaxLevel: 20, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300402, Name: "强力投掷", JobClass: 4, Description: "增加暗器攻击力", IsPassive: true, MaxLevel: 20, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300403, Name: "双飞斩", JobClass: 4, Description: "扔出两把飞镖", MaxLevel: 20, MPCost: 15, DamageRatio: 1.5, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300404, Name: "隐身术", JobClass: 4, Description: "短暂隐身不被发现", MaxLevel: 20, MPCost: 25, CoolDownMs: 5000, CreatedAt: time.Now()},

		// ========== 海盗 1转（JobClass=5）==========
		{ID: 300500, Name: "疾驰", JobClass: 5, Description: "瞬间快速移动", MaxLevel: 20, MPCost: 10, CoolDownMs: 3000, CreatedAt: time.Now()},
		{ID: 300501, Name: "百裂拳", JobClass: 5, Description: "用指节快速连击", MaxLevel: 20, MPCost: 12, DamageRatio: 1.8, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300502, Name: "半月踢", JobClass: 5, Description: "回旋踢攻击周围敌人", MaxLevel: 20, MPCost: 18, DamageRatio: 1.6, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300503, Name: "快动作", JobClass: 5, Description: "增加命中率和回避率", IsPassive: true, MaxLevel: 20, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 300504, Name: "双弹射杀", JobClass: 5, Description: "发射两发子弹", MaxLevel: 20, MPCost: 15, DamageRatio: 1.4, CoolDownMs: 0, CreatedAt: time.Now()},

		// ========== 2转技能样例 ==========
		{ID: 301100, Name: "剑客终极剑", JobClass: 1, Description: "终极攻击技能（战士2转）", MaxLevel: 30, MPCost: 25, DamageRatio: 3.0, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 301101, Name: "斧木锤", JobClass: 1, Description: "战士2转攻击技能", MaxLevel: 30, MPCost: 20, DamageRatio: 2.5, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 302100, Name: "火毒箭", JobClass: 2, Description: "发射火毒魔法弹（法师2转）", MaxLevel: 30, MPCost: 20, DamageRatio: 2.5, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 302101, Name: "冰冻术", JobClass: 2, Description: "冰冻敌人的魔法", MaxLevel: 30, MPCost: 25, DamageRatio: 2.0, CoolDownMs: 3000, CreatedAt: time.Now()},
		{ID: 302102, Name: "治愈", JobClass: 2, Description: "恢复 HP 的辅助魔法", MaxLevel: 30, MPCost: 30, CoolDownMs: 2000, CreatedAt: time.Now()},
		{ID: 303100, Name: "爆炸箭", JobClass: 3, Description: "发射爆炸性的箭（弓箭手2转）", MaxLevel: 30, MPCost: 25, DamageRatio: 2.2, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 303101, Name: "穿透箭", JobClass: 3, Description: "穿透多个敌人的箭", MaxLevel: 30, MPCost: 20, DamageRatio: 2.0, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 304100, Name: "快速暗器", JobClass: 4, Description: "提高暗器攻击速度", MaxLevel: 30, MPCost: 20, CoolDownMs: 10000, CreatedAt: time.Now()},
		{ID: 304101, Name: "轻功", JobClass: 4, Description: "提高移动速度和跳跃力", MaxLevel: 20, MPCost: 15, CoolDownMs: 10000, CreatedAt: time.Now()},
	}
	for i := range skills {
		if err := database.GetDB().FirstOrCreate(&skills[i], database.Skill{ID: skills[i].ID}).Error; err != nil {
			log.Printf("技能插入失败 id=%d: %v", skills[i].ID, err)
		}
	}
	fmt.Printf("✅ 技能数据初始化完成（共 %d 个）\n", len(skills))
}

// ==================== 任务数据（MapleStory 079 经典任务）====================
func seedQuests() {
	quests := []database.Quest{
		// 新手任务
		{ID: 400000, Name: "初来乍到", Description: "与彩虹村村长希娜对话", NPCID: 10100, LevelReq: 1, ExpReward: 15, MesosReward: 100, CreatedAt: time.Now()},
		{ID: 400001, Name: "击退蜗牛", Description: "击败 10 只蜗牛", NPCID: 10100, LevelReq: 1, ExpReward: 50, MesosReward: 300, ItemRewards: "240000", CreatedAt: time.Now()},
		{ID: 400002, Name: "蓝蜗牛的秘密", Description: "收集 5 个蓝蜗牛壳", NPCID: 10100, LevelReq: 3, ExpReward: 150, MesosReward: 500, ItemRewards: "240001,200000", CreatedAt: time.Now()},
		{ID: 400003, Name: "寻找露西娅", Description: "前往明珠港与露西娅对话", NPCID: 10200, LevelReq: 5, ExpReward: 200, MesosReward: 800, CreatedAt: time.Now()},
		{ID: 400004, Name: "长老斯坦的信", Description: "将长老斯坦的信送到射手村", NPCID: 10300, LevelReq: 8, ExpReward: 300, MesosReward: 1000, ItemRewards: "200301", CreatedAt: time.Now()},

		// 1转转职任务
		{ID: 400100, Name: "1转 - 战士", Description: "前往勇士部落找武术教练转职为战士", NPCID: 10501, LevelReq: 10, ExpReward: 1000, MesosReward: 5000, CreatedAt: time.Now()},
		{ID: 400101, Name: "1转 - 法师", Description: "前往魔法密林找魔法师教练转职为法师", NPCID: 10401, LevelReq: 10, ExpReward: 1000, MesosReward: 5000, CreatedAt: time.Now()},
		{ID: 400102, Name: "1转 - 弓箭手", Description: "前往射手村找赫丽娜转职为弓箭手", NPCID: 10301, LevelReq: 10, ExpReward: 1000, MesosReward: 5000, CreatedAt: time.Now()},
		{ID: 400103, Name: "1转 - 飞侠", Description: "前往废弃都市找达克鲁转职为飞侠", NPCID: 10600, LevelReq: 10, ExpReward: 1000, MesosReward: 5000, CreatedAt: time.Now()},
		{ID: 400104, Name: "1转 - 海盗", Description: "前往天空之城找凯琳转职为海盗", NPCID: 10800, LevelReq: 10, ExpReward: 1000, MesosReward: 5000, CreatedAt: time.Now()},

		// 2转任务
		{ID: 400200, Name: "2转 - 战士", Description: "完成2转战士转职任务", NPCID: 10501, LevelReq: 30, ExpReward: 5000, MesosReward: 20000, CreatedAt: time.Now()},
		{ID: 400201, Name: "2转 - 法师", Description: "完成2转法师转职任务", NPCID: 10401, LevelReq: 30, ExpReward: 5000, MesosReward: 20000, CreatedAt: time.Now()},
		{ID: 400202, Name: "2转 - 弓箭手", Description: "完成2转弓箭手转职任务", NPCID: 10301, LevelReq: 30, ExpReward: 5000, MesosReward: 20000, CreatedAt: time.Now()},
		{ID: 400203, Name: "2转 - 飞侠", Description: "完成2转飞侠转职任务", NPCID: 10600, LevelReq: 30, ExpReward: 5000, MesosReward: 20000, CreatedAt: time.Now()},
		{ID: 400204, Name: "2转 - 海盗", Description: "完成2转海盗转职任务", NPCID: 10800, LevelReq: 30, ExpReward: 5000, MesosReward: 20000, CreatedAt: time.Now()},

		// 中级任务
		{ID: 400300, Name: "猪猪牧场的危机", Description: "帮助猪猪牧场的主人", NPCID: 10300, LevelReq: 12, ExpReward: 800, MesosReward: 2000, ItemRewards: "240004", CreatedAt: time.Now()},
		{ID: 400301, Name: "蘑菇王的威胁", Description: "调查蘑菇王的领地", NPCID: 10700, LevelReq: 35, ExpReward: 3000, MesosReward: 15000, ItemRewards: "240006", CreatedAt: time.Now()},
		{ID: 400302, Name: "石头人的碎片", Description: "收集石头人的碎片", NPCID: 10700, LevelReq: 25, ExpReward: 2000, MesosReward: 8000, ItemRewards: "240007", CreatedAt: time.Now()},
	}
	for i := range quests {
		if err := database.GetDB().FirstOrCreate(&quests[i], database.Quest{ID: quests[i].ID}).Error; err != nil {
			log.Printf("任务插入失败 id=%d: %v", quests[i].ID, err)
		}
	}
	fmt.Printf("✅ 任务数据初始化完成（共 %d 个）\n", len(quests))
}

// ==================== 预览函数 ====================
func printSeedData() {
	lines := []string{
		"--- MapleStory 079 初始数据预览 ---",
		"地图(Map): 40+ 张 (彩虹村 / 明珠港 / 射手村 / 魔法密林 / 勇士部落 / 废弃都市 / 林中之城 / 冰峰雪域 / 天空之城 / 玩具城 / 训练场 / BOSS 地图)",
		"NPC: 30+ 个 (各职业转职教官 / 商店老板 / 村长)",
		"怪物(Mob): 30+ 种 (蜗牛 / 蘑菇 / 水灵 / 猪猪 / 野猪 / 石头人 / 冰独眼兽 / BOSS: 蘑菇王、扎昆树、皮亚努斯)",
		"物品(Item): 60+ 个 (药水 / 武器 / 防具 / 卷轴 / 任务道具)",
		"技能(Skill): 45+ 个 (五职业 1转 + 2转样例)",
		"任务(Quest): 15+ 个 (新手任务 / 1转任务 / 2转任务 / 中级任务)",
	}
	fmt.Println(strings.Join(lines, "\n"))
}
