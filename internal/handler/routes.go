package handler

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"mapleStory079/internal/middleware"
	"mapleStory079/pkg/cache"
	"mapleStory079/pkg/database"
)

// ServiceBundle 聚合各类业务服务实例，便于 router 统一注入。
// 目前保留最小实现：业务逻辑已在各 handler 内部构造。
type ServiceBundle struct{}

// NewServiceBundle 创建服务聚合实例。
func NewServiceBundle() *ServiceBundle { return &ServiceBundle{} }

// SetupRouter 创建 Gin 引擎并注册所有路由。
//
// 与 gin.Default() 不同，这里显式地装配我们自己的中间件链：
//  1. RequestID    链路追踪
//  2. Recovery     panic 恢复
//  3. CORS         跨域
//  4. Logger       请求日志
//  5. RateLimit    全局限流
func SetupRouter(services *ServiceBundle) *gin.Engine {
	r := gin.New()
	r.Use(middleware.RequestIDMiddleware())
	r.Use(middleware.RecoveryMiddleware())
	r.Use(middleware.CORSMiddleware())
	r.Use(middleware.LoggerMiddleware())
	r.Use(middleware.RateLimitMiddleware())

	authHandler := NewAuthHandler()
	charHandler := NewCharacterHandler()
	gameHandler := NewGameHandler()
	npcHandler := NewNPCHandler()
	invHandler := NewInventoryHandler()
	skillHandler := NewSkillHandler()
	chatHandler := NewChatHandler()
	socialHandler := NewSocialHandler()
	wsHandler := NewWebSocketHandler()

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
			registerSocialRoutes(v1, socialHandler)
		}
	}

	r.GET("/ws", wsHandler.Handle)
	r.GET("/health", healthHandler)
	return r
}

func registerAuthRoutes(r *gin.RouterGroup, h *AuthHandler) {
	auth := r.Group("/auth")
	{
		auth.POST("/register", h.Register)
		auth.POST("/login", h.Login)
	}
}

func registerCharacterRoutes(r *gin.RouterGroup, h *CharacterHandler) {
	characters := r.Group("/characters")
	{
		characters.POST("/", h.Create)
		characters.GET("/", h.GetByAccount)
		characters.GET("/:id", h.GetByID)
		characters.PUT("/:id", h.Update)
		characters.DELETE("/:id", h.Delete)
	}
}

func registerGameRoutes(r *gin.RouterGroup, h *GameHandler) {
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
		game.GET("/state", h.GetGameState)
		game.POST("/gain-exp", h.GainExp)
	}
}

func registerNPCRoutes(r *gin.RouterGroup, h *NPCHandler) {
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

func registerInventoryRoutes(r *gin.RouterGroup, h *InventoryHandler) {
	inventory := r.Group("/inventory")
	{
		inventory.GET("", h.List)
		inventory.POST("/add", h.Add)
		inventory.POST("/remove", h.Remove)
	}
}

func registerSkillRoutes(r *gin.RouterGroup, h *SkillHandler) {
	skills := r.Group("/skills")
	{
		skills.GET("", h.List)
		skills.GET("/:id", h.Get)
	}
}

func registerChatRoutes(r *gin.RouterGroup, h *ChatHandler) {
	chat := r.Group("/chat")
	{
		chat.POST("/send", h.Send)
		chat.GET("/history", h.List)
	}
}

// registerSocialRoutes 注册公会/组队/好友相关 API。
func registerSocialRoutes(r *gin.RouterGroup, h *SocialHandler) {
	guild := r.Group("/guilds")
	{
		guild.POST("/", h.CreateGuild)
		guild.POST("/:id/join", h.JoinGuild)
		guild.POST("/:id/leave", h.LeaveGuild)
	}

	party := r.Group("/parties")
	{
		party.POST("/", h.CreateParty)
		party.POST("/:id/accept", h.AcceptParty)
		party.POST("/:id/leave", h.LeaveParty)
	}

	friend := r.Group("/friends")
	{
		friend.POST("/", h.AddFriend)
		friend.GET("/:id", h.ListFriends)
		friend.DELETE("/:id", h.RemoveFriend)
	}
}

func parseUintOrZero(s string) uint64 {
	if s == "" {
		return 0
	}
	var n uint64
	for _, r := range s {
		if r < '0' || r > '9' {
			return 0
		}
		n = n*10 + uint64(r-'0')
	}
	return n
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
		"cache": gin.H{
			"entries":  cache.Size(),
			"hit_rate": cache.HitRate(),
		},
		"timestamp": time.Now().Format(time.RFC3339),
	})
}
