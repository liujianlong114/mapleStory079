package database

import (
	"log"
	"time"

	"mapleStory079/pkg/utils"
)

// 本地测试用演示账号（FirstOrCreate，重复执行安全）
const (
	DemoUsername = "test"
	DemoPassword = "test123456" // 明文，入库时会 HashPassword
	DemoEmail    = "test@local.dev"
)

// seedDemoAccounts 创建可登录的演示账号与预设新手角色。
func seedDemoAccounts() (accountCount, characterCount int) {
	if DB == nil {
		return 0, 0
	}

	hashed := utils.HashPassword(DemoPassword)
	acc := Account{
		Username:  DemoUsername,
		Password:  hashed,
		Email:     DemoEmail,
		Gender:    0,
		Status:    1,
		LastLogin: time.Now(),
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	if err := DB.FirstOrCreate(&acc, Account{Username: DemoUsername}).Error; err != nil {
		log.Printf("[Seed] 演示账号创建失败: %v", err)
		return 0, 0
	}
	DB.Model(&acc).Updates(map[string]interface{}{
		"password": hashed,
		"status":   1,
		"email":    DemoEmail,
		"gender":   0,
	})
	accountCount = 1

	const startMap = utils.MapTutorialStart
	type seedChar struct {
		Character
		Top    int
		Bottom int
		Shoes  int
		Weapon int
	}
	chars := []seedChar{
		{
			Character: Character{
				AccountID: acc.ID,
				Name:      "冒险者一号",
				Class:     utils.JobBeginner,
				Gender:    0,
				Face:      20100,
				Hair:      30000,
				Skin:      0,
				Level:     1,
				Exp:       0,
				MapID:     startMap,
				PositionX: 400,
				PositionY: 605,
				HP:        50,
				MaxHP:     50,
				MP:        50,
				MaxMP:     50,
				STR:       12,
				DEX:       5,
				INT:       4,
				LUK:       4,
				Mesos:     500,
				CreatedAt: time.Now(),
				UpdatedAt: time.Now(),
			},
			Top: 1040002, Bottom: 1060002, Shoes: 1072001, Weapon: 1302000,
		},
		{
			Character: Character{
				AccountID: acc.ID,
				Name:      "见习法师",
				Class:     200,
				Gender:    1,
				Face:      21002,
				Hair:      31002,
				Skin:      0,
				Level:     15,
				Exp:       0,
				MapID:     startMap,
				PositionX: 500,
				PositionY: 605,
				HP:        50,
				MaxHP:     50,
				MP:        50,
				MaxMP:     50,
				STR:       12,
				DEX:       5,
				INT:       4,
				LUK:       4,
				Mesos:     500,
				CreatedAt: time.Now(),
				UpdatedAt: time.Now(),
			},
			Top: 1041002, Bottom: 1061002, Shoes: 1072001, Weapon: 1322005,
		},
		{
			Character: Character{
				AccountID: acc.ID,
				Name:      "剑士试炼",
				Class:     100,
				Gender:    0,
				Face:      20401,
				Hair:      30027,
				Skin:      0,
				Level:     20,
				Exp:       0,
				MapID:     startMap,
				PositionX: 600,
				PositionY: 605,
				HP:        50,
				MaxHP:     50,
				MP:        50,
				MaxMP:     50,
				STR:       12,
				DEX:       5,
				INT:       4,
				LUK:       4,
				Mesos:     500,
				CreatedAt: time.Now(),
				UpdatedAt: time.Now(),
			},
			Top: 1040006, Bottom: 1060006, Shoes: 1072005, Weapon: 1322005,
		},
	}

	for i := range chars {
		c := chars[i].Character
		if err := DB.FirstOrCreate(&c, Character{Name: c.Name}).Error; err != nil {
			log.Printf("[Seed] 演示角色创建失败 name=%s: %v", c.Name, err)
			continue
		}
		DB.Model(&c).Updates(map[string]interface{}{
			"account_id": acc.ID,
			"class":      chars[i].Class,
			"gender":     chars[i].Gender,
			"face":       chars[i].Face,
			"hair":       chars[i].Hair,
			"level":      chars[i].Level,
			"map_id":     startMap,
			"position_x": chars[i].PositionX,
			"position_y": chars[i].PositionY,
			"hp":         50,
			"max_hp":     50,
			"mp":         50,
			"max_mp":     50,
			"str":        12,
			"dex":        5,
			"int":        4,
			"luk":        4,
			"mesos":      500,
		})
		if err := seedDemoCharacterEquipment(c.ID, chars[i].Top, chars[i].Bottom, chars[i].Shoes, chars[i].Weapon); err != nil {
			log.Printf("[Seed] 演示角色装备写入失败 name=%s: %v", c.Name, err)
		}
		characterCount++
	}

	log.Printf("[Seed] 演示账号: 用户名=%s 密码=%s 新手角色数=%d", DemoUsername, DemoPassword, characterCount)
	return accountCount, characterCount
}

// seedDemoCharacterEquipment 为演示角色写入已穿戴装备（选角 API 的 top/bottom/shoes/weapon 来源）
func seedDemoCharacterEquipment(characterID uint, top, bottom, shoes, weapon int) error {
	if DB == nil || characterID == 0 {
		return nil
	}
	type equip struct {
		itemID int
		slot   string
		idx    int
	}
	for _, e := range []equip{
		{top, "coat", 1},
		{bottom, "pants", 2},
		{shoes, "shoes", 3},
		{weapon, "weapon", 4},
	} {
		if e.itemID == 0 {
			continue
		}
		row := CharacterInventory{
			CharacterID: characterID,
			ItemID:      e.itemID,
			SlotIndex:   e.idx,
			Quantity:    1,
			IsEquipped:  true,
			EquipSlot:   e.slot,
		}
		if err := DB.Where("character_id = ? AND equip_slot = ?", characterID, e.slot).
			Assign(row).
			FirstOrCreate(&row).Error; err != nil {
			return err
		}
	}
	return nil
}
