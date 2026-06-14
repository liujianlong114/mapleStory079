// 从 Map.wz XML 导出 life 刷怪/NPC 点到 data/maplife/{mapId}.json
//
//	go run scripts/export_map_life/main.go
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
)

type lifeEntry struct {
	Type    string  `json:"type"`
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

type mapLifeOut struct {
	MapID    uint        `json:"mapId"`
	WzFile   string      `json:"wzFile"`
	VRLeft   int         `json:"vrLeft"`
	VRRight  int         `json:"vrRight"`
	VRTop    int         `json:"vrTop"`
	VRBottom int         `json:"vrBottom"`
	Life     []lifeEntry `json:"life"`
}

type exportSpec struct {
	MapID  uint
	WzFile string
}

func main() {
	wzRoot := os.Getenv("WZ_MAP_ROOT")
	if wzRoot == "" {
		wzRoot = filepath.Join("examples", "ellermister-MapleStory", "wz", "Map.wz", "Map", "Map0")
	}
	dstDir := filepath.Join("data", "maplife")
	_ = os.MkdirAll(dstDir, 0o755)

	specs := []exportSpec{
		{MapID: 1000000, WzFile: "000010000.img.xml"},
		{MapID: 1000001, WzFile: "001010000.img.xml"},
		{MapID: 101010000, WzFile: "001010000.img.xml"},
	}

	for _, spec := range specs {
		xmlPath := filepath.Join(wzRoot, spec.WzFile)
		out, err := parseMapLife(xmlPath, spec.MapID, spec.WzFile)
		if err != nil {
			fmt.Fprintf(os.Stderr, "✗ %d: %v\n", spec.MapID, err)
			continue
		}
		dst := filepath.Join(dstDir, fmt.Sprintf("%d.json", spec.MapID))
		f, err := os.Create(dst)
		if err != nil {
			panic(err)
		}
		enc := json.NewEncoder(f)
		enc.SetIndent("", "  ")
		_ = enc.Encode(out)
		f.Close()
		mobs := 0
		npcs := 0
		for _, e := range out.Life {
			if e.Type == "m" {
				mobs++
			} else if e.Type == "n" {
				npcs++
			}
		}
		fmt.Printf("✓ map %d ← %s (%d mobs, %d npcs) → %s\n", spec.MapID, spec.WzFile, mobs, npcs, dst)
	}
}

func parseMapLife(xmlPath string, mapID uint, wzFile string) (*mapLifeOut, error) {
	data, err := os.ReadFile(xmlPath)
	if err != nil {
		return nil, err
	}
	body := string(data)

	out := &mapLifeOut{
		MapID:  mapID,
		WzFile: wzFile,
	}
	out.VRLeft = intVal(body, "VRLeft")
	out.VRRight = intVal(body, "VRRight")
	out.VRTop = intVal(body, "VRTop")
	out.VRBottom = intVal(body, "VRBottom")

	sub := extractLifeBlock(body)
	if sub == "" {
		return out, nil
	}
	entryRe := regexp.MustCompile(`<imgdir name="\d+">([\s\S]*?)</imgdir>`)
	for _, em := range entryRe.FindAllStringSubmatch(sub, -1) {
		block := em[1]
		typ := strVal(block, "type")
		if typ == "" {
			continue
		}
		idStr := strVal(block, "id")
		id, _ := strconv.ParseUint(strings.TrimSpace(idStr), 10, 32)
		if id == 0 {
			continue
		}
		wzX := intVal(block, "x")
		wzY := intVal(block, "y")
		cy := intVal(block, "cy")
		if cy == 0 {
			cy = wzY
		}
		rx0 := intVal(block, "rx0")
		rx1 := intVal(block, "rx1")
		sx, sy := toScreen(wzX, cy, out.VRLeft, out.VRBottom)
		srx0 := toScreenRx(rx0, out.VRLeft)
		srx1 := toScreenRx(rx1, out.VRLeft)

		e := lifeEntry{
			Type: typ,
			ID:   uint(id),
			X:    sx,
			Y:    sy,
			CY:   float64(cy),
			FH:   intVal(block, "fh"),
			Rx0:  srx0,
			Rx1:  srx1,
			F:    intVal(block, "f"),
			Hide: intVal(block, "hide"),
		}
		if mt := intVal(block, "mobTime"); mt != 0 {
			e.MobTime = mt
		}
		out.Life = append(out.Life, e)
	}
	return out, nil
}

func toScreen(x, cy, vrLeft, vrBottom int) (float64, float64) {
	return float64(x - vrLeft), float64(vrBottom - cy)
}

func toScreenRx(rx, vrLeft int) float64 {
	return float64(rx - vrLeft)
}

func extractLifeBlock(body string) string {
	const marker = `<imgdir name="life">`
	i := strings.Index(body, marker)
	if i < 0 {
		return ""
	}
	i += len(marker)
	depth := 1
	for j := i; j < len(body); j++ {
		if strings.HasPrefix(body[j:], "<imgdir") {
			depth++
		} else if strings.HasPrefix(body[j:], "</imgdir>") {
			depth--
			if depth == 0 {
				return body[i:j]
			}
		}
	}
	return ""
}

func intVal(block, key string) int {
	re := regexp.MustCompile(`<int name="` + key + `" value="(-?\d+)"`)
	if m := re.FindStringSubmatch(block); len(m) > 1 {
		n, _ := strconv.Atoi(m[1])
		return n
	}
	return 0
}

func strVal(block, key string) string {
	re := regexp.MustCompile(`<string name="` + key + `" value="([^"]*)"`)
	if m := re.FindStringSubmatch(block); len(m) > 1 {
		return m[1]
	}
	return ""
}
