package service

import (
	"errors"
	"fmt"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
	"mapleStory079/pkg/utils"
)

type CharacterService struct {
}

func NewCharacterService() *CharacterService {
	return &CharacterService{}
}

func (s *CharacterService) CreateCharacter(accountID uint, name string, class int, gender int) (*database.Character, error) {
	if accountID == 0 {
		return nil, errors.New("account id required")
	}
	if name == "" {
		return nil, errors.New("character name required")
	}

	_, err := repository.GetCharacterByName(name)
	if err == nil {
		return nil, errors.New("character name already exists")
	}

	characters, err := repository.GetCharactersByAccount(accountID)
	if err != nil {
		return nil, err
	}
	if len(characters) >= utils.MaxCharacterSlots {
		return nil, errors.New("max character limit reached")
	}

	// 优先从 utils 中取标准初始属性；若未定义则回退到新手默认值
	baseStats, ok := utils.JobInitialStatsMap[class]
	if !ok {
		baseStats = utils.JobInitialStatsMap[utils.JobBeginner]
	}

	character := &database.Character{
		AccountID: accountID,
		Name:      name,
		Class:     class,
		Gender:    gender,
		Level:     1,
		Exp:       0,
		MapID:     utils.MapMapleIsland, // 新手村
		PositionX: 0,
		PositionY: 0,
		HP:        baseStats.HP,
		MaxHP:     baseStats.HP,
		MP:        baseStats.MP,
		MaxMP:     baseStats.MP,
		STR:       baseStats.STR,
		DEX:       baseStats.DEX,
		INT:       baseStats.INT,
		LUK:       baseStats.LUK,
		Mesos:     500,
	}

	if err := repository.CreateCharacter(character); err != nil {
		return nil, err
	}
	return character, nil
}

// GetClassName 根据职业编号返回中文名称；未知编号返回 "未知"。
func GetClassName(class int) string {
	if name, ok := utils.JobNames[class]; ok {
		return name
	}
	// 兼容 UI/测试使用的简化编号 1-5
	switch class {
	case 1:
		return "战士"
	case 2:
		return "法师"
	case 3:
		return "弓箭手"
	case 4:
		return "飞侠"
	case 5:
		return "海盗"
	}
	return "未知"
}

func (s *CharacterService) GetCharactersByAccountID(accountID uint) ([]database.Character, error) {
	return repository.GetCharactersByAccount(accountID)
}

func (s *CharacterService) GetCharacterByID(id uint) (*database.Character, error) {
	return repository.GetCharacterByID(id)
}

func (s *CharacterService) UpdateCharacter(character *database.Character) error {
	return repository.UpdateCharacter(character)
}

func (s *CharacterService) DeleteCharacter(id uint) error {
	return repository.DeleteCharacter(id)
}

// AssignAbilityPoints 分配属性点：每一项不可超过剩余可用属性点，且总数不可超过剩余点。
// 任何一项若为负值则被视为 0。
func (s *CharacterService) AssignAbilityPoints(characterID uint, str, dex, intVal, luk int) error {
	ch, err := repository.GetCharacterByID(characterID)
	if err != nil {
		return err
	}
	if str < 0 {
		str = 0
	}
	if dex < 0 {
		dex = 0
	}
	if intVal < 0 {
		intVal = 0
	}
	if luk < 0 {
		luk = 0
	}
	total := str + dex + intVal + luk
	if total == 0 {
		return nil
	}
	if total > ch.AbilityPoint {
		return fmt.Errorf("not enough ability points: have %d, need %d", ch.AbilityPoint, total)
	}
	ch.STR += str
	ch.DEX += dex
	ch.INT += intVal
	ch.LUK += luk
	ch.AbilityPoint -= total
	return repository.UpdateCharacter(ch)
}

// RestoreCharacter HP/MP 恢复（当角色使用药水或休息时调用）。
func (s *CharacterService) RestoreCharacter(characterID uint, hp, mp int) error {
	ch, err := repository.GetCharacterByID(characterID)
	if err != nil {
		return err
	}
	if hp > 0 {
		ch.HP += hp
		if ch.HP > ch.MaxHP {
			ch.HP = ch.MaxHP
		}
	}
	if mp > 0 {
		ch.MP += mp
		if ch.MP > ch.MaxMP {
			ch.MP = ch.MaxMP
		}
	}
	return repository.UpdateCharacter(ch)
}

// MoveCharacterInMap 验证边界并更新角色在地图内的坐标。
func (s *CharacterService) MoveCharacterInMap(characterID uint, newX, newY, width, height int) error {
	ch, err := repository.GetCharacterByID(characterID)
	if err != nil {
		return err
	}
	if newX < 0 {
		newX = 0
	}
	if newY < 0 {
		newY = 0
	}
	if width > 0 && newX > width {
		newX = width
	}
	if height > 0 && newY > height {
		newY = height
	}
	ch.PositionX = newX
	ch.PositionY = newY
	return repository.UpdateCharacter(ch)
}
