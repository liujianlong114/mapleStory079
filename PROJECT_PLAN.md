# MapleStory 079 复刻项目计划

> **用途**：以官方 079 客户端 WZ 资源 + `ms079-main` 服务端逻辑为基准，指导后续所有客户端/服务端/资源改动。  
> **原则**：业务规则跟 Java 源码，画面跟 WZ，**不手搓假 UI**（禁止再用 `build_login_scene` 生成街机框背景）。
> **最后更新**：2026-06-15（周期 #34：P1 #14 传送门地图切换（portal_name 触发 warp））

---

## 1. 项目目标

| 维度 | 目标 |
|------|------|
| 视觉 | 登录 MapLogin2 视差、选角 WZ UI、进图 WZ 地图 back / 精灵 |
| 操作 | 079 键位：←→ 移动、Ctrl 攻击、Z 拾取、Alt 跳跃 |
| 逻辑 | 创角白名单、禁名、初始 MP=50、出生图、装备 seed 与 ms079 一致 |
| 传输 | HTTP JSON REST + WebSocket（**非**原版 TCP Opcode，规则仍对照原版） |

**示例代码 / WZ / 对照源码**：见 **§2 外部参考资源**（`../mapleStory079-external/`，原 `examples/` 已迁出）。

**不做的事**：反编译 `MapleStory.exe` 还原 C++ 源码；100% 复刻 TCP 封包与频道服分离架构。

> **最后更新**：2026-06-14（示例代码已迁出至 `mapleStory079-external/`）

---

## 2. 外部参考资源（示例代码存放位置）

> **重要**：原仓库内 `examples/` **已删除**，不再纳入 git。  
> 所有示例源码、WZ 副本、Downloads 客户端链接，统一放在与**本仓库同级**的目录：

```
/Users/lijianjun/GolandProjects/
├── mapleStory079/           ← 本仓库（仅可运行项目 + client/assets）
└── mapleStory079-external/  ← 示例 / WZ / 对照源码（勿提交进 git）
```

| 文档 | 说明 |
|------|------|
| `EXTERNAL_REF.md` | 本仓库内速查：环境变量、提取命令 |
| `../mapleStory079-external/README.md` | 外部目录完整索引 |

### 2.1 目录一览（文件夹名已标注用途）

| 目录名 | 类型 | 本项目是否使用 | 说明 |
|--------|------|----------------|------|
| `00-官方客户端-冒险岛079-资源提取主源-WZ安装包与extracted_client` | 符号链接 → `~/Downloads/冒险岛079` | **★ 常用** | 官方 079 安装包与 `extracted_client/`（UI.wz、Map.wz 等）。`ingest_full.sh` 默认主源。 |
| `01-MAX3怀旧岛-补全grassySoil与Obj缺项-Data客户端` | 符号链接 → Downloads MAX3 整合包 | **★ 常用** | 补主客户端缺的 `grassySoil` back、Obj/login 等。 |
| `02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML` | 源码克隆 | **★ 必查** | Java 079 私服：`src/main/java` 业务规则 + `wz/*.xml` 坐标/禁名。Go 服务端按此对照。 |
| `03-★maple-client-ingest工作目录-WZ副本-脚本自动复制` | WZ 工作副本 | **★ 必用** | 脚本从 `00` 复制 WZ 到此再提取；含 MAX3 解压 `extracted/max3/`。 |
| `04-HeavenClient-C++参考-UI坐标与渲染逻辑` | 源码克隆 | 只读参考 | C++ 客户端：UI 布局、地图 Tile/Obj 渲染顺序。 |
| `05-HeavenMS-v83参考-服务端架构-已归档` | 源码克隆 | 只读参考 | v83 Java 服务端（已归档），架构/协议可翻阅。 |
| `06-ZLHSS2-079参考-中文全栈私服` | 源码克隆 | 按需 | 079 中文私服 + `import_wz` 物品图标来源。 |
| `07-ellermister-MapleStory-参考` | 源码克隆 | 按需 | 备用 MapleStory 实现参考。 |
| `08-MapleStory-Server-079-参考` | 源码克隆 | 按需 | 另一套 079 服务端参考。 |
| `09-mxd079-gitee-参考` | 源码克隆 | 按需 | Gitee 镜像参考。 |
| `10-cc-079-ms-Java079参考` | 源码克隆 | 按需 | Java 079：地图/NPC/怪物 ID 对照。 |
| `11-cc-079-ms-gitee-参考` | 源码克隆 | 按需 | 同上 Gitee 镜像。 |
| `12-Advanced-MapleLauncher-启动器参考` | 源码克隆 | 按需 | 启动器 UI 参考。 |
| `13-MXDtestServer-空目录-仅占位` | 空目录 | 忽略 | 历史占位，无内容。 |
| `archives/` | zip 备份 | 备份 | `ms079-main.zip`、`wz-python.zip`。 |
| `docs-OPEN_SOURCE_RESOURCES.md` | 文档 | 索引 | 全网开源资源汇总。 |

### 2.2 常用绝对路径（本机默认）

以下路径假设项目在 `~/GolandProjects/mapleStory079`：

| 用途 | 路径 |
|------|------|
| 外部根目录 | `~/GolandProjects/mapleStory079-external` |
| 官方解压客户端 | `~/GolandProjects/mapleStory079-external/00-官方客户端-冒险岛079-资源提取主源-WZ安装包与extracted_client/extracted_client` |
| MAX3 Data 客户端 | `~/GolandProjects/mapleStory079-external/03-★maple-client-ingest工作目录-WZ副本-脚本自动复制/extracted/max3/【怀旧岛079MAX3】2022虎年贺岁版/怀旧岛079MAX3_客户端` |
| ms079 Java 源码 | `~/GolandProjects/mapleStory079-external/02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML/src/main/java` |
| ms079 WZ XML | `~/GolandProjects/mapleStory079-external/02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML/wz` |
| ingest WZ 副本 | `~/GolandProjects/mapleStory079-external/03-★maple-client-ingest工作目录-WZ副本-脚本自动复制` |

### 2.3 环境变量与脚本解析

脚本通过 `scripts/lib/external_paths.sh`（Go：`scripts/lib/external_paths.go`）解析路径，**无需**再写 `examples/`。

| 变量 | 默认值 |
|------|--------|
| `MAPLE_EXTERNAL_ROOT` | `../mapleStory079-external`（相对本仓库根目录） |
| `MAPLE_CLIENT_DIR` | `…/03-★maple-client-ingest工作目录-WZ副本-脚本自动复制` |
| `MXD079_CLIENT` | `…/00-官方客户端-…/extracted_client` |

```bash
# 全量提取（读 00 + 01，WZ 副本写入 03，输出到 client/assets）
./scripts/ingest_full.sh

# 自定义外部目录
MAPLE_EXTERNAL_ROOT=/path/to/mapleStory079-external ./scripts/ingest_full.sh
```

### 2.4 迁移说明（原 `examples/` 对照）

