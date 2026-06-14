// 根据 WZ XML 布局合成 079 登录/选角场景 PNG 与 manifest。
// 若 client/assets/images/ui/login/ 已有 extract_wz_login 导出的真实 PNG，优先使用。
//
// 用法: go run scripts/build_login_scene/main.go
package main

import (
	"encoding/json"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/png"
	"math"
	"math/rand"
	"os"
	"path/filepath"
)

const (
	sceneW = 800
	sceneH = 600
)

type sceneManifest struct {
	Width      int         `json:"width"`
	Height     int         `json:"height"`
	BGM        string      `json:"bgm"`
	Background string      `json:"background"`
	Logo       *spriteRef  `json:"logo,omitempty"`
	Slots      []rect      `json:"slots,omitempty"`
	Buttons    []buttonDef `json:"buttons"`
	LoginPanel rect        `json:"login_panel,omitempty"`
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

type buttonDef struct {
	ID      string `json:"id"`
	Label   string `json:"label"`
	Rect    rect   `json:"rect"`
	Normal  string `json:"normal"`
	Hover   string `json:"hover,omitempty"`
	Pressed string `json:"pressed,omitempty"`
}

func main() {
	force := false
	if len(os.Args) > 1 && os.Args[1] == "--force" {
		force = true
		os.Args = append(os.Args[:1], os.Args[2:]...)
	}
	outRoot := filepath.Join("client", "assets")
	uiDir := filepath.Join(outRoot, "images", "ui", "login")
	sceneDir := filepath.Join(outRoot, "scenes")
	mustMkdir(uiDir)
	mustMkdir(filepath.Join(uiDir, "back"))
	mustMkdir(sceneDir)

	btnLogin := ensureButton(uiDir, "btn_login", 89, 42, force)
	btnSelect := ensureButton(uiDir, "btn_select", 101, 30, force)
	btnNew := ensureButton(uiDir, "btn_new", 101, 35, force)
	btnDelete := ensureButton(uiDir, "btn_delete", 101, 43, force)
	btnQuit := ensureButton(uiDir, "btn_quit", 84, 38, force)
	btnPageL := ensureButton(uiDir, "btn_page_l", 86, 74, force)
	btnPageR := ensureButton(uiDir, "btn_page_r", 89, 74, force)
	ensureButton(uiDir, "btn_yes", 85, 29, force)
	ensureButton(uiDir, "btn_no", 85, 29, force)
	ensureButton(uiDir, "btn_left", 15, 16, force)
	ensureButton(uiDir, "btn_right", 15, 16, force)
	ensureButtonAliases(uiDir)
	ensureNewCharPanels(uiDir, force)
	logoFrames := ensureLogo(uiDir, force)

	savePNG(filepath.Join(sceneDir, "login_title.png"), composeTitleScene(uiDir, logoFrames))
	savePNG(filepath.Join(sceneDir, "login_charselect.png"), composeCharSelectScene(uiDir))
	savePNG(filepath.Join(sceneDir, "login_newchar.png"), composeNewCharScene(uiDir))
	savePNG(filepath.Join(sceneDir, "login_gender.png"), composeTitleScene(uiDir, logoFrames))
	savePNG(filepath.Join(sceneDir, "login_worldselect.png"), composeCharSelectScene(uiDir))
	savePNG(filepath.Join(sceneDir, "login_raceselect.png"), composeCharSelectScene(uiDir))

	writeJSON(filepath.Join(sceneDir, "login_title.json"), sceneManifest{
		Width: sceneW, Height: sceneH, BGM: "audio/title.mp3", Background: "scenes/login_title.png",
		Logo: &spriteRef{
			Path: "images/ui/login/logo_0.png", X: 200, Y: 55, W: 397, H: 219,
			Frames: []string{"images/ui/login/logo_0.png", "images/ui/login/logo_1.png"}, FadeMs: 8000,
		},
		LoginPanel: rect{X: 268, Y: 320, W: 263, H: 179},
		Buttons: []buttonDef{
			{ID: "login", Label: "登录", Rect: rect{X: 355, Y: 468, W: 89, H: 42},
				Normal: relToAssets(btnLogin, outRoot), Hover: relToAssets(btnLogin+"_over", outRoot), Pressed: relToAssets(btnLogin+"_pressed", outRoot)},
			{ID: "quit", Label: "退出", Rect: rect{X: 620, Y: 555, W: 84, H: 38},
				Normal: relToAssets(btnQuit, outRoot), Hover: relToAssets(btnQuit+"_over", outRoot), Pressed: relToAssets(btnQuit+"_pressed", outRoot)},
		},
	})

	writeJSON(filepath.Join(sceneDir, "login_charselect.json"), sceneManifest{
		Width: sceneW, Height: sceneH, BGM: "audio/title.mp3", Background: "scenes/login_charselect.png",
		Slots: []rect{
			{X: 155, Y: 220, W: 120, H: 180}, {X: 340, Y: 220, W: 120, H: 180}, {X: 525, Y: 220, W: 120, H: 180},
		},
		Buttons: []buttonDef{
			{ID: "select", Label: "选择", Rect: rect{X: 220, Y: 520, W: 101, H: 30},
				Normal: relToAssets(btnSelect, outRoot), Hover: relToAssets(btnSelect+"_over", outRoot), Pressed: relToAssets(btnSelect+"_pressed", outRoot)},
			{ID: "new", Label: "创建", Rect: rect{X: 350, Y: 518, W: 101, H: 35},
				Normal: relToAssets(btnNew, outRoot), Hover: relToAssets(btnNew+"_over", outRoot), Pressed: relToAssets(btnNew+"_pressed", outRoot)},
			{ID: "delete", Label: "删除", Rect: rect{X: 480, Y: 515, W: 101, H: 43},
				Normal: relToAssets(btnDelete, outRoot), Hover: relToAssets(btnDelete+"_over", outRoot), Pressed: relToAssets(btnDelete+"_pressed", outRoot)},
			{ID: "page_prev", Label: "上一页", Rect: rect{X: 40, Y: 300, W: 86, H: 74},
				Normal: relToAssets(btnPageL, outRoot), Hover: relToAssets(btnPageL+"_over", outRoot), Pressed: relToAssets(btnPageL+"_pressed", outRoot)},
			{ID: "page_next", Label: "下一页", Rect: rect{X: 674, Y: 300, W: 89, H: 74},
				Normal: relToAssets(btnPageR, outRoot), Hover: relToAssets(btnPageR+"_over", outRoot), Pressed: relToAssets(btnPageR+"_pressed", outRoot)},
		},
	})

	writeJSON(filepath.Join(sceneDir, "login_newchar.json"), sceneManifest{
		Width: sceneW, Height: sceneH, BGM: "audio/title.mp3", Background: "scenes/login_newchar.png",
	})

	writeJSON(filepath.Join(sceneDir, "login_gender.json"), sceneManifest{
		Width: sceneW, Height: sceneH, BGM: "audio/title.mp3", Background: "scenes/login_gender.png",
	})

	writeJSON(filepath.Join(sceneDir, "login_worldselect.json"), sceneManifest{
		Width: sceneW, Height: sceneH, BGM: "audio/title.mp3", Background: "scenes/login_worldselect.png",
	})

	writeJSON(filepath.Join(sceneDir, "login_raceselect.json"), sceneManifest{
		Width: sceneW, Height: sceneH, BGM: "audio/title.mp3", Background: "scenes/login_raceselect.png",
	})

	fmt.Println("✓ 登录/选角/创建场景已合成 → client/assets/scenes/")
	fmt.Println("  真实 WZ: MAPLE_WZ_ROOT=/path/to/MapleStory go run scripts/extract_wz_login/main.go")
}

func relToAssets(absPath, outRoot string) string {
	r, err := filepath.Rel(outRoot, absPath+".png")
	if err != nil {
		return absPath + ".png"
	}
	return filepath.ToSlash(r)
}

func mustMkdir(p string) {
	if err := os.MkdirAll(p, 0o755); err != nil {
		panic(err)
	}
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

func savePNG(path string, img image.Image) {
	f, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer f.Close()
	if err := png.Encode(f, img); err != nil {
		panic(err)
	}
}

func loadPNG(path string) (image.Image, bool) {
	f, err := os.Open(path)
	if err != nil {
		return nil, false
	}
	defer f.Close()
	img, err := png.Decode(f)
	return img, err == nil
}

func fileExists(p string) bool {
	_, err := os.Stat(p)
	return err == nil
}

const minRealPNGSize = 512

func isRealAsset(p string) bool {
	st, err := os.Stat(p)
	if err != nil {
		return false
	}
	return st.Size() >= minRealPNGSize
}

func ensureButton(dir, name string, w, h int, force bool) string {
	base := filepath.Join(dir, name)
	if !force && isRealAsset(base+".png") {
		return base
	}
	if force && fileExists(base+".png") && !isRealAsset(base+".png") {
		// 占位文件，允许覆盖
	} else if fileExists(base+".png") {
		return base
	}
	drawWoodButton(base+".png", w, h, color.RGBA{210, 170, 90, 255}, color.RGBA{160, 110, 50, 255})
	if !isRealAsset(base+"_over.png") {
		drawWoodButton(base+"_over.png", w, h, color.RGBA{255, 210, 110, 255}, color.RGBA{190, 130, 60, 255})
	}
	if !isRealAsset(base+"_pressed.png") {
		drawWoodButton(base+"_pressed.png", w, h, color.RGBA{140, 100, 45, 255}, color.RGBA{100, 70, 30, 255})
	}
	return base
}

func ensureLogo(dir string, force bool) []string {
	f0 := filepath.Join(dir, "logo_0.png")
	f1 := filepath.Join(dir, "logo_1.png")
	if !force && isRealAsset(f0) && isRealAsset(f1) {
		return []string{f0, f1}
	}
	if force || !isRealAsset(f0) {
		drawMapleLogo(f0, false)
	}
	if force || !isRealAsset(f1) {
		drawMapleLogo(f1, true)
	}
	return []string{f0, f1}
}

func composeTitleScene(uiDir string, logoFrames []string) *image.RGBA {
	dst := image.NewRGBA(image.Rect(0, 0, sceneW, sceneH))
	drawLoginSky(dst)
	layered := false
	for i := 0; i <= 37; i++ {
		if img, ok := loadPNG(filepath.Join(uiDir, "back", fmt.Sprintf("%02d.png", i))); ok {
			draw.Draw(dst, dst.Bounds(), img, image.Point{}, draw.Over)
			layered = true
		}
	}
	if !layered {
		drawHills(dst)
		drawMushroomTrees(dst)
	}
	if sign, ok := loadPNG(filepath.Join(uiDir, "title_signboard.png")); ok {
		drawCentered(dst, sign, 400, 200)
	} else if logo, ok := loadPNG(logoFrames[0]); ok {
		drawCentered(dst, logo, 400, 130)
	}
	return dst
}

func composeCharSelectScene(uiDir string) *image.RGBA {
	dst := image.NewRGBA(image.Rect(0, 0, sceneW, sceneH))
	drawLoginSky(dst)
	drawHills(dst)
	drawMushroomTrees(dst)
	drawCharSelectStage(dst)
	if banner, ok := loadPNG(filepath.Join(uiDir, "charselect_banner.png")); ok {
		drawCentered(dst, banner, 400, 80)
	}
	slotImg, _ := loadPNG(filepath.Join(uiDir, "slot_board.png"))
	pedestal, _ := loadPNG(filepath.Join(uiDir, "pedestal.png"))
	for _, sx := range []int{155, 340, 525} {
		if slotImg != nil {
			drawCentered(dst, slotImg, sx+60, 260)
		}
		if pedestal != nil {
			drawCentered(dst, pedestal, sx+60, 340)
		}
	}
	return dst
}

func drawLoginSky(dst *image.RGBA) {
	for y := 0; y < sceneH; y++ {
		t := float64(y) / float64(sceneH)
		r := uint8(8 + t*25)
		g := uint8(12 + t*35)
		b := uint8(45 + t*80)
		for x := 0; x < sceneW; x++ {
			dst.Set(x, y, color.RGBA{r, g, b, 255})
		}
	}
	rng := rand.New(rand.NewSource(79))
	for i := 0; i < 180; i++ {
		x, y := rng.Intn(sceneW), rng.Intn(sceneH*2/3)
		b := uint8(180 + rng.Intn(75))
		dst.Set(x, y, color.RGBA{b, b, 255, 255})
	}
	moonX, moonY, moonR := 650, 90, 42
	for y := -moonR; y <= moonR; y++ {
		for x := -moonR; x <= moonR; x++ {
			if x*x+y*y <= moonR*moonR {
				dst.Set(moonX+x, moonY+y, color.RGBA{255, 252, 220, 255})
			}
		}
	}
}

func drawHills(dst *image.RGBA) {
	for y := 340; y < sceneH; y++ {
		wave := math.Sin(float64(y)*0.02)*20 + math.Sin(float64(y)*0.05)*8
		for x := 0; x < sceneW; x++ {
			if float64(x) < 120+wave || float64(x) > float64(sceneW)-100-wave {
				g := uint8(30 + (y-340)*80/sceneH)
				dst.Set(x, y, color.RGBA{20, g, 40, 255})
			} else if y > 420 {
				g := uint8(50 + (y-420)*120/sceneH)
				dst.Set(x, y, color.RGBA{25, g, 35, 255})
			}
		}
	}
}

func drawMushroomTrees(dst *image.RGBA) {
	drawMushroom(dst, 80, 380, 1.0)
	drawMushroom(dst, 720, 400, 0.85)
	drawMushroom(dst, 180, 420, 0.7)
}

func drawMushroom(dst *image.RGBA, cx, cy int, scale float64) {
	capR := int(28 * scale)
	for y := -capR; y <= 0; y++ {
		for x := -capR; x <= capR; x++ {
			if x*x+y*y <= capR*capR {
				dst.Set(cx+x, cy+y, color.RGBA{200, 50, 50, 255})
			}
		}
	}
	stemW, stemH := int(10*scale), int(35*scale)
	for y := 0; y < stemH; y++ {
		for x := -stemW; x <= stemW; x++ {
			dst.Set(cx+x, cy+y, color.RGBA{240, 220, 180, 255})
		}
	}
}

func drawCharSelectStage(dst *image.RGBA) {
	for y := 400; y < 460; y++ {
		t := float64(y-400) / 60
		shade := uint8(90 - t*20)
		for x := 80; x < sceneW-80; x++ {
			dst.Set(x, y, color.RGBA{shade + 40, shade + 20, shade, 255})
		}
	}
	for x := 80; x < sceneW-80; x += 40 {
		for y := 400; y < 460; y++ {
			dst.Set(x, y, color.RGBA{60, 40, 25, 255})
		}
	}
}

func drawWoodButton(path string, w, h int, face, border color.RGBA) {
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			c := face
			if x == 0 || y == 0 || x == w-1 || y == h-1 {
				c = border
			}
			if y < 3 {
				c = color.RGBA{255, 230, 160, 255}
			}
			img.Set(x, y, c)
		}
	}
	savePNG(path, img)
}

