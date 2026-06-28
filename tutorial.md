# 冒险岛 079 复刻项目 · 开发教程

> 本文档面向完全不熟悉 Flutter 的开发者。读完后你将理解：
> 1. 游戏如何**刷新画面**、**角色移动**、**渲染背景**
> 2. 如何从**原始 WZ 客户端**解析出 PNG / 音效资源

---

## 第一部分 · Flutter 游戏引擎原理（基于 Flame 框架）

### 1.1 整体架构一览

```
Flutter App
  ├── 登录页面（Widget 树）
  ├── 选角页面（Widget 树）
  └── 游戏主页面 → FlameGame（游戏循环）
          ├── 视差背景层（WzMapLayer）
          ├── 地图前景层（WzMapForegroundLayer）
          ├── 玩家组件（PlayerComponent）
          ├── 怪物组件（MobComponent）
          └── 相机（随玩家移动）
```

关键文件：

| 文件 | 作用 |
|------|------|
| `client/lib/game/engine/game_world.dart` | 游戏主逻辑、主循环、输入处理 |
| `client/lib/game/engine/game_controls.dart` | 键盘输入映射 |
| `client/lib/game/engine/wz_map_layer.dart` | 视差背景 + 前景渲染 |
| `client/lib/game/engine/map_foothold.dart` | 地面碰撞（玩家站立判定） |
| `client/lib/game/engine/sprite_loader.dart` | PNG 资源加载 + 动画合成 |

### 1.2 游戏循环：FlameGame 的 update / render

**Flame 框架**是 Flutter 的 2D 游戏引擎。它以固定频率（约 60 FPS）调用两个方法：

```
每一帧（约 16ms）：
  ├── update(dt)   ← dt = 距上一帧的秒数
  │     ├── 读取键盘输入（左右/跳跃/攻击）
  │     ├── 更新玩家位置（X/Y）
  │     ├── 重力下落 + foothold 碰撞
  │     ├── 更新怪物 AI / 伤害 / 掉落
  │     └── 相机跟随玩家
  └── render(canvas)
        ├── 先画背景（视差图层）
        ├── 再画 tile/obj（前景）
        ├── 再画怪物/NPC（按 z 值排序）
        ├── 再画玩家（脚底对齐 foothold）
        └── 最后画 UI（伤害数字、对话框等）
```

对照源码 `game_world.dart`：

```dart
class GameWorld extends FlameGame with HasCollisionDetection {
  // ========== 主循环 ==========
  @override
  void update(double dt) {
    super.update(dt);             // 父类：更新子组件
    // --- 读取键盘 ---
    final left = GameControls.anyMoveLeft(_keysPressed);
    final right = GameControls.anyMoveRight(_keysPressed);
    // --- 水平移动 ---
    if (left) player.moveHorizontal(-1, dt);
    if (right) player.moveHorizontal(1, dt);
    // --- 跳跃（重力下落 + foothold 着陆） ---
    if (jumpNow && _onGround) { _vy = -640; }
    if (!_onGround) {
      _vy += 2000 * dt;          // 重力 = 2000 像素/秒²
      player.position.y += _vy * dt;
      // 检测是否踩到 foothold
      final landing = _footholds!.landingYAt(x, y);
      if (landing != null && player.position.y >= landing) {
        player.position.y = landing;   // 落地
        _vy = 0;                        // 速度清零
        _onGround = true;               // 标记在地面
      }
    }
    // --- 相机跟随 ---
    _syncCamera();                 // 相机中心 = 玩家中心
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);          // 子组件自行渲染
  }
}
```

### 1.3 视差背景：如何"滚动"画面

冒险岛 079 的地图由多层图片构成：

- **Back 层**（最远处的天空/云）：视差滚动，玩家移动时它只移动一点点
- **Tile 层**（地面/墙面贴图）：与玩家同速移动
- **Obj 层**（树、牌子、建筑物）：同速或略微视差