| 原路径（已废弃） | 现路径 |
|------------------|--------|
| `examples/ms079-main` | `…/02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML` |
| `examples/maple-client` | `…/03-★maple-client-ingest工作目录-WZ副本-脚本自动复制` |
| `examples/HeavenClient` | `…/04-HeavenClient-C++参考-UI坐标与渲染逻辑` |
| `examples/HeavenMS` | `…/05-HeavenMS-v83参考-服务端架构-已归档` |
| `examples/ZLHSS2` | `…/06-ZLHSS2-079参考-中文全栈私服` |
| `examples/OPEN_SOURCE_RESOURCES.md` | `…/docs-OPEN_SOURCE_RESOURCES.md` |
| `~/Downloads/冒险岛079` | `…/00-官方客户端-…`（符号链接，原件仍在 Downloads） |
| `~/Downloads/【怀旧岛079MAX3】…` | `…/01-MAX3怀旧岛-…`（符号链接） |

### 2.5 按任务查参考代码（读哪个文件夹）

改功能前**先打开对应参考**，不要凭空手搓坐标/碰撞。

| 要改什么 | 优先读（外部参考） | 本项目实现 |
|----------|-------------------|------------|
| 地图 foothold / 跳跃 / 掉崖 | `04-HeavenClient-…/Gameplay/Physics/FootholdTree.cpp` `Foothold.cpp` `Physics.cpp` | `client/lib/game/engine/map_foothold.dart` `game_world.dart` |
| 地图 Tile/Obj 绘制顺序 | `04-HeavenClient-…/Gameplay/MapleMap/`（Stage、MapTilesObjs） | `wz_map_foreground.dart` `wz_map_layer.dart` |
| 视差背景 back 层 | `04-HeavenClient-…/Gameplay/MapleMap/MapBackgrounds.cpp` | `wz_map_layer.dart` `map_render_utils.dart` |
| 登录 UI 坐标 | `02-★ms079-main-…/wz/UI.wz/Login.img.xml` | `scripts/export_login_manifest/` `wz_scene.dart` |
| 创角/禁名/出生规则 | `02-★ms079-main-…/src/main/java/` | `internal/service/` `pkg/utils/` |
| NPC/任务/商店对话 | `02-★ms079-main-…/wz/String.wz` + Java Handler | `internal/service/npc_dialogue_wz.go` `pkg/npcdata/` |
| 地图 life 刷点 | `02-★ms079-main-…/wz/Map.wz/Map/Map0/000010000.img.xml` → `life` | `data/maplife/` `client/assets/maplife/` |
| 传送门 | `04-HeavenClient-…/Gameplay/MapleMap/Portal.cpp` + Map.wz `portal` 节点 | `portal_component.dart` `POST /game/change-map` |
| 进游戏 HUD | `02-★ms079-main-…/wz/UI.wz/StatusBar.img` `UIWindow.img/MiniMap` | `maple_status_bar.dart` `maple_mini_map.dart` |
| 角色外观合成 | `06-ZLHSS2-…/tools/import_wz`（按需） | `scripts/extract_wz_py/compose_look.py` + `/look/compose.png` API |

**HeavenClient 绝对路径（本机）**：

```
~/GolandProjects/mapleStory079-external/04-HeavenClient-C++参考-UI坐标与渲染逻辑/
├── Gameplay/Physics/FootholdTree.cpp    # get_fhid_below / update_fh
├── Gameplay/Physics/Foothold.cpp        # ground_below
├── Gameplay/Physics/Physics.cpp         # 重力 / 地面移动
└── Gameplay/MapleMap/                   # Stage 绘制、Portal
```

**ms079 XML 绝对路径（本机）**：

```
~/GolandProjects/mapleStory079-external/02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML/wz/
├── Map.wz/Map/Map0/000010000.img.xml    # 彩虹村：tile/obj/foothold/life/portal
├── Map.wz/Tile/grassySoil.img.xml       # 地砖 origin（enH0 oy=38 等）
├── UI.wz/StatusBar.img.xml              # 底部状态栏
├── UI.wz/UIWindow.img.xml               # MiniMap 框
└── String.wz/Npc.img.xml                # NPC 名称
```

### 2.6 资源解析：输入 WZ → 输出 assets（路径总表）

| 阶段 | 输入（WZ / 参考） | 解析脚本 | 输出到本仓库 |
|------|-------------------|----------|--------------|
| 全量 ingest | `00-…/extracted_client/*.wz` 复制到 `03-…` | `./scripts/ingest_full.sh` | 多目录，见下 |
| 登录 UI | `UI.wz/Login.img` | `scripts/extract_wz_py/extract.py` | `client/assets/images/ui/login/` |
| 登录 manifest | 上 + MapLogin2 XML | `scripts/export_login_manifest/main.go` | `client/assets/scenes/login_*.json` |
| MapLogin2 视差 | `Map.wz/MapLogin/MapLogin2.img` | `scripts/export_maplogin_layers/main.go` | `client/assets/scenes/maplogin2_layers.json` |
| 地图 JSON | `Map.wz/Map/Map0/000010000.img` | `scripts/extract_wz_py/export_map_from_wz.py` | `client/assets/maps/{mapId}.json` |
| 地图 back PNG | `Map.wz/Back/grassySoil.img`（主客户端常缺） | 同上 + `--back-client MAX3` | `client/assets/maps/back/grassySoil/` |
| 地图 tile PNG | `Map.wz/Tile/grassySoil.img` | 同上；失败项用 `gen_grassy_tile_placeholders.py` | `client/assets/maps/tiles/grassySoil/` |
| 地图 obj PNG | `Map.wz/Obj/*.img` | 同上 | `client/assets/maps/obj/{oS}/` |
| 地图 life | Map.wz `life` 节点 | `scripts/export_map_life/main.go` | `data/maplife/` + `client/assets/maplife/` |
| 进游戏 HUD | `UI.wz/StatusBar.img` `UIWindow.img` | `scripts/extract_wz_py/extract_hud_ui.py` | `client/assets/images/ui/hud/` |
| 传送门动画 | `Map.wz/MapHelper.img` portalContinue | 手动/脚本导出 | `client/assets/sprites/portal/continue_*.png` |
| Mob/Npc 精灵 | `Mob.wz` `Npc.wz` | `scripts/extract_wz_py/extract_mobs_npcs.py` | `client/assets/sprites/{mob,npc}/` |
| 角色部件 | `Character.wz` | `extract_parts.py` `extract_avatars.py` | `client/assets/characters/parts/` `avatars/` |
| 角色实时合成 | Character.wz + 后端 | `compose_look.py` + Go handler | HTTP `/look/compose.png` |
| wz-python 引擎 | GitHub 克隆 | `ingest_full.sh` 自动 | `.cache/wz-python/`（不提交 git） |

**官方 WZ 二进制（提取主源，勿提交 git）**：

```
~/GolandProjects/mapleStory079-external/00-官方客户端-冒险岛079-资源提取主源-WZ安装包与extracted_client/extracted_client/
├── Map.wz          # 地图 / back / tile / obj / MapHelper
├── Character.wz    # 角色外观
├── Mob.wz / Npc.wz
├── UI.wz           # 登录 + HUD
└── Sound.wz        # BGM / SE
```

**ingest 工作副本（脚本读写，勿手改）**：

