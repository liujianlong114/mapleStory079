// 从 MapleStory 079 客户端二进制 WZ 提取登录/选角界面与 BGM。
//
// 用法:
//
//	go run scripts/extract_wz_login/main.go --wz-root "/path/to/MapleStory"
//	MAPLE_WZ_ROOT=/path/to/MapleStory go run scripts/extract_wz_login/main.go
//
// wz-root 需包含 Base.wz 或 Base/ 目录，以及 Sound.wz / UI.wz / Map.wz 等。
package main

import (
	"flag"
	"fmt"
	"image/png"
	"os"
	"path/filepath"
	"strings"

	"github.com/anonymous5l/wzexplorer"
)

var (
	wzRoot = flag.String("wz-root", os.Getenv("MAPLE_WZ_ROOT"), "MapleStory 客户端根目录（含 Base.wz）")
	outDir = flag.String("out", "client/assets", "输出目录")
)

type extractJob struct {
	WzPath   string
	OutFile  string
	Kind     string // png | sound
	Optional bool
}

func main() {
	flag.Parse()
	if *wzRoot == "" {
		fmt.Println("❌ 请指定 --wz-root 或环境变量 MAPLE_WZ_ROOT 指向 MapleStory 079 客户端目录")
		fmt.Println("   示例: go run scripts/extract_wz_login/main.go --wz-root \"C:/MapleStory\"")
		os.Exit(1)
	}

	cp, err := wzexplorer.NewCryptProvider(79, wzexplorer.IvGMS)
	if err != nil {
		// 部分私服使用 EMS IV
		cp, err = wzexplorer.NewCryptProvider(79, wzexplorer.IvEMS)
		if err != nil {
			panic(err)
		}
		fmt.Println("ℹ️  使用 EMS 密钥")
	} else {
		fmt.Println("ℹ️  使用 GMS 密钥")
	}

	archive, err := wzexplorer.NewBase(cp, *wzRoot)
	if err != nil {
		fmt.Printf("❌ 无法打开 WZ: %v\n", err)
		os.Exit(1)
	}
	defer archive.Close()

	jobs := []extractJob{
		// BGM
		{"/Sound/BgmUI.img/Title", "audio/title.mp3", "sound", false},
		{"/Sound/BgmUI.img/Title", "audio/title.wav", "sound", true},
		{"/Sound/UI.img/CharSelect", "audio/char_select.mp3", "sound", false},
		{"/Sound/UI.img/CharSelect", "audio/char_select.wav", "sound", true},
		{"/Sound/BgmUI.img/WCSelect", "audio/char_select.mp3", "sound", true},
		// UI 按钮
		{"/UI/Login.img/Title/BtLogin/normal/0", "images/ui/login/btn_login_normal.png", "png", false},
		{"/UI/Login.img/Title/BtLogin/mouseOver/0", "images/ui/login/btn_login_over.png", "png", true},
		{"/UI/Login.img/Title/BtLogin/pressed/0", "images/ui/login/btn_login_pressed.png", "png", true},
		{"/UI/Login.img/Title/BtQuit/normal/0", "images/ui/login/btn_quit_normal.png", "png", true},
		{"/UI/Login.img/CharSelect/BtSelect/normal/0", "images/ui/login/btn_select_normal.png", "png", false},
		{"/UI/Login.img/CharSelect/BtSelect/mouseOver/0", "images/ui/login/btn_select_over.png", "png", true},
		{"/UI/Login.img/CharSelect/BtSelect/pressed/0", "images/ui/login/btn_select_pressed.png", "png", true},
		{"/UI/Login.img/CharSelect/BtNew/normal/0", "images/ui/login/btn_new_normal.png", "png", false},
		{"/UI/Login.img/CharSelect/BtNew/mouseOver/0", "images/ui/login/btn_new_over.png", "png", true},
		{"/UI/Login.img/CharSelect/BtDelete/normal/0", "images/ui/login/btn_delete_normal.png", "png", false},
		{"/UI/Login.img/CharSelect/BtDelete/mouseOver/0", "images/ui/login/btn_delete_over.png", "png", true},
		{"/UI/Login.img/Common/BtStart/normal/0", "images/ui/login/btn_start_normal.png", "png", true},
		{"/UI/Login.img/Common/BtOK/normal/0", "images/ui/login/btn_ok_normal.png", "png", true},
		{"/UI/Login.img/Common/BtCancel/normal/0", "images/ui/login/btn_cancel_normal.png", "png", true},
		// NewChar 创建角色 UI
		{"/UI/Login.img/NewChar/charSet", "images/ui/login/newchar_charset.png", "png", true},
		{"/UI/Login.img/NewChar/charName", "images/ui/login/newchar_charname.png", "png", true},
		{"/UI/Login.img/NewChar/BtYes/normal/0", "images/ui/login/btn_yes_normal.png", "png", true},
		{"/UI/Login.img/NewChar/BtYes/mouseOver/0", "images/ui/login/btn_yes_over.png", "png", true},
		{"/UI/Login.img/NewChar/BtNo/normal/0", "images/ui/login/btn_no_normal.png", "png", true},
		{"/UI/Login.img/NewChar/BtNo/mouseOver/0", "images/ui/login/btn_no_over.png", "png", true},
		{"/UI/Login.img/NewChar/BtLeft/normal/0", "images/ui/login/btn_left_normal.png", "png", true},
		{"/UI/Login.img/NewChar/BtRight/normal/0", "images/ui/login/btn_right_normal.png", "png", true},
		{"/UI/Login.img/NewChar/dice/0", "images/ui/login/newchar_dice_0.png", "png", true},
		{"/UI/Login.img/NewChar/scroll/0/1", "images/ui/login/newchar_scroll_open.png", "png", true},
		{"/UI/Login.img/NewChar/avatarSel/0/normal", "images/ui/login/newchar_tab_normal.png", "png", true},
		{"/UI/Login.img/NewChar/avatarSel/1/normal", "images/ui/login/newchar_tab_sel.png", "png", true},
		{"/UI/Login.img/CharSelect/pageL/normal/0", "images/ui/login/btn_page_l.png", "png", true},
		{"/UI/Login.img/CharSelect/pageR/normal/0", "images/ui/login/btn_page_r.png", "png", true},
		{"/Map/Obj/login.img/Title/logo/0", "images/ui/login/logo_0.png", "png", false},
		{"/Map/Obj/login.img/Title/logo/1", "images/ui/login/logo_1.png", "png", true},
		{"/Map/Obj/login.img/Title/signboard/0", "images/ui/login/title_signboard.png", "png", true},
		{"/Map/Obj/login.img/CharSelect/signboard/0", "images/ui/login/slot_board.png", "png", false},
		{"/Map/Obj/login.img/CharSelect/signboard/1", "images/ui/login/charselect_banner.png", "png", true},
		{"/Map/Obj/login.img/CharSelect/character/0", "images/ui/login/pedestal.png", "png", true},
	}

	// 登录背景层（Back/login.img）
	for i := 0; i <= 37; i++ {
		jobs = append(jobs, extractJob{
			fmt.Sprintf("/Map/Back/login.img/back/%d", i),
			fmt.Sprintf("images/ui/login/back/%02d.png", i),
			"png", true,
		})
	}

	ok, skip, fail := 0, 0, 0
	for _, job := range jobs {
		paths := []string{job.WzPath, strings.Replace(job.WzPath, "/Map/", "/Map/Map/", 1)}
		var lastErr error
		done := false
		for _, p := range paths {
			if err := extractOne(archive, p, filepath.Join(*outDir, job.OutFile), job.Kind); err == nil {
				fmt.Printf("  ✓ %s → %s\n", p, job.OutFile)
				ok++
				done = true
				break
			} else {
				lastErr = err
			}
		}
		if done {
			continue
		}
		if job.Optional {
			skip++
			continue
		}
		fmt.Printf("  ✗ %s: %v\n", job.WzPath, lastErr)
		fail++
	}

	fmt.Printf("\n提取完成: 成功 %d | 跳过(可选) %d | 失败 %d\n", ok, skip, fail)
	if ok > 0 {
		fmt.Println("请运行: go run scripts/build_login_scene/main.go  重新合成场景")
	}
	if fail > 0 && ok == 0 {
		fmt.Println("\n若 WZ 路径正确仍失败，可尝试用 HaRepacker 导出 PNG/MP3 到 client/assets/ 对应路径。")
		os.Exit(1)
	}
}

func extractOne(archive wzexplorer.File, wzPath, outPath, kind string) error {
	obj, err := archive.Get(wzPath)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(outPath), 0o755); err != nil {
		return err
	}
	switch kind {
	case "png":
		img, err := obj.Canvas().Image()
		if err != nil {
			return err
		}
		f, err := os.Create(outPath)
		if err != nil {
			return err
		}
		defer f.Close()
		return png.Encode(f, img)
	case "sound":
		data, err := obj.Sound().Stream(false)
		if err != nil {
			return err
		}
		return os.WriteFile(outPath, data, 0o644)
	default:
		return fmt.Errorf("unknown kind %s", kind)
	}
}
