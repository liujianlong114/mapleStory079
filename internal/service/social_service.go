package service

import (
	"errors"
	"strings"
	"time"

	"mapleStory079/pkg/database"
)

// ==================== 公会服务 ====================

// GuildService 公会服务。
type GuildService struct{}

func NewGuildService() *GuildService { return &GuildService{} }

// Create 创建公会（masterID 角色同时成为公会首位成员）。
func (s *GuildService) Create(name string, masterID uint) (*database.Guild, error) {
	name = strings.TrimSpace(name)
	if name == "" {
		return nil, errors.New("guild name required")
	}
	if masterID == 0 {
		return nil, errors.New("invalid master id")
	}

	var existing database.Guild
	if err := database.GetDB().Where("name = ?", name).First(&existing).Error; err == nil {
		return nil, errors.New("guild name already exists")
	}

	guild := &database.Guild{
		Name:      name,
		MasterID:  masterID,
		Members:   1,
		Level:     1,
		Point:     0,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	if err := database.GetDB().Create(guild).Error; err != nil {
		return nil, err
	}
	return guild, nil
}

// Join 让角色加入公会。
func (s *GuildService) Join(guildID, characterID uint) error {
	if guildID == 0 || characterID == 0 {
		return errors.New("invalid id")
	}
	var guild database.Guild
	if err := database.GetDB().First(&guild, guildID).Error; err != nil {
		return err
	}
	guild.Members += 1
	guild.UpdatedAt = time.Now()
	return database.GetDB().Save(&guild).Error
}

// Leave 让角色离开公会（会长离开时将随机将会长转让，此处仅递减成员数）。
func (s *GuildService) Leave(guildID, characterID uint) error {
	if guildID == 0 || characterID == 0 {
		return errors.New("invalid id")
	}
	var guild database.Guild
	if err := database.GetDB().First(&guild, guildID).Error; err != nil {
		return err
	}
	if guild.Members <= 1 {
		// 最后一人离开：解散公会
		return database.GetDB().Delete(&guild).Error
	}
	guild.Members -= 1
	guild.UpdatedAt = time.Now()
	if guild.MasterID == characterID {
		guild.MasterID = 0 // 由上层业务选择新会长
	}
	return database.GetDB().Save(&guild).Error
}

// Kick 踢出成员（需由会长调用）。
func (s *GuildService) Kick(guildID, masterID, targetID uint) error {
	if guildID == 0 || masterID == 0 || targetID == 0 {
		return errors.New("invalid id")
	}
	var guild database.Guild
	if err := database.GetDB().First(&guild, guildID).Error; err != nil {
		return err
	}
	if guild.MasterID != masterID {
		return errors.New("permission denied")
	}
	if guild.MasterID == targetID {
		return errors.New("cannot kick master")
	}
	guild.Members -= 1
	guild.UpdatedAt = time.Now()
	return database.GetDB().Save(&guild).Error
}

// ListMembers 返回公会信息（包含成员数）；当前模型未单独存储成员表，
// 上层业务可根据需要扩展为多对多关系。
func (s *GuildService) ListMembers(guildID uint) (*database.Guild, error) {
	if guildID == 0 {
		return nil, errors.New("invalid id")
	}
	var guild database.Guild
	if err := database.GetDB().First(&guild, guildID).Error; err != nil {
		return nil, err
	}
	return &guild, nil
}

// ==================== 组队服务 ====================

// PartyService 组队服务。
type PartyService struct{}

func NewPartyService() *PartyService { return &PartyService{} }

// Create 创建新队伍（leader 自动加入）。
func (s *PartyService) Create(leaderID uint) (*database.Party, error) {
	if leaderID == 0 {
		return nil, errors.New("invalid leader id")
	}
	var existing database.Party
	if err := database.GetDB().Where("leader_id = ?", leaderID).First(&existing).Error; err == nil {
		return nil, errors.New("already leading a party")
	}
	party := &database.Party{
		LeaderID:  leaderID,
		Members:   1,
		MapID:     0,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	if err := database.GetDB().Create(party).Error; err != nil {
		return nil, err
	}
	return party, nil
}

// Invite 邀请（在本实现中仅做合法性校验；具体邀请状态由上层业务扩展）。
func (s *PartyService) Invite(partyID, inviterID, inviteeID uint) error {
	if partyID == 0 || inviterID == 0 || inviteeID == 0 {
		return errors.New("invalid id")
	}
	var party database.Party
	if err := database.GetDB().First(&party, partyID).Error; err != nil {
		return err
	}
	if party.LeaderID != inviterID {
		return errors.New("only leader can invite")
	}
	return nil
}

// Accept 被邀请者接受邀请，加入队伍。
func (s *PartyService) Accept(partyID, characterID uint) error {
	if partyID == 0 || characterID == 0 {
		return errors.New("invalid id")
	}
	var party database.Party
	if err := database.GetDB().First(&party, partyID).Error; err != nil {
		return err
	}
	party.Members += 1
	party.UpdatedAt = time.Now()
	return database.GetDB().Save(&party).Error
}

// Leave 离开队伍，若为队长则队伍解散。
func (s *PartyService) Leave(partyID, characterID uint) error {
	if partyID == 0 || characterID == 0 {
		return errors.New("invalid id")
	}
	var party database.Party
	if err := database.GetDB().First(&party, partyID).Error; err != nil {
		return err
	}
	if party.LeaderID == characterID {
		return database.GetDB().Delete(&party).Error
	}
	party.Members -= 1
	party.UpdatedAt = time.Now()
	return database.GetDB().Save(&party).Error
}

// ListMembers 返回队伍信息。
func (s *PartyService) ListMembers(partyID uint) (*database.Party, error) {
	if partyID == 0 {
		return nil, errors.New("invalid id")
	}
	var party database.Party
	if err := database.GetDB().First(&party, partyID).Error; err != nil {
		return nil, err
	}
	return &party, nil
}

// ==================== 好友服务 ====================

// FriendService 好友服务。
type FriendService struct{}

func NewFriendService() *FriendService { return &FriendService{} }

// Add 添加好友（单向添加，由上层业务补充双向同步）。
func (s *FriendService) Add(characterID, friendID uint, group string) (*database.Friend, error) {
	if characterID == 0 || friendID == 0 {
		return nil, errors.New("invalid id")
	}
	if characterID == friendID {
		return nil, errors.New("cannot add self")
	}

	var existing database.Friend
	if err := database.GetDB().
		Where("character_id = ? AND friend_id = ?", characterID, friendID).
		First(&existing).Error; err == nil {
		return nil, errors.New("friend already exists")
	}

	friend := &database.Friend{
		CharacterID: characterID,
		FriendID:    friendID,
		Group:       group,
		CreatedAt:   time.Now(),
	}
	if err := database.GetDB().Create(friend).Error; err != nil {
		return nil, err
	}
	return friend, nil
}

// Remove 移除好友。
func (s *FriendService) Remove(characterID, friendID uint) error {
	if characterID == 0 || friendID == 0 {
		return errors.New("invalid id")
	}
	return database.GetDB().
		Where("character_id = ? AND friend_id = ?", characterID, friendID).
		Delete(&database.Friend{}).Error
}

// List 列出角色的全部好友。
func (s *FriendService) List(characterID uint) ([]database.Friend, error) {
	if characterID == 0 {
		return nil, errors.New("invalid id")
	}
	var friends []database.Friend
	if err := database.GetDB().Where("character_id = ?", characterID).Find(&friends).Error; err != nil {
		return nil, err
	}
	return friends, nil
}

// Block 拉黑：将 friend 记录中 group 标记为 "blocked"（简单实现）。
func (s *FriendService) Block(characterID, friendID uint) error {
	if characterID == 0 || friendID == 0 {
		return errors.New("invalid id")
	}
	return database.GetDB().Model(&database.Friend{}).
		Where("character_id = ? AND friend_id = ?", characterID, friendID).
		Update("group", "blocked").Error
}
