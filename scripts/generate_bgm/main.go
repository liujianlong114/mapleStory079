// 在无真实 WZ 音频时生成更接近 079 氛围的循环 BGM（WAV）。
// 真实资源可用后会被 extract_wz_login 覆盖。
//
//	go run scripts/generate_bgm/main.go
package main

import (
	"encoding/binary"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

const sampleRate = 44100

type note struct {
	freq   float64
	start  float64
	length float64
	vol    float64
	wave   int // 0=sine 1=triangle 2=square-soft
}

func main() {
	out := filepath.Join("client", "assets", "audio")
	if err := os.MkdirAll(out, 0o755); err != nil {
		panic(err)
	}

	writeLoop(filepath.Join(out, "title.wav"), titleNotes(), 24.0)
	writeLoop(filepath.Join(out, "00001000.wav"), floralLifeNotes(), 20.0)
	writeLoop(filepath.Join(out, "00002000.wav"), harborNotes(), 22.0)

	// 复制到其它 map bgm 占位（真实 WZ 提取后会覆盖）
	for _, name := range []string{
		"00100000", "00101000", "00102000", "00103000",
		"00200000", "00200001", "00300000",
	} {
		data, _ := os.ReadFile(filepath.Join(out, "00001000.wav"))
		_ = os.WriteFile(filepath.Join(out, name+".wav"), data, 0o644)
	}

	fmt.Println("✓ BGM 已生成 → client/assets/audio/")
}

func titleNotes() []note {
	// 079 Title 氛围：C 大调轻快旋律（原创近似，非原曲采样）
	return []note{
		{523.25, 0.0, 0.45, 0.35, 1}, {659.25, 0.45, 0.45, 0.32, 1},
		{783.99, 0.9, 0.6, 0.38, 0}, {659.25, 1.5, 0.4, 0.28, 1},
		{587.33, 1.9, 0.4, 0.30, 1}, {523.25, 2.3, 0.5, 0.32, 0},
		{493.88, 2.8, 0.4, 0.25, 1}, {523.25, 3.2, 0.8, 0.35, 0},
		{392.00, 4.0, 0.5, 0.28, 1}, {440.00, 4.5, 0.5, 0.28, 1},
		{493.88, 5.0, 0.5, 0.30, 1}, {523.25, 5.5, 1.0, 0.38, 0},
		{261.63, 0.0, 6.5, 0.18, 2}, {329.63, 0.0, 6.5, 0.14, 2},
	}
}

func floralLifeNotes() []note {
	// 彩虹岛 FloralLife 氛围：舒缓田园
	return []note{
		{392.00, 0.0, 0.6, 0.30, 0}, {440.00, 0.6, 0.6, 0.28, 1},
		{493.88, 1.2, 0.8, 0.32, 0}, {440.00, 2.0, 0.5, 0.26, 1},
		{392.00, 2.5, 0.7, 0.30, 0}, {349.23, 3.2, 0.5, 0.25, 1},
		{392.00, 3.7, 1.0, 0.32, 0},
		{196.00, 0.0, 4.7, 0.20, 2}, {246.94, 0.0, 4.7, 0.15, 2},
	}
}

func harborNotes() []note {
	return []note{
		{349.23, 0.0, 0.5, 0.28, 1}, {392.00, 0.5, 0.5, 0.28, 1},
		{440.00, 1.0, 0.7, 0.32, 0}, {392.00, 1.7, 0.5, 0.26, 1},
		{349.23, 2.2, 0.8, 0.30, 0}, {293.66, 3.0, 0.6, 0.24, 1},
		{349.23, 3.6, 1.2, 0.32, 0},
		{174.61, 0.0, 4.8, 0.18, 2},
	}
}

func writeLoop(path string, notes []note, loopSec float64) {
	if loopSec <= 0 {
		loopSec = 8
	}
	samples := int(sampleRate * loopSec)
	buf := make([]float64, samples)
	for _, n := range notes {
		start := int(n.start * sampleRate)
		end := int((n.start + n.length) * sampleRate)
		if end > samples {
			end = samples
		}
		for i := start; i < end; i++ {
			t := float64(i-start) / sampleRate
			env := math.Min(1.0, math.Min(t*8, (n.length-t)*6))
			var v float64
			phase := 2 * math.Pi * n.freq * t
			switch n.wave {
			case 1:
				v = 2/math.Pi * math.Asin(math.Sin(phase))
			case 2:
				v = math.Sin(phase) * 0.6
			default:
				v = math.Sin(phase)
			}
			buf[i] += v * n.vol * env
		}
	}
	// 简单混响
	for i := sampleRate / 20; i < samples; i++ {
		buf[i] += buf[i-sampleRate/20] * 0.25
	}
	// 归一化
	max := 0.0
	for _, v := range buf {
		if av := math.Abs(v); av > max {
			max = av
		}
	}
	if max < 0.001 {
		max = 1
	}
	pcm := make([]int16, samples)
	for i, v := range buf {
		pcm[i] = int16(v / max * 28000)
	}
	writeWAV(path, pcm)
}

func writeWAV(path string, samples []int16) {
	f, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer f.Close()
	dataSize := len(samples) * 2
	_ = binary.Write(f, binary.LittleEndian, []byte("RIFF"))
	_ = binary.Write(f, binary.LittleEndian, uint32(36+dataSize))
	_, _ = f.Write([]byte("WAVEfmt "))
	_ = binary.Write(f, binary.LittleEndian, uint32(16))
	_ = binary.Write(f, binary.LittleEndian, uint16(1))
	_ = binary.Write(f, binary.LittleEndian, uint16(1))
	_ = binary.Write(f, binary.LittleEndian, uint32(sampleRate))
	_ = binary.Write(f, binary.LittleEndian, uint32(sampleRate*2))
	_ = binary.Write(f, binary.LittleEndian, uint16(2))
	_ = binary.Write(f, binary.LittleEndian, uint16(16))
	_, _ = f.Write([]byte("data"))
	_ = binary.Write(f, binary.LittleEndian, uint32(dataSize))
	for _, s := range samples {
		_ = binary.Write(f, binary.LittleEndian, s)
	}
}
