// 从 MapleStory 079 客户端 WZ 提取新手创建用 Character 精灵（stand1/0）。
//
//	MAPLE_WZ_ROOT=/path/to/MapleStory go run scripts/extract_beginner_parts/main.go
package main

import (
	"flag"
	"fmt"
	"image/png"
	"os"
	"path/filepath"

	"github.com/anonymous5l/wzexplorer"
)

var (
	wzRoot = flag.String("wz-root", os.Getenv("MAPLE_WZ_ROOT"), "MapleStory 客户端根目录")
	outDir = flag.String("out", "client/assets/characters/parts", "输出目录")
)

var partIDs = []int{
	2000, 2001,
	20100, 20401, 20402, 21002, 21700, 21201,
	30000, 30027, 30030, 31002, 31047, 31057,
	1040002, 1040006, 1040010, 1041002, 1041006, 1041010, 1041011,
	1060002, 1060006, 1061002, 1061008,
	1072001, 1072005, 1072037, 1072038,
	1302000, 1322005, 1312004,
}

func main() {
	flag.Parse()
	if *wzRoot == "" {
		fmt.Println("❌ 请设置 MAPLE_WZ_ROOT 或 --wz-root")
		os.Exit(1)
	}
	cp, err := wzexplorer.NewCryptProvider(79, wzexplorer.IvGMS)
	if err != nil {
		cp, err = wzexplorer.NewCryptProvider(79, wzexplorer.IvEMS)
		if err != nil {
			panic(err)
		}
	}
	archive, err := wzexplorer.NewBase(cp, *wzRoot)
	if err != nil {
		fmt.Printf("❌ %v\n", err)
		os.Exit(1)
	}
	defer archive.Close()
	if err := os.MkdirAll(*outDir, 0o755); err != nil {
		panic(err)
	}

	ok, fail := 0, 0
	for _, id := range partIDs {
		out := filepath.Join(*outDir, fmt.Sprintf("%d.png", id))
		if err := extractPart(archive, id, out); err == nil {
			fmt.Printf("  ✓ %d\n", id)
			ok++
		} else {
			fail++
		}
	}
	fmt.Printf("\n完成: 成功 %d | 失败 %d → %s\n", ok, fail, *outDir)
}

func extractPart(archive wzexplorer.File, id int, outPath string) error {
	s := fmt.Sprintf("%08d", id)
	prefix := "/Character"
	if id >= 1000000 {
		prefix = "/Character/Weapon"
	} else if id >= 100000 {
		prefix = "/Character/Accessory"
	}
	candidates := []string{
		fmt.Sprintf("%s/%s.img/stand1/0", prefix, s),
		fmt.Sprintf("%s/%s.img/stand1/0/0", prefix, s),
		fmt.Sprintf("/Character/%s.img/stand1/0", s),
	}
	for _, p := range candidates {
		obj, err := archive.Get(p)
		if err != nil {
			continue
		}
		img, err := obj.Canvas().Image()
		if err != nil {
			continue
		}
		f, err := os.Create(outPath)
		if err != nil {
			return err
		}
		err = png.Encode(f, img)
		f.Close()
		if err != nil {
			return err
		}
		return nil
	}
	return fmt.Errorf("not found %d", id)
}
