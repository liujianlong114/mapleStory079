// WZ XML 批量导入：从外部 ZLHSS2/wz 解析 Mob/Npc/Item/Sound 元数据，
// 生成 client/assets 占位 PNG/WAV，并输出 manifest.json。
//
// 用法:
//
//	go run scripts/import_wz/main.go
//	go run scripts/import_wz/main.go --wz-root examples/ZLHSS2/wz --out client/assets
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"image"
	"image/color"
	"image/png"
	"io"
	"math"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"

	ext "mapleStory079/scripts/lib"
)

var (
	wzRoot  = flag.String("wz-root", "", "WZ XML 根目录（默认外部 ZLHSS2）")
	outRoot = flag.String("out", "client/assets", "输出资源目录")
	image2  = flag.String("image2", "", "已有 PNG 图标目录")
)

type manifest struct {
	Mobs   map[string]mobEntry  `json:"mobs"`
	NPCs   map[string]npcEntry  `json:"npcs"`
	Items  map[string]itemEntry `json:"items"`
	BGM    map[string]string    `json:"bgm_by_name"`
	Counts map[string]int       `json:"counts"`
}

type mobEntry struct {
	WzFile string `json:"wz_file"`
	Width  int    `json:"width"`
	Height int    `json:"height"`
	Level  int    `json:"level,omitempty"`
}

type npcEntry struct {
	WzFile string `json:"wz_file"`
	Width  int    `json:"width"`
	Height int    `json:"height"`
}

type itemEntry struct {
	Source string `json:"source"` // generated | copied
	Path   string `json:"path"`
}

var canvasRe = regexp.MustCompile(`<canvas name="0" width="(\d+)" height="(\d+)"`)
var levelRe = regexp.MustCompile(`<int name="level" value="(\d+)"`)
var soundRe = regexp.MustCompile(`<sound name="([^"]+)"`)

func main() {
	flag.Parse()
	wz := *wzRoot
	if wz == "" {
		wz = ext.ZLHSS2WzDir()
	}
	img2 := *image2
	if img2 == "" {
		img2 = filepath.Join(ext.ExternalRoot(), ext.DirZLHSS2, "src", "image2")
	}
	m := manifest{
		Mobs:   make(map[string]mobEntry),
		NPCs:   make(map[string]npcEntry),
		Items:  make(map[string]itemEntry),
		BGM:    make(map[string]string),
		Counts: make(map[string]int),
	}

	dirs := []string{
		"sprites/mob", "sprites/npc", "sprites/item", "audio", "images/tiles",
	}
	for _, d := range dirs {
		mustMkdir(filepath.Join(*outRoot, d))
	}

	mobCount := importMobs(&m)
	npcCount := importNPCs(&m)
	itemCount := importItems(&m)
	bgmCount := importSound(&m)

	m.Counts = map[string]int{
		"mobs": mobCount, "npcs": npcCount, "items": itemCount, "bgm": bgmCount,
	}

	manifestPath := filepath.Join(*outRoot, "manifest.json")
	f, err := os.Create(manifestPath)
	if err != nil {
		panic(err)
	}
	enc := json.NewEncoder(f)
	enc.SetIndent("", "  ")
	if err := enc.Encode(m); err != nil {
		panic(err)
	}
	f.Close()

	fmt.Printf("✓ WZ 导入完成 → %s\n", *outRoot)
	fmt.Printf("  怪物 %d | NPC %d | 物品 %d | BGM %d\n", mobCount, npcCount, itemCount, bgmCount)
	fmt.Printf("  manifest: %s\n", manifestPath)
}

func importMobs(m *manifest) int {
	mobDir := filepath.Join(wz, "Mob.wz")
	entries, err := os.ReadDir(mobDir)
	if err != nil {
		fmt.Printf("  [warn] Mob.wz 不可用: %v\n", err)
		return 0
	}
	count := 0
	for _, e := range entries {
		if !strings.HasSuffix(e.Name(), ".img.xml") {
			continue
		}
		data, err := os.ReadFile(filepath.Join(mobDir, e.Name()))
		if err != nil {
			continue
		}
		w, h := parseStandCanvas(string(data))
		if w <= 0 {
			w, h = 48, 48
		}
		// 0100100.img.xml → 100100
		base := strings.TrimSuffix(e.Name(), ".img.xml")
		mobID, err := strconv.Atoi(strings.TrimLeft(base, "0"))
		if err != nil || mobID == 0 {
			continue
		}
		lvl := parseLevel(string(data))
		key := strconv.Itoa(mobID)
		m.Mobs[key] = mobEntry{WzFile: e.Name(), Width: w, Height: h, Level: lvl}

		outPath := filepath.Join(*outRoot, "sprites/mob", key+".png")
		if _, err := os.Stat(outPath); os.IsNotExist(err) {
			writeSizedMobPNG(outPath, w, h, mobID)
		}
		count++
	}
	return count
}

