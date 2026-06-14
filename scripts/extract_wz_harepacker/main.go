// 从 HaRepacker「PNG/MP3 导出」目录复制登录/选角/创建角色资源到 client/assets。
//
// HaRepacker 导出后目录结构示例:
//
//	wz-root/UI.wz/Login.img/Title/BtLogin/normal/0.png
//	wz-root/Sound.wz/BgmUI.img/Title.mp3
//
// 用法:
//
//	go run scripts/extract_wz_harepacker/main.go
//	WZ_HAREPACKER_ROOT=/path/to/png-dump go run scripts/extract_wz_harepacker/main.go
package main

import (
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	ext "mapleStory079/scripts/lib"
)

var (
	wzRoot = flag.String("wz-root", "", "HaRepacker PNG/MP3 导出根目录")
	outDir = flag.String("out", "client/assets", "输出目录")
	force  = flag.Bool("force", false, "覆盖已有占位文件")
)

const minRealPNG = 512

type copyJob struct {
	Sources []string
	OutFile string
	Kind    string // png | sound
}

func main() {
	flag.Parse()
	root := *wzRoot
	if root == "" {
		if v := os.Getenv("WZ_HAREPACKER_ROOT"); v != "" {
			root = v
		} else if v := os.Getenv("MAPLE_WZ_ROOT"); v != "" {
			root = v
		} else {
			root = ext.Ms079WzDir()
		}
	}
	if !dirExists(root) {
		fmt.Printf("❌ 目录不存在: %s\n", root)
		os.Exit(1)
	}

	jobs := buildJobs()
	ok, skip, fail := 0, 0, 0
	for _, job := range jobs {
		src := findFirst(root, job.Sources)
		if src == "" {
			if job.Kind == "sound" {
				skip++
			} else {
				fail++
			}
			continue
		}
		dst := filepath.Join(*outDir, job.OutFile)
		if !*force && isRealFile(dst, job.Kind) {
			skip++
			continue
		}
		if err := copyAsset(src, dst); err != nil {
			fmt.Printf("  ✗ %s: %v\n", job.OutFile, err)
			fail++
			continue
		}
		fmt.Printf("  ✓ %s ← %s\n", job.OutFile, trimRoot(root, src))
		ok++
	}

	fmt.Printf("\nHaRepacker 复制: 成功 %d | 跳过 %d | 未找到 %d\n", ok, skip, fail)
	if ok == 0 {
		fmt.Printf("\n⚠️  %s 内未找到 HaRepacker 导出的 PNG/MP3（仅有 XML 元数据时无法解析贴图/音乐）。\n", root)
		fmt.Println("   请用 HaRepacker 对 079 客户端执行「PNG\\MP3 导出」，或设置 MAPLE_WZ_ROOT 指向含 Base.wz 的客户端后运行:")
		fmt.Println("   ./scripts/setup_maple_wz.sh")
		os.Exit(1)
	}
	fmt.Println("请运行: go run scripts/build_login_scene/main.go --force")
}

