package handler

import (
	"log"
	"net/http"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"mapleStory079/internal/service"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

// WebSocketHandler 处理实时消息（聊天广播）。
type WebSocketHandler struct {
	mu      sync.Mutex
	clients map[*websocket.Conn]string
	chat    *service.ChatService
}

func NewWebSocketHandler() *WebSocketHandler {
	return &WebSocketHandler{
		clients: make(map[*websocket.Conn]string),
		chat:    service.NewChatService(),
	}
}

type wsMessage struct {
	Type    string `json:"type"`
	Channel string `json:"channel"`
	From    string `json:"from"`
	To      string `json:"to,omitempty"`
	Content string `json:"content"`
}

func (h *WebSocketHandler) Handle(c *gin.Context) {
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Println("websocket upgrade error:", err)
		return
	}
	defer conn.Close()

	channel := c.DefaultQuery("channel", "world")
	h.mu.Lock()
	h.clients[conn] = channel
	h.mu.Unlock()

	defer func() {
		h.mu.Lock()
		delete(h.clients, conn)
		h.mu.Unlock()
	}()

	for {
		var msg wsMessage
		if err := conn.ReadJSON(&msg); err != nil {
			log.Println("websocket read error:", err)
			return
		}
		if msg.Type == "ping" {
			_ = conn.WriteJSON(gin.H{"type": "pong"})
			continue
		}
		if err := h.chat.SendMessage(service.ChatMessage{
			Channel: msg.Channel,
			From:    msg.From,
			To:      msg.To,
			Content: msg.Content,
		}); err != nil {
			log.Println("send chat message error:", err)
			continue
		}
		h.mu.Lock()
		for client, ch := range h.clients {
			if ch != msg.Channel {
				continue
			}
			if err := client.WriteJSON(msg); err != nil {
				log.Println("websocket write error:", err)
			}
		}
		h.mu.Unlock()
	}
}
