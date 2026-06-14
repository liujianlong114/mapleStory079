# MapleStory 079 复刻项目计划

> **用途**：以官方 079 客户端 WZ 资源 + `ms079-main` 服务端逻辑为基准，指导后续所有客户端/服务端/资源改动。  
> **原则**：业务规则跟 Java 源码，画面跟 WZ，**不手搓假 UI**（禁止再用 `build_login_scene` 生成街机框背景）。  
> **最后更新**：2026-06-14

---

## 1. 项目目标

| 维度 | 目标 |
|------|------|
| 视觉 | 登录 MapLogin2 视差、选角 WZ UI、进图 WZ 地图 back / 精灵 |
| 操作 | 079 键位：←→ 移动、Ctrl 攻击、Z 拾取、Alt 跳跃（跳跃待实现） |
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
  → GameSceneLoader（读 MapMeta）
  → GameScenePage → GameWorld (Flame)
```

| 步骤 | 官方 | 本项目 |
|------|------|--------|
| 地图 ID | 000010000 → 逻辑 1000000 | `pkg/utils/constants.go` `MapTutorialStart=0` 或 seed 彩虹村 |
| 视口 | 800×600 卷轴 | 横版 750 高，相机仅跟 X |
| 背景 | Map.wz back 层 + tile + obj | `WzMapLayer` 渲染 back PNG（**无 tile/obj**） |
| 地面 | foothold 碰撞 | `1000000.json` 83 条 foothold → `MapFootholds.groundYAt(x)` |
| 操作 | ←→ / Ctrl / Z | `game_controls.dart` |
| 怪物 | WZ life + 服务端 AI | `data/maplife/*.json` + `mob_sync_service` + WS |
| 精灵 | Character/Mob WZ | `assets/sprites/{player,mob,npc}/` |

**核心客户端文件**：

| 文件 | 职责 |
|------|------|
| `client/lib/game/engine/game_world.dart` | 横版移动、攻击、WS、foothold Y |
| `client/lib/game/engine/wz_map_layer.dart` | 地图视差 back 层 |
| `client/lib/game/engine/map_foothold.dart` | foothold 求 Y |
| `client/lib/game/engine/sprite_loader.dart` | Mob/Npc/Player PNG 加载 |
| `client/lib/features/maple/maple_avatar_view.dart` | 选角/角色 WZ 部件预览 |

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
│   ├── 1000000.json           ← 彩虹村：layers + footholds + spawn
│   └── back/grassySoil/{0,1,2,3,5,6}.png  ← MAX3 补全
│
├── sprites/
│   ├── mob/                   ← Mob.wz stand 帧（ingest 约 5800+）
│   ├── npc/                   ← Npc.wz
│   ├── player/                ← Character.wz 组合 avatar（按需/少量）
│   └── item/                  ← 部分 Item 图标
│
├── characters/
│   ├── parts/                 ← 部件 PNG（extract_parts / avatars）
│   └── avatars/               ← 预烘焙全身图
│
└── images/tiles/              ← 预留，当前几乎为空
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
| `scripts/extract_wz_py/export_map_from_wz.py` | 地图 JSON + foothold + back PNG |
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
| 登录 BGM | ✅ | title.mp3 |
| Login.img 按钮 | ✅ | 三态 PNG |
| MapLogin2 back 38 层 | ✅ | images/ui/login/back/ |
| 登录各屏视差 | ✅ | 6 个 login_*.json |
| 彩虹村 map JSON | ✅ | layers + 83 footholds |
| grassySoil back PNG | ✅ | MAX3 补 6 层 |
| Mob 精灵 | ✅ | ~5800 PNG |
| Npc 精灵 | ⚠️ | 部分 |
| Player 部件/avatar | ⚠️ | 少量，按 ID 按需提取 |
| 地图 Tile | ❌ | 未提取未渲染 |
| 地图 Obj（房屋树） | ❌ | 未提取未渲染 |
| 技能/物品/Effect 精灵 | ❌ | 未做 |
| UI.img 音效 | ⚠️ | 部分 |

### 10.2 客户端功能

| 功能 | 状态 |
|------|------|
| 登录→性别→世界→选角→创建 | ✅ |
| MapLogin2 视差背景 | ✅ |
| 079 键位 | ✅ |
| 横版移动（仅 X） | ✅ |
| WZ 地图 back 视差 | ✅ |
| foothold 地面 Y | ⚠️ 贴地无跳跃/多层 |
| WZ 角色预览（选角） | ⚠️ 依赖装备 API + 部件 PNG |
| WZ Mob 显示 | ✅ |
| 本地/WS 怪物同步 | ✅ |
| 背包/技能/社交 UI 页 | ⚠️ 框架有，未对齐 WZ UI |

### 10.3 服务端

| 功能 | 状态 |
|------|------|
| 登录/创角/禁名 | ✅ |
| FindEquipped (`is_equipped`) | ✅ 已修 |
| Mob spawn from maplife | ✅ |
| Mob AI + WS 广播 | ✅ |
| 完整伤害/技能/任务 | ⚠️ 简化 |

---

## 11. 缺失内容与优先级

### P0 — 视觉与玩法核心

| # | 缺失 | 做法 |
|---|------|------|
| 1 | 地图 **Tile 层** | 从 `Map.wz/Map/Map0/000010000.img` 导出 tile + `Tile/grassySoil.img`，Flame 渲染 |
| 2 | 地图 **Obj 层** | 导出 `Map.wz/Obj/*.img` 物件 PNG + 坐标，叠加到 `WzMapLayer` 之上 |
| 3 | **跳跃 + 多层 foothold** | 读 foothold 图结构，Alt 跳、落点检测 |
| 4 | 角色 **walk/attack 动画** | Character.wz 多帧 + Flame SpriteAnimation |

### P1 — 登录与角色

| # | 缺失 | 做法 |
|---|------|------|
| 5 | MapLogin2 **卷轴动画** | 标题→选角镜头平滑滚动（非硬切 camera） |
| 6 | Logo 从 WZ Obj 提取 | Map/Obj/login.img Title/logo（MAX3 Data 或补丁 WZ） |
| 7 | 全量 **Character 部件** | `extract_avatars.py --all` 或按需缓存策略 |
| 8 | 选角 **charInfo 面板** | Login.img CharSelect/charInfo1 叠加 |

### P2 — 体验补齐

| # | 缺失 | 做法 |
|---|------|------|
| 9 | UI.img 音效 | CharSelect/WorldSelect/BtMouseClick |
| 10 | 地图 BGM 逐图 | Sound.wz Bgm00/* → assets/audio/bgm/ |
| 11 | 背包/装备 UI | UIWindow.img 贴图 |
| 12 | 更多地图 | 按 mapId 批量跑 export_map_from_wz |

### 已知 WZ 缺口

| 缺口 | 说明 | 解决 |
|------|------|------|
| 主客户端无 grassySoil.img | Map.wz/Back 不含 | MAX3 Data 客户端 |
| 主客户端无 Obj/login.img | Map.wz/Obj 无 login | UI 层用 Login.img；Obj 用 MAX3 |
| 补丁 1.5m.exe | RAR 自解压，Mac 难解压 | Windows 解压后合并 WZ |

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
2. `export_map_from_wz.py --map 000010000 --map-id 1000000 --back-client MAX3`  
3. 缺 back set → `extract_map_backs.py` 或 MAX3 Data  
4. 改 `wz_map_layer.dart` / `game_world.dart` 渲染或碰撞  
5. 更新 `pubspec.yaml` 若新增 assets 子目录  
6. 服务端 `data/maplife/` + spawn 坐标与 WZ life 一致  

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
| 2026-06-14 | 示例代码迁出：`examples/` 删除，统一至同级 `mapleStory079-external/`；新增 §2 路径总表 |
| 2026-06-14 | 重写本文档：以官方 extracted_client + MAX3 为资源基准；MapLogin2 视差登录；彩虹村 foothold/back；弃用 build_login_scene |
