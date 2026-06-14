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
	var showHelp bool

	flag.StringVar(&configPath, "config", "", "配置文件路径")
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
	if configPath != "" {
		fmt.Printf("  配置文件: %s\n", configPath)
	}
	fmt.Printf("  重置模式: %t\n", reset)
	fmt.Println()

	if err := database.Init(); err != nil {
		log.Printf("数据库初始化失败: %v", err)
		fmt.Println()
		fmt.Println("⚠️  无法连接到数据库，以下是数据规模预览：")
		printSeedPreview()
		os.Exit(1)
	}

	if err := database.AutoMigrate(
		&database.Account{}, &database.Character{}, &database.CharacterStats{},
		&database.CharacterInventory{}, &database.Item{}, &database.Skill{},
		&database.Quest{}, &database.Map{}, &database.NPC{}, &database.Mob{},
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
	fmt.Printf("🎉 全部初始数据插入完成（技能 %d / 物品 %d / 地图 %d / NPC %d）\n",
		report.SkillCount, report.ItemCount, report.MapCount, report.NpcCount)
	fmt.Println("==============================================")
}

func printUsage() {
	fmt.Println("用法: init_data [options]")
	fmt.Println()
	flag.PrintDefaults()
}

func printSeedPreview() {
	fmt.Println("--- MapleStory 079 初始数据预览 ---")
	fmt.Println("地图: 45+ 张（含原版 MapID 100000000 系列）")
	fmt.Println("NPC: 35+ 个（含 1/2/3 转教官）")
	fmt.Println("怪物: 30+ 种")
	fmt.Println("物品: 50+ 个（含原版 ItemID 2000000 系列）")
	fmt.Println("技能: 190+ 个（五职业 1~3 转全技能）")
	fmt.Println("任务: 15+ 个")
}