func drawMapleLogo(path string, bright bool) {
	w, h := 397, 219
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			if x > 20 && x < w-20 && y > 40 && y < h-30 {
				sh := uint8(100)
				if (x/8+y/6)%2 == 0 {
					sh = 120
				}
				img.Set(x, y, color.RGBA{sh + 30, sh + 10, sh - 20, 255})
			}
		}
	}
	orange := color.RGBA{255, 140, 0, 255}
	if bright {
		orange = color.RGBA{255, 200, 50, 255}
	}
	for dy := 0; dy < 60; dy++ {
		for dx := 0; dx < 287; dx++ {
			edge := dx < 4 || dy < 4 || dx > 282 || dy > 55
			col := orange
			if edge {
				col = color.RGBA{120, 40, 0, 255}
			}
			img.Set(55+dx, 85+dy, col)
		}
	}
	savePNG(path, img)
}

func drawCentered(dst *image.RGBA, src image.Image, cx, cy int) {
	b := src.Bounds()
	x0, y0 := cx-b.Dx()/2, cy-b.Dy()/2
	draw.Draw(dst, image.Rect(x0, y0, x0+b.Dx(), y0+b.Dy()), src, b.Min, draw.Over)
}

func composeNewCharScene(uiDir string) *image.RGBA {
	dst := composeCharSelectScene(uiDir)
	// MapLogin2 NewChar signboard 装饰层（无真实 WZ 时用程序化横幅）
	if banner, ok := loadPNG(filepath.Join(uiDir, "newchar_banner.png")); ok {
		drawCentered(dst, banner, 400, 52)
	} else {
		drawNewCharBanner(dst)
	}
	return dst
}