func importNPCs(m *manifest) int {
	npcDir := filepath.Join(wz, "Npc.wz")
	entries, err := os.ReadDir(npcDir)
	if err != nil {
		fmt.Printf("  [warn] Npc.wz 不可用: %v\n", err)
		return 0
	}
	count := 0
	for _, e := range entries {
		if !strings.HasSuffix(e.Name(), ".img.xml") {
			continue
		}
		data, err := os.ReadFile(filepath.Join(npcDir, e.Name()))
		if err != nil {
			continue
		}
		w, h := parseStandCanvas(string(data))
		if w <= 0 {
			w, h = 48, 64
		}
		base := strings.TrimSuffix(e.Name(), ".img.xml")
		npcID, err := strconv.Atoi(strings.TrimLeft(base, "0"))
		if err != nil || npcID == 0 {
			continue
		}
		key := strconv.Itoa(npcID)
		m.NPCs[key] = npcEntry{WzFile: e.Name(), Width: w, Height: h}
		outPath := filepath.Join(*outRoot, "sprites/npc", key+".png")
		if _, err := os.Stat(outPath); os.IsNotExist(err) {
			writeSizedMobPNG(outPath, w, h, npcID)
		}
		count++
	}
	return count
}

func importItems(m *manifest) int {
	count := 0
	// 从 image2 复制数字文件名的 PNG
	if st, err := os.Stat(img2); err == nil && st.IsDir() {
		entries, _ := os.ReadDir(img2)
		for _, e := range entries {
			if !strings.HasSuffix(strings.ToLower(e.Name()), ".png") {
				continue
			}
			base := strings.TrimSuffix(e.Name(), ".png")
			if _, err := strconv.Atoi(base); err != nil {
				continue
			}
			src := filepath.Join(img2, e.Name())
			dst := filepath.Join(*outRoot, "sprites/item", e.Name())
			if err := copyFile(src, dst); err == nil {
				m.Items[base] = itemEntry{Source: "copied", Path: "sprites/item/" + e.Name()}
				count++
			}
		}
	}
	// Item.wz 仅记录 ID（无内嵌 PNG）
	itemDir := filepath.Join(wz, "Item.wz")
	filepath.WalkDir(itemDir, func(path string, d os.DirEntry, err error) error {
		if err != nil || d.IsDir() || !strings.HasSuffix(d.Name(), ".img.xml") {
			return nil
		}
		base := strings.TrimSuffix(d.Name(), ".img.xml")
		if id, err := strconv.Atoi(base); err == nil && id > 0 {
			key := strconv.Itoa(id)
			if _, ok := m.Items[key]; !ok {
				outPath := filepath.Join(*outRoot, "sprites/item", key+".png")
				if _, err := os.Stat(outPath); os.IsNotExist(err) {
					writeItemIcon(outPath, id)
					m.Items[key] = itemEntry{Source: "generated", Path: "sprites/item/" + key + ".png"}
					count++
				}
			}
		}
		return nil
	})
	return count
}

func importSound(m *manifest) int {
	soundDir := filepath.Join(wz, "Sound.wz")
	entries, err := os.ReadDir(soundDir)
	if err != nil {
		fmt.Printf("  [warn] Sound.wz 不可用: %v\n", err)
		return 0
	}
	// 079 地图 BGM 名 → 客户端 wav 文件名（与 assets.dart BgmAssets 对齐）
	bgmMap := map[string]string{
		"FloralLife": "00001000", "SleepyWood": "00002000", "GoPicnic": "00100000",
		"Nightmare": "00101000", "RestNPeace": "00102000", "MoonlightShadow": "00103000",
		"WhereverYouAre": "00200000", "WhereverYouAre2": "00200001",
		"Shinin'Harbor": "00300000", "HighlandStar": "00500000",
	}
	count := 0
	for _, e := range entries {
		if !strings.HasPrefix(e.Name(), "Bgm") || !strings.HasSuffix(e.Name(), ".img.xml") {
			continue
		}
		data, err := os.ReadFile(filepath.Join(soundDir, e.Name()))
		if err != nil {
			continue
		}
		for _, name := range soundRe.FindAllStringSubmatch(string(data), -1) {
			bgmName := name[1]
			wavName, ok := bgmMap[bgmName]
			if !ok {
				wavName = sanitizeFileName(bgmName)
			}
			m.BGM[bgmName] = wavName + ".wav"
			outPath := filepath.Join(*outRoot, "audio", wavName+".wav")
			if _, err := os.Stat(outPath); os.IsNotExist(err) {
				freq := 220.0 + float64((len(bgmName)*7)%400)
				writeToneWAV(outPath, freq, 2.0, 0.12)
			}
			count++
		}
	}
	return count
}

func parseStandCanvas(xml string) (int, int) {
	idx := strings.Index(xml, `name="stand"`)
	if idx < 0 {
		idx = strings.Index(xml, `name="move"`)
	}
	if idx < 0 {
		return 0, 0
	}
	sub := xml[idx:]
	m := canvasRe.FindStringSubmatch(sub)
	if len(m) < 3 {
		return 0, 0
	}
	w, _ := strconv.Atoi(m[1])
	h, _ := strconv.Atoi(m[2])
	return w, h
}

