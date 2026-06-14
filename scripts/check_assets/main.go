// 检查 client/assets 中占位资源 vs 真实 WZ 导出资源。
//
//	go run scripts/check_assets/main.go
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

const (
	minRealPNG   = 512
	minRealAudio = 8192
)

func main() {
	root := filepath.Join("client", "assets")
	real, placeholder, missing := 0, 0, 0

	checkDir(root, "images/ui/login", ".png", minRealPNG, &real, &placeholder, &missing)
	checkDir(root, "characters/parts", ".png", minRealPNG, &real, &placeholder, &missing)
	checkDir(root, "audio", ".mp3", minRealAudio, &real, &placeholder, &missing)
	checkDir(root, "audio", ".wav", minRealAudio, &real, &placeholder, &missing)
	checkDir(root, "scenes", ".png", 4096, &real, &placeholder, &missing)

	fmt.Println("\n--- 登录 UI 关键文件 ---")
	keyFiles := []string{
		"images/ui/login/btn_login_normal.png",
		"images/ui/login/logo_0.png",
		"images/ui/login/newchar_charset.png",
		"audio/title.mp3",
		"audio/title.wav",
		"scenes/login_title.png",
	}
	for _, rel := range keyFiles {
		reportFile(filepath.Join(root, rel))
	}

	fmt.Printf("\n汇总: 真实 %d | 占位 %d | 缺失 %d\n", real, placeholder, missing)
	if placeholder > 0 || missing > 0 {
		fmt.Println("\n替换占位资源:")
		fmt.Println("  export MAPLE_WZ_ROOT=/path/to/MapleStory   # 079 客户端（含 Base.wz 二进制）")
		fmt.Println("  ./scripts/setup_maple_wz.sh")
		fmt.Println("\n或使用 HaRepacker PNG 导出后:")
		fmt.Println("  export WZ_HAREPACKER_ROOT=/path/to/png-dump")
		fmt.Println("  go run scripts/extract_wz_harepacker/main.go --force")
	}
}

func checkDir(root, sub, ext string, minSize int, real, placeholder, missing *int) {
	dir := filepath.Join(root, sub)
	_ = filepath.WalkDir(dir, func(path string, d os.DirEntry, err error) error {
		if err != nil || d.IsDir() || !strings.HasSuffix(strings.ToLower(d.Name()), ext) {
			return nil
		}
		st, err := os.Stat(path)
		if err != nil {
			*missing++
			return nil
		}
		if st.Size() >= int64(minSize) {
			*real++
		} else {
			*placeholder++
		}
		return nil
	})
}

func reportFile(path string) {
	st, err := os.Stat(path)
	if err != nil {
		fmt.Printf("  ✗ 缺失  %s\n", path)
		return
	}
	tag := "占位"
	min := minRealPNG
	if strings.HasSuffix(path, ".mp3") || strings.HasSuffix(path, ".wav") {
		min = minRealAudio
	}
	if strings.Contains(path, "scenes/") {
		min = 4096
	}
	if int(st.Size()) >= min {
		tag = "真实"
	}
	fmt.Printf("  %s  %6d B  %s\n", statusIcon(tag), st.Size(), path)
}

func statusIcon(tag string) string {
	if tag == "真实" {
		return "✓"
	}
	return "○"
}