```
~/GolandProjects/mapleStory079-external/03-★maple-client-ingest工作目录-WZ副本-脚本自动复制/
├── Map.wz …        # 从 00 复制
└── extracted/max3/ # MAX3 解压备份（补 grassySoil 等）
```

**本项目已解析资源（Flutter 运行时读取）**：

```
client/assets/
├── maps/
│   ├── 1000000.json          # 彩虹村：6 back + 6 fg层 + 83 foothold(id/prev/next) + portal
│   ├── 20000.json            # 南门外道（传送目标）
│   ├── back/grassySoil/      # 视差背景 PNG
│   ├── tiles/grassySoil/     # 地砖 PNG + *.json(origin)
│   └── obj/                  # 物件 PNG（acc1/guide/house…）
├── maplife/1000000.json      # NPC x/y/fh（希娜 2101 等）
├── images/ui/hud/            # StatusBar + MiniMap（079 HUD）
├── sprites/portal/           # 传送门 continue 动画
└── scenes/login_*.json         # 登录屏 manifest
```

---

## 3. 官方基准客户端

### 3.1 主客户端（资源提取源）

| 项 | 路径 |
|----|------|
| 安装包 | `~/Downloads/冒险岛079/079客户端.exe`（NSIS） |
| 解压目录 | `~/Downloads/冒险岛079/extracted_client` |
| 外部 ingest 副本 | `../mapleStory079-external/03-★maple-client-ingest工作目录-WZ副本-脚本自动复制`（ingest 时复制 WZ） |

路径总表见 **§2 外部参考资源**；速查见 `EXTERNAL_REF.md`。

**验证特征**：`MapleStory.exe` 含 `NEXON Corp.`；WZ 日期约 2010-01；含完整 `Map.wz`（664MB）、`Character.wz`、`Mob.wz`、`UI.wz`、`Sound.wz`。

### 3.2 补充客户端（缺项回填）

| 用途 | 路径 |
|------|------|
| `grassySoil` 地图 back | `../mapleStory079-external/01-MAX3怀旧岛-补全grassySoil与Obj缺项-Data客户端` 或 `03-★maple-client-ingest工作目录-WZ副本-脚本自动复制/extracted/max3/【怀旧岛079MAX3】2022虎年贺岁版/怀旧岛079MAX3_客户端/Data/Map/Back/grassySoil.img` |
| Logo / Obj 等（若主客户端缺） | 同上 MAX3 Data 目录 |

> 官方 `extracted_client/Map.wz/Back/` **不含** `grassySoil.img`，但 `Map/Map0/000010000.img` 的 back 层仍引用 `bS=grassySoil`，必须用 MAX3 Data 补 PNG。

### 3.3 逻辑与 XML 参照（不提取贴图，只对照规则）

| 用途 | 路径 |
|------|------|
| Java 服务端逻辑 | `../mapleStory079-external/02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML/src/main/java/` |
| WZ XML（坐标/禁名/布局） | `../mapleStory079-external/02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML/wz/` |
| 登录管线详解 | `docs/MS079_LOGIN_PIPELINE.md` |
| 架构说明 | `docs/ARCHITECTURE.md` |
| 对齐清单（简表） | `docs/MS079_OFFICIAL_ALIGNMENT.md` |

---

## 4. 技术栈（当前实现）

```
Flutter Web (Flame)  ←HTTP/WS→  Go + Gin  ←→  MySQL + Redis
     :5173                        :8080
```

| 层 | 技术 |
|----|------|
| 客户端 | Flutter 3.x、Flame、Provider、audioplayers |
| 服务端 | Go 1.21+、GORM AutoMigrate、Gin |
| 资源提取 | Python wz-python（`.cache/wz-python`）、Go wzexplorer 脚本 |

---

## 5. 官方流程 vs 本项目流程

### 5.1 原版 TCP 流程（ms079-main）

```
HELLO → 登录 → [性别] → 服务器列表 → 频道 → 角色列表
  → [RaceSelect] → [NewChar] → 选角 → 进频道 TCP → 进图
```

### 5.2 本项目 REST + Flutter 流程

```
/login          LoginPage           账号密码 → POST /auth/login
/gender         GenderPage          未设性别 → POST /auth/gender
/world-select   WorldSelectPage     选世界/频道（简化 UI）
/character-select CharacterSelectPage GET /characters → 选/删/进游戏
/race-select    RaceSelectPage      创建角色前置（仅冒险家可用）
/new-char       NewCharPage         POST /characters
/game-scene     GameSceneLoader     WS + Flame GameWorld
```

**路由定义**：`client/lib/main.dart` → `Routes.*`

### 5.3 登录场景与 MapLogin2 镜头

所有登录屏统一 **800×600**，背景用 `MapLoginParallax` + `client/assets/scenes/maplogin2_layers.json`，**不用**合成 PNG 整屏背景。

| 场景 JSON | 页面 | use_parallax | parallax_camera (x, y) | 说明 |
|-----------|------|--------------|------------------------|------|
| `login_title.json` | 标题 | true | (22, -1785) | Logo 动画 + 登录/离开按钮 |
| `login_gender.json` | 性别 | true | (22, -1785) | Gender 面板叠加 |
| `login_worldselect.json` | 选世界 | true | (22, -1785) | chBackgrn 装饰 |
| `login_charselect.json` | 选角 | true | (290, -1220) | 3 槽 + 选择/建立/删除 |
| `login_raceselect.json` | 选种族 | true | (290, -1220) | 创建流程 |
| `login_newchar.json` | 创建 | true | (290, -1431) | NewChar WZ 面板 |

Manifest 由 `scripts/export_login_manifest/main.go` 生成；**勿运行** `scripts/build_login_scene/main.go`。

**核心客户端文件**：

| 文件 | 职责 |
|------|------|
| `client/lib/features/maple/wz_scene.dart` | 加载 JSON manifest、按钮、槽位、BGM |
| `client/lib/features/maple/maplogin_parallax.dart` | MapLogin2 视差绘制 + camera 偏移 |
| `client/lib/core/resources/login_ui_assets.dart` | Login.img 资源路径 |

---

## 6. 进游戏流程

```
CharacterSelectPage → GameProvider.loadCharacterState
  → GameSceneLoader（读 MapMeta + 恢复 token/charId）
  → GameScenePage → GameWorld (Flame)
```

| 步骤 | 官方 | 本项目 |
|------|------|--------|
| 地图 ID | 000010000 → 逻辑 1000000 | seed + `client/assets/maps/1000000.json` |
| 视口 | 800×600 卷轴 | `MapMeta.officialViewportW/H` = 800×600，相机跟玩家 |
| 背景 | Map.wz back 视差 | `WzMapLayer`（`camera.backdrop`） |
| 前景 | tile 0–7 + obj | `WzMapForegroundLayer`（世界坐标 1:1） |
| 地面 | FootholdTree | `map_foothold.dart`：id/prev/next，`getFhidBelow`，崖边掉落 |
| NPC 刷点 | maplife x/y/fh | `assets/maplife/*.json` → 用 WZ **y** 作脚点 |
| 传送门 | MapHelper portalContinue | `portal_component.dart` + `POST /game/change-map` |
| HUD | StatusBar + MiniMap | `maple_status_bar.dart`（底）`maple_mini_map.dart`（左上） |
| 操作 | ←→ / Ctrl / Alt / Z | `game_controls.dart`；空中按方向保持 jump 动作 |
| 怪物 | WZ life + 服务端 AI | `data/maplife/` + WS `mob_sync` |

