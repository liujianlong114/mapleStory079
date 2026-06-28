package main

import (
	"encoding/xml"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"mapleStory079/pkg/database"
)

// ==================== WZ XML 解析类型 ====================

type WzImgDir struct {
	XMLName  xml.Name   `xml:"imgdir"`
	Name     string     `xml:"name,attr"`
	ImgDirs  []WzImgDir `xml:"imgdir"`
	Ints     []WzInt    `xml:"int"`
	Strings  []WzString `xml:"string"`
	Floats   []WzFloat  `xml:"float"`
	Doubles  []WzDouble `xml:"double"`
	Canvases []WzCanvas `xml:"canvas"`
}

type WzInt struct {
	Name  string `xml:"name,attr"`
	Value int    `xml:"value,attr"`
}

type WzString struct {
	Name  string `xml:"name,attr"`
	Value string `xml:"value,attr"`
}

type WzFloat struct {
	Name  string  `xml:"name,attr"`
	Value float64 `xml:"value,attr"`
}

type WzDouble struct {
	Name  string  `xml:"name,attr"`
	Value float64 `xml:"value,attr"`
}

type WzCanvas struct {
	Name    string     `xml:"name,attr"`
	Width   int        `xml:"width,attr"`
	Height  int        `xml:"height,attr"`
	Vectors []WzVector `xml:"vector"`
}

type WzVector struct {
	Name string `xml:"name,attr"`
	X    int    `xml:"x,attr"`
	Y    int    `xml:"y,attr"`
}

// ==================== 路径配置 ====================

var wzRoot = "/Users/lijianjun/GolandProjects/mapleStory079-external/02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML/wz"

// ==================== 主入口 ====================

func autoMigrate() {
	fmt.Println("\n--- 数据库表迁移 ---")
	models := []interface{}{
		&database.Item{},
		&database.Mob{},
		&database.Skill{},
		&database.MobDrop{},
		&database.NPC{},
	}
	for _, m := range models {
		if err := database.GetDB().AutoMigrate(m).Error; err != nil {
			log.Printf("  [warn] 迁移失败: %v", err)
		}
	}
	fmt.Println("  ✓ 表迁移完成")
}

func main() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)
	fmt.Println("==============================================")
	fmt.Println(" MapleStory 079 WZ 数据导入工具")
	fmt.Println("==============================================")

	if err := database.LoadConfig(""); err != nil {
		log.Fatalf("数据库配置加载失败: %v", err)
	}
	if err := database.Init(); err != nil {
		log.Fatalf("数据库连接失败: %v", err)
	}
	defer database.Close()
	fmt.Println("✓ 数据库连接成功")

	// 自动迁移表结构
	autoMigrate()

	// 检查 WZ 根目录
	if _, err := os.Stat(wzRoot); os.IsNotExist(err) {
		log.Fatalf("WZ 根目录不存在: %s", wzRoot)
	}

	// 导入物品
	itemCount := importItems()
	fmt.Printf("\n✓ 物品导入完成: %d 条\n", itemCount)

	// 导入怪物
	mobCount := importMobs()
	fmt.Printf("✓ 怪物导入完成: %d 条\n", mobCount)

	// 导入技能
	skillCount := importSkills()
	fmt.Printf("✓ 技能导入完成: %d 条\n", skillCount)

	// 导入 NPC 名称
	npcCount := importNPCNames()
	fmt.Printf("✓ NPC名称导入完成: %d 条\n", npcCount)

	fmt.Println("\n==============================================")
	fmt.Println(" 导入完成！")
	fmt.Println("==============================================")
}


// ==================== 工具函数 ====================

func parseWZFile(path string) (*WzImgDir, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var root WzImgDir
	if err := xml.Unmarshal(data, &root); err != nil {
		return nil, fmt.Errorf("解析 %s 失败: %w", path, err)
	}
	return &root, nil
}

func getInt(dir *WzImgDir, name string, defaultVal int) int {
	if dir == nil {
		return defaultVal
	}
	for _, v := range dir.Ints {
		if v.Name == name {
			return v.Value
		}
	}
	for _, sub := range dir.ImgDirs {
		for _, v := range sub.Ints {
			if v.Name == name {
				return v.Value
			}
		}
	}
	return defaultVal
}

func getStringValue(dir *WzImgDir, name string) string {
	if dir == nil {
		return ""
	}
	for _, v := range dir.Strings {
		if v.Name == name {
			return v.Value
		}
	}
	return ""
}

