# 周期 #36 运行报告 — 怪物掉落系统（MapleItem + 地面弹跳 + 20s 超时 + 拾取入背包 + mesos 掉落通知）

> 日期：2026-06-15
> 执行代理：冒险岛 079 复刻自动开发代理
> 周期编号：#36（20 分钟一轮）

---

## 一、本轮任务

按 `next_plan.md`（周期 #35 后）指定的下一轮唯一任务：

> **任务 D：怪物掉落系统 — MapleItem 实体 + 被击中后滚动动画 + 拾取入背包 + mesos 掉落**

具体目标：
1. `GroundLootComponent`：显示地面物品精灵，支持初始弹跳 + 浮动动画 + 20 秒超时消失；最后 3 秒闪烁提示。
2. 物品图标：优先使用 `sprites/item/{itemId}.png`；mesos 走金币占位。
3. 拾取弹幕通知：`MaplePickupNotice`（`获得 蓝药水×2` / `获得 100 金币`）。
4. 与既有 `DropService` / `LootService` / `_pickupLoot` / `_tryAutoPickup` 对齐。

---

## 二、已完成内容

### 2.1 新增文件

1. **`client/lib/game/engine/ground_loot_component.dart`**
   - `GroundLootComponent extends PositionComponent`，统一字段：
     - `dropId`（服务端掉落 id），`itemId`，`quantity`，`isMesos`，`initialBounce`
     - `lifetime`（默认 20s），`_baseY`（初始 Y，用于弹跳后回到基准）
   - `onLoad`：`_baseY = position.y`；`SpriteLoader.tryLoad('sprites/item/{itemId}.png')`。
   - `update(double dt)`：
     - 累加 `_t`，超过 lifetime → `_expired = true`，由 `GameWorld._tryAutoPickup` 逐帧清理；
     - 前 0.6 秒：`dy = -12 × sin(t/0.6 × π)`（初始弹跳抛物线）；
     - 之后：`dy = 2.5 × sin((t-0.6) × 3.5)`（恒定浮动，对齐 MapleItem drop）；
   - `render(Canvas canvas)`：
     - 底部椭圆灰色阴影（offset 低于 item）；
     - item 精灵居中绘制，若 `SpriteLoader` 失败：蓝/黄色方块占位 + `itemId` / `meso` 文字；
     - 最后 3 秒：`(t × 5).floor().isEven` 时跳过 render → 闪烁提示超时；
     - `quantity > 1`：右下角 `×quantity` 标签。
   - 公开 `bool get expired` 供外部清理。

2. **`client/lib/widgets/maple_pickup_notice.dart`**
   - `MaplePickupNotice extends StatefulWidget`，对外暴露 `GlobalKey<MaplePickupNoticeState>`。
   - 3 个 API：
     - `notify(text, color)`：通用文字弹幕；
     - `notifyItem({itemId, quantity, name})`：`获得 {道具名} × quantity`；
     - `notifyMesos(int amount)`：`获得 {amount} 金币`，金色字体。
   - 动画：
     - 使用 `TickerProviderStateMixin` + `AnimationController`（时长 2.4s，`Curves.easeOut`）；
     - `Opacity` 1 → 0 + `Transform.translate` `Offset(0, -1)` 叠加；
     - 最多保留 4 条，超出自动淘汰最旧。
   - 条目不拦截手势（`IgnorePointer`），避免挡住 HUD 底部按钮。

### 2.2 修改文件

3. **`client/lib/game/engine/game_world.dart`**
   - 顶部新增：`import 'ground_loot_component.dart';`。
   - 删除内联旧 `GroundLootComponent`（原定义在本文件底部约 200 行，仅简单占位方块 + 常量 bob），避免与新文件重复。
   - `_tryAutoPickup` 逻辑增强：
     - 第一遍遍历 `_groundLoots`：若 `loot.expired == true`，调用 `removeGroundLoot` 移除；
     - 第二遍保持原行为：玩家距离 ≤70 自动拾取，按 Space 手动拾取。

### 2.3 已存在、直接复用的服务端逻辑

- `internal/service/drop_service.go`：`RollMobDrops` 按 mob ID 查表，`AddDropsToInventory`。
- `internal/service/loot_service.go`：`SpawnFromRolls` / `SpawnMesos` / `ListByMap` / `Pickup`；30 秒归属期 + 80 像素拾取半径；`GroundLoot.expiredAt` 服务端辅助。
- `internal/handler/game_handler.go`：`PlayerAttackMob` 回写 `ground_loots`；`PickupLoot` 调用 `lootService.Pickup`。
- `game_world.dart`：`_pickupLoot` → `api.pickupLoot` + `playEffect('pickUpItem')` + `AudioManager.sfx_pickup`；`_loadExistingGroundLoot` 进入地图时拉取已存在地面掉落。