对照 `wz_map_layer.dart` 中的渲染逻辑（简化）：

```
屏幕 X = 地图坐标 X - 相机 X + layer.rx * 0.01 * 视差系数
屏幕 Y = 地图坐标 Y - 相机 Y + layer.ry * 0.01 * 视差系数
```

即：**layer.rx 越大 → 该背景层移动越慢 → 给人"远"的感觉**。

每帧渲染时（简化版）：

```dart
// 1) 先铺底层天空色
canvas.drawRect(screen, Paint()..shader = 天空渐变色);

// 2) 按 ry 从小到大画各层（先远后近）
for layer in sorted(layers, key=ry):
    screenX = layer.x + layer.rx * (viewx - mapWidth/2) * 0.01 - viewx + viewW/2
    screenY = layer.y + layer.ry * (viewy - mapHeight/2) * 0.01 - viewy + viewH/2
    canvas.drawImage(layer.png, Offset(screenX, screenY));

// 3) 如果是 tile 层（type=1 横向平铺），要按 tile 宽度重复贴
```

### 1.4 角色移动：foothold 线段碰撞

**foothold**是冒险岛的核心机制。地图不是一个连续平面，而是由**很多线段**组成。

每个 foothold 段：

```json
{
  "id": 123,       // 段 ID
  "x1": 100, "y1": 200,   // 起点
  "x2": 200, "y2": 200,   // 终点
  "prev": 122,            // 前一段（可无缝衔接）
  "next": 124             // 后一段
}
```

玩家每帧的移动判定：

1. **先水平更新**（按方向键 + 速度 220 px/s）
2. **再判断脚下**：遍历玩家 X 位置上方的所有 foothold，取 `y >= 玩家脚y` 最小的那条
3. **如果找到**：把玩家 y 拉到该段上 → 判定"在地面"
4. **如果没找到**：玩家 y 继续增加（重力下落），超出边界后死亡复活

对照源码 `map_foothold.dart`：

```dart
// 在 x 位置找 y >= feetY 的最小地面高度
double? groundYAt(double x, { double? feetY }) {
  final candidates = [];
  for (final fh in _walkableAtX(x)) {
    final gy = fh.groundBelow(x);     // 用线性插值算这段在 x 处的 y
    if (gy >= feetY - 8) candidates.add(gy);
  }
  candidates.sort();
  return candidates.isEmpty ? null : candidates.first;
}
```

### 1.5 画面刷新：为何"屏幕在动"

Flame 的 `CameraComponent` 是一个**虚拟视口**，固定大小 `800x600`（冒险岛 079 官方分辨率）：

```dart
camera.viewport = FixedResolutionViewport(resolution: Vector2(800, 600));
camera.viewfinder.anchor = Anchor.topLeft;
```

每帧 `_syncCamera()`：

```dart
var camX = player.position.x - 400;   // 玩家在屏幕水平中央
var camY = player.position.y - 300;   // 玩家在屏幕垂直中央
camX = camX.clamp(vrLeft, vrRight - 800);  // 不超出地图左右边界
camY = camY.clamp(vrTop, vrBottom - 600);
camera.viewfinder.position = Vector2(camX, camY);
```

**所有组件都是按"地图坐标"存放的**，渲染时由 Camera 自动减去相机偏移，所以玩家动 = 整个世界都动了。

### 1.6 精灵动画：角色走路/站立

`PlayerComponent` 内部维护：

```dart
String animationState = 'idle';   // idle / walk / jump / attack
Sprite? _standSprite;              // 静止贴图
SpriteAnimation? _walkAnim;        // walk1 多帧动画循环

// 游戏内每帧按 state 渲染不同贴图
```

动画来自两部分：
- **Phase 1**：服务端 `CharLook` 实时合成（读 Character.wz 各部件叠加）
- **Phase 2**：客户端 `SpriteLoader.tryLoadComposeAnimation` 缓存 PNG