func findImgDir(dir *WzImgDir, name string) *WzImgDir {
	if dir == nil {
		return nil
	}
	for i := range dir.ImgDirs {
		if dir.ImgDirs[i].Name == name {
			return &dir.ImgDirs[i]
		}
	}
	return nil
}

func toItemID(paddedID string) int {
	id, err := strconv.Atoi(paddedID)
	if err != nil {
		return 0
	}
	return id
}

func parseID(filename string) int {
	name := strings.TrimSuffix(filename, ".img.xml")
	id, err := strconv.Atoi(name)
	if err != nil {
		return 0
	}
	return id
}

// ==================== String.wz 加载 ====================

type StringMap map[int]StringEntry

type StringEntry struct {
	Name string
	Desc string
}

func loadStringWz(fileName string) StringMap {
	result := make(StringMap)
	path := filepath.Join(wzRoot, "String.wz", fileName)
	root, err := parseWZFile(path)
	if err != nil {
		log.Printf("  [warn] String.wz/%s 不可用: %v", fileName, err)
		return result
	}
	for _, item := range root.ImgDirs {
		id, err := strconv.Atoi(item.Name)
		if err != nil {
			continue
		}
		entry := StringEntry{
			Name: getStringValue(&item, "name"),
			Desc: getStringValue(&item, "desc"),
		}
		if entry.Name != "" {
			result[id] = entry
		}
	}
	fmt.Printf("  String.wz/%s: %d 条目\n", fileName, len(result))
	return result
}

// ==================== 物品导入 ====================

func importItems() int {
	fmt.Println("\n--- 导入物品 ---")

	consumeNames := loadStringWz("Consume.img.xml")
	eqpNames := loadStringWz("Eqp.img.xml")
	etcNames := loadStringWz("Etc.img.xml")
	insNames := loadStringWz("Ins.img.xml")
	cashNames := loadStringWz("Cash.img.xml")
	petNames := loadStringWz("Pet.img.xml")

	allNames := make(StringMap)
	for k, v := range consumeNames {
		allNames[k] = v
	}
	for k, v := range eqpNames {
		allNames[k] = v
	}
	for k, v := range etcNames {
		allNames[k] = v
	}
	for k, v := range insNames {
		allNames[k] = v
	}
	for k, v := range cashNames {
		allNames[k] = v
	}
	for k, v := range petNames {
		allNames[k] = v
	}

	itemWzDir := filepath.Join(wzRoot, "Item.wz")
	count := 0
	catCounts := map[string]int{}

	subDirs := []string{"Consume", "Install", "Cash", "Etc", "Special", "Pet"}
	for _, sub := range subDirs {
		subPath := filepath.Join(itemWzDir, sub)
		entries, err := os.ReadDir(subPath)
		if err != nil {
			log.Printf("  [warn] Item.wz/%s 不可用: %v", sub, err)
			continue
		}
		for _, e := range entries {
			if !strings.HasSuffix(e.Name(), ".img.xml") {
				continue
			}
			n := parseItemFile(filepath.Join(subPath, e.Name()), sub, allNames)
			count += n
			catCounts[sub] += n
		}
	}

	for cat, n := range catCounts {
		fmt.Printf("  %s: %d\n", cat, n)
	}
	return count
}

