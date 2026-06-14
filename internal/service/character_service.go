package service

import (
	"errors"
	"fmt"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/database"
	"mapleStory079/pkg/utils"
)

// CharacterView 角色列表视图（含装备外观，供选角预览）
type CharacterView struct {
	database.Character
	Top    int `json:"top"`
	Bottom int `json:"bottom"`
	Shoes  int `json:"shoes"`
	Weapon int `json:"weapon"`
}

type CharacterService struct {
	invRepo *repository.InventoryRepository
}

func NewCharacterService() *CharacterService {
	return &CharacterService{invRepo: repository.NewInventoryRepository()}
}

func (s *CharacterService) CreateCharacter(accountID uint, name string, jobType int, gender int, look utils.BeginnerLook) (*database.Character, error) {
	if accountID == 0 {
		return nil, errors.New("account id required")
	}
	if name == "" {
		return nil, errors.New("character name required")
	}
	if !utils.CanCreateCharacterName(name) {
		return nil, errors.New("角色名不可用")
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

	classID, mapID, ok := jobTypeToSpawn(jobType)
	if !ok {
		return nil, errors.New("职业类型未开放")
	}
	if err := validateJobTypeEnabled(jobType); err != nil {
		return nil, err
	}

	if gender != 0 && gender != 1 {
		return nil, errors.New("invalid gender")
	}

	if look.Face == 0 && look.Hair == 0 && look.Top == 0 {
		look = utils.DefaultBeginnerLook(gender)
	}
	look.HairColor = 0
	look.Skin = 0
	if err := utils.ValidateBeginnerLook(gender, look); err != nil {
		return nil, errors.New("非法的新手外观: " + err.Error())
	}

	baseStats := utils.JobInitialStatsMap[utils.JobBeginner]

	character := &database.Character{
		AccountID: accountID,
		Name:      name,
		Class:     classID,
		Gender:    gender,
		Face:      look.Face,
		Hair:      look.Hair,
		Skin:      0,
		Level:     1,
		Exp:       0,
		MapID:     mapID,
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
		Mesos:     0,
	}

	if err := repository.CreateCharacter(character); err != nil {
		return nil, err
	}
	if err := seedBeginnerEquipment(character.ID, look); err != nil {
		return nil, fmt.Errorf("equip starter items: %w", err)
	}
	if err := seedBeginnerInventory(character.ID, jobType); err != nil {
		return nil, fmt.Errorf("seed starter inventory: %w", err)
	}
	return character, nil
}

func jobTypeToSpawn(jobType int) (classID int, mapID uint, ok bool) {
	switch jobType {
	case utils.JobTypeAdventurer:
		return utils.JobBeginner, utils.MapTutorialStart, true
	case utils.JobTypeKnight:
		return utils.JobKnightBeginner, utils.MapKnightStart, true
	case utils.JobTypeAran:
		return utils.JobAranBeginner, utils.MapAranStart, true
	default:
		return 0, 0, false
	}
}

// ms079 ServerProperties: adventurer=true, knights=false, warGod=false
func validateJobTypeEnabled(jobType int) error {
	switch jobType {
	case utils.JobTypeAdventurer:
		return nil
	case utils.JobTypeKnight:
		return errors.New("骑士团职业未开放")
	case utils.JobTypeAran:
		return errors.New("战神职业未开放")
	default:
		return errors.New("invalid job type")
	}
}

func seedBeginnerEquipment(characterID uint, look utils.BeginnerLook) error {
	equips := []struct {
		itemID int
		slot   string
	}{
		{look.Top, "coat"},
		{look.Bottom, "pants"},
		{look.Shoes, "shoes"},
		{look.Weapon, "weapon"},
	}
	for i, e := range equips {
		inv := &database.CharacterInventory{
			CharacterID: characterID,
			ItemID:      e.itemID,
			SlotIndex:   i + 1,
			Quantity:    1,
			IsEquipped:  true,
			EquipSlot:   e.slot,
		}
		if err := repository.AddCharacterItem(inv); err != nil {
			return err
		}
	}
	return nil
}

// seedBeginnerInventory ms079 CharLoginHandler.CreateChar L348-368
func seedBeginnerInventory(characterID uint, jobType int) error {
	var guideItem int
	switch jobType {
	case utils.JobTypeKnight:
		guideItem = 4161047
	case utils.JobTypeAdventurer:
		guideItem = 4161001
	case utils.JobTypeAran:
		guideItem = 4161048
	default:
		guideItem = 4161001
	}
	if err := repository.AddCharacterItem(&database.CharacterInventory{
		CharacterID: characterID,
		ItemID:      guideItem,
		SlotIndex:   100,
		Quantity:    1,
	}); err != nil {
		return err
	}
	return repository.AddCharacterItem(&database.CharacterInventory{
		CharacterID: characterID,
		ItemID:      2022336,
		SlotIndex:   1,
		Quantity:    1,
	})
}

func (s *CharacterService) CheckCharacterName(name string) (bool, string) {
	if !utils.CanCreateCharacterName(name) {
		if utils.IsForbiddenName(name) {
			return false, "角色名含有禁用词"
		}
		return false, "角色名格式不正确（2~12 字符，中文/字母/数字）"
	}
	if _, err := repository.GetCharacterByName(name); err == nil {
		return false, "角色名已被使用"
	}
	return true, ""
}

func (s *CharacterService) GetCharactersByAccountID(accountID uint) ([]CharacterView, error) {
	chars, err := repository.GetCharactersByAccount(accountID)
	if err != nil {
		return nil, err
	}
	out := make([]CharacterView, 0, len(chars))
	for _, ch := range chars {
		v := CharacterView{Character: ch}
		equips, err := s.invRepo.FindEquipped(ch.ID)
		if err == nil {
			for _, e := range equips {
				switch e.EquipSlot {
				case "coat":
					v.Top = e.ItemID
				case "pants":
					v.Bottom = e.ItemID
				case "shoes":
					v.Shoes = e.ItemID
				case "weapon":
					v.Weapon = e.ItemID
				}
			}
		}
		out = append(out, v)
	}
	return out, nil
}

// GetClassName 根据职业编号返回中文名称；未知编号返回 "未知"。
func GetClassName(class int) string {
	if name, ok := utils.JobNames[class]; ok {
		return name
	}
	switch class {
	case utils.JobKnightBeginner:
		return "初心者"
	case utils.JobAranBeginner:
		return "战童"
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
