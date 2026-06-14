// 生成客户端占位资源（PNG 精灵 + WAV 音效）
// 用法: go run scripts/generate_assets.go
// 有 WZ 文件后可用 HaRepacker 导出真实资源覆盖同名文件。
package main

import (
	"fmt"
	"image"
	"image/color"
	"image/png"
	"math"
	"os"
	"path/filepath"
)

func main() {
	root := filepath.Join("..", "..", "client", "assets")
	dirs := []string{
		"audio",
		"sprites/player",
		"sprites/mob",
		"sprites/npc",
		"sprites/item",
		"images/tiles",
		"images/map",
	}
	for _, d := range dirs {
		if err := os.MkdirAll(filepath.Join(root, d), 0o755); err != nil {
			panic(err)
		}
	}

	// 玩家精灵（4帧行走序列）
	writeSpriteSheet(filepath.Join(root, "sprites/player/stand.png"), 48, 64, 4, color.RGBA{241, 196, 15, 255}, color.RGBA{211, 84, 0, 255})
	writeSpriteSheet(filepath.Join(root, "sprites/player/walk.png"), 48, 64, 4, color.RGBA{52, 152, 219, 255}, color.RGBA{41, 128, 185, 255})

	// 怪物精灵（079 MobID）
	mobs := map[int][2]color.RGBA{
		100100: {{135, 206, 250, 255}, {70, 130, 180, 255}},
		100101: {{255, 182, 193, 255}, {220, 20, 60, 255}},
		100200: {{144, 238, 144, 255}, {34, 139, 34, 255}},
		100400: {{255, 218, 185, 255}, {210, 105, 30, 255}},
		100800: {{169, 169, 169, 255}, {105, 105, 105, 255}},
		100900: {{192, 192, 192, 255}, {128, 128, 128, 255}},
		109000: {{255, 215, 0, 255}, {184, 134, 11, 255}},
	}
	for id, cols := range mobs {
		writeMobSprite(filepath.Join(root, fmt.Sprintf("sprites/mob/%d.png", id)), cols[0], cols[1])
	}

	// NPC
	writeMobSprite(filepath.Join(root, "sprites/npc/1022000.png"), color.RGBA{220, 20, 60, 255}, color.RGBA{139, 0, 0, 255})
	writeMobSprite(filepath.Join(root, "sprites/npc/1012100.png"), color.RGBA{46, 204, 113, 255}, color.RGBA{39, 174, 96, 255})

	// 地图块
	writeTile(filepath.Join(root, "images/tiles/grass.png"), color.RGBA{76, 153, 0, 255})
	writeTile(filepath.Join(root, "images/tiles/dirt.png"), color.RGBA{139, 90, 43, 255})
	writeTile(filepath.Join(root, "images/tiles/stone.png"), color.RGBA{128, 128, 128, 255})

	// BGM / SFX（WAV 占位，audioplayers 支持）
	bgmFiles := []string{
		"00001000", "00002000", "00100000", "00101000", "00102000",
		"00103000", "00200000", "00200001", "00300000", "00500000",
	}
	for _, name := range bgmFiles {
		writeToneWAV(filepath.Join(root, "audio", name+".wav"), 220+float64(len(name)*3), 2.0, 0.15)
	}
	sfx := map[string]float64{
		"sfx_hit": 440, "sfx_levelup": 880, "sfx_pickup": 660,
		"sfx_meso": 550, "sfx_portal": 330, "sfx_ui_click": 200,
		"sfx_chat": 300, "sfx_dead": 110, "sfx_revive": 770,
	}
	for name, freq := range sfx {
		writeToneWAV(filepath.Join(root, "audio", name+".wav"), freq, 0.3, 0.25)
	}
	writeToneWAV(filepath.Join(root, "audio/boss_zakum.wav"), 80, 3.0, 0.2)

	fmt.Println("✓ 占位资源已生成到 client/assets/")
	fmt.Println("  提示: 用 HaRepacker 从 WZ 导出真实 PNG/OGG 覆盖即可")
}

func writeSpriteSheet(path string, w, h, frames int, c1, c2 color.RGBA) {
	img := image.NewRGBA(image.Rect(0, 0, w*frames, h))
	for f := 0; f < frames; f++ {
		for y := 0; y < h; y++ {
			for x := 0; x < w; x++ {
				t := float64(y) / float64(h)
				r := uint8(float64(c1.R)*(1-t) + float64(c2.R)*t)
				g := uint8(float64(c1.G)*(1-t) + float64(c2.G)*t)
				b := uint8(float64(c1.B)*(1-t) + float64(c2.B)*t)
				img.Set(x+f*w, y, color.RGBA{r, g, b, 255})
			}
		}
		// 头部圆
		cx, cy := f*w+w/2, h/5
		for dy := -8; dy <= 8; dy++ {
			for dx := -8; dx <= 8; dx++ {
				if dx*dx+dy*dy <= 64 {
					img.Set(cx+dx, cy+dy, color.RGBA{245, 222, 179, 255})
				}
			}
		}
	}
	mustPNG(path, img)
}

func writeMobSprite(path string, c1, c2 color.RGBA) {
	w, h := 48, 48
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
	// 眼睛
	img.Set(16, 18, color.White)
	img.Set(31, 18, color.White)
	img.Set(16, 19, color.Black)
	img.Set(31, 19, color.Black)
	mustPNG(path, img)
}

func writeTile(path string, c color.RGBA) {
	const size = 64
	img := image.NewRGBA(image.Rect(0, 0, size, size))
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			noise := uint8((x ^ y) & 15)
			img.Set(x, y, color.RGBA{c.R - noise, c.G - noise, c.B - noise, 255})
		}
	}
	mustPNG(path, img)
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
	out := append(header, data...)
	if err := os.WriteFile(path, out, 0o644); err != nil {
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
	h[20] = 1 // PCM
	h[22] = 1 // mono
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