**核心客户端文件**：

| 文件 | 职责 |
|------|------|
| `client/lib/game/engine/game_world.dart` | 移动/跳跃/foothold fhid、传送、实体 Y 排序 |
| `client/lib/game/engine/map_foothold.dart` | FootholdTree（对照 HeavenClient） |
| `client/lib/game/engine/wz_map_layer.dart` | 视差 back + `MapMetaFull.load` |
| `client/lib/game/engine/wz_map_foreground.dart` | Tile + Obj 前景层 |
| `client/lib/game/engine/portal_component.dart` | 传送门动画与碰撞 |
| `client/lib/game/engine/map_life_loader.dart` | maplife NPC x/y/fh |
| `client/lib/widgets/maple_status_bar.dart` | 079 底部状态栏 |
| `client/lib/widgets/maple_mini_map.dart` | 079 小地图 |
| `client/lib/providers/game_provider.dart` | `warpToMap()` 传送状态 |

---

## 7. 资源目录总览

```
client/assets/
├── audio/
│   ├── title.mp3              ← Sound.wz BgmUI/Title
│   ├── title.wav              ← 回退
│   └── char_select.mp3        ← UI.img CharSelect（可选）
│
├── scenes/
│   ├── login_*.json           ← 登录各屏 manifest（export_login_manifest）
│   ├── maplogin2_layers.json  ← MapLogin2 视差层（export_maplogin_layers）
│   └── login_*.png            ← ⚠️ 旧合成图，已弃用，可删
│
├── images/ui/login/
│   ├── btn_*_{normal,over,pressed}.png   ← Login.img 按钮三态
│   ├── back/00..37.png                   ← Map.wz Back/login.img
│   ├── logo_0.png, logo_1.png
│   ├── newchar_*.png, worldselect_*.png
│   └── panel_backgrnd.png
│
├── maps/
│   ├── 1000000.json           # 彩虹村：back + mapLayers + 83 foothold(id/prev/next) + portal
│   ├── 20000.json             # 南门外道
│   ├── back/grassySoil/       # 视差 back（MAX3 补全）
│   ├── tiles/grassySoil/      # 地砖 + origin json
│   └── obj/                   # 地图物件
├── maplife/                   # NPC 刷点（与 data/maplife 同步）
├── images/ui/hud/             # StatusBar + MiniMap
├── sprites/portal/            # 传送门 continue 动画
│
├── sprites/
│   ├── mob/                   # Mob.wz stand 帧（ingest 约 5800+）
│   ├── npc/                   # Npc.wz
│   ├── player/                # Character.wz 组合 avatar（按需/少量）
│   └── item/                  # 部分 Item 图标
│
├── characters/
│   ├── parts/                 # 部件 PNG（extract_parts / avatars）
│   └── avatars/               # 预烘焙全身图
│
└── images/tiles/              # 旧路径，新 tile 在 maps/tiles/
```

**Flutter 注册**：`client/pubspec.yaml` — 子目录必须**逐条**声明（如 `assets/sprites/mob/`），否则 Web 打包后 manifest 为空。

**服务端数据（非 Flutter assets）**：

```
data/maplife/
├── 1000000.json    ← 彩虹村 mob spawn（export_map_life）
├── 1000001.json
└── 101010000.json
```

---

## 8. 资源提取管线

### 8.1 一键全量（推荐）

```bash
# 默认主客户端：~/Downloads/冒险岛079/extracted_client
./scripts/ingest_full.sh

# 指定路径
MXD079_CLIENT=/path/to/extracted_client ./scripts/ingest_full.sh
```

**ingest_full 步骤**：

1. 复制 WZ → `../mapleStory079-external/03-★maple-client-ingest工作目录-WZ副本-脚本自动复制`
2. `extract_wz_py/run.sh --full` — 登录 UI、BGM、back/00..37
3. MAX3 补登录缺项（若有 Data 客户端）
4. `export_map_from_wz.py` — 彩虹村 JSON + grassySoil PNG（`--back-client MAX3`）
5. `export_maplogin_layers` / `export_map_life`
6. Mob/Npc 精灵批量提取
7. `export_login_manifest` — **不**跑 build_login_scene
8. `check_assets` 自检

### 8.2 常用单步命令

```bash
# 仅登录 UI + BGM
MAPLE_WZ_ROOT=~/Downloads/冒险岛079/extracted_client \
  scripts/extract_wz_py/run.sh --client "$MAPLE_WZ_ROOT" --full --force

# 彩虹村地图 + foothold + back
PYTHONPATH=.cache/wz-python .cache/wz-python/.venv/bin/python \
  scripts/extract_wz_py/export_map_from_wz.py \
  --client ~/Downloads/冒险岛079/extracted_client \
  --back-client ../mapleStory079-external/03-★maple-client-ingest工作目录-WZ副本-脚本自动复制/extracted/max3/【怀旧岛079MAX3】2022虎年贺岁版/怀旧岛079MAX3_客户端 \
  --map 000010000 --map-id 1000000 --force

# 登录 manifest
go run scripts/export_login_manifest/main.go

# Mob/Npc
scripts/extract_wz_py/run.sh --client "$MAPLE_WZ_ROOT" --mobs-npcs --all --force

# 资源自检
go run scripts/check_assets/main.go
```

### 8.3 脚本索引

| 脚本 | 作用 |
|------|------|
| `scripts/ingest_full.sh` | 全量 ingest（主入口） |
| `scripts/ingest_client.sh` | 扫描本机客户端路径 |
| `scripts/setup_maple_wz.sh` | 单客户端 WZ 提取 |
| `scripts/replica.sh` | 轻量复刻（无 WZ 时程序化回退） |
| `scripts/extract_wz_py/extract.py` | Login/BGM/Back 主提取 |
| `scripts/extract_wz_py/export_map_from_wz.py` | 地图 JSON + foothold(id) + tile/obj/back PNG |
| `scripts/extract_wz_py/gen_grassy_tile_placeholders.py` | 地砖 decode 失败时按 XML 尺寸生成占位 |
| `scripts/extract_wz_py/extract_hud_ui.py` | StatusBar + MiniMap HUD 贴图 |
| `scripts/extract_wz_py/extract_mobs_npcs.py` | Mob/Npc 精灵 |
| `scripts/extract_wz_py/extract_avatars.py` | 角色 avatar 烘焙 |
| `scripts/export_login_manifest/main.go` | 登录 JSON manifest |
| `scripts/export_maplogin_layers/main.go` | MapLogin2 视差 JSON |
| `scripts/export_map_life/main.go` | `data/maplife/*.json` |
| `scripts/export_rainbow_map/main.go` | 从 XML 导出地图（无 WZ 时回退） |
| `scripts/check_assets/main.go` | 占位/真实/缺失统计 |
| ~~`scripts/build_login_scene/main.go`~~ | **已弃用** — 假街机框 |

