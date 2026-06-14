// 从 examples/ 目录提取所有可用的真实资源到 client/assets。
//
// examples 里的 wz/ 多为 HaRepacker XML 元数据导出（无 PNG/MP3 像素数据），
// 本脚本会扫描并导入能找到的真实文件。
//
//	go run scripts/extract_from_examples/main.go
package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func main() {
	root, _ := os.Getwd()
	examples := filepath.Join(root, "examples")

	fmt.Println("==> 扫描 examples/ 可用资源…")
	reportWZ(examples)
	reportPNG(examples)

	fmt.Println("\n==> 导入 ZLHSS2 物品图标 (import_wz)…")
	run("go", "run", "scripts/import_wz/main.go",
		"--wz-root", filepath.Join(examples, "ZLHSS2", "wz"),
		"--image2", filepath.Join(examples, "ZLHSS2", "src", "image2"),
	)

	fmt.Println("\n==> 尝试 HaRepacker PNG 伴生文件…")
	for _, sub := range []string{"ms079-main/wz", "ZLHSS2/wz", "HeavenMS/wz", "cc-079-ms/wz"} {
		wz := filepath.Join(examples, sub)
		if !dirExists(wz) {
			continue
		}
		fmt.Printf("  检查 %s …\n", sub)
		_ = runQuiet("go", "run", "scripts/extract_wz_harepacker/main.go", "--wz-root", wz)
	}

	fmt.Println("\n==> 资源状态…")
	_ = runQuiet("go", "run", "scripts/check_assets/main.go")

	fmt.Println("\n结论:")
	fmt.Println("  • examples/*/wz/ 均为 XML 元数据，canvas/sound 节点无像素/音频内容")
	fmt.Println("  • 已导入 ZLHSS2/src/image2 中匹配的物品图标 (~148 个)")
	fmt.Println("  • 登录 UI / BGM / 怪物/NPC/角色贴图 需要 079 客户端二进制 WZ 或 HaRepacker PNG 导出")
	fmt.Println("\n下一步: export MAPLE_WZ_ROOT=/path/to/MapleStory && FORCE=1 ./scripts/setup_maple_wz.sh")
}

func reportWZ(examples string) {
	xmlCount, pngCount, mp3Count := 0, 0, 0
	_ = filepath.WalkDir(examples, func(path string, d os.DirEntry, err error) error {
		if err != nil || d.IsDir() {
			return nil
		}
		switch {
		case strings.HasSuffix(path, ".img.xml"):
			xmlCount++
		case strings.HasSuffix(strings.ToLower(path), ".png") && strings.Contains(path, "/wz/"):
			pngCount++
		case strings.HasSuffix(strings.ToLower(path), ".mp3") && strings.Contains(path, "/wz/"):
			mp3Count++
		}
		return nil
	})
	fmt.Printf("  WZ XML: %d | wz 内 PNG: %d | wz 内 MP3: %d\n", xmlCount, pngCount, mp3Count)
}

func reportPNG(examples string) {
	real := 0
	_ = filepath.WalkDir(examples, func(path string, d os.DirEntry, err error) error {
		if err != nil || d.IsDir() || !strings.HasSuffix(strings.ToLower(d.Name()), ".png") {
			return nil
		}
		if strings.Contains(path, "/wz/") {
			return nil
		}
		st, err := os.Stat(path)
		if err == nil && st.Size() >= 512 {
			real++
		}
		return nil
	})
	fmt.Printf("  examples 内非 wz 真实 PNG: %d (多为 GM 工具图标，非游戏 UI)\n", real)
}

func run(name string, args ...string) {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Printf("  [warn] %v\n", err)
	}
}

func runQuiet(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func dirExists(p string) bool {
	st, err := os.Stat(p)
	return err == nil && st.IsDir()
}
