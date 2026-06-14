//go:build ignore

package main

import (
	"fmt"
	"log"
	"time"

	"mapleStory079/pkg/database"
)

func main() {
	if err := database.Init(); err != nil {
		log.Fatalf("Init err: %v", err)
	}
	database.DB.LogMode(true)
	fmt.Println(">>> 先查 maps 现有行数")
	var cnt int
	database.DB.Model(&database.Map{}).Count(&cnt)
	fmt.Printf("maps 当前行数: %d\n", cnt)

	fmt.Println(">>> 尝试 FirstOrCreate 一条测试")
	m := database.Map{
		ID:          99999,
		Name:        "测试地图",
		Description: "调试用",
		Width:       100,
		Height:      100,
		Music:       "bgm.test",
		CreatedAt:   time.Now(),
	}
	err := database.DB.FirstOrCreate(&m, database.Map{ID: 99999}).Error
	fmt.Printf("FirstOrCreate err=%v, 写入后的 m.ID=%d, m.Name=%q\n", err, m.ID, m.Name)

	fmt.Println(">>> 直接手动 INSERT 一条测试")
	m2 := database.Map{
		ID:          99998,
		Name:        "直接插入测试",
		Description: "调试用",
		CreatedAt:   time.Now(),
	}
	err = database.DB.Create(&m2).Error
	fmt.Printf("Create err=%v, m2.ID=%d\n", err, m2.ID)

	var cnt2 int
	database.DB.Model(&database.Map{}).Count(&cnt2)
	fmt.Printf(">>> 操作后 maps 行数: %d\n", cnt2)
}
