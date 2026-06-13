package cache

import (
	"sync/atomic"
	"time"
)

type CacheStats struct {
	Hits        int64
	Misses      int64
	Evictions   int64
	Size        int
	LastUpdated time.Time
}

var (
	hits      int64
	misses    int64
	evictions int64
)

func RecordHit() {
	atomic.AddInt64(&hits, 1)
}

func RecordMiss() {
	atomic.AddInt64(&misses, 1)
}

func RecordEviction() {
	atomic.AddInt64(&evictions, 1)
}

func GetStats() CacheStats {
	return CacheStats{
		Hits:        atomic.LoadInt64(&hits),
		Misses:      atomic.LoadInt64(&misses),
		Evictions:   atomic.LoadInt64(&evictions),
		Size:        Size(),
		LastUpdated: time.Now(),
	}
}

func ResetStats() {
	atomic.StoreInt64(&hits, 0)
	atomic.StoreInt64(&misses, 0)
	atomic.StoreInt64(&evictions, 0)
}

func HitRate() float64 {
	h := atomic.LoadInt64(&hits)
	m := atomic.LoadInt64(&misses)
	total := h + m
	if total == 0 {
		return 0.0
	}
	return float64(h) / float64(total) * 100.0
}
