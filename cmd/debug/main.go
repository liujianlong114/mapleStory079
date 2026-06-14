package main

import (
	"fmt"
	"log"
	"time"

	"mapleStory079/pkg/database"
)

// 独立调试程序：直接跑来看 GORM 真实 SQL
func main() {
	if err := database.Init(); err != nil {
		log.Fatalf("Init err: %v", err)
	}
	database.DB.LogMode(true)

	fmt.Println("=== 先查每张表当前行数 ===")
	tables := []string{"maps", "npcs", "mobs", "items", "skills", "quests"}
	for _, t := range tables {
		var n int
		database.DB.Table(t).Count(&n)
		fmt.Printf("  %s = %d\n", t, n)
	}

	fmt.Println("\n=== 测试 1: 直接 Create 一条 map (id=77777 ===")
	m1 := database.Map{
		ID:          77777,
		Name:        "调试地图A",
		Description: "直接Create",
		Width:       1000, Height: 500,
		Music:     "bgm.debug",
		CreatedAt: time.Now(),
	}
	if err := database.DB.Create(&m1).Error; err != nil {
		fmt.Printf("  Create 失败: %v\n", err)
	} else {
		fmt.Printf("  Create 成功, 结果 m1.ID=%d\n", m1.ID)
	}

	fmt.Println("\n=== 测试 2: FirstOrCreate 一条 map id=88888 ===")
	m2 := database.Map{
		ID:          88888,
		Name:        "调试地图B",
		Description: "FirstOrCreate",
		Width:       1000, Height: 500,
		Music:     "bgm.debug",
		CreatedAt: time.Now(),
	}
	if err := database.DB.FirstOrCreate(&m2, database.Map{ID: 88888}).Error; err != nil {
		fmt.Printf("  FirstOrCreate 失败: %v\n", err)
	} else {
		fmt.Printf("  FirstOrCreate 完成, m2.ID=%d, m2.Name=%q\n", m2.ID, m2.Name)
	}

	fmt.Println("\n=== 测试 3: FirstOrCreate 已存在的 id=77777 ===")
	m3 := database.Map{
		ID:          77777,
		Name:        "调试地图A-updated",
		Description: "FirstOrCreate 已存在",
		Width:       1000, Height: 500,
		Music:     "bgm.debug",
		CreatedAt: time.Now(),
	}
	if err := database.DB.FirstOrCreate(&m3, database.Map{ID: 77777}).Error; err != nil {
		fmt.Printf("  FirstOrCreate(已存在) 失败: %v\n", err)
	} else {
		fmt.Printf("  FirstOrCreate(已存在) 完成, m3.ID=%d, m3.Name=%q\n", m3.ID, m3.Name)
	}

	fmt.Println("\n=== 最终 counts ===")
	var n int
	database.DB.Table("maps").Count(&n)
	fmt.Printf("  maps 总数: %d\n", n)
	fmt.Println("\n=== 清掉调试数据 ===")
	database.DB.Exec("DELETE FROM maps WHERE id IN (77777, 88888)")
}
