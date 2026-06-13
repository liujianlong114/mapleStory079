package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/spf13/viper"
	"mapleStory079/internal/handler"
	"mapleStory079/internal/middleware"
	"mapleStory079/internal/service"
	"mapleStory079/pkg/cache"
	"mapleStory079/pkg/database"
)

func initConfig() {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./config")
	viper.AddConfigPath("../config")
	viper.AddConfigPath("../../config")

	if err := viper.ReadInConfig(); err != nil {
		log.Fatalf("Error reading config file: %v", err)
	}

	log.Printf("Configuration loaded successfully")
	log.Printf("Game: %s %s", viper.GetString("game.name"), viper.GetString("game.version"))
}

// setupServices 统一初始化全部业务服务层，便于上层共享同一全局服务实例。
func setupServices() *ServiceBundle {
	return &ServiceBundle{
		ChatService:   service.NewChatService(),
		SkillService:  service.NewSkillService(),
		GuildService:  service.NewGuildService(),
		PartyService:  service.NewPartyService(),
		FriendService: service.NewFriendService(),
	}
}

// ServiceBundle 聚合各类业务服务实例，便于 router 统一注入。
type ServiceBundle struct {
	ChatService   *service.ChatService
	SkillService  *service.SkillService
	GuildService  *service.GuildService
	PartyService  *service.PartyService
	FriendService *service.FriendService
}

// setupRouter 创建 Gin 引擎并注册所有路由；路由定义抽取为独立函数。
func setupRouter(services *ServiceBundle) *gin.Engine {
	gin.SetMode(viper.GetString("server.mode"))

	r := gin.Default()

	r.Use(middleware.RequestIDMiddleware())
	r.Use(middleware.CORSMiddleware())
	r.Use(middleware.StructuredLoggerMiddleware())
	r.Use(middleware.LoggerMiddleware())
	r.Use(middleware.RateLimitMiddleware())

	authHandler := handler.NewAuthHandler()
	charHandler := handler.NewCharacterHandler()
	gameHandler := handler.NewGameHandler()
	npcHandler := handler.NewNPCHandler()
	invHandler := handler.NewInventoryHandler()
	skillHandler := handler.NewSkillHandler()
	chatHandler := handler.NewChatHandler()

	api := r.Group("/api")
	{
		v1 := api.Group("/v1")
		{
			registerAuthRoutes(v1, authHandler)
			registerCharacterRoutes(v1, charHandler)
			registerGameRoutes(v1, gameHandler)
			registerNPCRoutes(v1, npcHandler)
			registerInventoryRoutes(v1, invHandler)
			registerSkillRoutes(v1, skillHandler)
			registerChatRoutes(v1, chatHandler)
		}
	}

	wsHandler := handler.NewWebSocketHandler()
	r.GET("/ws", wsHandler.Handle)

	r.GET("/health", healthHandler)

	return r
}

func registerAuthRoutes(r *gin.RouterGroup, h *handler.AuthHandler) {
	auth := r.Group("/auth")
	{
		auth.POST("/register", h.Register)
		auth.POST("/login", h.Login)
	}
}

func registerCharacterRoutes(r *gin.RouterGroup, h *handler.CharacterHandler) {
	characters := r.Group("/characters")
	{
		characters.POST("/", h.Create)
		characters.GET("/", h.GetByAccount)
		characters.GET("/:id", h.GetByID)
		characters.PUT("/:id", h.Update)
		characters.DELETE("/:id", h.Delete)
	}
}

func registerGameRoutes(r *gin.RouterGroup, h *handler.GameHandler) {
	maps := r.Group("/maps")
	{
		maps.GET("/", h.ListMaps)
		maps.GET("/:id", h.GetMap)
	}

	mobs := r.Group("/mobs")
	{
		mobs.GET("/", h.ListMobs)
		mobs.GET("/:id", h.GetMob)
	}

	combat := r.Group("/combat")
	{
		combat.POST("/attack", h.Attack)
	}

	quests := r.Group("/quests")
	{
		quests.GET("/", h.ListQuests)
	}

	game := r.Group("/game")
	{
		game.GET("/state", h.ListMaps)
		game.POST("/gain-exp", h.Attack)
	}
}

func registerNPCRoutes(r *gin.RouterGroup, h *handler.NPCHandler) {
	npcs := r.Group("/npcs")
	{
		npcs.GET("/:id", h.Start)
		npcs.POST("/interact/:id", h.Start)
	}

	npc := r.Group("/npc")
	{
		npc.POST("/dialogue", h.Start)
		npc.POST("/dialogue/continue", h.Continue)
	}
}

func registerInventoryRoutes(r *gin.RouterGroup, h *handler.InventoryHandler) {
	inventory := r.Group("/inventory")
	{
		inventory.GET("", h.List)
		inventory.POST("/add", h.Add)
		inventory.POST("/remove", h.Remove)
	}
}

func registerSkillRoutes(r *gin.RouterGroup, h *handler.SkillHandler) {
	skills := r.Group("/skills")
	{
		skills.GET("", h.List)
		skills.GET("/:id", h.Get)
	}
}

func registerChatRoutes(r *gin.RouterGroup, h *handler.ChatHandler) {
	chat := r.Group("/chat")
	{
		chat.POST("/send", h.Send)
		chat.GET("/history", h.List)
	}
}

func healthHandler(c *gin.Context) {
	dbStatus := "ok"
	if err := database.HealthCheck(); err != nil {
		dbStatus = "unreachable"
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "ok",
		"message": "MapleStory 079 Server is running",
		"database": gin.H{
			"status": dbStatus,
		},
		"game": gin.H{
			"name":      viper.GetString("game.name"),
			"version":   viper.GetString("game.version"),
			"max_level": viper.GetInt("game.maxLevel"),
		},
		"timestamp": time.Now().Format(time.RFC3339),
	})
}

func main() {
	initConfig()

	if err := database.Init(); err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	if err := database.AutoMigrate(
		&database.Account{},
		&database.Character{},
		&database.CharacterStats{},
		&database.CharacterInventory{},
		&database.Item{},
		&database.Skill{},
		&database.Quest{},
		&database.Map{},
		&database.NPC{},
		&database.Mob{},
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

	if err := cache.Init(); err != nil {
		log.Println("Failed to initialize cache, proceeding without cache:", err)
	}
	defer cache.Close()

	services := setupServices()
	r := setupRouter(services)

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

	srv := &http.Server{
		Addr:         addr,
		Handler:      r,
		ReadTimeout:  time.Duration(readTimeout) * time.Second,
		WriteTimeout: time.Duration(writeTimeout) * time.Second,
	}

	go func() {
		log.Printf("Server is starting on http://%s", addr)
		log.Printf("  ReadTimeout: %ds", readTimeout)
		log.Printf("  WriteTimeout: %ds", writeTimeout)
		log.Printf("  ShutdownTimeout: %ds", shutdownTimeout)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
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

	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(shutdownTimeout)*time.Second)
	defer cancel()

	log.Println("Closing HTTP server...")
	if err := srv.Shutdown(ctx); err != nil {
		log.Printf("HTTP server shutdown error: %v", err)
	} else {
		log.Println("HTTP server closed successfully")
	}

	select {
	case <-ctx.Done():
		log.Printf("Shutdown timeout of %ds exceeded", shutdownTimeout)
	default:
	}

	log.Println("==============================================")
	log.Println("Server shutdown complete. Goodbye! 👋")
}
