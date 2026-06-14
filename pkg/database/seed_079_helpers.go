package database

import (
	"time"

	"mapleStory079/pkg/utils"
)

func seedNow() time.Time { return time.Now() }

type skillSeed struct {
	ID      int
	Name    string
	Desc    string
	Job     int
	LvlReq  int
	MaxLv   int
	MP      int
	Passive bool
	Dmg     float64
	CD      int
}

func buildSkills(defs []skillSeed) []Skill {
	out := make([]Skill, 0, len(defs))
	for _, d := range defs {
		out = append(out, Skill{
			ID:          uint(d.ID),
			Name:        d.Name,
			JobClass:    d.Job,
			Description: d.Desc,
			LevelReq:    d.LvlReq,
			MaxLevel:    d.MaxLv,
			MPCost:      d.MP,
			IsPassive:   d.Passive,
			DamageRatio: d.Dmg,
			CoolDownMs:  d.CD,
			CreatedAt:   seedNow(),
		})
	}
	return out
}

type itemSeed struct {
	ID     int
	Name   string
	Desc   string
	Type   int
	Price  int
	Lvl    int
	HP, MP int
	STR    int
	DEX    int
	INT    int
	LUK    int
	Stack  bool
}

func buildItems(defs []itemSeed) []Item {
	out := make([]Item, 0, len(defs))
	for _, d := range defs {
		out = append(out, Item{
			ID:          uint(d.ID),
			Name:        d.Name,
			Description: d.Desc,
			ItemType:    d.Type,
			Price:       d.Price,
			LevelReq:    d.Lvl,
			HPRecovery:  d.HP,
			MPRecovery:  d.MP,
			STR:         d.STR,
			DEX:         d.DEX,
			INT:         d.INT,
			LUK:         d.LUK,
			Stackable:   d.Stack,
			CreatedAt:   seedNow(),
		})
	}
	return out
}

type mapSeed struct {
	ID    int
	Name  string
	Desc  string
	Music string
}

func buildMaps(defs []mapSeed) []Map {
	out := make([]Map, 0, len(defs))
	for _, d := range defs {
		out = append(out, Map{
			ID:          uint(d.ID),
			Name:        d.Name,
			Description: d.Desc,
			Width:       1600,
			Height:      900,
			Music:       d.Music,
			CreatedAt:   seedNow(),
		})
	}
	return out
}

type npcSeed struct {
	ID     int
	Name   string
	Desc   string
	MapID  int
	X, Y   int
	Script string
	Shop   bool
}

func buildNPCs(defs []npcSeed) []NPC {
	out := make([]NPC, 0, len(defs))
	for _, d := range defs {
		out = append(out, NPC{
			ID:          uint(d.ID),
			Name:        d.Name,
			Description: d.Desc,
			MapID:       uint(d.MapID),
			PositionX:   d.X,
			PositionY:   d.Y,
			Scripts:     d.Script,
			HasShop:     d.Shop,
			CreatedAt:   seedNow(),
		})
	}
	return out
}

func is(id int, name, desc string, typ, price, lvl, hp, mp int, stack bool) itemSeed {
	return itemSeed{ID: id, Name: name, Desc: desc, Type: typ, Price: price, Lvl: lvl, HP: hp, MP: mp, Stack: stack}
}

func ie(id int, name, desc string, price, lvl, str, dex, intl, luk int) itemSeed {
	return itemSeed{ID: id, Name: name, Desc: desc, Type: 1, Price: price, Lvl: lvl, STR: str, DEX: dex, INT: intl, LUK: luk, Stack: false}
}

// job constants shortcut
const (
	jBeginner = utils.JobBeginner
	jWarrior  = utils.JobSwordsman
	jMage     = utils.JobMagician
	jBow      = utils.JobBowman
	jThief    = utils.JobThief
	jPirate   = utils.JobPirate

	jFighter  = utils.JobFighter
	jPage     = utils.JobPage
	jSpearman = utils.JobSpearman
	jFP       = utils.JobFirePoison
	jIL       = utils.JobIceLightning
	jCleric   = utils.JobCleric
	jHunter   = utils.JobHunter
	jCrossbow = utils.JobCrossbow
	jAssassin = utils.JobAssassin
	jBandit   = utils.JobBandit
	jBrawler  = utils.JobBrawler
	jGun      = utils.JobGunslinger

	jCrusader     = utils.JobCrusader
	jWhiteKnight  = utils.JobWhiteKnight
	jDragonKnight = utils.JobDragonKnight
	jFPWizard     = utils.JobFirePoisonWizard
	jILWizard     = utils.JobIceLightningWizard
	jPriest       = utils.JobPriest
	jRanger       = utils.JobRanger
	jSniper       = utils.JobSniper
	jHermit       = utils.JobHermit
	jChiefBandit  = utils.JobChiefBandit
	jMarauder     = utils.JobMarauder
	jOutlaw       = utils.JobOutlaw

	jHero       = utils.JobHero
	jPaladin    = utils.JobPaladin
	jDarkKnight = utils.JobDarkKnight
	jFPArchMage = utils.JobFPArchMage
	jILArchMage = utils.JobILArchMage
	jBishop     = utils.JobBishop
	jBowmaster  = utils.JobBowmaster
	jMarksman   = utils.JobMarksman
	jNightLord  = utils.JobNightLord
	jShadower   = utils.JobShadower
	jBuccaneer  = utils.JobBuccaneer
	jCorsair    = utils.JobCorsair
)
