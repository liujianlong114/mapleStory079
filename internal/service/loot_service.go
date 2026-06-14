package service

import (
	"errors"
	"fmt"
	"math"
	"math/rand"
	"sync"
	"time"
)

const (
	lootOwnerDuration = 30 * time.Second
	lootTTL           = 3 * time.Minute
	lootPickupRadius  = 80.0
)

// GroundLoot 地图上的可拾取掉落物（内存态，按 map/channel 隔离）。
type GroundLoot struct {
	ID        string  `json:"drop_id"`
	MapID     uint    `json:"map_id"`
	ItemID    int     `json:"item_id"`
	Quantity  int     `json:"quantity"`
	Mesos     int     `json:"mesos"`
	X         float64 `json:"x"`
	Y         float64 `json:"y"`
	OwnerID   uint    `json:"owner_id"`
	SpawnedAt int64   `json:"spawned_at"`
	ExpiresAt int64   `json:"expires_at"`
}

// LootService 管理地面掉落生成与拾取。
type LootService struct {
	mu     sync.RWMutex
	drops  map[string]*GroundLoot
	nextID uint64
	inv    *InventoryService
}

// DefaultLootService 全局单例，供 combat / handler / websocket 共享。
var DefaultLootService = NewLootService()

func NewLootService() *LootService {
	return &LootService{
		drops: make(map[string]*GroundLoot),
		inv:   NewInventoryService(),
	}
}

// SpawnFromRolls 将 RollMobDrops 结果生成地面掉落，坐标在 (x,y) 附近随机散开。
func (s *LootService) SpawnFromRolls(mapID, ownerID uint, x, y float64, rolls []DroppedItem) []GroundLoot {
	if len(rolls) == 0 {
		return nil
	}
	s.cleanupExpired()
	out := make([]GroundLoot, 0, len(rolls))
	now := time.Now()
	expires := now.Add(lootTTL).Unix()
	spawned := now.Unix()
	for i, d := range rolls {
		if d.ItemID <= 0 || d.Quantity <= 0 {
			continue
		}
		drop := s.insert(mapID, ownerID, d.ItemID, d.Quantity, 0,
			x+float64((i%3)-1)*18+rand.Float64()*10-5,
			y+float64((i/3)%3-1)*12+rand.Float64()*8-4,
			spawned, expires,
		)
		out = append(out, *drop)
	}
	return out
}

// SpawnMesos 生成金币堆（可选，当前战斗金币仍直接入账，此方法供扩展）。
func (s *LootService) SpawnMesos(mapID, ownerID uint, x, y float64, mesos int) *GroundLoot {
	if mesos <= 0 {
		return nil
	}
	s.cleanupExpired()
	now := time.Now()
	return s.insert(mapID, ownerID, 0, 0, mesos, x, y, now.Unix(), now.Add(lootTTL).Unix())
}

func (s *LootService) insert(mapID, ownerID uint, itemID, qty, mesos int, x, y float64, spawned, expires int64) *GroundLoot {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.nextID++
	id := fmt.Sprintf("drop_%d_%d", mapID, s.nextID)
	d := &GroundLoot{
		ID:        id,
		MapID:     mapID,
		ItemID:    itemID,
		Quantity:  qty,
		Mesos:     mesos,
		X:         x,
		Y:         y,
		OwnerID:   ownerID,
		SpawnedAt: spawned,
		ExpiresAt: expires,
	}
	s.drops[id] = d
	return d
}

// ListByMap 返回指定地图当前有效掉落。
func (s *LootService) ListByMap(mapID uint) []GroundLoot {
	s.cleanupExpired()
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := make([]GroundLoot, 0, 8)
	for _, d := range s.drops {
		if d.MapID == mapID {
			out = append(out, *d)
		}
	}
	return out
}

// Get 按 drop_id 查询。
func (s *LootService) Get(dropID string) (*GroundLoot, error) {
	s.cleanupExpired()
	s.mu.RLock()
	defer s.mu.RUnlock()
	d, ok := s.drops[dropID]
	if !ok {
		return nil, errors.New("drop not found")
	}
	cp := *d
	return &cp, nil
}

// Pickup 拾取：校验距离与归属，写入背包后移除地面掉落。
func (s *LootService) Pickup(dropID string, characterID uint, x, y float64) (*GroundLoot, error) {
	s.cleanupExpired()
	s.mu.Lock()
	defer s.mu.Unlock()

	d, ok := s.drops[dropID]
	if !ok {
		return nil, errors.New("drop not found")
	}
	if !s.canPickupLocked(d, characterID, x, y) {
		return nil, errors.New("cannot pickup: out of range or not owner")
	}

	if d.ItemID > 0 && d.Quantity > 0 {
		if err := s.inv.AddItem(characterID, d.ItemID, d.Quantity); err != nil {
			return nil, err
		}
	}
	// 金币地面拾取（若启用 SpawnMesos）
	if d.Mesos > 0 {
		// 简化：直接通过 repository 更新角色金币需 character 对象；此处仅移除地面物
		// 实际 mesos 在 combat 已入账，地面 mesos 暂不使用
	}

	cp := *d
	delete(s.drops, dropID)
	return &cp, nil
}

func (s *LootService) canPickupLocked(d *GroundLoot, characterID uint, x, y float64) bool {
	dx := d.X - x
	dy := d.Y - y
	if math.Sqrt(dx*dx+dy*dy) > lootPickupRadius {
		return false
	}
	if d.OwnerID == 0 || d.OwnerID == characterID {
		return true
	}
	// 归属期：30 秒内仅击杀者可拾取
	if time.Now().Unix()-d.SpawnedAt < int64(lootOwnerDuration.Seconds()) {
		return false
	}
	return true
}

func (s *LootService) cleanupExpired() {
	now := time.Now().Unix()
	s.mu.Lock()
	defer s.mu.Unlock()
	for id, d := range s.drops {
		if d.ExpiresAt <= now {
			delete(s.drops, id)
		}
	}
}
