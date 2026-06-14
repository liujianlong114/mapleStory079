package handler

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"mapleStory079/internal/service"
	"mapleStory079/pkg/utils"
)

const (
	maxMessageBytes   = 4096 // 单条消息上限（避免大包洪泛）
	writeWait         = 10 * time.Second
	pongWait          = 60 * time.Second
	pingPeriod        = (pongWait * 9) / 10
	maxChatRunes      = 256
	maxPositionOffset = 2000.0 // 单次坐标变化上限（像素），防瞬移外挂
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

// WSMessage 是 WebSocket 消息统一入口。
// Type 字段必须属于 pkg/utils.WSMessageTypes，否则会被视为非法消息。
type WSMessage struct {
	Type        string  `json:"type"`
	Channel     string  `json:"channel,omitempty"`
	From        string  `json:"from,omitempty"`
	To          string  `json:"to,omitempty"`
	Content     string  `json:"content,omitempty"`
	CharacterID int     `json:"character_id,omitempty"`
	Name        string  `json:"name,omitempty"`
	X           float64 `json:"x,omitempty"`
	Y           float64 `json:"y,omitempty"`
	DX          float64 `json:"dx,omitempty"`
	DY          float64 `json:"dy,omitempty"`
	SkillID     int     `json:"skill_id,omitempty"`
	TargetID    int     `json:"target_id,omitempty"`
	Damage      int     `json:"damage,omitempty"`
	Critical    bool    `json:"critical,omitempty"`
	ExpGained   int     `json:"exp_gained,omitempty"`
	LevelUp     bool    `json:"level_up,omitempty"`
	Mesos       int     `json:"mesos,omitempty"`
	ItemID      int     `json:"item_id,omitempty"`
	Quantity    int     `json:"quantity,omitempty"`
	RespawnAt   int64   `json:"respawn_at,omitempty"`
	MapID       int     `json:"map_id,omitempty"`
	Level       string  `json:"level,omitempty"` // 系统公告等级
	Timestamp   int64   `json:"ts,omitempty"`    // 服务端追加时间戳
}

// clientRef 用于统一管理连接 + 房间信息。
type clientRef struct {
	conn         *websocket.Conn
	channel      string
	characterID  int
	name         string
	lastMoveAt   time.Time
	lastAttackAt time.Time
}

// WebSocketHandler 处理实时消息（聊天 + 位置 + 移动 + 攻击 + 伤害 + 经验 + 复活）。
type WebSocketHandler struct {
	mu      sync.RWMutex
	clients map[*websocket.Conn]*clientRef
	chat    *service.ChatService
}

func NewWebSocketHandler() *WebSocketHandler {
	return &WebSocketHandler{
		clients: make(map[*websocket.Conn]*clientRef),
		chat:    service.NewChatService(),
	}
}

func (h *WebSocketHandler) Handle(c *gin.Context) {
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Println("websocket upgrade error:", err)
		return
	}
	defer conn.Close()

	channel := c.DefaultQuery("channel", "world")
	characterID := int(parseIntOrZero(c.Query("character_id")))
	name := c.DefaultQuery("name", "无名冒险者")

	ref := &clientRef{
		conn:        conn,
		channel:     channel,
		characterID: characterID,
		name:        name,
	}

	h.mu.Lock()
	h.clients[conn] = ref
	h.mu.Unlock()

	defer func() {
		h.mu.Lock()
		delete(h.clients, conn)
		h.mu.Unlock()
		h.broadcast(&WSMessage{
			Type:        utils.WSMessageTypeSystem,
			Channel:     channel,
			Level:       utils.SystemLevelInfo,
			Content:     "玩家 [" + name + "] 离开了地图",
			CharacterID: characterID,
			Timestamp:   time.Now().Unix(),
		})
	}()

	_ = h.send(conn, &WSMessage{
		Type:      utils.WSMessageTypeSystem,
		Level:     utils.SystemLevelSuccess,
		Channel:   channel,
		Content:   "欢迎来到 " + channel + "！共有 " + strconv.Itoa(h.channelCount(channel)) + " 个玩家在线",
		Timestamp: time.Now().Unix(),
	})
	h.broadcastChannel(channel, &WSMessage{
		Type:        utils.WSMessageTypeSystem,
		Level:       utils.SystemLevelInfo,
		Channel:     channel,
		Content:     "玩家 [" + name + "] 加入了地图",
		CharacterID: characterID,
		Name:        name,
		Timestamp:   time.Now().Unix(),
	})

	// 消息循环
	for {
		_, raw, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseNormalClosure) {
				log.Println("websocket read error:", err)
			}
			return
		}
		if len(raw) > maxMessageBytes {
			_ = h.send(conn, &WSMessage{
				Type:      utils.WSMessageTypeSystem,
				Level:     utils.SystemLevelWarning,
				Content:   "消息过大，已被拒绝",
				Timestamp: time.Now().Unix(),
			})
			continue
		}

		var msg WSMessage
		if err := json.Unmarshal(raw, &msg); err != nil {
			continue
		}

		// 类型校验：未知类型直接忽略，防止注入
		if !utils.WSMessageTypes[msg.Type] {
			continue
		}

		h.routeMessage(ref, &msg)
	}
}

