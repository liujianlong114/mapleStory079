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

func seedMaps() {
	maps := []database.Map{
		{ID: 1, Name: "南港", Description: "冒险开始的港口小镇", Width: 1600, Height: 900, Music: "south_henesys", CreatedAt: time.Now()},
		{ID: 2, Name: "训练场I", Description: "新手修炼场地", Width: 1400, Height: 800, Music: "training", CreatedAt: time.Now()},
		{ID: 3, Name: "蘑菇林", Description: "蘑菇怪物出没地", Width: 1800, Height: 900, Music: "mushroom_forest", CreatedAt: time.Now()},
	}
	for i := range maps {
		if err := database.GetDB().FirstOrCreate(&maps[i], database.Map{ID: maps[i].ID}).Error; err != nil {
			log.Printf("地图插入失败 id=%d: %v", maps[i].ID, err)
		}
	}
	fmt.Println("✅ 地图数据初始化完成")
}

func seedNPCs() {
	npcs := []database.NPC{
		{ID: 100, Name: "杂货商·陈", MapID: 1, PositionX: 500, PositionY: 400, Scripts: "general_store", HasShop: true, CreatedAt: time.Now()},
		{ID: 101, Name: "武器商·剑", MapID: 1, PositionX: 800, PositionY: 400, Scripts: "weapon_shop", HasShop: true, CreatedAt: time.Now()},
		{ID: 102, Name: "村长·吴", MapID: 1, PositionX: 1200, PositionY: 400, Scripts: "quest_giver", CreatedAt: time.Now()},
		{ID: 200, Name: "传送员·风", MapID: 1, PositionX: 1500, PositionY: 400, Scripts: "teleporter", CreatedAt: time.Now()},
	}
	for i := range npcs {
		if err := database.GetDB().FirstOrCreate(&npcs[i], database.NPC{ID: npcs[i].ID}).Error; err != nil {
			log.Printf("NPC 插入失败 id=%d: %v", npcs[i].ID, err)
		}
	}
	fmt.Println("✅ NPC 数据初始化完成")
}

func seedMobs() {
	mobs := []database.Mob{
		{ID: 100100, Name: "蜗牛", Level: 1, HP: 15, MaxHP: 15, PhysicalAttack: 5, PhysicalDefense: 0, MagicAttack: 3, MagicDefense: 1, Speed: 100, ExpReward: 3, MesosReward: 3, CreatedAt: time.Now()},
		{ID: 100200, Name: "蓝蜗牛", Level: 3, HP: 35, MaxHP: 35, PhysicalAttack: 8, PhysicalDefense: 2, MagicAttack: 4, MagicDefense: 1, Speed: 100, ExpReward: 8, MesosReward: 7, CreatedAt: time.Now()},
		{ID: 110100, Name: "蘑菇仔", Level: 5, HP: 60, MaxHP: 60, PhysicalAttack: 10, PhysicalDefense: 3, MagicAttack: 5, MagicDefense: 2, Speed: 100, ExpReward: 12, MesosReward: 10, CreatedAt: time.Now()},
		{ID: 120100, Name: "绿水灵", Level: 7, HP: 85, MaxHP: 85, PhysicalAttack: 12, PhysicalDefense: 4, MagicAttack: 6, MagicDefense: 2, Speed: 110, ExpReward: 18, MesosReward: 14, CreatedAt: time.Now()},
		{ID: 900100, Name: "大王蜗牛", Level: 30, HP: 5000, MaxHP: 5000, PhysicalAttack: 80, PhysicalDefense: 30, MagicAttack: 40, MagicDefense: 20, Speed: 120, ExpReward: 2000, MesosReward: 1250, CreatedAt: time.Now()},
	}
	for i := range mobs {
		if err := database.GetDB().FirstOrCreate(&mobs[i], database.Mob{ID: mobs[i].ID}).Error; err != nil {
			log.Printf("怪物插入失败 id=%d: %v", mobs[i].ID, err)
		}
	}
	fmt.Println("✅ 怪物数据初始化完成")
}

