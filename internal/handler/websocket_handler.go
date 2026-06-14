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
// 兼容客户端嵌套格式：{type, payload, sender_id, room}。
type WSMessage struct {
	Type        string                 `json:"type"`
	Channel     string                 `json:"channel,omitempty"`
	Room        string                 `json:"room,omitempty"`
	From        string                 `json:"from,omitempty"`
	To          string                 `json:"to,omitempty"`
	Content     string                 `json:"content,omitempty"`
	CharacterID int                    `json:"character_id,omitempty"`
	SenderID    int                    `json:"sender_id,omitempty"`
	Name        string                 `json:"name,omitempty"`
	X           float64                `json:"x,omitempty"`
	Y           float64                `json:"y,omitempty"`
	DX          float64                `json:"dx,omitempty"`
	DY          float64                `json:"dy,omitempty"`
	SkillID     int                    `json:"skill_id,omitempty"`
	TargetID    int                    `json:"target_id,omitempty"`
	Damage      int                    `json:"damage,omitempty"`
	Critical    bool                   `json:"critical,omitempty"`
	ExpGained   int                    `json:"exp_gained,omitempty"`
	LevelUp     bool                   `json:"level_up,omitempty"`
	Mesos       int                    `json:"mesos,omitempty"`
	ItemID      int                    `json:"item_id,omitempty"`
	Quantity    int                    `json:"quantity,omitempty"`
	RespawnAt   int64                  `json:"respawn_at,omitempty"`
	MapID       int                    `json:"map_id,omitempty"`
	Level       string                 `json:"level,omitempty"`  // 系统公告等级
	Action      string                 `json:"action,omitempty"` // loot: spawn | pickup
	DropID      string                 `json:"drop_id,omitempty"`
	Timestamp   int64                  `json:"ts,omitempty"` // 服务端追加时间戳
	Payload     map[string]interface{} `json:"payload,omitempty"`
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
	loot    *service.LootService
}

func NewWebSocketHandler() *WebSocketHandler {
	return &WebSocketHandler{
		clients: make(map[*websocket.Conn]*clientRef),
		chat:    service.NewChatService(),
		loot:    service.DefaultLootService,
	}
}

