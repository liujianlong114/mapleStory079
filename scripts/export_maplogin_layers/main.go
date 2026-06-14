// 从 MapLogin2.img.xml + login.img back 导出视差层 JSON，供 Flutter 079 登录动画。
//
//	go run scripts/export_maplogin_layers/main.go
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strconv"

	ext "mapleStory079/scripts/lib"
)

type layerOut struct {
	No    int     `json:"no"`
	Type  int     `json:"type"`
	X     int     `json:"x"`
	Y     int     `json:"y"`
	Rx    int     `json:"rx"`
	Ry    int     `json:"ry"`
	Cx    int     `json:"cx"`
	Cy    int     `json:"cy"`
	Alpha int     `json:"a"`
	BS    string  `json:"bS"`
	Width int     `json:"w,omitempty"`
	Height int    `json:"h,omitempty"`
	ScreenX float64 `json:"screenX"`
	ScreenY float64 `json:"screenY"`
}

type canvasMeta struct {
	Width  int
	Height int
	OriginX int
	OriginY int
}

func main() {
	wz := ext.Ms079WzDir()
	mapLogin := filepath.Join(wz, "UI.wz", "MapLogin2.img.xml")
	loginBack := filepath.Join(wz, "Map.wz", "Back", "login.img.xml")

	layers := parseMapLoginBack(mapLogin)
	canvas := parseLoginBackCanvas(loginBack)
	for i := range layers {
		if c, ok := canvas[layers[i].No]; ok {
			layers[i].Width = c.Width
			layers[i].Height = c.Height
		}
		layers[i].ScreenX, layers[i].ScreenY = mapToScreen(layers[i].X, layers[i].Y)
	}

	out := map[string]any{
		"width":  800,
		"height": 600,
		"bgm":    "BgmUI/Title",
		"layers": layers,
	}
	dst := filepath.Join("client", "assets", "scenes", "maplogin2_layers.json")
	mustMkdir(filepath.Dir(dst))
	f, _ := os.Create(dst)
	enc := json.NewEncoder(f)
	enc.SetIndent("", "  ")
	_ = enc.Encode(out)
	f.Close()
	fmt.Printf("✓ %d layers → %s\n", len(layers), dst)
}

func mapToScreen(x, y int) (float64, float64) {
	// MapLogin2 地图坐标 → 800×600 视口（镜头中心约 400,300）
	return 400.0 + float64(x)*0.52, 300.0 + float64(y)*0.11
}

func parseMapLoginBack(path string) []layerOut {
	data, err := os.ReadFile(path)
	if err != nil {
		panic(err)
	}
	var layers []layerOut
	// 粗解析 back 下每个 imgdir
	blockRe := regexp.MustCompile(`<imgdir name="(\d+)">([\s\S]*?)</imgdir>`)
	intRe := func(block, key string) int {
		re := regexp.MustCompile(`<int name="` + key + `" value="(-?\d+)"`)
		m := re.FindStringSubmatch(block)
		if len(m) < 2 {
			return 0
		}
		v, _ := strconv.Atoi(m[1])
		return v
	}
	strRe := func(block, key string) string {
		re := regexp.MustCompile(`<string name="` + key + `" value="([^"]*)"`)
		m := re.FindStringSubmatch(block)
		if len(m) < 2 {
			return ""
		}
		return m[1]
	}

	body := string(data)
	start := regexp.MustCompile(`<imgdir name="back">`).FindStringIndex(body)
	if start == nil {
		return layers
	}
	sub := body[start[1]:]
	end := regexp.MustCompile(`</imgdir>\s*<imgdir name="life">`).FindStringIndex(sub)
	if end != nil {
		sub = sub[:end[0]]
	}
	for _, m := range blockRe.FindAllStringSubmatch(sub, -1) {
		block := m[2]
		if strRe(block, "bS") != "login" {
			continue
		}
		layers = append(layers, layerOut{
			No:    intRe(block, "no"),
			Type:  intRe(block, "type"),
			X:     intRe(block, "x"),
			Y:     intRe(block, "y"),
			Rx:    intRe(block, "rx"),
			Ry:    intRe(block, "ry"),
			Cx:    intRe(block, "cx"),
			Cy:    intRe(block, "cy"),
			Alpha: intRe(block, "a"),
			BS:    strRe(block, "bS"),
		})
	}
	return layers
}

func parseLoginBackCanvas(path string) map[int]canvasMeta {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil
	}
	body := string(data)
	start := regexp.MustCompile(`<imgdir name="back">`).FindStringIndex(body)
	if start == nil {
		return nil
	}
	sub := body[start[1]:]
	end := regexp.MustCompile(`</imgdir>\s*<imgdir name="ani">`).FindStringIndex(sub)
	if end != nil {
		sub = sub[:end[0]]
	}
	out := make(map[int]canvasMeta)
	re := regexp.MustCompile(`<canvas name="(\d+)" width="(\d+)" height="(\d+)">\s*<vector name="origin" x="(-?\d+)" y="(-?\d+)"`)
	for _, m := range re.FindAllStringSubmatch(sub, -1) {
		no, _ := strconv.Atoi(m[1])
		w, _ := strconv.Atoi(m[2])
		h, _ := strconv.Atoi(m[3])
		ox, _ := strconv.Atoi(m[4])
		oy, _ := strconv.Atoi(m[5])
		out[no] = canvasMeta{Width: w, Height: h, OriginX: ox, OriginY: oy}
	}
	return out
}

func mustMkdir(p string) {
	_ = os.MkdirAll(p, 0o755)
}
