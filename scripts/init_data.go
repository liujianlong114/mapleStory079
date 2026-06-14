package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"mapleStory079/pkg/database"
)

// init_data 工具：向数据库插入 MapleStory 079 初始数据。
func main() {
	var configPath string
	var reset bool
	var verifyOnly bool
	var showHelp bool

	flag.StringVar(&configPath, "config", "", "配置文件路径（默认 config/config.yaml）")
	flag.BoolVar(&reset, "reset", false, "清空已有游戏数据后重新插入")
	flag.BoolVar(&verifyOnly, "verify", false, "仅验证数据库连接与行数，不写入")
	flag.BoolVar(&showHelp, "help", false, "显示帮助信息")
	flag.Parse()

	if showHelp {
		printUsage()
		return
	}

	fmt.Println("==============================================")
	fmt.Println(" MapleStory 079 - 数据初始化工具")
	fmt.Println("==============================================")

	if err := database.LoadConfig(configPath); err != nil {
		log.Fatalf("❌ 无法读取配置: %v\n   请确认 config/config.yaml 存在，或用 -config 指定路径", err)
	}
	fmt.Printf("  数据库: %s\n", database.DSNInfo())
	fmt.Printf("  重置模式: %t\n", reset)
	fmt.Printf("  仅验证: %t\n", verifyOnly)
	fmt.Println()

	if err := database.Init(); err != nil {
		log.Printf("❌ 数据库连接失败: %v", err)
		fmt.Println()
		fmt.Println("请检查：")
		fmt.Println("  1. MySQL 是否已启动")
		fmt.Println("  2. config/config.yaml 中 host/port/user/password/database 是否正确")
		fmt.Println("  3. 是否已创建数据库: CREATE DATABASE maplestory CHARACTER SET utf8mb4;")
		os.Exit(1)
	}
	defer database.Close()

	if verifyOnly {
		printCounts("当前数据库状态")
		if database.IsGameDataReady() {
			fmt.Println("✅ 游戏数据已就绪")
		} else {
			fmt.Println("⚠️  游戏数据不完整，请运行: go run scripts/init_data.go")
			os.Exit(1)
		}
		return
	}

	if err := database.AutoMigrate(
		&database.Account{}, &database.Character{}, &database.CharacterStats{},
		&database.CharacterInventory{}, &database.Item{}, &database.Skill{},
		&database.Quest{}, &database.CharacterQuest{}, &database.Map{}, &database.NPC{}, &database.Mob{}, &database.MobDrop{},
		&database.Guild{}, &database.Party{}, &database.Friend{},
		&database.LoginLog{}, &database.TradeLog{}, &database.ChatLog{},
	); err != nil {
		log.Fatalf("自动迁移失败: %v", err)
	}
	fmt.Println("✅ 数据表迁移完成")

	if reset {
		fmt.Println("🧹 执行 --reset：清空已有游戏数据")
		database.TruncateSeedTables()
	}

	report, err := database.SeedDefaultData()
	if err != nil {
		log.Fatalf("种子数据填充失败: %v", err)
	}

	fmt.Println()
	fmt.Printf("🎉 全部初始数据插入完成\n")
	fmt.Printf("   地图 %d | NPC %d | 怪物 %d | 物品 %d | 技能 %d | 任务 %d | 掉落 %d\n",
		report.MapCount, report.NpcCount, report.MobCount, report.ItemCount, report.SkillCount, report.QuestCount, report.DropCount)
	fmt.Printf("   演示账号 %d | 演示角色 %d\n", report.AccountCount, report.CharacterCount)
	printCounts("验证结果")
	fmt.Println()
	fmt.Println("📌 测试登录账号:")
	fmt.Printf("   用户名: %s\n", database.DemoUsername)
	fmt.Printf("   密码:   %s\n", database.DemoPassword)
	fmt.Println("📌 验证命令:")
	fmt.Println("   curl http://localhost:8080/health")
	fmt.Println("   go run scripts/init_data.go --verify")
	fmt.Println("==============================================")
}

func printCounts(title string) {
	c, err := database.QueryTableCounts()
	if err != nil {
		fmt.Printf("⚠️  %s: 无法统计 — %v\n", title, err)
		return
	}
	fmt.Printf("\n--- %s ---\n", title)
	fmt.Printf("  maps=%d mobs=%d items=%d skills=%d npcs=%d quests=%d drops=%d accounts=%d characters=%d\n",
		c.Maps, c.Mobs, c.Items, c.Skills, c.Npcs, c.Quests, c.MobDrops, c.Accounts, c.Characters)
}

func printUsage() {
	fmt.Println("用法: go run scripts/init_data.go [options]")
	fmt.Println()
	fmt.Println("选项:")
	fmt.Println("  -config path   指定 config.yaml")
	fmt.Println("  -reset         清空游戏表后重新种子")
	fmt.Println("  -verify        只检查连接与行数")
	fmt.Println("  -help          显示帮助")
}
