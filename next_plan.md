# 冒险岛 079 复刻项目 - 下一周期任务清单

> **周期编号**: #37（下一周期）
> **上次完成**: 周期 #36（UI 点击音效 / CharSelect/BtMouseClick 接入 AudioManager + 怪物掉落系统 MapleItem 实体 + 被击中后滚动动画 + 拾取入背包 + mesos 掉落）

---

## 🎯 优先（下一轮唯一任务）

### 任务 E：HP/MP 药水自动使用（点击道具槽 → 服务端 InventoryService.useItem → 前端同步 HP/MP）

- **说明**: 玩家在游戏 UI 底部道具槽中点击药水图标 → 前端调用 `InventoryService.useItem` → 服务端扣除物品数量 → HP/MP 数值同步到 GameWorld 并播放视觉/音效反馈。
- **具体内容**:
  - Go 后端：`internal/service/inventory_service.go` 补充 `UseItem`（支持消耗类道具返回恢复 HP/MP 值与数量）。
  - Flutter 前端：`client/lib/widgets/maple_game_panels.dart` 底部道具槽增加点击回调 → `api_service.dart` 调用 `POST /game/use-item`。
  - UI 反馈：使用 `MaplePickupNotice` 显示 `恢复 HP 100 / MP 50`；角色位置播放 `effect_sprite_component` drink 动画。
  - 动画：参考 HeavenClient `UI/Pot/UseItem` 动画 + `sfx_pickup` 音效。
- **涉及文件**:
  - Go: `internal/service/inventory_service.go`, `internal/handler/game_handler.go`（`POST /game/use-item` 路由）
  - Flutter: `client/lib/widgets/maple_game_panels.dart`, `client/lib/services/api_service.dart`, `client/lib/game/engine/game_world.dart`
- **参考源码**: `02-★ms079-main-…` Java 端 `MapleInventory` / `UseItemHandler`；HeavenClient `UI/Pot/UseItem`。
- **验收标准**:
  1. 点击药水图标 → 数量减少，HP/MP 数值同步增加。
  2. 无药水时，状态栏显示"道具不足"。
  3. 前后端测试通过：`go build ./cmd/server`、`flutter analyze client` 无新增 error。

---

## 🎯 其他（后续周期，仅供追踪）

- **任务 F**: 怪物 AI - 巡逻/追击（使用 foothold 判定，无跳跃时走斜坡）。
- **任务 G**: 拾取弹幕与战斗伤害数字统一动画库（`effect_sprite_component.dart` 扩展）。

---

## ✅ 已完成（周期 #1 ~ #36）

| 任务 | 状态 | 说明 |
|------|------|------|
| #34 地图切换（portal_name trigger warp） | ✅ | `spawnForMap` 按 portal_name 落点。 |
| #35 UI 点击音效 (BtMouseClick/SfxClick) | ✅ | `AudioManager.playUiClick` 统一接入。 |
| #36 怪物掉落 / 拾取 / mesos 系统 | ✅ | `GroundLootComponent`（初始弹跳 + 浮动 + 20s 超时），`MaplePickupNotice` UI，`DropService` 与 `LootService` 已在后端就绪，`_tryAutoPickup` 已接入。 |

---

## 📋 任务依赖关系

```
UI 点击音效 (#35 ✅)
  └── 怪物掉落 / 拾取 (#36 ✅)
          └── HP/MP 药水使用 (#37)
                  └── 怪物 AI (#38)
```

---

## 🔖 执行规则（重申）

1. 每轮只做一个任务；做完即更新本文件 + `PROJECT_PLAN.md` + `.cursor/automation/last-run.md` 后退出。
2. 资源/坐标以 `02-★ms079-main-…` Java 源码与 WZ XML 为准；贴图走 `scripts/extract_wz_py/` 导出。
3. Go 后端改动需 `go build ./cmd/server` 通过；客户端改动需 `flutter analyze client` 无新增 error。

---

_本清单由开发自动化维护。下一周期从 **任务 E（HP/MP 药水自动使用）** 开始。_
