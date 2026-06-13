package repository

import (
	"mapleStory079/pkg/database"
)

type GuildRepository struct{}

func NewGuildRepository() *GuildRepository {
	return &GuildRepository{}
}

func (r *GuildRepository) Create(guild *database.Guild) error {
	return database.DB.Create(guild).Error
}

func (r *GuildRepository) FindByID(id uint) (*database.Guild, error) {
	var guild database.Guild
	err := database.DB.Where("id = ?", id).First(&guild).Error
	return &guild, err
}

func (r *GuildRepository) FindByName(name string) (*database.Guild, error) {
	var guild database.Guild
	err := database.DB.Where("name = ?", name).First(&guild).Error
	return &guild, err
}

func (r *GuildRepository) FindAll() ([]database.Guild, error) {
	var guilds []database.Guild
	err := database.DB.Find(&guilds).Error
	return guilds, err
}

func (r *GuildRepository) Update(guild *database.Guild) error {
	return database.DB.Save(guild).Error
}

func (r *GuildRepository) Delete(id uint) error {
	return database.DB.Delete(database.Guild{}, id).Error
}

func (r *GuildRepository) AddMembers(guildID uint, delta int) error {
	return database.DB.Model(&database.Guild{}).
		Where("id = ?", guildID).
		UpdateColumn("members", database.DB.Raw("members + ?", delta)).Error
}

func (r *GuildRepository) AddPoint(guildID uint, delta int) error {
	return database.DB.Model(&database.Guild{}).
		Where("id = ?", guildID).
		UpdateColumn("point", database.DB.Raw("point + ?", delta)).Error
}

// PartyRepository 组队仓库
type PartyRepository struct{}

func NewPartyRepository() *PartyRepository {
	return &PartyRepository{}
}

func (r *PartyRepository) Create(party *database.Party) error {
	return database.DB.Create(party).Error
}

func (r *PartyRepository) FindByID(id uint) (*database.Party, error) {
	var party database.Party
	err := database.DB.Where("id = ?", id).First(&party).Error
	return &party, err
}

func (r *PartyRepository) FindByLeaderID(leaderID uint) (*database.Party, error) {
	var party database.Party
	err := database.DB.Where("leader_id = ?", leaderID).First(&party).Error
	return &party, err
}

func (r *PartyRepository) FindAll() ([]database.Party, error) {
	var parties []database.Party
	err := database.DB.Find(&parties).Error
	return parties, err
}

func (r *PartyRepository) Update(party *database.Party) error {
	return database.DB.Save(party).Error
}

func (r *PartyRepository) Delete(id uint) error {
	return database.DB.Delete(database.Party{}, id).Error
}

func (r *PartyRepository) AddMembers(partyID uint, delta int) error {
	return database.DB.Model(&database.Party{}).
		Where("id = ?", partyID).
		UpdateColumn("members", database.DB.Raw("members + ?", delta)).Error
}

// FriendRepository 好友仓库
type FriendRepository struct{}

func NewFriendRepository() *FriendRepository {
	return &FriendRepository{}
}

func (r *FriendRepository) Create(friend *database.Friend) error {
	return database.DB.Create(friend).Error
}

func (r *FriendRepository) FindByCharacterID(characterID uint) ([]database.Friend, error) {
	var friends []database.Friend
	err := database.DB.Where("character_id = ?", characterID).Find(&friends).Error
	return friends, err
}

func (r *FriendRepository) FindByFriendID(friendID uint) ([]database.Friend, error) {
	var friends []database.Friend
	err := database.DB.Where("friend_id = ?", friendID).Find(&friends).Error
	return friends, err
}

func (r *FriendRepository) Delete(id uint) error {
	return database.DB.Delete(database.Friend{}, id).Error
}

func (r *FriendRepository) FindByGroup(characterID uint, group string) ([]database.Friend, error) {
	var friends []database.Friend
	err := database.DB.Where("character_id = ? AND `group` = ?", characterID, group).Find(&friends).Error
	return friends, err
}