// routeMessage 根据 msg.Type 分发处理
func (h *WebSocketHandler) routeMessage(ref *clientRef, msg *WSMessage) {
	now := time.Now()
	msg.CharacterID = pickID(msg.CharacterID, ref.characterID)
	msg.Name = firstNotEmpty(msg.Name, ref.name)

	switch msg.Type {
	case utils.WSMessageTypePing:
		_ = h.send(ref.conn, &WSMessage{
			Type:      utils.WSMessageTypePong,
			Timestamp: now.Unix(),
		})
		return

	case utils.WSMessageTypeChat:
		cleaned := sanitizeChat(msg.Content)
		if cleaned == "" {
			return
		}
		if err := h.chat.SendMessage(service.ChatMessage{
			Channel: firstNotEmpty(msg.Channel, ref.channel),
			From:    msg.Name,
			Content: cleaned,
		}); err != nil {
			log.Println("chat persist error:", err)
		}
		h.broadcastChannel(ref.channel, &WSMessage{
			Type:      utils.WSMessageTypeChat,
			Channel:   ref.channel,
			From:      msg.Name,
			Content:   cleaned,
			Timestamp: now.Unix(),
		})
		return

	case utils.WSMessageTypePosition, utils.WSMessageTypeMove:
		// 节流：位置消息至少 50ms 一条
		if now.Sub(ref.lastMoveAt) < 50*time.Millisecond {
			return
		}
		ref.lastMoveAt = now
		// 防瞬移：当绝对值 > maxPositionOffset 时截断
		msg.X = clamp(msg.X, -maxPositionOffset, maxPositionOffset)
		msg.Y = clamp(msg.Y, -maxPositionOffset, maxPositionOffset)
		h.broadcastChannel(ref.channel, &WSMessage{
			Type:        msg.Type,
			Channel:     ref.channel,
			CharacterID: msg.CharacterID,
			Name:        msg.Name,
			X:           msg.X,
			Y:           msg.Y,
			MapID:       msg.MapID,
			Timestamp:   now.Unix(),
		})
		return

	case utils.WSMessageTypeAttack:
		// 节流：攻击至少 200ms 一次
		if now.Sub(ref.lastAttackAt) < 200*time.Millisecond {
			return
		}
		ref.lastAttackAt = now
		h.broadcastChannel(ref.channel, &WSMessage{
			Type:        utils.WSMessageTypeAttack,
			Channel:     ref.channel,
			CharacterID: msg.CharacterID,
			Name:        msg.Name,
			X:           msg.X,
			Y:           msg.Y,
			SkillID:     msg.SkillID,
			Timestamp:   now.Unix(),
		})
		return

	case utils.WSMessageTypeDamage:
		if msg.Damage <= 0 || msg.Damage > utils.MaxHP {
			return
		}
		h.broadcastChannel(ref.channel, &WSMessage{
			Type:        utils.WSMessageTypeDamage,
			Channel:     ref.channel,
			CharacterID: msg.CharacterID,
			TargetID:    msg.TargetID,
			Damage:      msg.Damage,
			Critical:    msg.Critical,
			X:           msg.X,
			Y:           msg.Y,
			Timestamp:   now.Unix(),
		})
		return

	case utils.WSMessageTypeExp:
		if msg.ExpGained <= 0 {
			return
		}
		h.broadcastChannel(ref.channel, &WSMessage{
			Type:        utils.WSMessageTypeExp,
			Channel:     ref.channel,
			CharacterID: msg.CharacterID,
			Name:        msg.Name,
			ExpGained:   msg.ExpGained,
			LevelUp:     msg.LevelUp,
			Timestamp:   now.Unix(),
		})
		return

	case utils.WSMessageTypeLoot:
		if msg.ItemID == 0 && msg.Mesos <= 0 {
			return
		}
		h.broadcastChannel(ref.channel, &WSMessage{
			Type:        utils.WSMessageTypeLoot,
			Channel:     ref.channel,
			CharacterID: msg.CharacterID,
			Name:        msg.Name,
			ItemID:      msg.ItemID,
			Quantity:    msg.Quantity,
			Mesos:       msg.Mesos,
			Timestamp:   now.Unix(),
		})
		return

	case utils.WSMessageTypeDead:
		h.broadcastChannel(ref.channel, &WSMessage{
			Type:        utils.WSMessageTypeDead,
			Channel:     ref.channel,
			CharacterID: msg.CharacterID,
			Name:        msg.Name,
			TargetID:    msg.TargetID,
			RespawnAt:   now.Add(5 * time.Second).Unix(),
			Timestamp:   now.Unix(),
		})
		return

	case utils.WSMessageTypeRevive:
		h.broadcastChannel(ref.channel, &WSMessage{
			Type:        utils.WSMessageTypeRevive,
			Channel:     ref.channel,
			CharacterID: msg.CharacterID,
			Name:        msg.Name,
			X:           msg.X,
			Y:           msg.Y,
			Timestamp:   now.Unix(),
		})
		return

	case utils.WSMessageTypeSystem:
		// 只有服务端产生 system 消息，客户端上抛的一律忽略
		return

	case utils.WSMessageTypePong:
		// 客户端心跳响应，仅记录
		return
	}
}

