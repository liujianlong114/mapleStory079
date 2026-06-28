package service

import (
	"errors"
	"fmt"
	"time"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
)

// CashShopItemResponse 商城物品响应
type CashShopItemResponse struct {
	ID          uint   `json:"id"`
	ItemID      int    `json:"item_id"`
	Name        string `json:"name"`
	Desc        string `json:"desc"`
	Category    string `json:"category"`
	Price       int    `json:"price"`       // 枫叶点价格
	PriceMesos  int64  `json:"price_mesos"` // 金币价格
	Stock       int    `json:"stock"`
	IsFeatured  bool   `json:"is_featured"`
	IsNew       bool   `json:"is_new"`
	IsOnSale    bool   `json:"is_on_sale"`
	SalePrice   int    `json:"sale_price"`
	Icon        string `json:"icon"`
	LevelReq    int    `json:"level_req"`
}

type CashShopService struct {
	inv *InventoryService
}

func NewCashShopService() *CashShopService {
	return &CashShopService{inv: NewInventoryService()}
}

// ListItems 获取商城物品列表
func (s *CashShopService) ListItems(category string, characterID uint) ([]CashShopItemResponse, error) {
	var items []database.CashShopItem
	query := database.GetDB()
	if category != "" && category != "all" {
		query = query.Where("category = ?", category)
	}
	if err := query.Order("is_featured DESC, id ASC").Find(&items).Error; err != nil {
		return nil, err
	}

	// 如果没有商城数据，则自动生成
	if len(items) == 0 {
		s.SeedItems()
		query = database.GetDB()
		if category != "" && category != "all" {
			query = query.Where("category = ?", category)
		}
		query.Order("is_featured DESC, id ASC").Find(&items)
	}

	result := make([]CashShopItemResponse, 0, len(items))
	for _, item := range items {
		var itemData database.Item
		if err := database.GetDB().First(&itemData, item.ItemID).Error; err != nil {
			continue
		}
		resp := CashShopItemResponse{
			ID:         item.ID,
			ItemID:     item.ItemID,
			Name:       itemData.Name,
			Desc:       itemData.Description,
			Category:   item.Category,
			Price:      item.Price,
			PriceMesos: item.PriceMesos,
			Stock:      item.Stock,
			IsFeatured: item.IsFeatured,
			IsNew:      item.IsNew,
			IsOnSale:   item.IsOnSale,
			SalePrice:  item.SalePrice,
			LevelReq:   itemData.LevelReq,
		}
		result = append(result, resp)
	}
	return result, nil
}

// Purchase 购买商城物品
func (s *CashShopService) Purchase(characterID uint, shopItemID uint, quantity int) error {
	if quantity < 1 {
		quantity = 1
	}

	var shopItem database.CashShopItem
	if err := database.GetDB().First(&shopItem, shopItemID).Error; err != nil {
		return errors.New("商城物品不存在")
	}

	character, err := repository.GetCharacterByID(characterID)
	if err != nil {
		return errors.New("角色不存在")
	}

	totalPoints := shopItem.Price * quantity
	totalMesos := shopItem.PriceMesos * int64(quantity)

	// 检查枫叶点
	if character.MaplePoints < totalPoints {
		return fmt.Errorf("枫叶点不足，需要 %d，当前 %d", totalPoints, character.MaplePoints)
	}

	// 检查金币
	if shopItem.PriceMesos > 0 && character.Mesos < int(totalMesos) {
		return fmt.Errorf("金币不足，需要 %d，当前 %d", totalMesos, character.Mesos)
	}

	// 检查库存
	if shopItem.Stock >= 0 && shopItem.Stock < quantity {
		return fmt.Errorf("库存不足，剩余 %d", shopItem.Stock)
	}

	// 扣款
	newPoints := character.MaplePoints - totalPoints
	newMesos := character.Mesos - int(totalMesos)
	if newMesos < 0 {
		newMesos = 0
	}

	// 扣库存
	if shopItem.Stock >= 0 {
		shopItem.Stock -= quantity
		database.GetDB().Save(&shopItem)
	}

	// 更新角色枫叶点
	repository.UpdateCharacterStats(characterID, map[string]interface{}{
		"maple_points": newPoints,
		"mesos":        newMesos,
	})

	// 发放物品
	if err := s.inv.AddItem(characterID, shopItem.ItemID, quantity); err != nil {
		return err
	}

	// 记录购买
	purchase := database.CashShopPurchase{
		CharacterID: characterID,
		ItemID:      shopItem.ItemID,
		Price:       totalPoints,
		PriceMesos:  totalMesos,
		Quantity:    quantity,
		CreatedAt:   time.Now(),
	}
	database.GetDB().Create(&purchase)

	return nil
}

// GetBalance 获取枫叶点余额
func (s *CashShopService) GetBalance(characterID uint) (int, error) {
	character, err := repository.GetCharacterByID(characterID)
	if err != nil {
		return 0, err
	}
	return character.MaplePoints, nil
}

// AddPoints 增加枫叶点（管理员/GM功能）
func (s *CashShopService) AddPoints(characterID uint, points int) error {
	if points <= 0 {
		return errors.New("点数必须为正数")
	}
	return repository.UpdateCharacterStats(characterID, map[string]interface{}{
		"maple_points": database.GetDB().Raw("maple_points + ?", points),
	})
}

// SeedItems 初始化商城数据（基于已导入的 Cash 类物品）
func (s *CashShopService) SeedItems() {
	var count int64
	database.GetDB().Model(&database.CashShopItem{}).Count(&count)
	if count > 0 {
		return // 已有数据，跳过
	}

	var cashItems []database.Item
	database.GetDB().Where("item_type = 3 OR cash = 1").Find(&cashItems)

	if len(cashItems) == 0 {
		// 如果还没有 Cash 物品，从 items 表选取部分物品
		database.GetDB().Where("item_type IN (0, 1)").Limit(50).Find(&cashItems)
	}

	for i, item := range cashItems {
		cat := "equip"
		switch item.ItemType {
		case 0:
			cat = "use"
		case 1:
			cat = "equip"
		case 2:
			cat = "etc"
		case 3:
			cat = "cash"
		}

		price := 100 + (i % 5) * 50  // 枫叶点价格
		priceMesos := int64(item.Price) // 金币价格

		csItem := database.CashShopItem{
			ItemID:      int(item.ID),
			Category:    cat,
			Price:       price,
			PriceMesos:  priceMesos,
			Stock:       -1, // 无限
			IsFeatured:  i < 10,
			IsNew:       i < 20,
			IsOnSale:    false,
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
		}
		database.GetDB().Create(&csItem)
	}
}
