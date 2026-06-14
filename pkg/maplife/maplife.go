package maplife

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
)

// LifeEntry 对应 Map.wz life 节点（怪物/ NPC 刷点）。
type LifeEntry struct {
	Type    string  `json:"type"` // "m" monster, "n" npc
	ID      uint    `json:"id"`
	X       float64 `json:"x"`
	Y       float64 `json:"y"`
	CY      float64 `json:"cy,omitempty"`
	FH      int     `json:"fh,omitempty"`
	Rx0     float64 `json:"rx0"`
	Rx1     float64 `json:"rx1"`
	MobTime int     `json:"mobTime,omitempty"`
	F       int     `json:"f,omitempty"`
	Hide    int     `json:"hide,omitempty"`
}

// MapLife 单张地图的 life 数据（含视口，用于坐标换算）。
type MapLife struct {
	MapID    uint        `json:"mapId"`
	WzFile   string      `json:"wzFile,omitempty"`
	VRLeft   int         `json:"vrLeft"`
	VRRight  int         `json:"vrRight"`
	VRTop    int         `json:"vrTop"`
	VRBottom int         `json:"vrBottom"`
	Life     []LifeEntry `json:"life"`
}

var (
	mu    sync.RWMutex
	cache = map[uint]*MapLife{}
)

// DataDir 默认 life JSON 目录（可被 MAPLIFE_DIR 覆盖）。
func DataDir() string {
	if d := os.Getenv("MAPLIFE_DIR"); d != "" {
		return d
	}
	return filepath.Join("data", "maplife")
}

// Load 读取地图 life；同 mapID 只解析一次并缓存。
func Load(mapID uint) (*MapLife, error) {
	mu.RLock()
	if m, ok := cache[mapID]; ok {
		mu.RUnlock()
		return m, nil
	}
	mu.RUnlock()

	path := filepath.Join(DataDir(), fmt.Sprintf("%d.json", mapID))
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var ml MapLife
	if err := json.Unmarshal(raw, &ml); err != nil {
		return nil, err
	}
	if ml.MapID == 0 {
		ml.MapID = mapID
	}

	mu.Lock()
	cache[mapID] = &ml
	mu.Unlock()
	return &ml, nil
}

// MobSpawns 返回 type=m 且未 hide 的刷怪点（屏幕坐标）。
func (m *MapLife) MobSpawns() []LifeEntry {
	if m == nil {
		return nil
	}
	out := make([]LifeEntry, 0, len(m.Life))
	for _, e := range m.Life {
		if e.Type != "m" || e.Hide != 0 {
			continue
		}
		out = append(out, e)
	}
	return out
}

// NpcSpawns 返回 type=n 且未 hide 的 NPC 刷点（屏幕坐标）。
func (m *MapLife) NpcSpawns() []LifeEntry {
	if m == nil {
		return nil
	}
	out := make([]LifeEntry, 0, len(m.Life))
	for _, e := range m.Life {
		if e.Type != "n" || e.Hide != 0 {
			continue
		}
		out = append(out, e)
	}
	return out
}

// ToScreen 将 WZ 坐标转为客户端屏幕坐标（与 export 脚本一致）。
func ToScreen(x, cy, vrLeft, vrBottom int) (float64, float64) {
	sx := float64(x - vrLeft)
	sy := float64(vrBottom - cy)
	return sx, sy
}

// ToScreenRx 将 WZ rx 转为屏幕 X。
func ToScreenRx(rx, vrLeft int) float64 {
	return float64(rx - vrLeft)
}

// ParseWZMobID 解析 life id 字符串（如 "0100101" → 100101）。
func ParseWZMobID(s string) (uint, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return 0, fmt.Errorf("empty mob id")
	}
	n, err := strconv.ParseUint(s, 10, 32)
	if err != nil {
		return 0, err
	}
	return uint(n), nil
}