---

## 9. 服务端规则要点（必须对照 ms079）

| 规则 | 位置 |
|------|------|
| JobType / 出生图 | `pkg/utils/constants.go` |
| 创角白名单 | `pkg/utils/beginner_look.go` |
| 禁名 | `pkg/utils/forbidden_names.go` ← `Etc.wz/ForbiddenName.img.xml` |
| 创角逻辑 | `internal/service/character_service.go` |
| 初始装备 seed | `seedBeginnerEquipment` |
| 演示账号 | `pkg/database/seed_079_accounts.go` — `test` / `test123456` |

**演示角色**（account_id=1）：

| 名字 | class | level | 说明 |
|------|-------|-------|------|
| 冒险者一号 | 0 新手 | 1 | 默认 |
| 见习法师 | 200 法师 | 15 | 女角 face/hair |
| 剑士试炼 | 100 战士 | 20 | |

**API 基址**：`http://localhost:8080/api/v1`（`client/lib/config/app_config.dart`）  
**WebSocket**：`ws://localhost:8080/ws`

---

## 10. 当前完成度

### 10.1 资源

| 模块 | 状态 | 说明 |
|------|------|------|
| 登录 BGM / Login.img | ✅ | title.mp3、按钮三态 |
| MapLogin2 视差 | ✅ | 6 个 login_*.json |
| 彩虹村 map JSON | ✅ | 83 foothold（含 id/prev/next/layer）、6 portal |
| grassySoil back | ✅ | MAX3 补 6 层 |
| 地图 Tile | ✅ | 已导出 22 个 grassySoil 地砖 PNG（含 enV0/enH0/edU），非占位 |
| 地图 Obj | ⚠️ | 彩虹村/guide/acc 等已导出；缺项按地图补 |
| 进游戏 HUD | ✅ | `images/ui/hud/` StatusBar + MiniMap |
| 传送门精灵 | ✅ | `sprites/portal/continue_0..6.png` |
| Mob 精灵 | ⚠️ | 大量已有；部分怪仍显示占位红块 |
| Npc 精灵 | ⚠️ | 部分 ID 缺 PNG |
| Player 动画 | ⚠️ | compose API walk/jump/attack；缺帧时回退火柴人 |
| 地图 20000 | ✅ | 南门外道 JSON（out00 传送目标） |

### 10.2 客户端功能

| 功能 | 状态 |
|------|------|
| 登录→性别→世界→选角→创建 | ✅ |
| MapLogin2 视差背景 | ✅ |
| 079 键位 | ✅ |
| 移动 + Alt 跳跃 + 重力 | ✅ |
| FootholdTree（多层平台/崖边掉落） | ⚠️ 已接 HeavenClient 算法；下跳穿板未做 |
| WZ 地图 back + tile + obj | ⚠️ 已渲染；脚点与贴图偶发错位需逐图修 |
| 079 HUD（底栏+小地图） | ✅ 代码已接；需硬刷新去旧 Material 顶栏缓存 |
| 传送门显示 + 切图 API | ⚠️ 彩虹村 out00→20000 可测；更多地图待导出 |
| 空中按方向保持 jump 动作 | ✅ |
| walk/attack 动画 | ⚠️ 攻击已防 walk 覆盖；walk 多帧依赖 compose |
| WS 怪物同步 | ✅ |
| 背包/技能/社交 UI | ⚠️ 框架有，未对齐 WZ UIWindow |

### 10.3 服务端

| 功能 | 状态 |
|------|------|
| 登录/创角/禁名 | ✅ |
| 彩虹村官方 NPC（希娜/莎丽） | ✅ maplife + WZ 对话 |
| `POST /game/change-map` | ✅ 落点 spawnForMap |
| Mob spawn from maplife | ✅ |
| Mob AI + WS 广播 | ✅ |
| 完整伤害/技能/任务 | ⚠️ 简化 |

---

## 11. 当前重要问题与计划

### 11.1 已知问题（优先修）

| # | 现象 | 根因 | 计划 |
|---|------|------|------|
| **A** | 人/怪/NPC 脚点与地砖视觉错位、悬空或埋地 | 多层 foothold（425/605）+ tile 层 zM 混渲；部分 tile 占位图 origin 不准 | 对照 `grassySoil.img.xml` 校验 origin；按 fhlayer 过滤或 Y 排序 tile；逐坐标验收 |
| **B** | 浏览器仍见旧顶栏 HUD（黄框属性条） | Flutter Web 缓存 / 未硬刷新 | 用户 Cmd+Shift+R；确认 `game_scene_page` 仅用 `MapleStatusBar` |
| **C** | 部分怪物红块占位 | MobId 无对应 `sprites/mob/{id}.png` | `extract_mobs_npcs.py --id` 补提取 + manifest |
| **D** | 地图边缘地砖呈「石墙满屏」 | enV0 竖边 tile 叠层 + 占位 PNG | 优先真实 WZ decode；失败项用 XML 尺寸占位并核对 ox/oy |
| **E** | 下跳（Alt+↓）穿薄板 | 未实现 `enablejd` / CHECKBELOW | 对照 HeavenClient `PhysicsObject::Flag::CHECKBELOW` |
| **F** | 传送后仅客户端切图，频道/同图玩家 | 无原版 TCP 频道服 | 短期：HTTP change-map + 重载 GameScene；长期再议 |

### 11.2 优先级路线图

#### P0 — 地图可玩性（本周）

| # | 状态 | 任务 | 参考 | 产出 |
|---|------|------|------|------|
| 1 | **完成（周期 #21）** | 彩虹村脚点/贴图逐段验收（spawn、希娜、out00） | HeavenClient FootholdTree + `000010000.img.xml` 对照 `100000000.json` footholds | foothold 无 id 时自动补；玩家脚底 snapSpawn；NPC 按 maplife Y；调试 overlay 可绘制 foothold/脚点十字 |
| 2 | **完成（周期 #22）** | 补全/修正 tile PNG（enV0/enH0/edU 非占位） | `_ext_grassy_soil.py`（wz-python decode + 枚举 offset/尺寸/像素格式） | `maps/tiles/grassySoil/*.png` 22/22 非占位；json 仅存 ox/oy/w/h |
| 3 | **完成（周期 #23）** | 怪物精灵补缺（蘑菇、野猪等新手怪） | `Mob.wz` + `extract_mobs_npcs.py --ids 100100,1110100,...`（first_canvas 处理 info/default + link 重定向） | `sprites/mob/{id}.png` 非 placeholder；彩虹村/新手岛关键 mob&npc 精灵 OK |
| 4 | **完成（周期 #24）** | 下跳穿板 + 绳梯（rope/ladder obj） | HeavenClient `PhysicsObject::Flag::CHECKBELOW` + `Foothold::prev/next==0` 判定薄平台；WZ obj `l0=rope/ladder` 解析 | `game_world.dart` 下跳（仅薄平台/跳+↓）；`MapMetaFull._extractRopeLadders`；玩家靠近+↑攀爬、Space 跳离；ladder 锁 X / rope 允许微调 |