### 1.7 实战：改一个参数体验

打开 `client/lib/game/engine/game_world.dart` 搜索 `_gravity = 2000`：

- 改成 `5000` → 角色变得很重，跳不起来
- 改成 `1000` → 角色轻飘飘的，像在月球
- 再改 `_jumpSpeed = -640` → 改成 `-1200` 就跳得更高

保存后 `flutter run`（热重启）即可看到效果。

---

## 第二部分 · 从 WZ 客户端解析 PNG 资源

### 2.1 什么是 WZ 文件

冒险岛 079 的**所有游戏资源**（图片、音效、地图数据）都打包在 `.wz` 容器文件里：

```
你的客户端目录（例：~/Downloads/冒险岛079/extracted_client/）
├── UI.wz            ← 登录界面、背包、对话框等 UI 贴图
├── Sound.wz         ← BGM、音效
├── Map.wz           ← 地图数据（back/tile/obj/foothold/portal 等）
├── Character.wz     ← 角色部件（头发/脸/衣服/武器等）
├── Mob.wz           ← 怪物贴图与动画
├── Npc.wz           ← NPC 贴图
└── ...其他 wz 文件
```

每个 `.wz` 内部是一颗**属性树**：

```
Map.wz / Map / Map0 / 000010000.img
├── back / 0 / no=0, type=1, x=0, y=0, rx=0, ry=0, bS="grassySoil"
│        1 / ...
│        2 / ...
├── 0 / info / tS="grassySoil"
│       tile / 0 / x=0, y=0, u="enG0", no=0, zM=0
│               1 / ...
│       obj / 0 / x=100, y=200, oS="login", l0="Title", l1="logo", l2="0"
│               1 / ...
├── 1 / ...
├── foothold / 0 / 0 / ... (线段碰撞数据)
└── portal / ... (传送门)
```

### 2.2 解析工具链

本项目使用 **wz-python**（GitHub 开源，自动克隆到 `.cache/wz-python`）：

```
脚本目录: scripts/extract_wz_py/
  ├── extract.py              ← 登录 UI + BGM 导出
  ├── export_map_from_wz.py   ← 单张地图 JSON + 视差 PNG 导出
  ├── compose_look.py         ← CharLook 运行时合成
  ├── extract_parts.py        ← 角色部件批量提取
  ├── extract_mobs_npcs.py    ← Mob/Npc 批量提取
  ├── extract_bgm.py          ← 地图 BGM 提取
  └── requirements.txt        ← Python 依赖
```

### 2.3 导出登录 UI（最小例子）

**步骤 1**：确保客户端存在，Python 依赖已装：

```bash
cd /Users/lijianjun/GolandProjects/mapleStory079
export MAPLE_WZ_ROOT=~/Downloads/冒险岛079/extracted_client
pip install -r scripts/extract_wz_py/requirements.txt
```

**步骤 2**：运行导出脚本：

```bash
python scripts/extract_wz_py/extract.py --client $MAPLE_WZ_ROOT --out client/assets
```

**步骤 3**：观察 `extract.py` 的核心逻辑（简化）：

```python
# 1) 打开 WZ 文件
from wzpy.wz_file import WzFile
wf = WzFile.open(path, region="EMS", version=79)

# 2) 按路径定位到某个 Canvas
ui_img = wf.root.get("Login.img")
btn = ui_img.get("Title").get("BtLogin").get("normal").get("0")
# ↑ Login.img 是登录界面，Title 子目录下有标题画面、按钮、Logo 等

# 3) 解码 Canvas（WZ 内部用一种压缩格式存像素数据）
from wzpy.canvas import decode_canvas
image = decode_canvas(btn, region="EMS")   # 返回 PIL.Image

# 4) 保存为 PNG
image.save("client/assets/images/ui/login/btn_login_normal.png", format="PNG")
```

### 2.4 导出地图（更复杂的例子）

