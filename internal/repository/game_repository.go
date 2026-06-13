package repository

import (
	"mapleStory079/pkg/database"
)

type MapRepository struct{}

func (r *MapRepository) Create(gameMap *database.Map) error {
	return database.DB.Create(gameMap).Error
}

func (r *MapRepository) FindByID(id uint) (*database.Map, error) {
	var gameMap database.Map
	err := database.DB.Where("id = ?", id).First(&gameMap).Error
	return &gameMap, err
}

func (r *MapRepository) FindAll() ([]database.Map, error) {
	var maps []database.Map
	err := database.DB.Find(&maps).Error
	return maps, err
}

func (r *MapRepository) Update(gameMap *database.Map) error {
	return database.DB.Save(gameMap).Error
}

func (r *MapRepository) Delete(id uint) error {
	return database.DB.Delete(&database.Map{}, id).Error
}

type NPCRepository struct{}

func (r *NPCRepository) Create(npc *database.NPC) error {
	return database.DB.Create(npc).Error
}

func (r *NPCRepository) FindByID(id uint) (*database.NPC, error) {
	var npc database.NPC
	err := database.DB.Where("id = ?", id).First(&npc).Error
	return &npc, err
}

func (r *NPCRepository) FindByMapID(mapID int) ([]database.NPC, error) {
	var npcs []database.NPC
	err := database.DB.Where("map_id = ?", mapID).Find(&npcs).Error
	return npcs, err
}

func (r *NPCRepository) Update(npc *database.NPC) error {
	return database.DB.Save(npc).Error
}

func (r *NPCRepository) Delete(id uint) error {
	return database.DB.Delete(&database.NPC{}, id).Error
}

type MobRepository struct{}

func (r *MobRepository) Create(mob *database.Mob) error {
	return database.DB.Create(mob).Error
}

func (r *MobRepository) FindByID(id uint) (*database.Mob, error) {
	var mob database.Mob
	err := database.DB.Where("id = ?", id).First(&mob).Error
	return &mob, err
}

func (r *MobRepository) FindAll() ([]database.Mob, error) {
	var mobs []database.Mob
	err := database.DB.Find(&mobs).Error
	return mobs, err
}

func (r *MobRepository) Update(mob *database.Mob) error {
	return database.DB.Save(mob).Error
}

func (r *MobRepository) Delete(id uint) error {
	return database.DB.Delete(&database.Mob{}, id).Error
}
