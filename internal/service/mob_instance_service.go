package service

import (
	"fmt"
	"math"
	"sync"
	"time"

	"mapleStory079/internal/repository"
	"mapleStory079/pkg/maplife"
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
	Rx0        float64 `json:"rx0"`
	Rx1        float64 `json:"rx1"`
	Speed      int     `json:"speed"`
	Facing     int     `json:"facing"`
	Alive      bool    `json:"alive"`
}

type spawnDef struct {
	templateID uint
	x, y       float64
	rx0, rx1   float64
	facing     int
}

type mobInstanceInternal struct {
	MobInstance
	respawnAt time.Time
	spawnX    float64
	spawnY    float64
	moving    bool
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

// EnsureMap 确保地图已有怪物实例，若无则按 WZ life 或默认池生成。
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
	inst := s.findLocked(instanceID)
	if inst == nil {
		s.mu.Unlock()
		return nil, fmt.Errorf("mob instance %d not found", instanceID)
	}
	if hp < 0 {
		hp = 0
	}
	inst.HP = hp
	killed := false
	var mapID, id uint
	if hp <= 0 {
		inst.Alive = false
		inst.respawnAt = time.Now().Add(mobRespawnDelay)
		killed = true
		mapID = inst.MapID
		id = inst.InstanceID
		go s.scheduleRespawn(instanceID)
	}
	cp := inst.MobInstance
	s.mu.Unlock()
	if killed {
		NotifyMobDead(mapID, id)
	}
	return &cp, nil
}

func (s *MobInstanceService) ApplyDamage(instanceID uint, damage int) (*MobInstance, bool, error) {
	s.mu.Lock()
	inst := s.findLocked(instanceID)
	if inst == nil {
		s.mu.Unlock()
		return nil, false, fmt.Errorf("mob instance %d not found", instanceID)
	}
	if !inst.Alive {
		cp := inst.MobInstance
		s.mu.Unlock()
		return &cp, false, fmt.Errorf("mob already dead")
	}
	if damage < 0 {
		damage = 0
	}
	inst.HP -= damage
	killed := false
	var mapID, id uint
	if inst.HP <= 0 {
		inst.HP = 0
		inst.Alive = false
		inst.respawnAt = time.Now().Add(mobRespawnDelay)
		killed = true
		mapID = inst.MapID
		id = inst.InstanceID
		go s.scheduleRespawn(instanceID)
	}
	cp := inst.MobInstance
	s.mu.Unlock()
	if killed {
		NotifyMobDead(mapID, id)
	}
	return &cp, killed, nil
}

// TickAI 服务端水平巡逻（与客户端 AI 同逻辑，不含追击玩家）。
func (s *MobInstanceService) TickAI(dt float64) []MobMoveUpdate {
	s.mu.Lock()
	defer s.mu.Unlock()

	var updates []MobMoveUpdate
	for mapID, list := range s.byMap {
		s.respawnDueLocked(mapID)
		for _, inst := range list {
			if !inst.Alive {
				continue
			}
			if inst.tickPatrol(dt) {
				updates = append(updates, MobMoveUpdate{
					MapID:      inst.MapID,
					InstanceID: inst.InstanceID,
					TemplateID: inst.TemplateID,
					X:          inst.X,
					Y:          inst.Y,
					Facing:     inst.Facing,
					Moving:     inst.moving,
				})
			}
		}
	}
	return updates
}

func (inst *mobInstanceInternal) tickPatrol(dt float64) bool {
	const patrolFactor = 0.55
	speedPx := float64(inst.Speed) * 0.045
	if speedPx <= 0 {
		speedPx = 60 * 0.045
	}
	if inst.Facing == 0 {
		inst.Facing = 1
	}
	if inst.X >= inst.Rx1-4 {
		inst.Facing = -1
	}
	if inst.X <= inst.Rx0+4 {
		inst.Facing = 1
	}
	oldX := inst.X
	inst.X += float64(inst.Facing) * speedPx * dt * patrolFactor
	inst.X = math.Max(inst.Rx0, math.Min(inst.Rx1, inst.X))
	inst.Y = inst.spawnY
	inst.moving = math.Abs(inst.X-oldX) > 0.01
	return inst.moving
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
	defs := spawnsForMap(mapID)
	list := make([]*mobInstanceInternal, 0, len(defs))
	for _, d := range defs {
		tmpl, err := repository.GetMobByID(d.templateID)
		if err != nil || tmpl == nil {
			continue
		}
		s.nextID++
		id := uint(s.nextID)
		facing := d.facing
		if facing == 0 {
			facing = 1
		}
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
				Rx0:        d.rx0,
				Rx1:        d.rx1,
				Speed:      tmpl.Speed,
				Facing:     facing,
				Alive:      true,
			},
			spawnX: d.x,
			spawnY: d.y,
		})
	}
	s.byMap[mapID] = list
}

func spawnsForMap(mapID uint) []spawnDef {
	if ml, err := maplife.Load(mapID); err == nil {
		mobs := ml.MobSpawns()
		if len(mobs) > 0 {
			out := make([]spawnDef, 0, len(mobs))
			for _, e := range mobs {
				facing := 1
				if e.F != 0 {
					facing = -1
				}
				out = append(out, spawnDef{
					templateID: e.ID,
					x:          e.X,
					y:          e.Y,
					rx0:        e.Rx0,
					rx1:        e.Rx1,
					facing:     facing,
				})
			}
			return out
		}
		// life 文件存在但无怪物 → 不刷怪
		return nil
	}
	return defaultSpawns(mapID)
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
		inst.X = inst.spawnX
		inst.Y = inst.spawnY
		inst.respawnAt = time.Time{}
		cp := inst.MobInstance
		go NotifyMobRespawn(&cp)
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
	inst.X = inst.spawnX
	inst.Y = inst.spawnY
	inst.respawnAt = time.Time{}
	cp := inst.MobInstance
	go NotifyMobRespawn(&cp)
}

func defaultSpawns(mapID uint) []spawnDef {
	switch {
	case mapID == 0:
		return nil
	case mapID == 10000 || mapID == 1000000 || mapID == 1000002:
		// 1000000 彩虹村 WZ 无怪物；1000001 由 life 文件驱动
		return nil
	default:
		baseX, baseY := 800.0, 450.0
		pool := []uint{100100, 100101, 100200, 100400, 100800}
		if mapID >= 200000000 {
			pool = []uint{100401, 100700, 100900, 101000, 109000}
			baseX, baseY = 700, 400
		}
		out := make([]spawnDef, 0, len(pool))
		for i, id := range pool {
			x := baseX + float64(i-2)*140
			y := baseY + float64((i%2)*2-1)*60
			out = append(out, spawnDef{
				templateID: id,
				x:          x,
				y:          y,
				rx0:        x - 120,
				rx1:        x + 120,
				facing:     1,
			})
		}
		return out
	}
}