func drawNewCharBanner(dst *image.RGBA) {
	for y := 18; y < 62; y++ {
		for x := 220; x < 580; x++ {
			t := float64(y-18) / 44
			sh := uint8(180 - t*40)
			dst.Set(x, y, color.RGBA{sh + 40, sh + 20, sh - 30, 255})
		}
	}
	for x := 220; x < 580; x++ {
		dst.Set(x, 18, color.RGBA{255, 220, 140, 255})
		dst.Set(x, 61, color.RGBA{80, 50, 20, 255})
	}
}

func ensureButtonAliases(dir string) {
	names := []string{"btn_yes", "btn_no", "btn_left", "btn_right", "btn_login", "btn_select", "btn_new", "btn_delete", "btn_quit", "btn_page_l", "btn_page_r"}
	for _, n := range names {
		src := filepath.Join(dir, n+".png")
		dst := filepath.Join(dir, n+"_normal.png")
		if fileExists(src) && !fileExists(dst) {
			copyFile(src, dst)
		}
		overSrc := filepath.Join(dir, n+"_over.png")
		overDst := filepath.Join(dir, n+"_mouseOver.png")
		if fileExists(overSrc) && !fileExists(overDst) {
			copyFile(overSrc, overDst)
		}
	}
}

func copyFile(src, dst string) {
	data, err := os.ReadFile(src)
	if err != nil {
		return
	}
	_ = os.WriteFile(dst, data, 0o644)
}