func (h *WebSocketHandler) Handle(c *gin.Context) {
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Println("websocket upgrade error:", err)
		return
	}
	defer conn.Close()

	channel := c.DefaultQuery("channel", "")
	if channel == "" {
		channel = c.DefaultQuery("room", "world")
	}
	characterID := int(parseIntOrZero(c.Query("character_id")))
	name := c.DefaultQuery("name", "无名冒险者")

	ref := &clientRef{
		conn:        conn,
		channel:     channel,
		characterID: characterID,
		name:        name,
	}

	_ = conn.SetReadDeadline(time.Now().Add(pongWait))
	conn.SetPongHandler(func(string) error {
		return conn.SetReadDeadline(time.Now().Add(pongWait))
	})

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
		normalizeWSMessage(&msg)

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
		_ = ref.conn.SetReadDeadline(time.Now().Add(pongWait))
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
		if msg.Action == "pickup" && msg.DropID != "" {
			h.handleLootPickup(ref, msg, now)
			return
		}
		if msg.Action == "spawn" {
			// spawn 仅由服务端 HTTP 战斗触发，客户端不可伪造
			return
		}
		if msg.ItemID == 0 && msg.Mesos <= 0 {
			return
		}
		h.broadcastChannel(ref.channel, &WSMessage{
			Type:        utils.WSMessageTypeLoot,
			Channel:     ref.channel,
			Action:      firstNotEmpty(msg.Action, "notify"),
			CharacterID: msg.CharacterID,
			Name:        msg.Name,
			DropID:      msg.DropID,
			ItemID:      msg.ItemID,
			Quantity:    msg.Quantity,
			Mesos:       msg.Mesos,
			X:           msg.X,
			Y:           msg.Y,
			MapID:       msg.MapID,
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

func (h *WebSocketHandler) BroadcastLoot(channel string, msg *WSMessage) {
	if msg.Timestamp == 0 {
		msg.Timestamp = time.Now().Unix()
	}
	h.broadcastChannel(channel, msg)
}

func (h *WebSocketHandler) handleLootPickup(ref *clientRef, msg *WSMessage, now time.Time) {
	charID := uint(pickID(msg.CharacterID, ref.characterID))
	loot, err := h.loot.Pickup(msg.DropID, charID, msg.X, msg.Y)
	if err != nil {
		_ = h.send(ref.conn, &WSMessage{
			Type:      utils.WSMessageTypeSystem,
			Level:     utils.SystemLevelWarning,
			Content:   "拾取失败: " + err.Error(),
			Timestamp: now.Unix(),
		})
		return
	}
	h.broadcastChannel(ref.channel, &WSMessage{
		Type:        utils.WSMessageTypeLoot,
		Channel:     ref.channel,
		Action:      "pickup",
		DropID:      loot.ID,
		CharacterID: int(charID),
		Name:        ref.name,
		ItemID:      loot.ItemID,
		Quantity:    loot.Quantity,
		Mesos:       loot.Mesos,
		X:           loot.X,
		Y:           loot.Y,
		Timestamp:   now.Unix(),
	})
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

// normalizeWSMessage 将客户端 {type,payload,sender_id,room} 格式展平为顶层字段。
func normalizeWSMessage(msg *WSMessage) {
	if msg.SenderID != 0 && msg.CharacterID == 0 {
		msg.CharacterID = msg.SenderID
	}
	if msg.Room != "" && msg.Channel == "" {
		msg.Channel = msg.Room
	}
	if len(msg.Payload) == 0 {
		return
	}
	p := msg.Payload
	if v, ok := p["content"].(string); ok && msg.Content == "" {
		msg.Content = v
	}
	if v, ok := p["character_id"].(float64); ok && msg.CharacterID == 0 {
		msg.CharacterID = int(v)
	}
	if v, ok := p["sender_name"].(string); ok && msg.Name == "" {
		msg.Name = v
	}
	if v, ok := p["x"].(float64); ok && msg.X == 0 {
		msg.X = v
	}
	if v, ok := p["y"].(float64); ok && msg.Y == 0 {
		msg.Y = v
	}
	if v, ok := p["skill_id"].(float64); ok && msg.SkillID == 0 {
		msg.SkillID = int(v)
	}
	if v, ok := p["target_id"].(float64); ok && msg.TargetID == 0 {
		msg.TargetID = int(v)
	}
	if v, ok := p["damage"].(float64); ok && msg.Damage == 0 {
		msg.Damage = int(v)
	}
	if v, ok := p["critical"].(bool); ok {
		msg.Critical = v
	}
	if v, ok := p["exp_gained"].(float64); ok && msg.ExpGained == 0 {
		msg.ExpGained = int(v)
	}
	if v, ok := p["level_up"].(bool); ok {
		msg.LevelUp = v
	}
	if v, ok := p["item_id"].(float64); ok && msg.ItemID == 0 {
		msg.ItemID = int(v)
	}
	if v, ok := p["quantity"].(float64); ok && msg.Quantity == 0 {
		msg.Quantity = int(v)
	}
	if v, ok := p["mesos"].(float64); ok && msg.Mesos == 0 {
		msg.Mesos = int(v)
	}
	if v, ok := p["action"].(string); ok && msg.Action == "" {
		msg.Action = v
	}
	if v, ok := p["drop_id"].(string); ok && msg.DropID == "" {
		msg.DropID = v
	}
	if v, ok := p["map_id"].(string); ok && msg.MapID == 0 {
		msg.MapID = int(parseIntOrZero(v))
	}
	if v, ok := p["map_id"].(float64); ok && msg.MapID == 0 {
		msg.MapID = int(v)
	}
	if v, ok := p["channel"].(float64); ok && msg.Channel == "" {
		msg.Channel = strconv.Itoa(int(v))
	}
	msg.Payload = nil
}
