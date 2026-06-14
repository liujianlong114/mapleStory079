package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"mapleStory079/internal/handler"
	"mapleStory079/pkg/cache"
	"mapleStory079/pkg/database"
	"mapleStory079/pkg/utils"

	"github.com/spf13/viper"
)

func initConfig() {
	if err := database.LoadConfig(""); err != nil {
		log.Fatalf("Error reading config file: %v", err)
	}
	log.Printf("Game: %s %s", viper.GetString("game.name"), viper.GetString("game.version"))
}

func main() {
	initConfig()

	if err := database.Init(); err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	if err := utils.InitForbiddenNames(); err != nil {
		log.Printf("Warning: forbidden names not loaded: %v", err)
	} else {
		log.Println("Forbidden names loaded from ms079-main")
	}
	if err := database.AutoMigrate(
		&database.Account{},
		&database.Character{},
		&database.CharacterStats{},
		&database.CharacterInventory{},
		&database.Item{},
		&database.Skill{},
		&database.Quest{},
		&database.CharacterQuest{},
		&database.Map{},
		&database.NPC{},
		&database.Mob{},
		&database.MobDrop{},
		&database.Guild{},
		&database.Party{},
		&database.Friend{},
		&database.LoginLog{},
		&database.TradeLog{},
		&database.ChatLog{},
	); err != nil {
		log.Printf("Warning: auto-migration failed: %v", err)
	}
	defer database.Close()

	if _, err := database.SeedDefaultData(); err != nil {
		log.Printf("Warning: seed default data failed: %v", err)
	}

	if err := cache.Init(); err != nil {
		log.Println("Failed to initialize cache, proceeding without cache:", err)
	}
	defer cache.Close()

	services := handler.NewServiceBundle()
	r := handler.SetupRouter(services)

	host := viper.GetString("server.host")
	port := viper.GetString("server.port")
	addr := host + ":" + port

	readTimeout := viper.GetInt("server.readTimeout")
	if readTimeout <= 0 {
		readTimeout = 10
	}
	writeTimeout := viper.GetInt("server.writeTimeout")
	if writeTimeout <= 0 {
		writeTimeout = 10
	}
	shutdownTimeout := viper.GetInt("server.shutdownTimeout")
	if shutdownTimeout <= 0 {
		shutdownTimeout = 5
	}

	go func() {
		log.Printf("Server is starting on http://%s", addr)
		log.Printf("  ReadTimeout: %ds", readTimeout)
		log.Printf("  WriteTimeout: %ds", writeTimeout)
		log.Printf("  ShutdownTimeout: %ds", shutdownTimeout)
		if err := r.Run(addr); err != nil {
			log.Fatalf("Failed to run server: %v", err)
		}
	}()

	log.Printf("Server is running on http://%s", addr)
	log.Println("Press Ctrl+C to shutdown gracefully")

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("")
	log.Println("========== Shutdown Signal Received ==========")
	log.Println("Initiating graceful shutdown...")
	time.Sleep(time.Duration(shutdownTimeout) * time.Second)
	log.Println("==============================================")
	log.Println("Server shutdown complete. Goodbye! 👋")
}