func ensureNewCharPanels(uiDir string, force bool) {
	// ms079 Login.img/NewChar 尺寸
	drawCharSetPanel(filepath.Join(uiDir, "newchar_charset.png"), 245, 193, force)
	drawCharNamePanel(filepath.Join(uiDir, "newchar_charname.png"), 199, 128, force)
	drawScrollPanel(filepath.Join(uiDir, "newchar_scroll_open.png"), 245, 193, true, force)
	drawScrollPanel(filepath.Join(uiDir, "newchar_scroll_closed.png"), 245, 28, false, force)
	drawDice(filepath.Join(uiDir, "newchar_dice_0.png"), force)
	drawAvatarTab(filepath.Join(uiDir, "newchar_tab_normal.png"), false, force)
	drawAvatarTab(filepath.Join(uiDir, "newchar_tab_sel.png"), true, force)
	drawAvatarTab(filepath.Join(uiDir, "newchar_tab_disabled.png"), false, force)
	drawNewCharBannerPNG(filepath.Join(uiDir, "newchar_banner.png"), force)
}

func drawCharSetPanel(path string, w, h int, force bool) {
	if !force && isRealAsset(path) {
		return
	}
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	// 深色木框 + 镜面台座（仿 079 charSet）
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			img.Set(x, y, color.RGBA{28, 18, 12, 255})
		}
	}
	for y := 4; y < h-4; y++ {
		for x := 4; x < w-4; x++ {
			sh := uint8(35 + (x+y)%8)
			img.Set(x, y, color.RGBA{sh + 15, sh, sh - 5, 255})
		}
	}
	// 金色边框
	for x := 0; x < w; x++ {
		img.Set(x, 0, color.RGBA{212, 163, 115, 255})
		img.Set(x, h-1, color.RGBA{120, 80, 40, 255})
	}
	for y := 0; y < h; y++ {
		img.Set(0, y, color.RGBA{212, 163, 115, 255})
		img.Set(w-1, y, color.RGBA{120, 80, 40, 255})
	}
	// 台座
	for y := h - 36; y < h-8; y++ {
		for x := 40; x < w-40; x++ {
			img.Set(x, y, color.RGBA{90, 60, 35, 255})
		}
	}
	for y := h - 40; y < h-36; y++ {
		for x := 30; x < w-30; x++ {
			img.Set(x, y, color.RGBA{180, 140, 80, 255})
		}
	}
	savePNG(path, img)
}

