package repository

import (
	"mapleStory079/pkg/database"
)

type ItemRepository struct{}

func NewItemRepository() *ItemRepository {
	return &ItemRepository{}
}

func (r *ItemRepository) Create(item *database.Item) error {
	return database.DB.Create(item).Error
}

func (r *ItemRepository) FindByID(id uint) (*database.Item, error) {
	var item database.Item
	err := database.DB.Where("id = ?", id).First(&item).Error
	return &item, err
}

func (r *ItemRepository) FindByName(name string) (*database.Item, error) {
	var item database.Item
	err := database.DB.Where("name LIKE ?", "%"+name+"%").First(&item).Error
	return &item, err
}

func (r *ItemRepository) FindAll() ([]database.Item, error) {
	var items []database.Item
	err := database.DB.Find(&items).Error
	return items, err
}

func (r *ItemRepository) FindByItemType(itemType int) ([]database.Item, error) {
	var items []database.Item
	err := database.DB.Where("item_type = ?", itemType).Find(&items).Error
	return items, err
}

func (r *ItemRepository) FindByLevelReq(level int) ([]database.Item, error) {
	var items []database.Item
	err := database.DB.Where("level_req <= ?", level).Find(&items).Error
	return items, err
}

func (r *ItemRepository) Update(item *database.Item) error {
	return database.DB.Save(item).Error
}

func (r *ItemRepository) Delete(id uint) error {
	return database.DB.Delete(database.Item{}, id).Error
}

func (r *ItemRepository) Count() (int64, error) {
	var count int64
	err := database.DB.Model(&database.Item{}).Count(&count).Error
	return count, err
}

func (r *ItemRepository) Paginate(page, pageSize int) ([]database.Item, int64, error) {
	var items []database.Item
	var total int64
	if err := database.DB.Model(&database.Item{}).Count(&total).Error; err != nil {
		return items, total, err
	}
	offset := (page - 1) * pageSize
	err := database.DB.Offset(offset).Limit(pageSize).Find(&items).Error
	return items, total, err
}