导出彩虹村（地图 ID 1000000）：

```bash
python scripts/extract_wz_py/export_map_from_wz.py \
  --client $MAPLE_WZ_ROOT \
  --map 000010000 \
  --map-id 1000000 \
  --name "彩虹村" \
  --out client/assets
```

它会产生：

- `client/assets/maps/1000000.json` — 地图元数据（视口、foothold、portal、tile/obj 引用）
- `client/assets/maps/back/grassySoil/0.png` — 视差背景 PNG
- `client/assets/maps/tiles/grassySoil/enG0_0.png` — tile 贴图
- `client/assets/maps/obj/login/Title_logo_0.png` — obj 贴图

JSON 简化结构：

```json
{
  "mapId": 1000000,
  "name": "彩虹村",
  "vrLeft": -315, "vrRight": 1390, "vrTop": -480, "vrBottom": 750,
  "layers": [
    {"no": 0, "type": 1, "x": 0, "y": 0, "rx": 0, "ry": 0, "bS": "grassySoil"}
  ],
  "mapLayers": [
    {"id": 0, "tS": "grassySoil",
     "tiles": [{"x": 0, "y": 0, "u": "enG0", "no": 0, "ox": 0, "oy": 0}],
     "objs":  [{"x": 100, "y": 200, "oS": "login", "l0": "Title", "l1": "logo", "l2": "0", "ox": -10, "oy": -20}]}
  ],
  "footholds": [{"id": 1, "x1": 0, "y1": 605, "x2": 200, "y2": 605, "prev": 0, "next": 2}],
  "portals": [{"id": 0, "x": 800, "y": 600, "targetMap": 1000001}]
}
```

### 2.5 运行时角色合成（服务端 compose API）

游戏中玩家外观是运行时**实时合成**的（不是预存一张图）：

**请求**：`GET http://localhost:8080/look/compose.png?hair=30000&face=20100&top=1050060&bottom=1060034&shoes=1072178&weapon=1302000&pose=stand1&frame=0&scale=3`

**服务端实现**（`scripts/extract_wz_py/compose_look.py` 逻辑的 Go 版）：

1. `CharLook` 包含 hair/face/top/bottom/shoes/weapon 等 12 个装备 ID
2. 每个 ID → 在 `Character.wz` 中找对应目录 → 读 `pose/frame` 下的 Canvas
3. 按 `anchor + origin` 偏移叠加（从下往上：鞋子→裤子→衣服→武器→头发→脸）
4. 整体 scale 放大（游戏用 1x，选角用 3x 更清晰）

### 2.6 怪物/NPC 精灵

`extract_mobs_npcs.py`：

```python
# 1) 打开 Mob.wz
wf = WzFile.open("Mob.wz", region="EMS", version=79)

# 2) 每个 mob ID（例：100100 = 红蜗牛）
for mob_id in ["100100", "100101", ...]:
    img = wf.root.get(mob_id + ".img")
    for (pose_name, pose_node) in img.children():
        # pose: stand / walk / hit1 / hit2 / attack ...
        for (frame_name, canvas) in pose_node.children():
            image = decode_canvas(canvas, region="EMS")
            image.save(f"client/assets/sprites/mob/{mob_id}/{pose_name}_{frame_name}.png")
```

### 2.7 资源校验

`flutter analyze client` 会提示 Dart 语法错误，但不会检查 PNG 是否存在。

检查 PNG 是否齐全：

```bash
# 统计 client/assets 下的 PNG 总数
find client/assets -name "*.png" | wc -l

# 按子目录分类
for d in sprites characters maps images scenes; do
    echo "$d: $(find client/assets/$d -name "*.png" 2>/dev/null | wc -l)"
done
```

项目当前约 **12,222 张 PNG**（2026 年 6 月数据）。

---

## 第三部分 · 完整开发流程示例

### 3.1 添加一张新地图的完整流程

