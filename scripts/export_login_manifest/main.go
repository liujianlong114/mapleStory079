// 从 ms079 Login.img / MapLogin2 布局导出 079 标准登录流程 manifest（800×600）。
//
//	go run scripts/export_login_manifest/main.go
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

const sceneW, sceneH = 800, 600

type sceneManifest struct {
	Width       int          `json:"width"`
	Height      int          `json:"height"`
	BGM         string       `json:"bgm"`
	UseParallax bool         `json:"use_parallax"`
	ParallaxCam *parallaxCam `json:"parallax_camera,omitempty"`
	Background  string       `json:"background,omitempty"`
	Logo        *spriteRef   `json:"logo,omitempty"`
	Slots       []rect       `json:"slots,omitempty"`
	Buttons     []buttonDef  `json:"buttons"`
	LoginPanel  *rect        `json:"login_panel,omitempty"`
	PanelImage  string       `json:"panel_image,omitempty"`
	Decorations []decoration `json:"decorations,omitempty"`
}

type decoration struct {
	Path string  `json:"path"`
	X    float64 `json:"x"`
	Y    float64 `json:"y"`
	W    float64 `json:"w"`
	H    float64 `json:"h"`
}

type spriteRef struct {
	Path   string   `json:"path"`
	X      float64  `json:"x"`
	Y      float64  `json:"y"`
	W      float64  `json:"w"`
	H      float64  `json:"h"`
	Frames []string `json:"frames,omitempty"`
	FadeMs int      `json:"fade_ms,omitempty"`
}

type rect struct {
	X float64 `json:"x"`
	Y float64 `json:"y"`
	W float64 `json:"w"`
	H float64 `json:"h"`
}

type parallaxCam struct {
	X float64 `json:"x"`
	Y float64 `json:"y"`
}

type buttonDef struct {
	ID      string `json:"id"`
	Label   string `json:"label"`
	Rect    rect   `json:"rect"`
	Normal  string `json:"normal"`
	Hover   string `json:"hover,omitempty"`
	Pressed string `json:"pressed,omitempty"`
}

func btn(id, label string, r rect, base string) buttonDef {
	p := "images/ui/login/" + base
	return buttonDef{
		ID: id, Label: label, Rect: r,
		Normal:  p + "_normal.png",
		Hover:   p + "_over.png",
		Pressed: p + "_pressed.png",
	}
}

func main() {
	out := filepath.Join("client", "assets", "scenes")
	_ = os.MkdirAll(out, 0o755)

	titleBGM := "audio/title.mp3"

	writeJSON(filepath.Join(out, "login_title.json"), sceneManifest{
		Width: sceneW, Height: sceneH, BGM: titleBGM,
		UseParallax: true,
		ParallaxCam: &parallaxCam{X: 22, Y: -1785},
		Logo: &spriteRef{
			Path: "images/ui/login/logo_0.png", X: 201, Y: 48, W: 397, H: 219,
			Frames: []string{"images/ui/login/logo_0.png", "images/ui/login/logo_1.png"},
			FadeMs: 8000,
		},
		Buttons: []buttonDef{
			btn("login", "登录", rect{X: 352, Y: 462, W: 97, H: 68}, "btn_login"),
			btn("quit", "离开", rect{X: 667, Y: 568, W: 94, H: 29}, "btn_quit"),
		},
	})

	writeJSON(filepath.Join(out, "login_charselect.json"), sceneManifest{
		Width: sceneW, Height: sceneH, BGM: titleBGM,
		UseParallax: true,
		ParallaxCam: &parallaxCam{X: 290, Y: -1220},
		Slots: []rect{
			{X: 155, Y: 265, W: 120, H: 180},
			{X: 340, Y: 265, W: 120, H: 180},
			{X: 525, Y: 265, W: 120, H: 180},
		},
		Buttons: []buttonDef{
			btn("select", "选择", rect{X: 248, Y: 520, W: 94, H: 43}, "btn_select"),
			btn("new", "建立", rect{X: 353, Y: 518, W: 94, H: 43}, "btn_new"),
			btn("delete", "删除", rect{X: 458, Y: 515, W: 94, H: 43}, "btn_delete"),
			btn("page_prev", "", rect{X: 40, Y: 300, W: 86, H: 74}, "btn_page_l"),
			btn("page_next", "", rect{X: 674, Y: 300, W: 89, H: 74}, "btn_page_r"),
		},
	})

	writeJSON(filepath.Join(out, "login_worldselect.json"), sceneManifest{
		Width: sceneW, Height: sceneH, BGM: titleBGM,
		UseParallax: true,
		ParallaxCam: &parallaxCam{X: 22, Y: -1785},
		Decorations: []decoration{
			{Path: "images/ui/login/worldselect_chback.png", X: 176, Y: 184, W: 520, H: 262},
		},
		Buttons: []buttonDef{
			btn("world_0", "蓝蜗牛", rect{X: 220, Y: 248, W: 97, H: 23}, "btn_world_0"),
			btn("world_1", "蘑菇仔", rect{X: 352, Y: 248, W: 97, H: 23}, "btn_world_1"),
			btn("world_2", "绿水灵", rect{X: 484, Y: 248, W: 97, H: 23}, "btn_world_2"),
			btn("ch_1", "频道1", rect{X: 260, Y: 310, W: 97, H: 23}, "btn_world_0"),
			btn("ch_2", "频道2", rect{X: 352, Y: 310, W: 97, H: 23}, "btn_world_1"),
			btn("ch_3", "频道3", rect{X: 444, Y: 310, W: 97, H: 23}, "btn_world_2"),
			btn("enter", "确认", rect{X: 310, Y: 420, W: 94, H: 43}, "btn_yes"),
			btn("cancel", "取消", rect{X: 410, Y: 420, W: 94, H: 43}, "btn_no"),
		},
	})

	writeJSON(filepath.Join(out, "login_gender.json"), sceneManifest{
		Width: sceneW, Height: sceneH, BGM: titleBGM,
		UseParallax: true,
		ParallaxCam: &parallaxCam{X: 22, Y: -1785},
		LoginPanel: &rect{X: 268, Y: 320, W: 263, H: 179},
		PanelImage: "images/ui/login/panel_backgrnd.png",
		Buttons: []buttonDef{
			btn("male", "男生", rect{X: 290, Y: 380, W: 94, H: 43}, "btn_yes"),
			btn("female", "女生", rect{X: 416, Y: 380, W: 94, H: 43}, "btn_no"),
		},
	})

	writeJSON(filepath.Join(out, "login_newchar.json"), sceneManifest{
		Width: sceneW, Height: sceneH, BGM: titleBGM,
		UseParallax: true,
		ParallaxCam: &parallaxCam{X: 290, Y: -1431},
		Decorations: []decoration{
			{Path: "images/ui/login/newchar_charset.png", X: 0, Y: 0, W: 800, H: 600},
		},
	})

	writeJSON(filepath.Join(out, "login_raceselect.json"), sceneManifest{
		Width: sceneW, Height: sceneH, BGM: titleBGM,
		UseParallax: true,
		ParallaxCam: &parallaxCam{X: 290, Y: -1220},
	})

	fmt.Println("✓ 079 登录 manifest → client/assets/scenes/")
}

func writeJSON(path string, v any) {
	f, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer f.Close()
	enc := json.NewEncoder(f)
	enc.SetIndent("", "  ")
	if err := enc.Encode(v); err != nil {
		panic(err)
	}
}
