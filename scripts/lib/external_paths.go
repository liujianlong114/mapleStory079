package lib

import (
	"os"
	"path/filepath"
)

const (
	DirMs079Main    = "02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML"
	DirMapleClient  = "03-★maple-client-ingest工作目录-WZ副本-脚本自动复制"
	DirZLHSS2       = "06-ZLHSS2-079参考-中文全栈私服"
)

// ProjectRoot returns mapleStory079 repo root (parent of scripts/).
func ProjectRoot() string {
	if r := os.Getenv("MAPLE_PROJECT_ROOT"); r != "" {
		return r
	}
	wd, _ := os.Getwd()
	for {
		if _, err := os.Stat(filepath.Join(wd, "go.mod")); err == nil {
			return wd
		}
		parent := filepath.Dir(wd)
		if parent == wd {
			return wd
		}
		wd = parent
	}
}

// ExternalRoot is sibling mapleStory079-external (override with MAPLE_EXTERNAL_ROOT).
func ExternalRoot() string {
	if r := os.Getenv("MAPLE_EXTERNAL_ROOT"); r != "" {
		return r
	}
	return filepath.Join(filepath.Dir(ProjectRoot()), "mapleStory079-external")
}

func Ms079MainDir() string  { return filepath.Join(ExternalRoot(), DirMs079Main) }
func Ms079WzDir() string    { return filepath.Join(Ms079MainDir(), "wz") }
func MapleClientDir() string {
	if d := os.Getenv("MAPLE_CLIENT_DIR"); d != "" {
		return d
	}
	return filepath.Join(ExternalRoot(), DirMapleClient)
}
func ZLHSS2WzDir() string { return filepath.Join(ExternalRoot(), DirZLHSS2, "wz") }
