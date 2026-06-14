package database

import "fmt"

// TableCounts 各游戏数据表行数（用于健康检查与 init_data 验证）。
type TableCounts struct {
	Maps       int64
	Mobs       int64
	Items      int64
	Skills     int64
	Npcs       int64
	Quests     int64
	MobDrops   int64
	Accounts   int64
	Characters int64
}

// QueryTableCounts 统计当前库中关键表行数。
func QueryTableCounts() (TableCounts, error) {
	if DB == nil {
		return TableCounts{}, fmt.Errorf("database not initialized")
	}
	var c TableCounts
	models := []struct {
		ptr   interface{}
		count *int64
	}{
		{&Map{}, &c.Maps},
		{&Mob{}, &c.Mobs},
		{&Item{}, &c.Items},
		{&Skill{}, &c.Skills},
		{&NPC{}, &c.Npcs},
		{&Quest{}, &c.Quests},
		{&MobDrop{}, &c.MobDrops},
		{&Account{}, &c.Accounts},
		{&Character{}, &c.Characters},
	}
	for _, m := range models {
		if err := DB.Model(m.ptr).Count(m.count).Error; err != nil {
			return c, err
		}
	}
	return c, nil
}

// IsGameDataReady 判断核心游戏数据是否已填充（地图/怪物/技能非空）。
func IsGameDataReady() bool {
	c, err := QueryTableCounts()
	if err != nil {
		return false
	}
	return c.Maps > 0 && c.Mobs > 0 && c.Skills > 0 && c.Items > 0
}
