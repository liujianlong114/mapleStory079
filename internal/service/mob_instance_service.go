package service

import (
	"fmt"
	"math/rand"
	"sync"
	"time"

	"mapleStory079/internal/repository"
)

const mobRespawnDelay = 8 * time.Second

// MobInstance 地图上的怪物实例（内存态，按 map 隔离）。
type MobInstance struct {
	InstanceID uint    `json:"instance_id"`
	MapID      uint    `json:"map_id"`
	TemplateID uint    `json:"template_id"`
	Name       string  `json:"name"`
	Level      int     `json:"level"`
	HP         int     `json:"hp"`
	MaxHP      int     `json:"max_hp"`
	X          float64 `json:"x"`
	Y          float64 `json:"y"`
	Alive      bool    `json:"alive"`
}

type spawnDef struct {
	templateID uint
	x, y       float64
}

type mobInstanceInternal struct {
	MobInstance
	respawnAt time.Time
}

// MobInstanceService 管理各地图怪物实例。
type MobInstanceService struct {
	mu     sync.RWMutex
	byMap  map[uint][]*mobInstanceInternal
	nextID uint64
}

var DefaultMobInstanceService = NewMobInstanceService()

func NewMobInstanceService() *MobInstanceService {
	return &MobInstanceService{byMap: make(map[uint][]*mobInstanceInternal)}
}

// EnsureMap 确保地图已有怪物实例，若无则按默认池生成。
func (s *MobInstanceService) EnsureMap(mapID uint) []MobInstance {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.respawnDueLocked(mapID)
	if len(s.byMap[mapID]) == 0 {
		s.seedMapLocked(mapID)
	}
	return s.snapshotLocked(mapID)
}

func (s *MobInstanceService) Get(instanceID uint) (*MobInstance, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	inst := s.findLocked(instanceID)
	if inst == nil {
		return nil, fmt.Errorf("mob instance %d not found", instanceID)
	}
	cp := inst.MobInstance
	return &cp, nil
}

func (s *MobInstanceService) SetHP(instanceID uint, hp int) (*MobInstance, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	inst := s.findLocked(instanceID)
	if inst == nil {
		return nil, fmt.Errorf("mob instance %d not found", instanceID)
	}
	if hp < 0 {
		hp = 0
	}
	inst.HP = hp
	if hp <= 0 {
		inst.Alive = false
		inst.respawnAt = time.Now().Add(mobRespawnDelay)
		go s.scheduleRespawn(instanceID)
	}
	cp := inst.MobInstance
	return &cp, nil
}

func (s *MobInstanceService) ApplyDamage(instanceID uint, damage int) (*MobInstance, bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	inst := s.findLocked(instanceID)
	if inst == nil {
		return nil, false, fmt.Errorf("mob instance %d not found", instanceID)
	}
	if !inst.Alive {
		return &inst.MobInstance, false, fmt.Errorf("mob already dead")
	}
	if damage < 0 {
		damage = 0
	}
	inst.HP -= damage
	killed := false
	if inst.HP <= 0 {
		inst.HP = 0
		inst.Alive = false
		inst.respawnAt = time.Now().Add(mobRespawnDelay)
		killed = true
		go s.scheduleRespawn(instanceID)
	}
	cp := inst.MobInstance
	return &cp, killed, nil
}

func (s *MobInstanceService) findLocked(instanceID uint) *mobInstanceInternal {
	for _, list := range s.byMap {
		for _, inst := range list {
			if inst.InstanceID == instanceID {
				return inst
			}
		}
	}
	return nil
}

func (s *MobInstanceService) seedMapLocked(mapID uint) {
	defs := defaultSpawns(mapID)
	list := make([]*mobInstanceInternal, 0, len(defs))
	for _, d := range defs {
		tmpl, err := repository.GetMobByID(d.templateID)
		if err != nil || tmpl == nil {
			continue
		}
		s.nextID++
		id := uint(s.nextID)
		list = append(list, &mobInstanceInternal{
			MobInstance: MobInstance{
				InstanceID: id,
				MapID:      mapID,
				TemplateID: d.templateID,
				Name:       tmpl.Name,
				Level:      tmpl.Level,
				HP:         tmpl.MaxHP,
				MaxHP:      tmpl.MaxHP,
				X:          d.x,
				Y:          d.y,
				Alive:      true,
			},
		})
	}
	s.byMap[mapID] = list
}

func (s *MobInstanceService) respawnDueLocked(mapID uint) {
	now := time.Now()
	for _, inst := range s.byMap[mapID] {
		if inst.Alive || inst.respawnAt.IsZero() || now.Before(inst.respawnAt) {
			continue
		}
		tmpl, err := repository.GetMobByID(inst.TemplateID)
		if err != nil || tmpl == nil {
			continue
		}
		inst.HP = tmpl.MaxHP
		inst.MaxHP = tmpl.MaxHP
		inst.Alive = true
		inst.respawnAt = time.Time{}
	}
}

func (s *MobInstanceService) snapshotLocked(mapID uint) []MobInstance {
	list := s.byMap[mapID]
	out := make([]MobInstance, 0, len(list))
	for _, inst := range list {
		if inst.Alive {
			out = append(out, inst.MobInstance)
		}
	}
	return out
}

func (s *MobInstanceService) scheduleRespawn(instanceID uint) {
	time.Sleep(mobRespawnDelay)
	s.mu.Lock()
	defer s.mu.Unlock()
	inst := s.findLocked(instanceID)
	if inst == nil || inst.Alive {
		return
	}
	tmpl, err := repository.GetMobByID(inst.TemplateID)
	if err != nil || tmpl == nil {
		return
	}
	inst.HP = tmpl.MaxHP
	inst.MaxHP = tmpl.MaxHP
	inst.Alive = true
	inst.respawnAt = time.Time{}
}

func defaultSpawns(mapID uint) []spawnDef {
	baseX, baseY := 800.0, 450.0
	pool := []uint{100100, 100101, 100200, 100400, 100800}
	if mapID >= 200000000 {
		pool = []uint{100401, 100700, 100900, 101000, 109000}
		baseX, baseY = 700, 400
	}
	out := make([]spawnDef, 0, len(pool))
	for i, id := range pool {
		out = append(out, spawnDef{
			templateID: id,
			x:          baseX + float64(i-2)*140 + rand.Float64()*20,
			y:          baseY + float64((i%2)*2-1)*60,
		})
	}
	return out
}