func parseItemFile(path, category string, names StringMap) int {
	root, err := parseWZFile(path)
	if err != nil {
		log.Printf("  [warn] 解析 %s 失败: %v", path, err)
		return 0
	}
	count := 0
	for _, item := range root.ImgDirs {
		itemID := toItemID(item.Name)
		if itemID <= 0 {
			continue
		}

		info := findImgDir(&item, "info")
		if info == nil {
			continue
		}

		entry, _ := names[itemID]
		itemName := entry.Name
		if itemName == "" {
			continue // 跳过无名称物品（非游戏用数据）
		}

		itemType := 0
		switch category {
		case "Consume":
			itemType = 0
		case "Install":
			itemType = 2
		case "Cash":
			itemType = 3
		case "Etc":
			itemType = 2
		case "Special":
			itemType = 2
		case "Pet":
			itemType = 3
		}

		price := getInt(info, "price", 0)
		slotMax := getInt(info, "slotMax", 100)
		levelReq := getInt(info, "reqLevel", 0)
		hpRec := getInt(info, "hp", 0)
		mpRec := getInt(info, "mp", 0)

		str := getInt(info, "incSTR", 0)
		dex := getInt(info, "incDEX", 0)
		intel := getInt(info, "incINT", 0)
		luk := getInt(info, "incLUK", 0)
		pad := getInt(info, "incPAD", 0)
		mad := getInt(info, "incMAD", 0)
		pdd := getInt(info, "incPDD", 0)
		mdd := getInt(info, "incMDD", 0)

		// Try spec subdir for potion data
		if hpRec == 0 && mpRec == 0 {
			spec := findImgDir(&item, "spec")
			if spec != nil {
				hpRec = getInt(spec, "hp", 0)
				mpRec = getInt(spec, "mp", 0)
			}
		}

		// Also check for consume item specific HP/MP in info
		if hpRec == 0 {
			hpRec = getInt(info, "hp", 0)
		}
		if mpRec == 0 {
			mpRec = getInt(info, "mp", 0)
		}

		cash := getInt(info, "cash", 0)
		tradeBlock := getInt(info, "tradeBlock", 0)

		desc := entry.Desc

		item := database.Item{
			ID:          uint(itemID),
			Name:        itemName,
			Description: desc,
			ItemType:    itemType,
			Price:       price,
			LevelReq:    levelReq,
			STR:         str,
			DEX:         dex,
			INT:         intel,
			LUK:         luk,
			HPRecovery:  hpRec,
			MPRecovery:  mpRec,
			PAD:         pad,
			MAD:         mad,
			PDD:         pdd,
			MDD:         mdd,
			SlotMax:     slotMax,
			Cash:        cash,
			TradeBlock:  tradeBlock,
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
		}

		if err := database.GetDB().Save(&item).Error; err != nil {
			log.Printf("  [warn] 插入物品 %d (%s) 失败: %v", itemID, itemName, err)
			continue
		}
		count++
	}
	return count
}

// ==================== 怪物导入 ====================

func importMobs() int {
	fmt.Println("\n--- 导入怪物 ---")

	mobNames := loadStringWz("Mob.img.xml")

	mobWzDir := filepath.Join(wzRoot, "Mob.wz")
	entries, err := os.ReadDir(mobWzDir)
	if err != nil {
		log.Fatalf("Mob.wz 不可用: %v", err)
	}

	count := 0
	for _, e := range entries {
		if !strings.HasSuffix(e.Name(), ".img.xml") {
			continue
		}
		mobID := parseID(e.Name())
		if mobID <= 0 {
			continue
		}

		root, err := parseWZFile(filepath.Join(mobWzDir, e.Name()))
		if err != nil {
			continue
		}

		info := findImgDir(root, "info")
		if info == nil {
			continue
		}

		name := ""
		if entry, ok := mobNames[mobID]; ok {
			name = entry.Name
		}
		if name == "" {
			continue // 跳过无名称的怪物
		}

		level := getInt(info, "level", 1)
		maxHP := getInt(info, "maxHP", 10)
		maxMP := getInt(info, "maxMP", 0)
		pad := getInt(info, "PADamage", 0)
		mad := getInt(info, "MADamage", 0)
		pdd := getInt(info, "PDDamage", 0)
		mdd := getInt(info, "MDDamage", 0)
		acc := getInt(info, "acc", 20)
		eva := getInt(info, "eva", 10)
		expVal := getInt(info, "exp", 0)
		speed := getInt(info, "speed", 0)

		isBoss := getInt(info, "boss", 0)
		if isBoss > 0 && expVal > 0 {
			expVal *= 2
		}

		mob := database.Mob{
			ID:              uint(mobID),
			Name:            name,
			Level:           level,
			HP:              maxHP,
			MaxHP:           maxHP,
			MP:              maxMP,
			PhysicalAttack:  pad,
			MagicAttack:     mad,
			PhysicalDefense: pdd,
			MagicDefense:    mdd,
			Acc:             acc,
			Eva:             eva,
			ExpReward:       expVal,
			MesosReward:     level * 2,
			Speed:           speed,
			IsBoss:          isBoss > 0,
			CreatedAt:       time.Now(),
		}
		if err := database.GetDB().Save(&mob).Error; err != nil {
			log.Printf("  [warn] 插入怪物 %d (%s) 失败: %v", mobID, name, err)
			continue
		}
		count++
	}
	return count
}

// ==================== 技能导入 ====================