#### P1 — 079 体验对齐

| # | 状态 | 任务 | 说明 |
|---|------|------|------|
| 5 | **完成（周期 #25）** | 批量导出新手岛地图链 | `scripts/extract_wz_py/batch_export_novice_island.py` — 1000000/20000/30000/100000000/101000000 JSON + foothold(id/prev/next) + tile/obj/back PNG + data/maplife + client/assets/maplife |
| 6 | **完成（周期 #26）** | 小地图 canvas 贴图逐图导出 | `scripts/extract_wz_py/extract_minimap_from_wz.py` — 1000000/30000/100000000/101000000 真实 WZ miniMap canvas；20000 无 miniMap 节点 → foothold 程序化占位；MapMetaFull 暴露 miniMapAsset，GameWorld 传入 MapleMiniMap |
| 7 | **完成（周期 #27）** | 伤害数字 / 拾取特效 | `Effect.wz/BasicEff.img` → `levelUp_*` / `pickUpItem_*`（QuestClear）；`EffectSpriteComponent` + `GameWorld.playEffect(type)`；`_doLevelUp` / `_pickupLoot` 接入 |
| 8 | **完成（周期 #28）** | 地图 BGM 按图切换（资源） | `Sound.wz/Bgm00/` → `assets/audio/bgm/`；`assets/audio/*.wav` 覆盖主要大地图 |
| 9 | **完成（周期 #29）** | 背包/装备 UIWindow | `UI.wz/UIWindow.img`；`MapleInventoryPanel`/`MapleEquipPanel`/`MapleStatPanel`/`MapleSkillPanel` 已接入 `GameScenePage._openPanel`；底部 HUD 按钮 → 切换打开；`assets/images/ui/windows/*.png` 贴图齐备 |
| 10 | **完成（周期 #30）** | 地图 BGM 按图切换（代码接入） | `BgmAssets.byMapId` 统一返回 `.wav` 路径（精确地图 `audio/bgm/{mapId}.wav`；大区回退 `audio/00xxxxxx.wav`；BOSS 回退 `audio/boss_zakum.wav`）；`GameWorld.onLoad` → `AudioManager().playBgm(bgm)`；`GameWorld.onRemove` → `stopBgm`；`game_scene_loader.dart` 写入 `bgmAsset` 传递至 `GameScenePage` |
| 11 | **完成（周期 #31）** | NPC 对话分支（say/choice/end）+ 对话结果回写血量/金币 | `internal/service/npc_service.go` 的 `ContinueDialogue` 支持 `say` 节点与 `node.NextID` 推进（非仅 choice）；`NPCRequest` 新增 `NextID`；`NpcDialogueNode.fromJson` 解析 `next_id`；`NpcDialoguePanel` 新增 `onNext` + OK 按钮；`_runDialogueLoop` 根据 `isNext/choice/close` 分支请求服务端；`DialogueEffect` 写回 mesos/hp/mp → HUD 同步 |
| 12 | **完成（周期 #32）** | NPC 商店（希娜 2101 买药水，回写 mesos/inventory） | `internal/service/shop_service.go` 重写 `npcShopCatalog`，按地图+职业组织商品；`buyShopItem` 校验 mesos 并回滚；`InventoryService.AddItem` 改为合并同 itemID（避免重复插入）；`pkg/database/seed_079_world.go` 的 2101/2100 NPC 设 `HasShop=true`；`NpcShopPanel` 新增 quantity 输入框，购买后调用 `GameProvider.syncFromGameWorld(mesos:)` + `InventoryProvider.loadInventory` 实时刷新 |
| 13 | **完成（周期 #33）** | NPC 转职正式流程（按职业分配 SP + 升级 MaxHP/MP 回写） | `npc_service.go` `JobChangeScript`：等级<10 提示"你还需要更多修炼"；`ExecuteAction` 按 079 标准计算 SP 补偿（超过 10 级部分 × 3 SP）；`applyJobInitialStats` 写入 `Class/STR/DEX/INT/LUK/MaxHP/MaxMP/HP/MP`；`DialogueEffect` 新增 `NewSP/NewMaxHP/NewMaxMP` 字段；`GainExp`/`LevelUpCharacter` API 返回 `sp/max_hp/max_mp`；Dart `GameState.updateFromJson` + `GameProvider.syncFromGameWorld` 支持 `sp` 同步 |
| 14 | **完成（周期 #34）** | 传送门地图切换（portal_name 触发 warp，服务端落位 + 客户端重载场景） | `game_service.go` `spawnForMap` 扩展至 10 张以上主城镇（彩虹村/明珠港/射手村/魔法密林/勇士部落/废弃都市/冰峰雪域/玩具城/天空之城）+ 训练场/BOSS 地图；`npc_service.go` `PortalScript`：选项含各主城，`ExecuteAction` 解析 `mapId|portalName`，调用 `spawnForMap` 落位；`DialogueEffect` 新增 `NewPositionX/NewPositionY` 字段；`game_scene_page.dart` `_runDialogueLoop` 检测 `effects.new_map_id` → `GameProvider.warpToMap` → `pushReplacementNamed` 重载场景；`MapMetaFull.hasAsset/load` + `MapMeta.loadForMap` 扩展 ID 回退至已导出 JSON（1000000/20000/101000000/102000000/103000000/104000000/100000000） |
| 15 | **完成（周期 #36）** | 怪物掉落系统（MapleItem 实体 + 初始弹跳 + 浮动 + 20s 超时 + 拾取入背包 + mesos 掉落通知） | 新增 `client/lib/game/engine/ground_loot_component.dart`（dropId/itemId/quantity/isMesos；`update` 前 0.6s 抛物线弹跳 + 之后 sin 浮动；`render` 绘制阴影 + `SpriteLoader.tryLoad('sprites/item/{id}.png')`，失败时占位方+文字，最后 3s 闪烁；`_baseY` + `_expired` 由 GameWorld 每帧清理）；新增 `client/lib/widgets/maple_pickup_notice.dart`（`MaplePickupNoticeState.notify/notifyItem/notifyMesos`，最多 4 条向上渐隐弹幕，`AnimationController` + `Opacity` + `Transform.translate`）；`game_world.dart` 引入 `ground_loot_component.dart`；删除内联旧 `GroundLootComponent`，`_tryAutoPickup` 增加 `loot.expired` 过期清理 |

#### P2 — 登录与角色

| # | 任务 | 说明 |
|---|------|------|
| 10 | MapLogin2 镜头平滑滚动 | 标题→选角非硬切 camera |
| 11 | 全量 Character 部件缓存 | `extract_avatars.py --all` 或按需 |
| 12 | **完成（周期 #35）** UI.img 点击音效 | CharSelect/BtMouseClick 统一 `AudioManager.playUiClick`；Login/Gender/WorldSelect/CharSelect/NpcShopPanel 等 UI 按钮均接入音效 |

### 11.3 已知 WZ 缺口

