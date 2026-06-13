package repository

import (
	"mapleStory079/pkg/database"
)

type AccountRepository struct{}

func (r *AccountRepository) Create(account *database.Account) error {
	return database.DB.Create(account).Error
}

func (r *AccountRepository) FindByUsername(username string) (*database.Account, error) {
	var account database.Account
	err := database.DB.Where("username = ?", username).First(&account).Error
	return &account, err
}

func (r *AccountRepository) FindByID(id uint) (*database.Account, error) {
	var account database.Account
	err := database.DB.Where("id = ?", id).First(&account).Error
	return &account, err
}

func (r *AccountRepository) Update(account *database.Account) error {
	return database.DB.Save(account).Error
}

func (r *AccountRepository) Delete(id uint) error {
	return database.DB.Delete(&database.Account{}, id).Error
}