func parseLevel(xml string) int {
	m := levelRe.FindStringSubmatch(xml)
	if len(m) < 2 {
		return 0
	}
	v, _ := strconv.Atoi(m[1])
	return v
}

func writeSizedMobPNG(path string, w, h, seed int) {
	if w < 16 {
		w = 16
	}
	if h < 16 {
		h = 16
	}
	if w > 128 {
		w = 128
	}
	if h > 128 {
		h = 128
	}
	c1, c2 := colorsFromSeed(seed)
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			t := float64(y) / float64(h)
			img.Set(x, y, color.RGBA{
				R: uint8(float64(c1.R)*(1-t) + float64(c2.R)*t),
				G: uint8(float64(c1.G)*(1-t) + float64(c2.G)*t),
				B: uint8(float64(c1.B)*(1-t) + float64(c2.B)*t),
				A: 255,
			})
		}
	}
	ex, ey := w/4, h/3
	if ex > 0 && ey > 0 {
		img.Set(ex, ey, color.White)
		img.Set(w-ex-1, ey, color.White)
	}
	mustPNG(path, img)
}

func writeItemIcon(path string, itemID int) {
	const size = 32
	c1, c2 := colorsFromSeed(itemID)
	img := image.NewRGBA(image.Rect(0, 0, size, size))
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			if x < 2 || y < 2 || x >= size-2 || y >= size-2 {
				img.Set(x, y, color.RGBA{60, 60, 60, 255})
				continue
			}
			t := float64(x+y) / float64(size*2)
			img.Set(x, y, color.RGBA{
				R: uint8(float64(c1.R)*(1-t) + float64(c2.R)*t),
				G: uint8(float64(c1.G)*(1-t) + float64(c2.G)*t),
				B: uint8(float64(c1.B)*(1-t) + float64(c2.B)*t),
				A: 255,
			})
		}
	}
	mustPNG(path, img)
}

func colorsFromSeed(seed int) (color.RGBA, color.RGBA) {
	r := uint8((seed*17)%156 + 80)
	g := uint8((seed*31)%156 + 80)
	b := uint8((seed*53)%156 + 80)
	return color.RGBA{r, g, b, 255}, color.RGBA{r / 2, g / 2, b / 2, 255}
}

func sanitizeFileName(s string) string {
	s = strings.Map(func(r rune) rune {
		if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') {
			return r
		}
		return '_'
	}, s)
	if s == "" {
		return "bgm_unknown"
	}
	return strings.ToLower(s)
}

func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer out.Close()
	_, err = io.Copy(out, in)
	return err
}

func mustMkdir(path string) {
	if err := os.MkdirAll(path, 0o755); err != nil {
		panic(err)
	}
}

func mustPNG(path string, img image.Image) {
	f, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer f.Close()
	if err := png.Encode(f, img); err != nil {
		panic(err)
	}
}

func writeToneWAV(path string, freq, durationSec, volume float64) {
	const sampleRate = 22050
	nSamples := int(float64(sampleRate) * durationSec)
	data := make([]byte, nSamples*2)
	for i := 0; i < nSamples; i++ {
		t := float64(i) / float64(sampleRate)
		env := 1.0
		if t > durationSec*0.7 {
			env = (durationSec - t) / (durationSec * 0.3)
		}
		sample := int16(float64(32767) * volume * env * math.Sin(2*math.Pi*freq*t))
		data[i*2] = byte(sample)
		data[i*2+1] = byte(sample >> 8)
	}
	header := buildWAVHeader(len(data), sampleRate)
	if err := os.WriteFile(path, append(header, data...), 0o644); err != nil {
		panic(err)
	}
}

func buildWAVHeader(dataLen, sampleRate int) []byte {
	fileLen := 36 + dataLen
	h := make([]byte, 44)
	copy(h[0:4], "RIFF")
	h[4] = byte(fileLen)
	h[5] = byte(fileLen >> 8)
	h[6] = byte(fileLen >> 16)
	h[7] = byte(fileLen >> 24)
	copy(h[8:12], "WAVE")
	copy(h[12:16], "fmt ")
	h[16] = 16
	h[20] = 1
	h[22] = 1
	h[24] = byte(sampleRate)
	h[25] = byte(sampleRate >> 8)
	h[26] = byte(sampleRate >> 16)
	h[27] = byte(sampleRate >> 24)
	byteRate := sampleRate * 2
	h[28] = byte(byteRate)
	h[29] = byte(byteRate >> 8)
	h[30] = byte(byteRate >> 16)
	h[31] = byte(byteRate >> 24)
	h[32] = 2
	h[34] = 16
	copy(h[36:40], "data")
	h[40] = byte(dataLen)
	h[41] = byte(dataLen >> 8)
	h[42] = byte(dataLen >> 16)
	h[43] = byte(dataLen >> 24)
	return h
}
