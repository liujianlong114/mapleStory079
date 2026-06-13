package service

import (
	"errors"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
	"mapleStory079/pkg/utils"
)

type AuthService struct {
	accountRepo *AccountRepository
}

// AccountRepository 用于与数据库 Account 交互。
type AccountRepository struct{}

func (a *AccountRepository) Create(acc *database.Account) error {
	return database.GetDB().Create(acc).Error
}

func (a *AccountRepository) FindByUsername(username string) (*database.Account, error) {
	var acc database.Account
	err := database.GetDB().Where("username = ?", username).First(&acc).Error
	if err != nil {
		return nil, err
	}
	return &acc, nil
}

func (a *AccountRepository) FindByID(id uint) (*database.Account, error) {
	var acc database.Account
	err := database.GetDB().First(&acc, id).Error
	if err != nil {
		return nil, err
	}
	return &acc, nil
}

func (a *AccountRepository) Update(acc *database.Account) error {
	return database.GetDB().Save(acc).Error
}

func NewAuthService() *AuthService {
	return &AuthService{accountRepo: &AccountRepository{}}
}

func (s *AuthService) Register(username, password, email string) error {
	if _, err := s.accountRepo.FindByUsername(username); err == nil {
		return errors.New("username already exists")
	}
	account := &database.Account{
		Username: username,
		Password: utils.HashPassword(password),
		Email:    email,
		Status:   1,
	}
	return s.accountRepo.Create(account)
}

func (s *AuthService) Login(username, password string) (*database.Account, error) {
	account, err := s.accountRepo.FindByUsername(username)
	if err != nil {
		return nil, errors.New("invalid username or password")
	}
	if account.Password != utils.HashPassword(password) {
		return nil, errors.New("invalid username or password")
	}
	if account.Status != 1 {
		return nil, errors.New("account is disabled")
	}
	return account, nil
}

func (s *AuthService) GetAccountByID(id uint) (*database.Account, error) {
	return s.accountRepo.FindByID(id)
}

// RegisterLegacy 提供与旧实现兼容的便捷函数接口。
func RegisterLegacy(username, password, email string) error {
	svc := NewAuthService()
	return svc.Register(username, password, email)
}

// 确保 compiler 保留对 repository 包的依赖（便于跨模块扩展）。
var _ = repository.GetAccountByID
