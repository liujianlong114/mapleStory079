package database

import (
	"fmt"
	"log"

	"github.com/spf13/viper"
)

// LoadConfig 读取 config.yaml（与 cmd/server/main.go 一致）。
// configPath 非空时优先使用该文件。
func LoadConfig(configPath string) error {
	if configPath != "" {
		viper.SetConfigFile(configPath)
	} else {
		viper.SetConfigName("config")
		viper.SetConfigType("yaml")
		viper.AddConfigPath("./config")
		viper.AddConfigPath("../config")
		viper.AddConfigPath("../../config")
	}
	if err := viper.ReadInConfig(); err != nil {
		return fmt.Errorf("read config: %w", err)
	}
	log.Printf("Configuration loaded: %s", viper.ConfigFileUsed())
	return nil
}

// DSNInfo 返回当前配置中的数据库连接摘要（不含密码明文）。
func DSNInfo() string {
	host := viper.GetString("database.host")
	port := viper.GetString("database.port")
	user := viper.GetString("database.username")
	db := viper.GetString("database.database")
	if host == "" {
		host = "127.0.0.1"
	}
	if port == "" {
		port = "3306"
	}
	if db == "" {
		db = "maplestory"
	}
	return fmt.Sprintf("%s@%s:%s/%s", user, host, port, db)
}
