package utils

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
)

var (
	forbiddenOnce sync.Once
	forbiddenList []string
)

// InitForbiddenNames 从外部 ms079-main 的 Etc.wz/ForbiddenName.img.xml 加载禁名列表
func InitForbiddenNames() error {
	var err error
	forbiddenOnce.Do(func() {
		candidates := []string{
			// 外部参考目录（与 mapleStory079 同级）
			filepath.Join("..", "mapleStory079-external", "02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML", "wz", "Etc.wz", "ForbiddenName.img.xml"),
			os.Getenv("MAPLE_MS079_WZ"),
			filepath.Join(os.Getenv("MAPLE_EXTERNAL_ROOT"), "02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML", "wz", "Etc.wz", "ForbiddenName.img.xml"),
		}
		if ext := os.Getenv("MAPLE_EXTERNAL_ROOT"); ext != "" {
			candidates = append(candidates, filepath.Join(ext, "02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML", "wz", "Etc.wz", "ForbiddenName.img.xml"))
		}
		for _, p := range candidates {
			if p == "" {
				continue
			}
			if e := loadForbiddenFile(p); e == nil {
				return
			} else {
				err = e
			}
		}
	})
	return err
}

func loadForbiddenFile(path string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	re := regexp.MustCompile(`<string name="\d+" value="([^"]*)"`)
	matches := re.FindAllStringSubmatch(string(data), -1)
	for _, m := range matches {
		if len(m) > 1 && m[1] != "" {
			forbiddenList = append(forbiddenList, m[1])
		}
	}
	return nil
}

// IsForbiddenName ms079 LoginInformationProvider.isForbiddenName — 子串匹配
func IsForbiddenName(name string) bool {
	lower := strings.ToLower(name)
	for _, ban := range forbiddenList {
		if ban == "" {
			continue
		}
		if strings.Contains(lower, strings.ToLower(ban)) {
			return true
		}
	}
	return false
}
