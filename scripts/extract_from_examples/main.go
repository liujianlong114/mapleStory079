// 从外部参考目录 mapleStory079-external 扫描并导入可用资源到 client/assets。
//
//	go run scripts/extract_from_examples/main.go
package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	ext "mapleStory079/scripts/lib"
)

func main() {
	external := ext.ExternalRoot()

	fmt.Printf("==> 扫描外部参考目录: %s\n", external)
	reportWZ(external)
	reportPNG(external)

	fmt.Println("\n==> 导入 ZLHSS2 物品图标 (import_wz)…")
	run("go", "run", "scripts/import_wz/main.go")

	fmt.Println("\n==> 尝试 HaRepacker PNG 伴生文件…")
	for _, sub := range []string{
		filepath.Join(ext.DirMs079Main, "wz"),
		filepath.Join(ext.DirZLHSS2, "wz"),
		"05-HeavenMS-v83参考-服务端架构-已归档/wz",
		"10-cc-079-ms-Java079参考/wz",
	} {
		wz := filepath.Join(external, sub)
		if !dirExists(wz) {
			continue
		}
		fmt.Printf("  检查 %s …\n", sub)
		_ = runQuiet("go", "run", "scripts/extract_wz_harepacker/main.go", "--wz-root", wz)
	}

	fmt.Println("\n完成。运行 go run scripts/check_assets/main.go 查看统计。")
}

func reportWZ(examples string) {
	fmt.Println("\n--- WZ 目录 ---")
	_ = filepath.WalkDir(examples, func(path string, d os.DirEntry, err error) error {
		if err != nil || !d.IsDir() {
			return nil
		}
		if d.Name() == "Base.wz" || d.Name() == "UI.wz" {
			parent := filepath.Dir(path)
			fmt.Printf("  XML 元数据: %s\n", parent)
		}
		return nil
	})
	fmt.Println("  • 外部 */wz/ 多为 XML 元数据，canvas/sound 节点无像素/音频内容")
}

func reportPNG(examples string) {
	var count int
	_ = filepath.WalkDir(examples, func(path string, d os.DirEntry, err error) error {
		if err != nil || d.IsDir() {
			return nil
		}
		if strings.HasSuffix(strings.ToLower(path), ".png") {
			count++
		}
		return nil
	})
	fmt.Printf("\n--- PNG 文件总数: %d ---\n", count)
}

func dirExists(p string) bool {
	st, err := os.Stat(p)
	return err == nil && st.IsDir()
}

func run(name string, args ...string) {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	_ = cmd.Run()
}

func runQuiet(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
