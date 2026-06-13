package cache

import (
	"log"
	"sync"
	"time"
)

type cacheItem struct {
	value      interface{}
	expiration time.Time
	hasExpiry  bool
}

type Cache struct {
	mu    sync.RWMutex
	items map[string]cacheItem
	hits  uint64
	miss  uint64
}

var instance *Cache
var once sync.Once

func Init() error {
	once.Do(func() {
		instance = &Cache{
			items: make(map[string]cacheItem),
		}
	})
	log.Println("In-memory cache initialized")
	return nil
}

func GetInstance() *Cache {
	if instance == nil {
		Init()
	}
	return instance
}

func Set(key string, value interface{}, ttl time.Duration) {
	c := GetInstance()
	c.mu.Lock()
	defer c.mu.Unlock()

	item := cacheItem{value: value}
	if ttl > 0 {
		item.expiration = time.Now().Add(ttl)
		item.hasExpiry = true
	}
	c.items[key] = item
}

func Get(key string) (interface{}, bool) {
	c := GetInstance()
	c.mu.RLock()
	defer c.mu.RUnlock()

	item, exists := c.items[key]
	if !exists {
		c.miss++
		return nil, false
	}
	if item.hasExpiry && time.Now().After(item.expiration) {
		c.miss++
		return nil, false
	}
	c.hits++
	return item.value, true
}

func Delete(key string) {
	c := GetInstance()
	c.mu.Lock()
	defer c.mu.Unlock()
	delete(c.items, key)
}

func Clear() {
	c := GetInstance()
	c.mu.Lock()
	defer c.mu.Unlock()
	c.items = make(map[string]cacheItem)
}

func Stats() map[string]interface{} {
	c := GetInstance()
	c.mu.RLock()
	defer c.mu.RUnlock()
	total := c.hits + c.miss
	hitRate := 0.0
	if total > 0 {
		hitRate = float64(c.hits) / float64(total) * 100
	}
	return map[string]interface{}{
		"hits":    c.hits,
		"misses":  c.miss,
		"total":   total,
		"hitRate": hitRate,
		"entries": len(c.items),
	}
}

func StartCleanup(interval time.Duration) {
	go func() {
		ticker := time.NewTicker(interval)
		defer ticker.Stop()
		for range ticker.C {
			c := GetInstance()
			c.mu.Lock()
			now := time.Now()
			for k, v := range c.items {
				if v.hasExpiry && now.After(v.expiration) {
					delete(c.items, k)
				}
			}
			c.mu.Unlock()
		}
	}()
}

func Close() error {
	if instance != nil {
		Clear()
		log.Println("Cache closed")
	}
	return nil
}

// Size 返回当前缓存中的条目总数。
func Size() int {
	c := GetInstance()
	c.mu.RLock()
	defer c.mu.RUnlock()
	return len(c.items)
}

// Exists 检查指定 key 是否存在且未过期。
func Exists(key string) (bool, error) {
	c := GetInstance()
	c.mu.RLock()
	defer c.mu.RUnlock()
	item, ok := c.items[key]
	if !ok {
		return false, nil
	}
	if item.hasExpiry && time.Now().After(item.expiration) {
		return false, nil
	}
	return true, nil
}
