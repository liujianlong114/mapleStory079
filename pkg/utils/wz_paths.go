package utils

import (
	"os"
	"path/filepath"
)

const dirMapleClient = "03-★maple-client-ingest工作目录-WZ副本-脚本自动复制"

// ProjectRoot 返回仓库根目录（含 go.mod）
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

// ExternalRoot 外部参考目录 mapleStory079-external
func ExternalRoot() string {
	if r := os.Getenv("MAPLE_EXTERNAL_ROOT"); r != "" {
		return r
	}
	return filepath.Join(filepath.Dir(ProjectRoot()), "mapleStory079-external")
}

// MapleClientDir Character.wz 等工作副本路径
func MapleClientDir() string {
	if d := os.Getenv("MAPLE_CLIENT_DIR"); d != "" {
		return d
	}
	return filepath.Join(ExternalRoot(), dirMapleClient)
}

// WzPythonVenv Python wzpy 虚拟环境解释器
func WzPythonVenv() string {
	root := ProjectRoot()
	return filepath.Join(root, ".cache", "wz-python", ".venv", "bin", "python")
}