func importSkills() int {
	fmt.Println("\n--- 导入技能 ---")

	skillNames := loadStringWz("Skill.img.xml")

	skillWzDir := filepath.Join(wzRoot, "Skill.wz")
	entries, err := os.ReadDir(skillWzDir)
	if err != nil {
		log.Printf("  [warn] Skill.wz 不可用: %v", err)
		return 0
	}

	count := 0
	for _, e := range entries {
		if !strings.HasSuffix(e.Name(), ".img.xml") {
			continue
		}

		root, err := parseWZFile(filepath.Join(skillWzDir, e.Name()))
		if err != nil {
			continue
		}

		skill := findImgDir(root, "skill")
		if skill == nil {
			continue
		}

		for _, sk := range skill.ImgDirs {
			skillID, err := strconv.Atoi(sk.Name)
			if err != nil {
				continue
			}
			if skillID <= 0 {
				continue
			}

			name := ""
			if entry, ok := skillNames[skillID]; ok {
				name = entry.Name
			}
			if name == "" {
				continue
			}

			levelDir := findImgDir(&sk, "level")
			if levelDir == nil {
				continue
			}

			maxLevel := len(levelDir.ImgDirs)
			if maxLevel <= 0 {
				maxLevel = 1
			}

			lv1 := findImgDir(levelDir, "1")
			if lv1 == nil && len(levelDir.ImgDirs) > 0 {
				lv1 = &levelDir.ImgDirs[0]
			}

			hpCon := 0
			mpCon := 0
			damage := 0
			if lv1 != nil {
				hpCon = getInt(lv1, "hpCon", 0)
				mpCon = getInt(lv1, "mpCon", 0)
				damage = getInt(lv1, "damage", 0)
				if damage == 0 {
					damage = getInt(lv1, "x", 0)
				}
			}

			jobClass := inferJobFromSkillID(skillID)

			coolTime := 0
			skInfo := findImgDir(&sk, "info")
			if skInfo != nil {
				coolTime = getInt(skInfo, "cooltime", 0)
			}

			skill := database.Skill{
				ID:          uint(skillID),
				Name:        name,
				JobClass:    jobClass,
				MaxLevel:    maxLevel,
				MPCost:      mpCon,
				HPCost:      hpCon,
				DamageRatio: float64(damage),
				CoolDownMs:  coolTime * 1000,
				CreatedAt:   time.Now(),
				UpdatedAt:   time.Now(),
			}
			if err := database.GetDB().Save(&skill).Error; err != nil {
				log.Printf("  [warn] 插入技能 %d (%s) 失败: %v", skillID, name, err)
				continue
			}
			count++
		}
	}
	return count
}

func inferJobFromSkillID(skillID int) int {
	classBase := skillID / 10000
	classMap := map[int]int{
		10: 100, 11: 110, 12: 120,
		20: 200, 21: 210, 22: 220, 23: 230,
		30: 300, 31: 310, 32: 320,
		40: 400, 41: 410, 42: 420,
		50: 500, 51: 510, 52: 520,
		111: 1110, 112: 1120,
		121: 1210, 122: 1220,
		131: 1310, 132: 1320,
		211: 2110, 212: 2120,
		221: 2210, 222: 2220,
		231: 2310, 232: 2320,
		311: 3110, 312: 3120,
		321: 3210, 322: 3220,
		411: 4110, 412: 4110,
		421: 4210, 422: 4220,
		511: 5110, 512: 5120,
		521: 5210, 522: 5220,
	}
	if j, ok := classMap[classBase]; ok {
		return j
	}
	return 0
}

// ==================== NPC 名称导入 ====================

func importNPCNames() int {
	fmt.Println("\n--- 导入NPC名称 ---")

	npcNames := loadStringWz("Npc.img.xml")
	count := 0

	for npcID, entry := range npcNames {
		var npc database.NPC
		result := database.GetDB().Where("id = ?", npcID).First(&npc)
		if result.Error != nil {
			npc = database.NPC{
				ID:          uint(npcID),
				Name:        entry.Name,
				Description: entry.Desc,
				CreatedAt:   time.Now(),
			}
			if err := database.GetDB().Create(&npc).Error; err != nil {
				continue
			}
			count++
		} else if npc.Name == "" || npc.Name == fmt.Sprintf("NPC_%d", npcID) {
			npc.Name = entry.Name
			npc.Description = entry.Desc
			database.GetDB().Save(&npc)
			count++
		}
	}
	return count
}
