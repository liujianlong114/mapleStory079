// 从 000010000.img.xml 导出彩虹村视差层 + 视口，供 Flutter 地图渲染。
//
//	go run scripts/export_rainbow_map/main.go
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
)

type layerOut struct {
	No    int    `json:"no"`
	Type  int    `json:"type"`
	X     int    `json:"x"`
	Y     int    `json:"y"`
	Rx    int    `json:"rx"`
	Ry    int    `json:"ry"`
	Alpha int    `json:"a"`
	BS    string `json:"bS"`
}

type mapOut struct {
	MapID      int        `json:"mapId"`
	Name       string     `json:"name"`
	BGM        string     `json:"bgm"`
	VRLeft     int        `json:"vrLeft"`
	VRRight    int        `json:"vrRight"`
	VRTop      int        `json:"vrTop"`
	VRBottom   int        `json:"vrBottom"`
	Width      int        `json:"width"`
	Height     int        `json:"height"`
	MapMark    string     `json:"mapMark"`
	Layers     []layerOut `json:"layers"`
	SpawnX     int        `json:"spawnX"`
	SpawnY     int        `json:"spawnY"`
}

func main() {
	xmlPath := os.Getenv("MAP_XML")
	if xmlPath == "" {
		xmlPath = filepath.Join("examples", "ms079-main", "wz", "Map.wz", "Map", "Map0", "000010000.img.xml")
	}
	data, err := os.ReadFile(xmlPath)
	if err != nil {
		panic(err)
	}
	body := string(data)

	out := mapOut{
		MapID: 1000000,
		Name:  "彩虹村",
		BGM:   "Bgm00/FloralLife",
	}
	out.VRLeft = intVal(body, `VRLeft`)
	out.VRRight = intVal(body, `VRRight`)
	out.VRTop = intVal(body, `VRTop`)
	out.VRBottom = intVal(body, `VRBottom`)
	out.Width = out.VRRight - out.VRLeft
	out.Height = out.VRBottom - out.VRTop
	out.MapMark = strVal(body, `mapMark`)
	out.BGM = strVal(body, `bgm`)
	if out.BGM == "" {
		out.BGM = "Bgm00/FloralLife"
	}

	blockRe := regexp.MustCompile(`<imgdir name="back">([\s\S]*?)</imgdir>\s*<imgdir name="life">`)
	if m := blockRe.FindStringSubmatch(body); len(m) > 1 {
		sub := m[1]
		layerRe := regexp.MustCompile(`<imgdir name="\d+">([\s\S]*?)</imgdir>`)
		for _, lm := range layerRe.FindAllStringSubmatch(sub, -1) {
			block := lm[1]
			out.Layers = append(out.Layers, layerOut{
				No:    intVal(block, "no"),
				Type:  intVal(block, "type"),
				X:     intVal(block, "x"),
				Y:     intVal(block, "y"),
				Rx:    intVal(block, "rx"),
				Ry:    intVal(block, "ry"),
				Alpha: intVal(block, "a"),
				BS:    strVal(block, "bS"),
			})
		}
	}

	// 默认出生点（与 pkg 中 character spawn 对齐）
	out.SpawnX = 400
	out.SpawnY = 470

	dst := filepath.Join("client", "assets", "maps", "1000000.json")
	_ = os.MkdirAll(filepath.Dir(dst), 0o755)
	f, _ := os.Create(dst)
	enc := json.NewEncoder(f)
	enc.SetIndent("", "  ")
	_ = enc.Encode(out)
	f.Close()
	fmt.Printf("✓ 彩虹村 %d layers → %s (%dx%d)\n", len(out.Layers), dst, out.Width, out.Height)
}

func intVal(block, key string) int {
	re := regexp.MustCompile(`<int name="` + key + `" value="(-?\d+)"`)
	m := re.FindStringSubmatch(block)
	if len(m) < 2 {
		return 0
	}
	v, _ := strconv.Atoi(m[1])
	return v
}

func strVal(block, key string) string {
	re := regexp.MustCompile(`<string name="` + key + `" value="([^"]*)"`)
	m := re.FindStringSubmatch(block)
	if len(m) < 2 {
		return ""
	}
	return m[1]
}