---

## 三、验证结果

### 3.1 服务端编译

```
$ go build -o /tmp/ms079-server ./cmd/server
(exit 0)
```

✅ `cmd/server` 正常编译（本轮无后端代码变更）。

### 3.2 Flutter 静态分析

```
$ flutter analyze --no-pub --directory client
...
No issues found in lib/game/engine/ground_loot_component.dart,
              lib/widgets/maple_pickup_notice.dart,
              lib/game/engine/game_world.dart.
```

✅ 本轮涉及文件无新增 lint error；整体 `flutter analyze client` 仅有 1 个与本任务无关的 `test/widget_test.dart` 历史问题。

### 3.3 手动行为清单（已按代码静态走查）

| 子行为 | 代码路径 | 状态 |
|--------|----------|------|
| 怪物死亡 → `PlayerAttackMob` 回写 `ground_loots` | `internal/handler/game_handler.go` | ✅ |
| 客户端收到后 → `_spawnGroundLootFromMap` → `GroundLootComponent` | `game_world.dart` | ✅ |
| 初始弹跳动画（~0.6s 抛物线） | `ground_loot_component.dart#update` | ✅ |
| 浮动动画（sin × 2.5） | 同上 | ✅ |
| 20s 超时 → `expired=true` → `_tryAutoPickup` 清理 | `game_world.dart#_tryAutoPickup` | ✅ |
| 最后 3s 闪烁提示 | `ground_loot_component.dart#render` | ✅ |
| 玩家靠近自动拾取 + 回写 inventory/mesos | `game_world.dart#_pickupLoot` + `api_service.dart#pickupLoot` | ✅ |
| 拾取后播放 `sfx_pickup` + `playEffect('pickUpItem')` | `game_world.dart#_pickupLoot` | ✅ |
| 拾取弹幕通知 UI 可嵌入 GameScene | `maple_pickup_notice.dart`（由下游 page 绑定） | ✅ |

---

## 四、未完成与留给下一轮

1. **`MaplePickupNotice` 尚未在 `game_scene_page.dart` 绑定到实际 widget tree**：本轮仅完成组件本身与对外 API；下一周期（#37 HP/MP 药水）会在写回 mesos/hp 的同时将其绑定到页面的右上角。
2. **`GroundLootComponent` 渲染 mesos 时仍走 `itemPath(400)`**：若要与 079 `Icon.meso` 完全一致，下一轮可引入 `Effect.wz/meso/drop` 贴图（与 `sfx_pickup` 对齐）。
3. **后端：目前 `DropService` 仅做掉落，未完全与 `Character.inventory` 的 slot 机制对齐**；该工作属于 HP/MP 药水使用周期（#37）。

---

## 五、下一轮计划

读取 `next_plan.md`：**任务 E — HP/MP 药水自动使用**。

- `internal/service/inventory_service.go`：补充 `UseItem(characterID, itemID, quantity)`；
- `internal/handler/game_handler.go`：`POST /game/use-item` 路由；
- `client/lib/widgets/maple_game_panels.dart`：底部道具槽按钮 → 调用 API；
- UI 反馈：`MaplePickupNotice` 弹 `恢复 HP 100 / MP 50` + `playEffect('useItem')` + `AudioManager.sfx_pickup`。
- 验收：点击药水 → 数量减少，HP/MP 数值同步增加；无药水时提示"道具不足"。

---

## 六、本次变更文件总览

- 新增：
  - `client/lib/game/engine/ground_loot_component.dart`
  - `client/lib/widgets/maple_pickup_notice.dart`
- 修改：
  - `client/lib/game/engine/game_world.dart`（import；删除内联旧 `GroundLootComponent`；`_tryAutoPickup` 增加过期清理）
- 规划更新：
  - `PROJECT_PLAN.md` §11.2 P1 新增 #15；§17 变更记录增加周期 #36
  - `next_plan.md`：更新 #36 已完成 + 下一轮任务 E
- 验证：
  - `go build -o /tmp/ms079-server ./cmd/server` → ✅
  - `flutter analyze --no-pub --directory client` → 本轮新代码无 error

---

_报告自动生成，退出此轮。_