func buildJobs() []copyJob {
	j := func(sources []string, out, kind string) copyJob {
		return copyJob{Sources: sources, OutFile: out, Kind: kind}
	}
	png := func(wzRel, out string) copyJob {
		return j(pngSources(wzRel), out, "png")
	}
	snd := func(wzRel, out string) copyJob {
		return j(soundSources(wzRel), out, "sound")
	}

	jobs := []copyJob{
		snd("Sound.wz/BgmUI.img/Title", "audio/title.mp3"),
		snd("Sound.wz/BgmUI.img/Title", "audio/title.wav"),
		snd("Sound.wz/UI.img/CharSelect", "audio/char_select.mp3"),
		snd("Sound.wz/UI.img/CharSelect", "audio/char_select.wav"),
		snd("Sound.wz/BgmUI.img/WCSelect", "audio/char_select.mp3"),

		png("UI.wz/Login.img/Title/BtLogin/normal/0", "images/ui/login/btn_login_normal.png"),
		png("UI.wz/Login.img/Title/BtLogin/mouseOver/0", "images/ui/login/btn_login_over.png"),
		png("UI.wz/Login.img/Title/BtLogin/pressed/0", "images/ui/login/btn_login_pressed.png"),
		png("UI.wz/Login.img/Title/BtQuit/normal/0", "images/ui/login/btn_quit_normal.png"),
		png("UI.wz/Login.img/Title/BtQuit/mouseOver/0", "images/ui/login/btn_quit_over.png"),
		png("UI.wz/Login.img/CharSelect/BtSelect/normal/0", "images/ui/login/btn_select_normal.png"),
		png("UI.wz/Login.img/CharSelect/BtSelect/mouseOver/0", "images/ui/login/btn_select_over.png"),
		png("UI.wz/Login.img/CharSelect/BtSelect/pressed/0", "images/ui/login/btn_select_pressed.png"),
		png("UI.wz/Login.img/CharSelect/BtNew/normal/0", "images/ui/login/btn_new_normal.png"),
		png("UI.wz/Login.img/CharSelect/BtNew/mouseOver/0", "images/ui/login/btn_new_over.png"),
		png("UI.wz/Login.img/CharSelect/BtDelete/normal/0", "images/ui/login/btn_delete_normal.png"),
		png("UI.wz/Login.img/CharSelect/BtDelete/mouseOver/0", "images/ui/login/btn_delete_over.png"),
		png("UI.wz/Login.img/Common/BtStart/normal/0", "images/ui/login/btn_start_normal.png"),
		png("UI.wz/Login.img/Common/BtOK/normal/0", "images/ui/login/btn_ok_normal.png"),
		png("UI.wz/Login.img/Common/BtCancel/normal/0", "images/ui/login/btn_cancel_normal.png"),
		png("UI.wz/Login.img/NewChar/charSet", "images/ui/login/newchar_charset.png"),
		png("UI.wz/Login.img/NewChar/charName", "images/ui/login/newchar_charname.png"),
		png("UI.wz/Login.img/NewChar/BtYes/normal/0", "images/ui/login/btn_yes_normal.png"),
		png("UI.wz/Login.img/NewChar/BtYes/mouseOver/0", "images/ui/login/btn_yes_over.png"),
		png("UI.wz/Login.img/NewChar/BtNo/normal/0", "images/ui/login/btn_no_normal.png"),
		png("UI.wz/Login.img/NewChar/BtNo/mouseOver/0", "images/ui/login/btn_no_over.png"),
		png("UI.wz/Login.img/NewChar/BtLeft/normal/0", "images/ui/login/btn_left_normal.png"),
		png("UI.wz/Login.img/NewChar/BtRight/normal/0", "images/ui/login/btn_right_normal.png"),
		png("UI.wz/Login.img/NewChar/dice/0", "images/ui/login/newchar_dice_0.png"),
		png("UI.wz/Login.img/NewChar/scroll/0/1", "images/ui/login/newchar_scroll_open.png"),
		png("UI.wz/Login.img/NewChar/avatarSel/0/normal", "images/ui/login/newchar_tab_normal.png"),
		png("UI.wz/Login.img/NewChar/avatarSel/1/normal", "images/ui/login/newchar_tab_sel.png"),
		png("UI.wz/Login.img/CharSelect/pageL/normal/0", "images/ui/login/btn_page_l.png"),
		png("UI.wz/Login.img/CharSelect/pageR/normal/0", "images/ui/login/btn_page_r.png"),
		png("Map.wz/Obj/login.img/Title/logo/0", "images/ui/login/logo_0.png"),
		png("Map.wz/Obj/login.img/Title/logo/1", "images/ui/login/logo_1.png"),
		png("Map.wz/Obj/login.img/Title/signboard/0", "images/ui/login/title_signboard.png"),
		png("Map.wz/Obj/login.img/CharSelect/signboard/0", "images/ui/login/slot_board.png"),
		png("Map.wz/Obj/login.img/CharSelect/signboard/1", "images/ui/login/charselect_banner.png"),
		png("Map.wz/Obj/login.img/CharSelect/character/0", "images/ui/login/pedestal.png"),
	}
	for i := 0; i <= 37; i++ {
		name := fmt.Sprintf("%02d", i)
		jobs = append(jobs, png(
			fmt.Sprintf("Map.wz/Back/login.img/back/%d", i),
			fmt.Sprintf("images/ui/login/back/%s.png", name),
		))
	}
	return jobs
}

func pngSources(wzRel string) []string {
	// HaRepacker PNG 导出: .../Login.img/Title/BtLogin/normal/0.png
	// cc-079 XML 伴生 PNG: .../Login.img/Title/BtLogin/normal/0.png (canvas name)
	parts := strings.Split(wzRel, "/")
	fileName := parts[len(parts)-1]
	dirRel := strings.Join(parts[:len(parts)-1], "/")
	altDir := strings.TrimPrefix(dirRel, "Map.wz/")
	altDir2 := strings.TrimPrefix(dirRel, "UI.wz/")
	return []string{
		filepath.Join(dirRel, fileName+".png"),
		filepath.Join(dirRel, fileName),
		filepath.Join(altDir, fileName+".png"),
		filepath.Join(altDir2, fileName+".png"),
	}
}

func soundSources(wzRel string) []string {
	name := filepath.Base(wzRel)
	dir := filepath.Dir(wzRel)
	return []string{
		filepath.Join(wzRel + ".mp3"),
		filepath.Join(wzRel + ".wav"),
		filepath.Join(dir, name+".mp3"),
		filepath.Join(dir, name+".wav"),
	}
}

func findFirst(root string, rels []string) string {
	for _, rel := range rels {
		p := filepath.Join(root, filepath.FromSlash(rel))
		if fileExists(p) {
			return p
		}
	}
	return ""
}

func copyAsset(src, dst string) error {
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}
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

func isRealFile(path, kind string) bool {
	st, err := os.Stat(path)
	if err != nil {
		return false
	}
	switch kind {
	case "png":
		return st.Size() >= minRealPNG
	case "sound":
		return st.Size() >= 8192
	default:
		return st.Size() > 1024
	}
}

func fileExists(p string) bool {
	st, err := os.Stat(p)
	return err == nil && !st.IsDir()
}

func dirExists(p string) bool {
	st, err := os.Stat(p)
	return err == nil && st.IsDir()
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func trimRoot(root, path string) string {
	rel, err := filepath.Rel(root, path)
	if err != nil {
		return path
	}
	return rel
}