| 缺口 | 说明 | 解决 |
|------|------|------|
| 主客户端无 grassySoil.img | Map.wz/Back 不含 | MAX3 Data（`01-…` 或 `03-…/extracted/max3`） |
| 部分 Tile canvas decode 失败 | wz-python 对部分 enV0/edU 报错 | XML origin + `gen_grassy_tile_placeholders.py` |
| 主客户端无 Obj/login.img | Map.wz/Obj 无 login | UI 层用 Login.img；Obj 用 MAX3 |
| 补丁 1.5m.exe | RAR 自解压，Mac 难解压 | Windows 解压后合并 WZ |

### 11.4 已废弃 / 勿再使用

| 项 | 说明 |
|----|------|
| `scripts/build_login_scene/main.go` | 假街机框背景 |
| `client/lib/widgets/player_stats.dart` | 旧 Material 顶栏（已由 `MapleStatusBar` 替代） |
| `client/lib/widgets/mini_map.dart` | 手绘小地图（已由 `MapleMiniMap` 替代） |
| 仅用 `groundYAt` 扁平 foothold | 已升级为 FootholdTree（id/prev/next） |

---

## 12. 标准修改流程（后续按此执行）

### 12.1 改登录/UI 画面

1. 查 `../mapleStory079-external/02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML/wz/UI.wz/Login.img.xml` 节点坐标  
2. 查 `MapLogin2.img.xml` 对应屏 signboard 的 x,y → `parallax_camera`  
3. 缺 PNG → `extract.py` 或 HaRepacker 导出到 `client/assets/images/ui/login/`  
4. 改 `scripts/export_login_manifest/main.go` → `go run ...`  regenerate JSON  
5. 改 `client/lib/features/.../*_page.dart` 交互  
6. **不要**跑 `build_login_scene`  
7. `flutter run -d chrome --web-port=5173` 硬刷新验证  

### 12.2 改地图/进游戏画面

1. 确定 WZ 地图文件：`Map/Map0/000010000.img` ↔ 逻辑 mapId `1000000`  
2. 对照 HeavenClient：`04-…/Gameplay/Physics/FootholdTree.cpp`  
3. 导出：
   ```bash
   PYTHONPATH=.cache/wz-python .cache/wz-python/.venv/bin/python \
     scripts/extract_wz_py/export_map_from_wz.py \
     --client "$(maple_mxd079_client)/extracted_client" \
     --map 000010000 --map-id 1000000 --force
   ```
4. 地砖缺项：`scripts/extract_wz_py/gen_grassy_tile_placeholders.py`  
5. 改 `map_foothold.dart` / `game_world.dart` / `wz_map_foreground.dart`  
6. NPC 刷点：`data/maplife/` + `client/assets/maplife/` 必须含 **x/y/fh**  
7. 更新 `pubspec.yaml` 若新增 assets 子目录  
8. `flutter run -d web-server --web-port=5173` 后 **硬刷新** 验证

### 12.3 改服务端规则

1. 先读 `../mapleStory079-external/02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML` 对应 Handler/Service  
2. 改 `pkg/utils/constants.go` 或 `internal/service/*`  
3. 禁名/白名单改 XML 或 Go 常量  
4. `go run cmd/server/main.go` 重启  
5. 演示账号：`pkg/database/seed_079_accounts.go`  

### 12.4 改角色/Mob 贴图

1. `scripts/extract_wz_py/extract_mobs_npcs.py --id <mobId>` 或 `--all`  
2. 角色：`extract_avatars.py` / `extract_parts.py`  
3. 确认 `pubspec.yaml` 包含对应 sprites 目录  
4. `sprite_loader.dart` / `avatar_assets.dart` 路径候选  

---

## 13. 本地开发

### 13.1 环境

- Go 1.21+、MySQL 8、Flutter 3.x  
- Python 3 + wz-python：首次 ingest 自动克隆到 `.cache/wz-python`  

### 13.2 启动

```bash
# 1. 数据库 + 配置 config/config.yaml

# 2. 服务端（AutoMigrate + seed）
go run cmd/server/main.go          # :8080

# 3. 客户端
cd client && flutter run -d chrome --web-port=5173
```

### 13.3 测试账号

| 字段 | 值 |
|------|-----|
| 账号 | `test` |
| 密码 | `test123456` |

### 13.4 自检

```bash
go run scripts/check_assets/main.go
cd client && flutter analyze
curl http://localhost:8080/health
```

---

## 14. 仓库目录结构（精简）

```
mapleStory079/
├── cmd/server/              # Go 入口
├── client/                  # Flutter + Flame
│   ├── assets/              # ★ 所有游戏资源
│   └── lib/
│       ├── features/        # login / character / game / maple
│       └── game/engine/     # GameWorld / WzMapLayer / controls
├── internal/                # handler / service / repository
├── pkg/                     # database / utils / maplife
├── data/maplife/            # 地图刷怪 JSON
├── scripts/                 # ★ 资源提取与 ingest
├── docs/                    # 详细手册
│   ├── MS079_LOGIN_PIPELINE.md
│   ├── MS079_OFFICIAL_ALIGNMENT.md
│   └── ARCHITECTURE.md
└── EXTERNAL_REF.md        # 外部参考速查 → 完整说明见 §2
```

**外部参考**（不纳入本仓库 git，详见 **§2 外部参考资源**）：

```
../mapleStory079-external/
├── 00-官方客户端-冒险岛079-资源提取主源-WZ安装包与extracted_client   # ★ 链 Downloads
├── 01-MAX3怀旧岛-补全grassySoil与Obj缺项-Data客户端                 # ★ 链 Downloads
├── 02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML                  # ★ Java + XML
├── 03-★maple-client-ingest工作目录-WZ副本-脚本自动复制              # ★ ingest 副本
├── 04-HeavenClient-C++参考-UI坐标与渲染逻辑
├── 05-HeavenMS-v83参考-服务端架构-已归档
├── 06-ZLHSS2-079参考-中文全栈私服
├── 07–12 …                                                          # 其他开源参考
├── archives/                                                        # zip 备份
└── docs-OPEN_SOURCE_RESOURCES.md
```

---

## 15. 相关文档

| 文档 | 内容 |
|------|------|
| `docs/MS079_LOGIN_PIPELINE.md` | 登录→创角完整对照、API、排错 |
| `docs/MS079_OFFICIAL_ALIGNMENT.md` | 官方对齐简表（随改动更新） |
| `docs/ARCHITECTURE.md` | 分层架构、模块说明 |
| `docs/DATABASE.md` | 表结构 |
| `EXTERNAL_REF.md` | 外部参考速查（§2 精简版） |
| `../mapleStory079-external/README.md` | 外部目录完整索引 |
| `scripts/README.md` | init_data、旧版脚本说明 |

---

## 16. 法律声明

本项目仅供**学习研究**，不得商业使用。冒险岛为 Nexon 注册商标，WZ 资源受版权保护。使用官方客户端资源仅限本地私服开发，请勿公开分发 WZ 文件。

---

## 17. 变更记录

