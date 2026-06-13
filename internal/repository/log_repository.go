package repository

import (
	"mapleStory079/pkg/database"
	"time"
)

// LoginLogRepository 登录日志仓库
type LoginLogRepository struct{}

func NewLoginLogRepository() *LoginLogRepository {
	return &LoginLogRepository{}
}

func (r *LoginLogRepository) Create(log *database.LoginLog) error {
	return database.DB.Create(log).Error
}

func (r *LoginLogRepository) FindByAccountID(accountID uint) ([]database.LoginLog, error) {
	var logs []database.LoginLog
	err := database.DB.Where("account_id = ?", accountID).Order("created_at DESC").Limit(50).Find(&logs).Error
	return logs, err
}

func (r *LoginLogRepository) FindByIP(ip string) ([]database.LoginLog, error) {
	var logs []database.LoginLog
	err := database.DB.Where("ip = ?", ip).Order("created_at DESC").Limit(50).Find(&logs).Error
	return logs, err
}

func (r *LoginLogRepository) FindRecent(hours int) ([]database.LoginLog, error) {
	var logs []database.LoginLog
	since := time.Now().Add(-time.Duration(hours) * time.Hour)
	err := database.DB.Where("created_at >= ?", since).Order("created_at DESC").Limit(200).Find(&logs).Error
	return logs, err
}

func (r *LoginLogRepository) CountByStatus(status int, sinceHours int) (int64, error) {
	var count int64
	query := database.DB.Model(&database.LoginLog{}).Where("status = ?", status)
	if sinceHours > 0 {
		since := time.Now().Add(-time.Duration(sinceHours) * time.Hour)
		query = query.Where("created_at >= ?", since)
	}
	err := query.Count(&count).Error
	return count, err
}

// TradeLogRepository 交易日志仓库
type TradeLogRepository struct{}

func NewTradeLogRepository() *TradeLogRepository {
	return &TradeLogRepository{}
}

func (r *TradeLogRepository) Create(log *database.TradeLog) error {
	return database.DB.Create(log).Error
}

func (r *TradeLogRepository) FindBySenderID(senderID uint) ([]database.TradeLog, error) {
	var logs []database.TradeLog
	err := database.DB.Where("sender_id = ?", senderID).Order("created_at DESC").Limit(100).Find(&logs).Error
	return logs, err
}

func (r *TradeLogRepository) FindByReceiverID(receiverID uint) ([]database.TradeLog, error) {
	var logs []database.TradeLog
	err := database.DB.Where("receiver_id = ?", receiverID).Order("created_at DESC").Limit(100).Find(&logs).Error
	return logs, err
}

func (r *TradeLogRepository) FindByCharacterID(characterID uint) ([]database.TradeLog, error) {
	var logs []database.TradeLog
	err := database.DB.Where("sender_id = ? OR receiver_id = ?", characterID, characterID).
		Order("created_at DESC").Limit(200).Find(&logs).Error
	return logs, err
}

// ChatLogRepository 聊天日志仓库
type ChatLogRepository struct{}

func NewChatLogRepository() *ChatLogRepository {
	return &ChatLogRepository{}
}

func (r *ChatLogRepository) Create(log *database.ChatLog) error {
	return database.DB.Create(log).Error
}

func (r *ChatLogRepository) FindByChannel(channel int, sinceMinutes int) ([]database.ChatLog, error) {
	var logs []database.ChatLog
	query := database.DB.Where("channel = ?", channel)
	if sinceMinutes > 0 {
		since := time.Now().Add(-time.Duration(sinceMinutes) * time.Minute)
		query = query.Where("created_at >= ?", since)
	}
	err := query.Order("created_at DESC").Limit(200).Find(&logs).Error
	return logs, err
}

func (r *ChatLogRepository) FindByCharacterID(characterID uint) ([]database.ChatLog, error) {
	var logs []database.ChatLog
	err := database.DB.Where("character_id = ?", characterID).
		Order("created_at DESC").Limit(200).Find(&logs).Error
	return logs, err
}

func (r *ChatLogRepository) FindByReceiverID(receiverID uint) ([]database.ChatLog, error) {
	var logs []database.ChatLog
	err := database.DB.Where("receiver_id = ?", receiverID).
		Order("created_at DESC").Limit(200).Find(&logs).Error
	return logs, err
}

func (r *ChatLogRepository) FindRecentMessages(sinceMinutes int) ([]database.ChatLog, error) {
	var logs []database.ChatLog
	since := time.Now().Add(-time.Duration(sinceMinutes) * time.Minute)
	err := database.DB.Where("created_at >= ?", since).
		Order("created_at DESC").Limit(500).Find(&logs).Error
	return logs, err
}
