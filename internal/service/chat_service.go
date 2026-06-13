package service

import (
	"errors"
	"strings"
	"sync"
	"time"

	"mapleStory079/pkg/database"
	"mapleStory079/pkg/utils"
)

// ChatMessage 内存聊天消息结构（供 handler 使用）。
type ChatMessage struct {
	ID        int64  `json:"id"`
	Channel   string `json:"channel"` // world/guild/party/private
	From      string `json:"from"`
	To        string `json:"to,omitempty"`
	Content   string `json:"content"`
	Timestamp int64  `json:"timestamp"`
}

// ChatService 聊天服务：负责消息发送、历史查询、频道广播、内容过滤。
type ChatService struct {
	mu           sync.RWMutex
	memoryBuffer []ChatMessage // 内存消息缓冲
	nextID       int64
	broadcast    map[string][]chan string // room -> subscribers
}

// NewChatService 创建聊天服务实例。
func NewChatService() *ChatService {
	return &ChatService{
		memoryBuffer: make([]ChatMessage, 0, 256),
		broadcast:    make(map[string][]chan string),
	}
}

// channelNameToInt 将 handler 中传入的字符串频道名转换为常量 int 值。
func channelNameToInt(name string) int {
	switch name {
	case "world":
		return utils.ChannelWorld
	case "guild":
		return utils.ChannelGuild
	case "party":
		return utils.ChannelParty
	case "private":
		return utils.ChannelWhisper
	}
	return utils.ChannelWorld
}

// SendMessage 发送一条聊天消息（API 形式：ChatMessage）。
// 兼容现有 handler；同时会写入数据库 ChatLog。
func (s *ChatService) SendMessage(msg ChatMessage) error {
	if !s.ValidateContent(msg.Content) {
		return errors.New("invalid message content")
	}

	channel := channelNameToInt(msg.Channel)
	// 构建数据库 ChatLog 并写入
	trimmed := strings.TrimSpace(msg.Content)
	if len([]rune(trimmed)) > utils.ChatMessageMaxLength {
		trimmed = string([]rune(trimmed)[:utils.ChatMessageMaxLength])
	}
	log := &database.ChatLog{
		CharacterID: 0, // 简化：这里不绑定具体角色
		ReceiverID:  0,
		Channel:     channel,
		Message:     trimmed,
		CreatedAt:   time.Now(),
	}
	if err := database.GetDB().Create(log).Error; err != nil {
		return err
	}

	s.mu.Lock()
	s.nextID++
	msg.ID = s.nextID
	msg.Timestamp = time.Now().Unix()
	msg.Content = trimmed
	s.memoryBuffer = append(s.memoryBuffer, msg)
	if len(s.memoryBuffer) > 512 {
		s.memoryBuffer = s.memoryBuffer[len(s.memoryBuffer)-512:]
	}
	s.mu.Unlock()

	// 向对应房间广播
	s.BroadcastToRoom(msg.Channel, msg.Content)
	return nil
}

// GetRecent 返回最近 N 条消息；若 channel 非空，则仅返回对应通道。
func (s *ChatService) GetRecent(n int, channel string) []ChatMessage {
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := make([]ChatMessage, 0, n)
	for i := len(s.memoryBuffer) - 1; i >= 0 && len(out) < n; i-- {
		m := s.memoryBuffer[i]
		if channel == "" || m.Channel == channel {
			out = append(out, m)
		}
	}
	// 反转回时间升序
	for l, r := 0, len(out)-1; l < r; l, r = l+1, r-1 {
		out[l], out[r] = out[r], out[l]
	}
	return out
}

// SendMessageWithID 带角色/频道 ID 的精确发送 API（新服务接口）。
func (s *ChatService) SendMessageWithID(characterID uint, channel int, receiverID uint, message string) (*database.ChatLog, error) {
	if characterID == 0 {
		return nil, errors.New("invalid character id")
	}
	if !IsValidChannel(channel) {
		return nil, errors.New("invalid channel")
	}
	if !s.ValidateContent(message) {
		return nil, errors.New("invalid message content")
	}

	trimmed := strings.TrimSpace(message)
	if len([]rune(trimmed)) > utils.ChatMessageMaxLength {
		trimmed = string([]rune(trimmed)[:utils.ChatMessageMaxLength])
	}

	log := &database.ChatLog{
		CharacterID: characterID,
		ReceiverID:  receiverID,
		Channel:     channel,
		Message:     trimmed,
		CreatedAt:   time.Now(),
	}
	if err := database.GetDB().Create(log).Error; err != nil {
		return nil, err
	}
	return log, nil
}

// GetHistory 查询指定频道自 since 时间起的聊天记录（按时间升序返回）。
func (s *ChatService) GetHistory(channel int, since time.Time) ([]database.ChatLog, error) {
	if !IsValidChannel(channel) {
		return nil, errors.New("invalid channel")
	}
	var logs []database.ChatLog
	query := database.GetDB().Where("channel = ?", channel)
	if !since.IsZero() {
		query = query.Where("created_at >= ?", since)
	}
	err := query.Order("created_at ASC").Limit(200).Find(&logs).Error
	if err != nil {
		return nil, err
	}
	return logs, nil
}

// BroadcastToRoom 向指定房间广播消息（供外部实时推送使用）。
func (s *ChatService) BroadcastToRoom(room string, message string) {
	if room == "" || message == "" {
		return
	}
	s.mu.RLock()
	chans := s.broadcast[room]
	s.mu.RUnlock()
	for _, ch := range chans {
		select {
		case ch <- message:
		default:
			// 队列已满，丢弃消息避免阻塞
		}
	}
}

// Subscribe 订阅房间消息；返回只读 channel；调用方负责退出时调用 Unsubscribe。
func (s *ChatService) Subscribe(room string) <-chan string {
	ch := make(chan string, 16)
	s.mu.Lock()
	s.broadcast[room] = append(s.broadcast[room], ch)
	s.mu.Unlock()
	return ch
}

// Unsubscribe 取消订阅房间消息。
func (s *ChatService) Unsubscribe(room string, ch <-chan string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	items := s.broadcast[room]
	for i, c := range items {
		if c == ch {
			items = append(items[:i], items[i+1:]...)
			break
		}
	}
	s.broadcast[room] = items
}

// ValidateContent 校验消息内容：非空、长度合规、不包含敏感词。
func (s *ChatService) ValidateContent(message string) bool {
	trimmed := strings.TrimSpace(message)
	if trimmed == "" {
		return false
	}
	if len([]rune(trimmed)) > utils.ChatMessageMaxLength {
		return false
	}
	for _, word := range utils.SensitiveWords {
		if word != "" && strings.Contains(trimmed, word) {
			return false
		}
	}
	return true
}

// IsValidChannel 判断频道号是否合法。
func IsValidChannel(channel int) bool {
	switch channel {
	case utils.ChannelWorld, utils.ChannelGuild, utils.ChannelParty, utils.ChannelWhisper:
		return true
	}
	return false
}