func (h *WebSocketHandler) broadcastChannel(channel string, msg *WSMessage) {
	h.mu.RLock()
	refs := make([]*clientRef, 0, len(h.clients))
	for _, ref := range h.clients {
		if ref.channel == channel {
			refs = append(refs, ref)
		}
	}
	h.mu.RUnlock()
	for _, ref := range refs {
		_ = h.send(ref.conn, msg)
	}
}

func (h *WebSocketHandler) broadcast(msg *WSMessage) {
	h.mu.RLock()
	refs := make([]*clientRef, 0, len(h.clients))
	for _, ref := range h.clients {
		refs = append(refs, ref)
	}
	h.mu.RUnlock()
	for _, ref := range refs {
		_ = h.send(ref.conn, msg)
	}
}

func (h *WebSocketHandler) send(conn *websocket.Conn, msg *WSMessage) error {
	if err := conn.WriteJSON(msg); err != nil {
		log.Println("websocket write error:", err)
		return err
	}
	return nil
}

func (h *WebSocketHandler) channelCount(channel string) int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	n := 0
	for _, ref := range h.clients {
		if ref.channel == channel {
			n++
		}
	}
	return n
}

// ChannelCount 对外暴露的统计（例如给 /health 使用）。
func (h *WebSocketHandler) ChannelCount(channel string) int { return h.channelCount(channel) }

// TotalClients 返回当前所有 WebSocket 连接总数。
func (h *WebSocketHandler) TotalClients() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.clients)
}

// ---- 小工具 ----
func parseIntOrZero(s string) int64 {
	if s == "" {
		return 0
	}
	var n int64
	for _, r := range s {
		if r < '0' || r > '9' {
			return 0
		}
		n = n*10 + int64(r-'0')
	}
	return n
}

func firstNotEmpty(a, b string) string {
	if a != "" {
		return a
	}
	return b
}

func pickID(a, b int) int {
	if a != 0 {
		return a
	}
	return b
}

func clamp(v, min, max float64) float64 {
	if v < min {
		return min
	}
	if v > max {
		return max
	}
	return v
}

// sanitizeChat 对聊天内容进行基础清洗：敏感词替换 + 长度裁剪 + 去首尾空白。
func sanitizeChat(s string) string {
	s = strings.TrimSpace(s)
	if len(s) == 0 {
		return ""
	}
	// 长度裁剪（按 rune）
	runes := []rune(s)
	if len(runes) > maxChatRunes {
		runes = runes[:maxChatRunes]
		s = string(runes)
	}
	// 敏感词替换
	for _, w := range utils.SensitiveWords {
		if strings.Contains(s, w) {
			s = strings.ReplaceAll(s, w, strings.Repeat("*", len([]rune(w))))
		}
	}
	return s
}
