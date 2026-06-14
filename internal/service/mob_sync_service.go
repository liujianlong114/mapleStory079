package service

import (
	"strconv"
	"sync"
	"time"

	"mapleStory079/pkg/utils"
)

const mobTickInterval = 100 * time.Millisecond

// MobMoveUpdate 单次怪物位置同步。
type MobMoveUpdate struct {
	MapID      uint
	InstanceID uint
	TemplateID uint
	X          float64
	Y          float64
	Facing     int
	Moving     bool
}

// MobEventNotifier 怪物 WS 广播回调（由 handler 注入，避免循环依赖）。
type MobEventNotifier struct {
	Broadcast func(channel string, msgType string, fields map[string]interface{})
}

var (
	mobNotifier   MobEventNotifier
	mobTickOnce   sync.Once
)

// SetMobEventNotifier 注册怪物事件广播器。
func SetMobEventNotifier(n MobEventNotifier) {
	mobNotifier = n
}

// StartMobSimulation 启动服务端怪物巡逻 AI 并定期广播位置。
func StartMobSimulation(instances *MobInstanceService) {
	mobTickOnce.Do(func() {
		go func() {
			ticker := time.NewTicker(mobTickInterval)
			dt := mobTickInterval.Seconds()
			for range ticker.C {
				updates := instances.TickAI(dt)
				if len(updates) == 0 || mobNotifier.Broadcast == nil {
					continue
				}
				for _, u := range updates {
					channel := mapChannel(u.MapID)
					mobNotifier.Broadcast(channel, utils.WSMessageTypeMobMove, map[string]interface{}{
						"instance_id": u.InstanceID,
						"template_id": u.TemplateID,
						"map_id":      u.MapID,
						"x":           u.X,
						"y":           u.Y,
						"facing":      u.Facing,
						"moving":      u.Moving,
					})
				}
			}
		}()
	})
}

func mapChannel(mapID uint) string {
	return "map_" + strconv.FormatUint(uint64(mapID), 10)
}

func broadcastMobEvent(mapID uint, msgType string, fields map[string]interface{}) {
	if mobNotifier.Broadcast == nil {
		return
	}
	if fields == nil {
		fields = map[string]interface{}{}
	}
	fields["map_id"] = mapID
	mobNotifier.Broadcast(mapChannel(mapID), msgType, fields)
}

func mobInstanceFields(inst *MobInstance) map[string]interface{} {
	return map[string]interface{}{
		"instance_id": inst.InstanceID,
		"template_id": inst.TemplateID,
		"map_id":      inst.MapID,
		"name":        inst.Name,
		"level":       inst.Level,
		"hp":          inst.HP,
		"max_hp":      inst.MaxHP,
		"x":           inst.X,
		"y":           inst.Y,
		"rx0":         inst.Rx0,
		"rx1":         inst.Rx1,
		"speed":       inst.Speed,
		"facing":      inst.Facing,
		"alive":       inst.Alive,
	}
}

// BroadcastMobSnapshot 向指定连接发送当前地图怪物快照。
func BroadcastMobSnapshot(mapID uint, send func(msgType string, fields map[string]interface{})) {
	if send == nil {
		return
	}
	instances := DefaultMobInstanceService.EnsureMap(mapID)
	for _, inst := range instances {
		fields := mobInstanceFields(&inst)
		fields["map_id"] = mapID
		send(utils.WSMessageTypeMobSpawn, fields)
	}
}

// NotifyMobDead 广播怪物死亡。
func NotifyMobDead(mapID, instanceID uint) {
	broadcastMobEvent(mapID, utils.WSMessageTypeMobDead, map[string]interface{}{
		"instance_id": instanceID,
	})
}

// NotifyMobRespawn 广播怪物重生。
func NotifyMobRespawn(inst *MobInstance) {
	if inst == nil {
		return
	}
	broadcastMobEvent(inst.MapID, utils.WSMessageTypeMobRespawn, mobInstanceFields(inst))
}