**目标**：把明珠港（mapId = 104000000）加入游戏

```bash
# 1) 导出地图 JSON + PNG
python scripts/extract_wz_py/export_map_from_wz.py \
  --client $MAPLE_WZ_ROOT \
  --map 000010000 --map-id 104000000 --name "明珠港"

# 2) 导出 BGM（可选，Map.wz 已有信息字段）
python scripts/extract_wz_py/extract_bgm.py --client $MAPLE_WZ_ROOT

# 3) Flutter 端重新运行，GameWorld 的 MapMetaFull.load(104000000) 会自动读到新 JSON
flutter run
```

### 3.2 修改游戏玩法参数

| 参数 | 文件位置 | 作用 |
|------|---------|------|
| `_gravity` | `game_world.dart:169` | 重力加速度 |
| `_jumpSpeed` | `game_world.dart:170` | 跳跃初速度 |
| `viewportW/viewportH` | `map_meta.dart` | 游戏内逻辑分辨率（800x600） |
| `PlayerComponent.moveSpeed` | `game_world.dart:1498` | 玩家水平速度 |

### 3.3 验证构建

```bash
# 后端：确保编译通过
go build ./cmd/server

# 前端：静态分析（应 0 issues）
flutter analyze client

# 前端：运行（需连接 Android/iOS 设备或模拟器）
flutter run -d macos  # macOS 桌面版
```

---

## 第四部分 · 快速问题排查

| 问题 | 原因 | 解决 |
|------|------|------|
| 玩家站在空中不下落 | foothold 数据缺失或坐标不连续 | 检查 maps/{mapId}.json 的 footholds 段，确认覆盖 spawnX |
| 玩家穿过地面 | foothold 段过长或跳跃中断 | 搜索 `_footholds.landingYAt`，加 debug 打印当前候选段 |
| 背景是纯色块 | back PNG 缺失或路径不对 | 检查 `client/assets/maps/back/{bS}/{no}.png` 是否存在 |
| 怪物显示为空白方块 | Mob PNG 未导出 | 运行 `python scripts/extract_wz_py/extract.py --mobs-npcs --client $MAPLE_WZ_ROOT` |
| Flutter 报大量 red error | 编译前的语法/类型错误 | 先 `flutter analyze client`，根据错误信息改对应文件 |

---

## 第五部分 · 相关源码索引

**核心游戏逻辑**：
- `client/lib/game/engine/game_world.dart` — 游戏主循环（update/render）
- `client/lib/game/engine/map_foothold.dart` — foothold 碰撞计算
- `client/lib/game/engine/sprite_loader.dart` — PNG / 动画加载
- `client/lib/game/engine/wz_map_layer.dart` — 视差背景 + 前景渲染

**资源提取脚本**（Python，基于 wz-python）：
- `scripts/extract_wz_py/extract.py` — 登录 UI + BGM
- `scripts/extract_wz_py/export_map_from_wz.py` — 地图 JSON + tile/obj/back PNG
- `scripts/extract_wz_py/compose_look.py` — 角色运行时合成
- `scripts/extract_wz_py/extract_mobs_npcs.py` — Mob/NPC 精灵

**Flutter UI 页面**：
- `client/lib/features/login/login_page.dart` — 登录页
- `client/lib/features/game/game_scene_page.dart` — 游戏场景页（含 HUD、对话框）
- `client/lib/features/character/character_select_page.dart` — 选角页

**后端服务**：
- `internal/handler/avatar_handler.go` — `/look/compose.png` 运行时合成 API
- `internal/handler/game_handler.go` — 地图/怪物/掉落数据 API

---

> 📌 重要提醒：所有贴图和逻辑坐标**都来自 WZ 文件**。如果看到某个 UI 元素位置不对，先去 WZ 中确认原始 `origin` 偏移，再在 `wz_map_layer.dart` 的渲染代码中对齐，不要手搓假坐标。
