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

// InitForbiddenNames 从 ms079-main Etc.wz/ForbiddenName.img.xml 加载禁名列表
func InitForbiddenNames() error {
	var err error
	forbiddenOnce.Do(func() {
		candidates := []string{
			filepath.Join("examples", "ms079-main", "wz", "Etc.wz", "ForbiddenName.img.xml"),
			filepath.Join("..", "examples", "ms079-main", "wz", "Etc.wz", "ForbiddenName.img.xml"),
		}
		for _, p := range candidates {
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