| 日期 | 摘要 |
|------|------|
| 2026-06-15 | 周期 #36：新增 `client/lib/game/engine/ground_loot_component.dart`（地面掉落 MapleItem/meso：dropId/itemId/quantity/isMesos；前 0.6s 抛物线弹跳 + 之后 sin 浮动；20s 超时 `expired=true`；最后 3s 闪烁；render 含阴影 + `SpriteLoader.tryLoad('sprites/item/{id}.png')`，失败时占位方+文字；右下角 `×quantity` 标签）；新增 `client/lib/widgets/maple_pickup_notice.dart`（`MaplePickupNoticeState` 暴露 `notify/notifyItem/notifyMesos`；最多 4 条向上渐隐弹幕，`AnimationController` + `Opacity` + `Transform.translate`）；`game_world.dart` 引入 `ground_loot_component.dart`，删除内联旧 `GroundLootComponent`；`_tryAutoPickup` 增加 `loot.expired` 过期清理；`go build ./cmd/server` 通过；`flutter analyze client` 无新增 error；§11.2 P1 #15 标记完成 |
|------|------|
| 2026-06-15 | 周期 #35：`AudioManager.playUiClick` 统一接入 `LoginPage` / `GenderPage` / `WorldSelectPage` / `CharacterSelectPage` (`_onSceneButton` select/new/delete/page/prev) / `NpcShopPanel`（购买 + 关闭）/ `RaceSelectPage` / `NewCharPage`（toggleScroll/cycleOption/randomize/tab select）/ `NpcDialoguePanel`（OK/关闭/choice）/ `MapleInventoryPanel`（tab 切换）/ `MapleStatusBar` 全部图标按钮；`login_page.dart` 退出键 `stopBgm`；`gender_page.dart` / `world_select_page.dart` / `npc_shop_panel.dart` 补充 `import '../../core/resources/assets.dart'`（AudioManager）；Flutter analyze 无新增错误；§11.2 P2 #12 标记完成 |
|------|------|
| 2026-06-15 | 周期 #34：`game_service.go` `spawnForMap` 扩展至 10 张以上主城镇 + 训练场/BOSS；`npc_service.go` `PortalScript`：选项含各主城，`ExecuteAction` 解析 `mapId|portalName`，调用 `spawnForMap` 落位；`DialogueEffect` 新增 `NewPositionX/NewPositionY`；`_runDialogueLoop` 检测 `effects.new_map_id` → `GameProvider.warpToMap` → `pushReplacementNamed`；`MapMetaFull.hasAsset/load` + `MapMeta.loadForMap` 扩展 ID 回退；§11.2 P1 #14 标记完成 |
|------|------|
| 2026-06-15 | 周期 #32：`internal/service/shop_service.go` 重写 `npcShopCatalog`（彩虹村 2101/2100 + 明珠港/射手村/勇士部落/废弃都市多套商品）；`buyShopItem` 校验 mesos 并支持 quantity；`InventoryService.AddItem` 改为合并同 itemID 而非重复插入；`pkg/database/seed_079_world.go` 希娜/莎丽 `HasShop=true`；Dart `NpcShopPanel` 新增 quantity 输入框，购买成功后调用 `GameProvider.syncFromGameWorld(mesos:)` + `InventoryProvider.loadInventory` 实时刷新；`api_service.dart` `buyShopItem` 发送 quantity，解析服务端 `success` + `error`；§11.2 P1 #12 标记完成 |
| 2026-06-15 | 周期 #31：Go `NPCRequest` 新增 `NextID`；`ContinueDialogue` 支持纯台词 `say` 节点与 `node.NextID` 推进；NPC 对话 `executeAction` 统一持久化角色修改；`NpcDialogueNode.fromJson` 解析 `next_id`；`NpcDialoguePanel` 新增 `onNext` + OK/关闭按钮；`game_scene_page.dart` `_runDialogueLoop` 按 isNext/choice/close 分支调用 API；DialogueEffect 回写 mesos/hp/mp → HUD 同步；§11.2 P1 #11 标记完成 |
| 2026-06-15 | 周期 #27：新增 `scripts/extract_wz_py/extract_effect_from_wz.py`，从 `Effect.wz/BasicEff.img` 导出 `levelUp` / `pickUpItem` 帧 → `assets/sprites/effect/{type}_{n}.png`（附带 `{type}.json` 元数据）；新增 `EffectSpriteComponent`（Flame `SpriteAnimationComponent` + `removeOnFinish=true`）；`GameWorld.playEffect` 统一入口；在 `_doLevelUp` / `_pickupLoot` 接入；`pubspec.yaml` 新增 `assets/sprites/effect/`；§11.2 P1 #7 标记完成 |
| 2026-06-15 | 周期 #26：新增 `scripts/extract_wz_py/extract_minimap_from_wz.py`（含 `--fallback-footholds`），导出 1000000/30000/100000000/101000000 真实 miniMap canvas；20000 无 miniMap 节点 → foothold 程序化占位；`MapMetaFull.miniMapAsset` 暴露给 `MapleMiniMap`；`pubspec.yaml` 新增 `assets/maps/miniMap/`；§11.2 P1 #6 标记完成 |
| 2026-06-15 | 周期 #25：`batch_export_novice_island.py` 导出 5 张新手地图 JSON（footholds id/prev/next + portals） + tile/obj PNG + MAX3 补 grassySoil back PNG；新增 `extract_maplife_from_wz.py`（`data/maplife/` 与 `client/assets/maplife/` 同步覆盖 5 图）；§11.2 P1 #5 标记完成 |
| 2026-06-15 | 周期 #24：`map_foothold.dart` 新增 `isThinPlatform` + 下跳仅薄平台有效；`MapMetaFull._extractRopeLadders` 从 WZ obj `l0=rope/ladder` 解析攀爬段；`game_world.dart` 下跳穿板（↓+Alt/Space）+ 攀爬状态机（↑ 进入、Space 跳离、ladder 锁 X / rope 微调）；`game_controls.dart` 新增 `anyMoveUp`；§11.2 P0 #4 标记完成 |
| 2026-06-15 | 周期 #23：怪物精灵补缺（新手怪蘑菇/野猪等）；`scripts/extract_wz_py/extract_mobs_npcs.py` `first_canvas` 处理 link 重定向；补充 `sprites/mob/{id}.png` 非 placeholder |
| 2026-06-15 | 周期 #22：grassySoil tile PNG 重新 decode（wz-python + 枚举 offset/尺寸/像素格式），22/22 非占位；`scripts/extract_wz_py/_ext_grassy_soil.py`；§11.2 P0 #2 标记完成 |
| 2026-06-15 | 周期 #21：FootholdTree JSON 缺 id/prev/next 时 `map_foothold.dart` 自动补唯一 id；`GameWorld.renderTree` 新增调试 overlay（FH / 脚点十字）；HUD 层增加两个切换按钮；§11.2 P0 #1 标记完成 |
| 2026-06-14 | 进游戏：FootholdTree(id/prev/next)、Tile/Obj 前景、079 HUD、传送门+change-map；更新 §2.5/§2.6 参考与解析路径表；重写 §11 问题与计划 |
| 2026-06-14 | 示例代码迁出：`examples/` 删除，统一至同级 `mapleStory079-external/`；新增 §2 路径总表 |
| 2026-06-14 | 重写本文档：以官方 extracted_client + MAX3 为资源基准；MapLogin2 视差登录；彩虹村 foothold/back；弃用 build_login_scene |
