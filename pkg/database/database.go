package database

import (
	"fmt"
	"log"
	"time"

	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/mysql"
	"github.com/spf13/viper"
)

// DB 全局数据库连接句柄，供其他包直接使用（database.DB.Where(...)）。
var DB *gorm.DB

// Init 读取配置并连接 MySQL 数据库。
func Init() error {
	host := viper.GetString("database.host")
	if host == "" {
		host = "127.0.0.1"
	}
	port := viper.GetString("database.port")
	if port == "" {
		port = "3306"
	}
	username := viper.GetString("database.username")
	if username == "" {
		username = "root"
	}
	password := viper.GetString("database.password")
	database := viper.GetString("database.database")
	if database == "" {
		database = "maplestory"
	}
	charset := viper.GetString("database.charset")
	if charset == "" {
		charset = "utf8mb4"
	}
	parseTime := viper.GetBool("database.parseTime")
	// 即使 parseTime 未配置，也强制启用，否则 time.Time 字段无法解析。
	parseTimeStr := "true"
	if !parseTime && viper.IsSet("database.parseTime") {
		parseTimeStr = "false"
	}

	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=%s&parseTime=%s&loc=Local",
		username, password, host, port, database, charset, parseTimeStr)

	maxRetries := viper.GetInt("database.maxRetries")
	if maxRetries <= 0 {
		maxRetries = 3
	}
	retryInterval := viper.GetInt("database.retryInterval")
	if retryInterval <= 0 {
		retryInterval = 2
	}

	var err error
	for attempt := 1; attempt <= maxRetries; attempt++ {
		log.Printf("Connecting to database %s@%s:%s/%s (attempt %d/%d)...", username, host, port, database, attempt, maxRetries)
		DB, err = gorm.Open("mysql", dsn)
		if err == nil {
			log.Printf("Database connection established successfully")
			break
		}
		log.Printf("Connection failed: %v", err)
		if attempt < maxRetries {
			log.Printf("Retrying in %d seconds...", retryInterval)
			time.Sleep(time.Duration(retryInterval) * time.Second)
		}
	}
	if err != nil {
		return fmt.Errorf("failed to connect to database after %d attempts: %w", maxRetries, err)
	}

	maxIdle := viper.GetInt("database.maxIdleConns")
	if maxIdle <= 0 {
		maxIdle = 10
	}
	maxOpen := viper.GetInt("database.maxOpenConns")
	if maxOpen <= 0 {
		maxOpen = 100
	}
	connMaxLifetime := viper.GetInt("database.connMaxLifetime")
	if connMaxLifetime <= 0 {
		connMaxLifetime = 3600
	}

	DB.DB().SetMaxIdleConns(maxIdle)
	DB.DB().SetMaxOpenConns(maxOpen)
	DB.DB().SetConnMaxLifetime(time.Duration(connMaxLifetime) * time.Second)
	DB.LogMode(viper.GetString("logging.level") == "debug")

	if viper.GetBool("database.autoMigrate") || viper.GetBool("database.auto_migrate") {
		log.Println("Database migration flag set; callers should invoke database.AutoMigrate(models)")
	}

	return nil
}

// AutoMigrate 对传入的模型执行 gorm 自动建表/迁移。
func AutoMigrate(models ...interface{}) error {
	if DB == nil {
		return fmt.Errorf("database not initialized, call Init() first")
	}
	if len(models) == 0 {
		log.Println("AutoMigrate skipped: no models provided")
		return nil
	}
	log.Printf("Auto-migrating %d model(s)...", len(models))
	if err := DB.AutoMigrate(models...).Error; err != nil {
		return err
	}
	log.Println("Auto-migration completed successfully")
	return nil
}

// GetDB 返回当前数据库连接（与 DB 等价，便于部分调用方选择使用）。
func GetDB() *gorm.DB {
	return DB
}

// HealthCheck 测试数据库是否仍可访问。
func HealthCheck() error {
	if DB == nil {
		return fmt.Errorf("database not initialized")
	}
	return DB.DB().Ping()
}

// Close 关闭数据库连接。
func Close() error {
	if DB != nil {
		log.Println("Closing database connection...")
		err := DB.Close()
		DB = nil
		return err
	}
	return nil
}