func drawCharNamePanel(path string, w, h int, force bool) {
	if !force && isRealAsset(path) {
		return
	}
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	parchment(img, w, h)
	// 卷轴顶饰
	for y := 0; y < 28; y++ {
		for x := 20; x < w-20; x++ {
			img.Set(x, y, color.RGBA{160, 120, 60, 255})
		}
	}
	for x := 10; x < w-10; x++ {
		img.Set(x, 28, color.RGBA{100, 60, 20, 255})
	}
	savePNG(path, img)
}

func drawScrollPanel(path string, w, h int, open bool, force bool) {
	if !force && isRealAsset(path) {
		return
	}
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	parchment(img, w, h)
	if open {
		// 左侧标签栏区域略深
		for y := 30; y < h-10; y++ {
			for x := 6; x < 170; x++ {
				img.Set(x, y, color.RGBA{220, 200, 160, 255})
			}
		}
		// 分隔线
		for y := 30; y < h-10; y++ {
			img.Set(170, y, color.RGBA{139, 105, 20, 255})
		}
	} else {
		// 卷轴收起 — 只显示顶栏
		for y := h - 6; y < h; y++ {
			for x := 0; x < w; x++ {
				img.Set(x, y, color.RGBA{139, 105, 20, 255})
			}
		}
	}
	scrollBorder(img, w, h)
	savePNG(path, img)
}

