# MapleStory 079 官方对齐清单

> 基准客户端：`~/Downloads/冒险岛079/extracted_client`（从 NSIS 安装包解出）  
> 验证：NEXON Corp. 签名、`MapleStory.exe` 2010-01、标准 WZ 套件（Map/Character/Mob/UI/Sound）

## 不需要 / 做不到的事

| 项 | 说明 |
|----|------|
| 反编译 `MapleStory.exe` | C++ 二进制无法还原可用源码；私服复刻靠 **WZ 资源 + ms079 服务端逻辑** |
| 100% 客户端行为 | 键盘、UI 动画、MapLogin2 卷轴等需逐项对照 HeavenClient / ms079-main 实现 |

## 资源（贴图 / 音频）

| 模块 | 官方来源 | 本项目路径 | 状态 |
|------|----------|------------|------|
| 登录 BGM | `Sound.wz/BgmUI.img/Title` | `client/assets/audio/title.mp3` | ✅ 已提取 |
| 登录 UI 按钮 | `UI.wz/Login.img` | `client/assets/images/ui/login/btn_*.png` | ✅ 已提取 |
| MapLogin2 视差 | `Map.wz/Back/login.img` | `client/assets/images/ui/login/back/*.png` | ✅ 38 层 |
| 选角背景 | MapLogin2 镜头 (290,-1220) | `login_charselect.json` + `MapLoginParallax` | ✅ 已改 |
| 角色部件 | `Character.wz` | `client/assets/sprites/player/` | ⚠️ 部分（按 ID 按需提取） |
| Mob / Npc | `Mob.wz` / `Npc.wz` | `client/assets/sprites/mob|npc/` | ⚠️ 已跑 ingest，按 manifest |
| 彩虹村视差 | `Map.wz/Map/Map0/000010000.img` | `client/assets/maps/1000000.json` | ✅ JSON 来自官方 WZ |
| 彩虹村 back 图 | `Map.wz/Back/grassySoil.img` | `client/assets/maps/back/grassySoil/` | ✅ MAX3 Data 客户端补全 |
| 地图地砖 / obj | `Map.wz` Tile + Obj + foothold | `maps/1000000.json` footholds | ⚠️ foothold Y 已用，tile/obj 未渲染 |

### 已知 WZ 缺口

官方 079 客户端（本包）的 `Map.wz/Back/` **不含** `grassySoil.img`，但地图层仍引用 `bS=grassySoil`。完整 back 可能在：

- `补丁1.5m.exe`（RAR，需在 Windows 解压）
- 其他整合包（如 MAX3 服务端 wz）

## 流程（登录 → 进游戏）

| 步骤 | 官方 | 本项目 | 状态 |
|------|------|--------|------|
| 标题 | MapLogin2 + Logo | `login_title.json` | ✅ MapLogin2 视差 (22,-1785) |
| 性别 | Login.img Gender | `gender_page.dart` | ✅ 视差背景 |
| 世界/频道 | WorldSelect | `world_select_page.dart` | ✅ 视差 + WZ 面板 |
| 选角 | CharSelect + MapLogin2 | `character_select_page.dart` | ✅ 视差已开 |
| 种族 | RaceSelect | `race_select_page.dart` | ✅ 视差 |
| 创建 | NewChar 6 tab | `new_char_page.dart` | ✅ 视差 + WZ 面板 |
| 进图 | 服务端 spawn | `game_scene_page.dart` | ✅ |

## 逻辑（服务端 + 客户端）

| 项 | 参照 | 状态 |
|----|------|------|
| 初始 MP=50、出生图 | `pkg/utils/constants.go` | ✅ |
| 禁名 / 外观白名单 | `ForbiddenName.img` + `beginner_look.go` | ✅ |
| 079 键位 ←→ Ctrl Z | `game_controls.dart` | ✅ |
| 横版移动（仅 X） | `game_world.dart` | ✅ |
| Mob 刷新 / AI | `data/maplife` + WS | ✅ |
| 装备栏 `is_equipped` 列 | DB + FindEquipped | ✅ 已修 `character_repository.go` |
| Foothold / 平台碰撞 | Map.wz 导出 | ⚠️ 地面 Y 随 x 变化，无跳跃/多层 |

## 一键同步官方资源

```bash
# 默认使用 ~/Downloads/冒险岛079/extracted_client
./scripts/ingest_full.sh

# 或指定路径
MXD079_CLIENT=/path/to/client ./scripts/ingest_full.sh
```

**不要**再运行 `go run scripts/build_login_scene/main.go`（会生成假街机框背景）。

## 下一步优先级

1. **P0** 解压 `补丁1.5m.exe` 或找含 `Back/grassySoil.img` 的 WZ，补彩虹村视差 PNG  
2. **P0** 实现 Map tile + foothold 渲染（替换 `MapleIslandMapLayer` 程序化山丘）  
3. **P1** 登录标题页 MapLogin2 卷轴动画（非静态 PNG）  
4. **P1** 全量 Character 部件缓存策略（按需 / 全量 ingest）  
5. **P2** UI.img 音效（CharSelect click 等）