func seedItems() {
	items := []database.Item{
		{ID: 1000, Name: "苹果", Description: "恢复 50 HP", ItemType: 0, HPRecovery: 50, Price: 50, CreatedAt: time.Now()},
		{ID: 1001, Name: "蓝药水", Description: "恢复 50 MP", ItemType: 0, MPRecovery: 50, Price: 80, CreatedAt: time.Now()},
		{ID: 2000, Name: "新手之剑", Description: "攻击力+5", ItemType: 1, STR: 5, Price: 500, CreatedAt: time.Now()},
		{ID: 2001, Name: "皮甲", Description: "防御力+3", ItemType: 1, DEX: 3, Price: 400, CreatedAt: time.Now()},
		{ID: 3000, Name: "神秘卷轴", Description: "随机传送", ItemType: 2, Price: 200, CreatedAt: time.Now()},
	}
	for i := range items {
		if err := database.GetDB().FirstOrCreate(&items[i], database.Item{ID: items[i].ID}).Error; err != nil {
			log.Printf("物品插入失败 id=%d: %v", items[i].ID, err)
		}
	}
	fmt.Println("✅ 物品数据初始化完成")
}

func seedSkills() {
	skills := []database.Skill{
		{ID: 1, Name: "攻击力提升", JobClass: 1, Description: "被动增加物理攻击", IsPassive: true, MaxLevel: 20, CoolDownMs: 0, CreatedAt: time.Now()},
		{ID: 2, Name: "治愈术", JobClass: 2, Description: "恢复生命", MaxLevel: 30, MPCost: 10, CoolDownMs: 5000, DamageRatio: 0, CreatedAt: time.Now()},
		{ID: 3, Name: "飞箭", JobClass: 3, Description: "射出箭矢", MaxLevel: 20, MPCost: 5, CoolDownMs: 3000, DamageRatio: 2.0, CreatedAt: time.Now()},
		{ID: 4, Name: "分身术", JobClass: 4, Description: "召唤影子", MaxLevel: 15, MPCost: 20, CoolDownMs: 8000, DamageRatio: 1.5, CreatedAt: time.Now()},
		{ID: 5, Name: "百裂拳", JobClass: 5, Description: "快速连击", MaxLevel: 20, MPCost: 12, CoolDownMs: 4000, DamageRatio: 1.8, CreatedAt: time.Now()},
	}
	for i := range skills {
		if err := database.GetDB().FirstOrCreate(&skills[i], database.Skill{ID: skills[i].ID}).Error; err != nil {
			log.Printf("技能插入失败 id=%d: %v", skills[i].ID, err)
		}
	}
	fmt.Println("✅ 技能数据初始化完成")
}

func seedQuests() {
	quests := []database.Quest{
		{ID: 1, Name: "初来乍到", Description: "在南港与村长对话", LevelReq: 1, ExpReward: 15, MesosReward: 100, CreatedAt: time.Now()},
		{ID: 2, Name: "击退蜗牛", Description: "击败 10 只蜗牛", LevelReq: 2, ExpReward: 50, MesosReward: 300, CreatedAt: time.Now()},
		{ID: 3, Name: "蓝蜗牛的秘密", Description: "收集 5 个蓝蜗牛壳", LevelReq: 5, ExpReward: 150, MesosReward: 500, CreatedAt: time.Now()},
	}
	for i := range quests {
		if err := database.GetDB().FirstOrCreate(&quests[i], database.Quest{ID: quests[i].ID}).Error; err != nil {
			log.Printf("任务插入失败 id=%d: %v", quests[i].ID, err)
		}
	}
	fmt.Println("✅ 任务数据初始化完成")
}

func printSeedData() {
	lines := []string{
		"--- 地图 ---",
		"ID=1 南港, ID=2 训练场I, ID=3 蘑菇林",
		"--- 怪物 ---",
		"蜗牛 / 蓝蜗牛 / 蘑菇仔 / 绿水灵 / 大王蜗牛",
		"--- NPC ---",
		"杂货商·陈 / 武器商·剑 / 村长·吴 / 传送员·风",
	}
	fmt.Println(strings.Join(lines, "\n"))
}
