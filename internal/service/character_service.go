package service

import (
	"errors"
	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
)

type CharacterService struct {
}

func NewCharacterService() *CharacterService {
	return &CharacterService{}
}

func (s *CharacterService) CreateCharacter(accountID uint, name string, class int, gender int) (*database.Character, error) {
	_, err := repository.GetCharacterByName(name)
	if err == nil {
		return nil, errors.New("character name already exists")
	}

	characters, err := repository.GetCharactersByAccount(accountID)
	if err != nil {
		return nil, err
	}

	if len(characters) >= 6 {
		return nil, errors.New("max character limit reached")
	}

	// 根据职业设置差异化初始属性
	baseStats := getClassBaseStats(class)

	character := &database.Character{
		AccountID: accountID,
		Name:      name,
		Class:     class,
		Gender:    gender,
		Level:     1,
		Exp:       0,
		MapID:     1, // 南港
		PositionX: 0,
		PositionY: 0,
		HP:        baseStats.hp,
		MaxHP:     baseStats.maxHp,
		MP:        baseStats.mp,
		MaxMP:     baseStats.maxMp,
		STR:       baseStats.str,
		DEX:       baseStats.dex,
		INT:       baseStats.int,
		LUK:       baseStats.luk,
		Mesos:     500,
	}

	err = repository.CreateCharacter(character)
	if err != nil {
		return nil, err
	}

	return character, nil
}

// 职业基础属性配置 - 模仿079版本冒险岛
type classBaseStats struct {
	hp    int
	maxHp int
	mp    int
	maxMp int
	str   int
	dex   int
	int   int
	luk   int
}

func getClassBaseStats(class int) classBaseStats {
	switch class {
	case 0: // 新手 (Beginner)
		return classBaseStats{
			hp: 50, maxHp: 50,
			mp: 5, maxMp: 5,
			str: 12, dex: 5, int: 4, luk: 4,
		}
	case 1: // 战士 (Warrior) - 力量为主
		return classBaseStats{
			hp: 80, maxHp: 80,
			mp: 4, maxMp: 4,
			str: 35, dex: 15, int: 4, luk: 4,
		}
	case 2: // 法师 (Magician) - 智力为主
		return classBaseStats{
			hp: 40, maxHp: 40,
			mp: 80, maxMp: 80,
			str: 4, dex: 4, int: 35, luk: 20,
		}
	case 3: // 弓箭手 (Bowman) - 敏捷为主
		return classBaseStats{
			hp: 60, maxHp: 60,
			mp: 8, maxMp: 8,
			str: 25, dex: 35, int: 4, luk: 4,
		}
	case 4: // 飞侠 (Thief) - 运气为主
		return classBaseStats{
			hp: 55, maxHp: 55,
			mp: 10, maxMp: 10,
			str: 4, dex: 25, int: 4, luk: 35,
		}
	case 5: // 海盗 (Pirate) - 力量+敏捷平衡
		return classBaseStats{
			hp: 70, maxHp: 70,
			mp: 12, maxMp: 12,
			str: 20, dex: 20, int: 4, luk: 15,
		}
	default: // 默认新手
		return classBaseStats{
			hp: 50, maxHp: 50,
			mp: 5, maxMp: 5,
			str: 12, dex: 5, int: 4, luk: 4,
		}
	}
}

// 职业名称映射
func GetClassName(class int) string {
	switch class {
	case 0:
		return "新手"
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
	default:
		return "未知"
	}
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