func parchment(img *image.RGBA, w, h int) {
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			noise := (x*3 + y*7) % 11
			img.Set(x, y, color.RGBA{uint8(240 - noise), uint8(225 - noise), uint8(190 - noise), 255})
		}
	}
}

func scrollBorder(img *image.RGBA, w, h int) {
	gold := color.RGBA{180, 140, 60, 255}
	dark := color.RGBA{100, 65, 25, 255}
	for x := 0; x < w; x++ {
		img.Set(x, 0, gold)
		img.Set(x, h-1, dark)
	}
	for y := 0; y < h; y++ {
		img.Set(0, y, gold)
		img.Set(w-1, y, dark)
	}
}

func drawAvatarTab(path string, selected bool, force bool) {
	if !force && isRealAsset(path) {
		return
	}
	// ms079 avatarSel 160×17
	w, h := 160, 17
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	base := color.RGBA{188, 170, 164, 255}
	if selected {
		base = color.RGBA{139, 105, 20, 255}
	}
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			c := base
			if y == 0 || y == h-1 {
				c = color.RGBA{80, 50, 20, 255}
			}
			img.Set(x, y, c)
		}
	}
	savePNG(path, img)
}

func drawNewCharBannerPNG(path string, force bool) {
	if !force && isRealAsset(path) {
		return
	}
	w, h := 360, 44
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			img.Set(x, y, color.RGBA{60, 35, 20, 200})
		}
	}
	for x := 0; x < w; x++ {
		img.Set(x, 0, color.RGBA{255, 210, 100, 255})
		img.Set(x, h-1, color.RGBA{80, 50, 20, 255})
	}
	savePNG(path, img)
}

func drawPanel(path string, w, h int, bg color.RGBA) {
	if fileExists(path) {
		return
	}
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			img.Set(x, y, bg)
			if x == 0 || y == 0 || x == w-1 || y == h-1 {
				img.Set(x, y, color.RGBA{212, 163, 115, 255})
			}
		}
	}
	savePNG(path, img)
}

func drawScroll(path string, w, h int, open bool) {
	if fileExists(path) {
		return
	}
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	base := color.RGBA{245, 230, 200, 255}
	if !open {
		base = color.RGBA{230, 210, 170, 255}
	}
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			img.Set(x, y, base)
		}
	}
	savePNG(path, img)
}

func drawDice(path string, force bool) {
	if !force && isRealAsset(path) {
		return
	}
	img := image.NewRGBA(image.Rect(0, 0, 37, 26))
	for y := 0; y < 26; y++ {
		for x := 0; x < 37; x++ {
			img.Set(x, y, color.RGBA{240, 240, 240, 255})
		}
	}
	for _, p := range [][2]int{{8, 8}, {18, 13}, {28, 18}} {
		for dy := -2; dy <= 2; dy++ {
			for dx := -2; dx <= 2; dx++ {
				if dx*dx+dy*dy <= 4 {
					img.Set(p[0]+dx, p[1]+dy, color.RGBA{30, 30, 30, 255})
				}
			}
		}
	}
	savePNG(path, img)
}

func drawTab(path string, c color.RGBA) {
	if fileExists(path) {
		return
	}
	img := image.NewRGBA(image.Rect(0, 0, 160, 17))
	for y := 0; y < 17; y++ {
		for x := 0; x < 160; x++ {
			img.Set(x, y, c)
		}
	}
	savePNG(path, img)
}
