# MapleStory 079 开发进度报告

**项目名称**: MapleStory 079 复刻项目
**创建日期**: 2024-06-12
**当前版本**: v0.9.20
**最后更新**: 2026-06-14 (自动化开发任务周期 #20 执行完毕)
**状态**: ✅ 周期 #20 完成 API 路由补全（combat/items/npcs） ✅ WebSocket 嵌套 payload 协议统一 ✅ room/channel 查询参数兼容 ✅ go vet / go build / go test 全部通过 ⚠️ 客户端资源文件仍缺失（需 WZ 提取，见任务 4） ⚠️ REST 响应格式与客户端部分不一致（见任务 5） ⚠️ game/move 等 4 个路由仍缺失（见任务 8）

---

## 📊 项目统计

### 代码统计
- **Go 源文件**: 52 个 (~8408 行)
- **Dart 源文件**: 43 个 (~9851 行)
- **资源文件**: 7 个 (README 文档 + 资源清单)
- **自动化周期**: #19 (2026-06-14 架构审计 + 构建验证 + 代码量 + 下周期规划 + API联调审计)
- **可执行文件**: 2 个
  - `bin/server` (18MB) - 游戏服务器
  - `bin/init_data` (12MB) - 数据初始化工具

### 项目规模
```
mapleStory079/
├── cmd/                     # 应用入口
│   └── server/main.go       # 服务器启动入口（路由注册 + 初始化）
├── config/                  # 配置文件
│   └── config.yaml          # 数据库/Redis/日志/游戏倍率配置
├── internal/                # 内部包（业务逻辑层）
│   ├── handler/             # HTTP处理器 (9个)
│   │   ├── auth_handler.go        # 认证（注册/登录）
│   │   ├── character_handler.go   # 角色CRUD
│   │   ├── game_handler.go        # 地图/怪物/任务/战斗/升级
│   │   ├── websocket_handler.go   # WebSocket 实时连接与房间
│   │   ├── npc_handler.go         # NPC 对话 / 交互
│   │   ├── inventory_handler.go   # 背包 / 物品
│   │   ├── skill_handler.go       # 技能
│   │   ├── chat_handler.go        # 聊天消息 / 历史
│   │   └── social_handler.go      # 公会 / 组队 / 好友
│   ├── service/             # 业务服务 (10个)
│   │   ├── auth_service.go         # 账号认证
│   │   ├── character_service.go    # 角色逻辑
│   │   ├── game_service.go         # 升级 / 经验 / 恢复 / 复活
│   │   ├── combat_service.go       # PlayerAttackMob / MobAttackPlayer
│   │   ├── npc_service.go          # NPC 对话脚本
│   │   ├── inventory_service.go    # 物品切换 / 装备
│   │   ├── skill_service.go        # 技能释放与冷却
│   │   ├── chat_service.go         # 频道 / 私信 / 持久化
│   │   ├── social_service.go       # 公会 / 组队 / 好友
│   │   └── service.go              # 聚合服务入口
│   ├── repository/          # 数据访问层 (10个)
│   │   ├── account_repository.go
│   │   ├── character_repository.go
│   │   ├── game_repository.go      # 地图 / NPC / 怪物统一管理
│   │   ├── item_repository.go
│   │   ├── item_skill_repository.go
│   │   ├── skill_repository.go
│   │   ├── quest_repository.go
│   │   ├── social_repository.go    # 公会 / 组队 / 好友
│   │   ├── log_repository.go       # 登录 / 交易 / 聊天日志
│   │   └── repository.go           # 基础仓库接口
│   ├── model/               # 业务模型
│   └── middleware/          # 中间件 (7个)
│       ├── cors.go / jwt_auth.go / logger.go
│       ├── rate_limit.go / request_id.go / middleware.go
├── pkg/                     # 公共库（可复用工具包）
│   ├── database/           # 数据库 (database.go / models.go)
│   │   └── models.go       # 17+ 核心数据表定义（Account/Character/Item/Mob/NPC/Map/Quest/Guild/Party/Friend/ChatLog/TradeLog/LoginLog 等）
│   ├── cache/              # 缓存 (cache.go / stats.go) - 带TTL+命中率统计的内存缓存
│   └── utils/              # 工具集 (5个)
│       ├── constants.go    # 职业 / 频道 / 地图 / 倍率 / 敏感词
│       ├── helpers.go      # 字符串 / 切片 / JSON / 反射 / 时间
│       ├── response.go     # 统一响应结构 + 错误码
│       ├── jwt.go          # 安全 token / session id / 过期管理
│       └── utils.go        # 经验公式 / 伤害计算 / 职业加成 / MD5
├── client/                 # Flutter 客户端
│   ├── lib/
│   │   ├── config/         # app_config.dart
│   │   ├── core/           # network / storage / theme
│   │   ├── models/         # 数据模型 (account/character/game_map/mob/item/skill/game_state)
│   │   ├── providers/      # 状态管理 (auth/game/combat/inventory/skill/chat)
│   │   ├── features/       # 功能页面 (login/character/game/combat/inventory/skills/chat/social)
│   │   ├── game/engine/    # Flame 游戏世界骨架 (game_world.dart)
│   │   ├── widgets/        # 组件库 (player_stats/game_chat/mini_map/damage_number/npc_dialogue/skill_bar/stateless_button)
│   │   ├── services/       # 网络服务 (api_service.dart / websocket_service.dart)
│   │   └── main.dart       # 入口（MultiProvider + 路由）
│   ├── assets/
│   │   ├── audio/          # BGM / SFX 资源清单
│   │   ├── images/         # UI / Tile / Map / Items 资源清单
│   │   ├── sprites/        # 角色/怪物/NPC/坐骑精灵资源清单
│   │   └── README.md       # 资源获取指引 + 开源替代资源
│   ├── pubspec.yaml        # 依赖配置 (flame, provider, http, audioplayers, web_socket_channel)
│   └── README.md
├── scripts/                # 辅助脚本
│   └── init_data.go        # 地图/NPC/怪物/物品/技能/任务批量入库
├── EXTERNAL_REF.md  # 外部参考见 ../mapleStory079-external/               # 参考项目
│   ├── HeavenMS/           # Java v83服务端参考
│   ├── ZLHSS2/             # Java v079服务端参考
│   └── OPEN_SOURCE_RESOURCES.md
├── bin/                    # 编译输出
├── Makefile                # make server / make init / make test / make clean
├── PROJECT_PLAN.md         # 完整技术方案
├── API_TEST.md             # API测试指南
├── README.md               # 项目说明
└── DEVELOPMENT_STATUS.md   # 本文件
```

---

## ✅ 已完成功能

### 1. 后端框架 ⭐⭐⭐⭐⭐
- [x] Gin Web 框架集成
- [x] GORM ORM 框架
- [x] MySQL 数据库连接
- [x] 内存缓存系统（带 TTL + 命中率统计）
- [x] 配置管理系统 (Viper)
- [x] 中间件系统（CORS / JWT / 限流 / 请求ID / 日志 / Panic 恢复）

### 2. 数据库系统 ⭐⭐⭐⭐⭐
- [x] 自动建表功能（类似 Hibernate）
- [x] 17 个核心数据表（Account / Character / CharacterStats / CharacterInventory / Item / Skill / Quest / Map / NPC / Mob / Guild / Party / Friend / LoginLog / TradeLog / ChatLog 等）
- [x] 数据模型定义（pkg/database/models.go）
- [x] 数据初始化脚本（scripts/init_data.go）

### 3. 用户认证系统 ⭐⭐⭐⭐⭐
- [x] 用户注册 API
- [x] 用户登录 API
- [x] 密码加密（MD5）
- [x] Token / Session 生成（pkg/utils/jwt.go）

### 4. 角色管理系统 ⭐⭐⭐⭐⭐
- [x] 创建角色
- [x] 获取角色列表（按账号）
- [x] 获取角色详情
- [x] 更新角色信息（属性 / 地图坐标 / 金币等）
- [x] 删除角色
- [x] 角色属性系统（HP/MP/EXP/STR/DEX/INT/LUK/AP/SP/Fame）

### 5. 游戏系统 ⭐⭐⭐⭐⭐
- [x] 地图管理 API（ListMaps / GetMap）
- [x] NPC 管理 API
- [x] 怪物管理 API（ListMobs / GetMob）
- [x] 物品管理 API
- [x] 技能管理 API
- [x] 任务管理 API

### 6. 战斗系统 ⭐⭐⭐⭐⭐
- [x] PlayerAttackMob — 玩家攻击怪物
- [x] MobAttackPlayer — 怪物攻击玩家
- [x] GetCombatStats — 获取战斗属性
- [x] ReviveCharacter — 复活角色
- [x] 命中率计算（等级差 + DEX 影响）
- [x] 暴击率与暴击伤害（飞侠高暴击）
- [x] 按职业划分的伤害计算（战士力量/法师智力/弓箭手敏捷/飞侠运气/海盗混合）
- [x] 怪物闪避（DEX 影响）

### 7. 数据初始化 ⭐⭐⭐⭐⭐
- [x] 地图数据（南港 / 训练场I / 蘑菇林）
- [x] NPC 数据
- [x] 怪物数据（10+怪物）
- [x] 物品数据（23+物品）
- [x] 技能数据（14+技能）
- [x] 任务数据（4+任务）

### 8. WebSocket 实时通信 ⭐⭐⭐⭐⭐
- ✅ WebSocket 连接升级
- ✅ 房间管理（创建/加入/离开）
- ✅ 消息读写泵（readPump/writePump）
- ✅ 玩家消息广播
- ✅ 心跳机制（Ping/Pong）
- ✅ 连接状态管理
- ✅ 服务器路由注册

### 9. Flutter 客户端 ⭐⭐⭐⭐⭐
- ✅ Flutter 项目结构搭建（features/ 分层架构）
- ✅ 登录界面（LoginPage）
- ✅ 角色选择界面（CharacterSelectPage）
- ✅ 游戏主界面（GamePage）
- ✅ 游戏场景页面（GameScenePage - Flame 引擎骨架）
- ✅ 战斗页面（CombatPage）
- ✅ 背包页面（InventoryPage）
- ✅ 技能页面（SkillsPage）
- ✅ 聊天页面（ChatPage）
- ✅ 社交页面（SocialPage）
- ✅ 状态管理（Provider）
  - AuthProvider / GameProvider / CombatProvider / InventoryProvider / SkillProvider / ChatProvider
- ✅ 数据模型
  - Account / Character / GameMap / GameState / Item / Mob / Skill
- ✅ UI 组件库
  - PlayerStats / GameChat / MiniMap / DamageNumber / NpcDialogueWidget / SkillBarWidget / StatelessButton
- ✅ 网络服务（api_service.dart + websocket_service.dart）
- ✅ core/ 层（network / storage / theme）
- ✅ pubspec.yaml 依赖配置

### 10. 服务层完善 ⭐⭐⭐⭐⭐
- ✅ 聊天系统服务层（chat_service.go）
- ✅ 技能系统服务层（skill_service.go）
- ✅ 社交系统服务层（social_service.go）
- ✅ 战斗服务完善（combat_service.go）
- ✅ 游戏服务升级流程（game_service.go — ProcessLevelUp / GainExp / Restore / ReviveCharacter）

### 11. 工具集 & 构建 ⭐⭐⭐⭐⭐
- ✅ 全局常量（pkg/utils/constants.go — 职业 / 频道 / 地图 / 倍率 / 敏感词）
- ✅ 数据初始化工具（scripts/init_data.go）
- ✅ 构建脚本（Makefile — make server / make init / make test / make clean）
- ✅ 辅助函数（helpers.go — 字符串 / 切片 / JSON / 反射 / 时间 / 协程）
- ✅ 统一响应结构（response.go）
- ✅ JWT / Token 工具（jwt.go）
- ✅ 经验公式 & 伤害计算 & 职业加成（utils.go）

### 12. Flutter 架构增强 ⭐⭐⭐⭐⭐
- ✅ core/ 层（network / storage / theme）
- ✅ Flame 游戏世界骨架（game/engine/game_world.dart + sprite_loader.dart）
- ✅ GameScene 页面（features/game/game_scene_page.dart）
- ✅ features/ 目录完整分层（login / character / game / combat / inventory / skills / chat / social）
- ✅ 程序化 TileMap 背景层（不同 mapId 自动分配森林/岩石/浅蓝配色）
- ✅ 玩家/怪物/NPC/远程玩家 Canvas 组件（阴影 + 血条 + 名字 + 朝向）
- ✅ 键盘输入 WASD/方向键 移动 + J/Space 攻击
- ✅ 伤害飘字 DamagePopup（暴击黄字 + 向上淡出）
- ✅ 怪物 AI（近距离追击玩家、远距离随机巡逻）

### 13. 仓库（Repository）模块完善 ⭐⭐⭐⭐⭐
- ✅ account_repository.go
- ✅ character_repository.go
- ✅ game_repository.go（地图 / NPC / 怪物统一管理）
- ✅ item_repository.go
- ✅ item_skill_repository.go
- ✅ skill_repository.go
- ✅ quest_repository.go
- ✅ social_repository.go（公会 / 组队 / 好友）
- ✅ log_repository.go（登录 / 交易 / 聊天日志）
- ✅ repository.go（基础接口）

### 14. 缓存模块完善 ⭐⭐⭐⭐⭐
- ✅ 内存缓存（pkg/cache/cache.go — 线程安全 / TTL / 读写锁）
- ✅ 命中率统计（pkg/cache/stats.go — hits / miss / hitRate / entries）
- ✅ 后台清理协程（StartCleanup）

### 19. 游戏循环 & 服务端对齐 ✅
- ✅ game_world.dart 接入 AudioManager：按 mapId 自动播放 BGM，攻击/升级/死亡播放 SFX
- ✅ 玩家死亡 → HP=0，自动倒计时 5 秒后在出生点复活
- ✅ 怪物 AI 近身攻击玩家（HP 扣减 / mob 等级影响伤害 / 1.2 秒冷却）
- ✅ WebSocket 客户端 sendPosition / sendAttack / sendDamage / sendDead / sendRevive 节流上报
- ✅ WebSocket 服务端 damage/exp/dead/revive/position 消息分发与远程玩家位置同步
- ✅ 经验累计 → 自动升级（递归检测）→ HP/MP 恢复 + 职业加成
- ✅ pkg/utils 扩展：DamageByJob / RollDamage / RollCritical / HitRate / RollHit / RollMesos / RollExpGained / LevelFromExp / ClassPrimaryStat / FormatNumber / ClampInt
- ✅ 编译验证：go vet / go build / go test 全部通过

### 20. Flutter 统一分层 ⭐⭐⭐⭐⭐
- ✅ 删除 `client/lib/pages/` 重复目录（统一使用 `features/`）
- ✅ `main.dart` 中显式注册 `ChatProvider` 到 `MultiProvider`（此前已声明但未注入）
- ✅ `core/theme/app_theme.dart` 暗色/亮色主题基础完成
- ✅ `core/network/http_client.dart` 封装 HTTP 请求
- ✅ `core/storage/storage_service.dart` 本地存储封装（shared_preferences）
- ✅ `game/engine/sprite_loader.dart` 精灵加载器骨架

### 16. 资源清单文档 ⭐⭐⭐⭐⭐
- ✅ 音频资源清单（client/assets/audio/README.md）
- ✅ 贴图资源清单（client/assets/images/README.md）
- ✅ 精灵资源清单（client/assets/sprites/README.md）
- ✅ 开源替代资源指引（../mapleStory079-external/docs-OPEN_SOURCE_RESOURCES.md）

### 17. 业务错误码 & 分页响应 ⭐⭐⭐⭐⭐
- ✅ pkg/utils/response.go: CodeOK / CodeBadRequest / CodeUnauthorized / CodeForbidden / CodeNotFound / CodeInternalError / CodeInvalidParameter / CodeCharacterBanned / CodeInventoryFull / CodeSkillOnCooldown / CodeChatSensitive
- ✅ PageResponse 结构（Total/Page/Size/Records）与 OKPage 工具方法
- ✅ FailWithCode 支持业务错误码
- ✅ 统一的 Response.Time 字段（NowUnix）

### 18. 职业常量对齐 ⭐⭐⭐⭐⭐
- ✅ internal/service/combat_service.go: PlayerAttackMob 暴击/伤害使用 utils.JobThief / utils.JobWarrior 等替代魔数
- ✅ internal/service/game_service.go: ProcessLevelUp 升级 HP/MP 加成使用 utils 职业常量
- ✅ pkg/utils/constants.go: DamageBaseFactor / DamageCeilingFactor / CritMultiplierDefault / CritMultiplierThief 统一
- ✅ pkg/utils/helpers.go: 新增 NowUnix 并去除 jwt.go 中的重复声明

### 19. 编译与测试验证 ✅
- ✅ go vet ./... 全部通过，无编译错误
- ✅ go build ./cmd/server/ 通过
- ✅ go test ./... 全部通过（test/combat_formula_test.go / test/game_service_test.go）
- ✅ inventory_service.go 字段统一（Equipped → IsEquipped，Slot → SlotIndex）
- ✅ npc_service.go PortalScript 地图 ID 类型一致
- ✅ character_handler.go MapID 类型统一
- ✅ game_handler.go 所有字段名统一（Experience→Exp，Str/Dex/Int/Luk → STR/DEX/INT/LUK）

---

## 🎯 API 接口一览

### 认证接口（2个）
```
POST   /api/v1/auth/register        # 注册账号
POST   /api/v1/auth/login           # 登录账号
```

### 角色接口（5个）
```
POST   /api/v1/characters/          # 创建角色
GET    /api/v1/characters/          # 获取角色列表
GET    /api/v1/characters/:id       # 获取角色详情
PUT    /api/v1/characters/:id       # 更新角色
DELETE /api/v1/characters/:id       # 删除角色
```

### 游戏接口（6个+）
```
GET    /api/v1/maps/                # 获取所有地图
GET    /api/v1/maps/:id             # 获取地图详情
GET    /api/v1/mobs/                # 获取所有怪物
GET    /api/v1/mobs/:id             # 获取怪物详情
POST   /api/v1/combat/attack        # 攻击（玩家攻击怪物）
GET    /api/v1/quests/              # 获取所有任务
POST   /api/v1/game/gain-exp        # 获得经验（调试用）
GET    /api/v1/game/state           # 游戏状态
```

### NPC 接口（3个）
```
GET    /api/v1/npcs/:id             # 获取NPC详情
POST   /api/v1/npc/dialogue         # 开始对话
POST   /api/v1/npc/dialogue/continue # 对话继续
```

### 物品 & 背包接口（3个）
```
GET    /api/v1/inventory            # 获取背包列表
POST   /api/v1/inventory/add        # 添加物品
POST   /api/v1/inventory/remove     # 移除物品
```

### 技能接口（2个）
```
GET    /api/v1/skills               # 获取所有技能
GET    /api/v1/skills/:id           # 获取技能详情
```

### 聊天接口（2个）
```
POST   /api/v1/chat/send            # 发送消息
GET    /api/v1/chat/history         # 获取聊天历史
```

### WebSocket 接口（1个）
```
GET    /ws?character_id=1&room=default   # WebSocket 实时通信
```

### 系统接口（1个）
```
GET    /health                      # 健康检查（含缓存命中 / 数据库状态）
```

**总计**: 27+ 个 RESTful API + WebSocket

---

## 🔄 开发进度

| 阶段 | 状态 | 完成度 |
|------|------|--------|
| 基础架构（Gin/GORM/Redis/Viper） | ✅ 完成 | 100% |
| 用户系统（注册/登录/角色） | ✅ 完成 | 100% |
| 游戏系统（地图/怪物/NPC/物品/技能） | ✅ 完成 | 100% |
| 实时通信（WebSocket） | ✅ 完成 | 100% |
| 战斗系统（Player/Mob 攻防） | ✅ 完成 | 100% |
| 后端架构增强（中间件 / JWT / 限流 / 请求ID） | ✅ 完成 | 100% |
| 仓库模块完善（10 个 repository） | ✅ 完成 | 100% |
| Flutter 客户端（8 个 features 页面 + 6 个 providers） | ✅ 完成 | 100% |
| Flame 游戏世界骨架（game_world.dart） | ✅ 完成 | 100% |
| Flame 游戏循环 / 键盘输入 / 伤害飘字 | ✅ 完成 | 100% |
| 工具函数完善（5 个 utils 模块） | ✅ 完成 | 100% |
| 缓存统计 & 命中率 | ✅ 完成 | 100% |
| 编译验证（go vet / go build / go test） | ✅ 完成 | 100% |
| 程序化 TileMap / 怪物 AI / 远程玩家 | ✅ 完成 | 100% |
| 精灵动画加载 / 多人同步 | ⏳ 待开始 | 0% |
| 资源自动化抽取脚本（wz → assets） | ⏳ 待开始 | 0% |
| 性能优化 / 压力测试 | ⏳ 待开始 | 0% |

---

## 🗂 冒险岛 079 资源文件参考（外部搜索结果）

根据公开资料（CSDN / Bilibili）整理，完整的 V079 客户端 `WZ` 目录一般包含以下资源文件：

| WZ 文件 | 用途 | 对应 assets 目录 |
|---|---|---|
| `Base.wz` | 基础信息 / 全局配置 | - |
| `Character.wz` | 角色、装备、武器图像与动画 | `assets/sprites/player/`、`assets/sprites/equipment/` |
| `Effect.wz` | 技能特效、屏幕特效 | `assets/sprites/effects/` |
| `Map.wz` | 地图背景、地形、迷你地图、BGM 索引 | `assets/images/maps/`、`assets/audio/` |
| `Mob.wz` | 所有怪物图像与动画 | `assets/sprites/mobs/` |
| `Morph.wz` | 变身 / 骑宠动画 | `assets/sprites/mounts/` |
| `Npc.wz` | NPC 图像与对话基础数据 | `assets/sprites/npcs/` |
| `Skill.wz` | 技能图标、数据、特效 | `assets/images/skills/` |
| `String.wz` | 文本（物品 / 任务 / NPC / 地图名） | -（数据库字符串） |
| `Sound.wz` | 音效与 BGM | `assets/audio/` |
| `Item.wz` | 物品图标与文本 | `assets/images/items/` |
| `Quest.wz` | 任务对话与触发 | -（数据库脚本） |
| `Reactor.wz` | 地图机关 / 可击物体 | - |
| `TramingMob.wz` | 骑宠相关属性与动画 | `assets/sprites/mounts/` |
| `UI.wz` | 用户界面图像 | `assets/images/ui/` |

**备注**：在部分纯净 079 客户端中，还可能存在 `PATCH`/`PACK` 目录（用于游戏在读取原始 WZ 前优先加载自定义补丁），以及 `Sound` 目录（用于存放一些未打包的 `.wav` 音效）。这些资源在复刻项目中可通过脚本工具解包为 PNG/OGG 后导入 `client/assets/` 对应子目录。

---

## 📈 下一步计划

### 本周期已完成（周期 #1）
1. ✅ **架构审计** — 确认 cmd/internal/pkg/config/scripts/docs/test/deploy/examples 目录齐全；9 个 handler + 10 个 service + 10 个 repository + 7 个 middleware；pkg/utils/cache/database 三层完整；routes.go 显式装配中间件链
2. ✅ **资源清单审计** — audio/images/sprites 三类资源 README 齐全；城镇 BGM 15 首 + 野外 8 首 + BOSS/副本 8 首 + SFX 13 项；玩家/怪物/NPC/坐骑/宠物/传送门精灵清单齐全
3. ✅ **Flutter 客户端审计** — features/login/character/game/combat/inventory/skills/chat/social 9 个页面完整；providers/auth/game/combat/inventory/skill/chat 完整；core/network/storage/theme/resources 完整；pubspec.yaml 依赖 flame/flame_audio/audioplayers/provider/http/web_socket_channel/shared_preferences 齐全
4. ✅ **游戏核心逻辑审计** — Character 模型 HP/MP/EXP/STR/DEX/INT/LUK/AP/SP/Mesos/Fame 齐全；CombatService PlayerAttackMob/MobAttackPlayer/命中率/暴击/职业伤害公式；GameService 升级流程；game_world.dart WASD/J/Space 键盘输入 + 怪物 AI 追击巡逻 + 伤害飘字
5. ✅ **编译/测试验证** — go vet ./... 通过；go build ./cmd/server 通过；go test ./... 全部通过
6. ✅ **代码量统计** — Go 7616 行 / Dart 8815 行 / 资源 7 个

### 立即任务（下一个周期 #2）
1. **Flame 精灵动画控制器真实化** — 为 `sprite_loader.dart` 提供可选的 CC0 精灵图片替换程序化占位，按职业/动作分目录加载，玩家/怪物/NPC 显示真实精灵序列帧
2. **多人实时位置同步协议 E2E** — `internal/handler/websocket_handler.go` 的 12 类消息（chat/position/move/attack/damage/exp/loot/dead/revive/system/ping/levelup）在 `client/lib/services/websocket_service.dart` 中与 `game_world.dart` 对接，远程玩家实体动态出现/消失
3. **战斗结果回写数据库** — `internal/service/combat_service.go` PlayerAttackMob 击杀怪物时由 handler 统一更新 player HP/EXP 与怪物状态，避免重复计算；加入 GORM 事务
4. **GameScene 页面与 GameProvider 双向绑定** — `features/game/game_scene_page.dart` 的 `_gameWorld` 运行时 HP/MP/等级/经验自动同步到 `GameProvider`，UI PlayerStats widget 实时刷新
5. **AudioManager 真实化** — 接入 flame_audio 播放 SFX（攻击/升级/死亡/拾取/传送门），BGM 按 mapId 映射 assets/audio 资源，音频缺失时静默而不是崩溃
6. **wz 资源抽取工具** — 在 `scripts/` 新增 Go CLI 工具，支持将 wz 资源（公开测试数据）转为 PNG/OGG 放到 `client/assets/`
7. **压力测试** — 100 并发 WebSocket 广播下的延迟/内存/CPU 表现，输出基准报告

### 短期任务（本月）
1. Flutter Flame 地图瓦片渲染
2. 角色移动动画控制（键盘 + 触摸摇杆）
3. 战斗界面 UI 完善（HP/MP 实时条、伤害飘字动画）
4. NPC 对话 UI（使用 NpcDialogueWidget）
5. 物品栏 UI（拖放 + 装备切换）
6. 技能栏 UI（冷却倒计时）

### 中期任务（本季度）
1. 怪物 AI 服务器端（追击 / 巡逻 / 技能）
2. 任务脚本系统（NPC 触发任务 / 奖励发放）
3. 交易系统（玩家间交易）
4. 多人在线同步（位置 / 动作 / 聊天）

### 长期任务（未来）
1. 公会系统（Guild CRUD + 公会战）
2. 组队系统（Party CRUD + 组队经验分配）
3. 活动系统（节日活动 / 限时活动）
4. 排行榜（等级 / 财富 / 击杀）

---

## 🛠 技术栈

### 后端
- **语言**: Go 1.21+
- **框架**: Gin 1.9.1
- **ORM**: GORM 1.9.16
- **数据库**: MySQL 8.0+
- **配置**: Viper 1.15.0
- **WebSocket**: gorilla/websocket v1.5.3
- **缓存**: 内存缓存（pkg/cache）→ 可扩展为 Redis

### 客户端（Flutter）
- **Flutter SDK**: 3.44.0+
- **Dart**: 3.12+
- **状态管理**: provider 6.0.5
- **网络请求**: http 1.1.0
- **实时通信**: web_socket_channel 2.4.0
- **音频**: audioplayers 5.1.0
- **游戏引擎**: flame 1.10.1 + flame_audio 2.1.2
- **本地存储**: shared_preferences 2.2.0

### 参考项目
- HeavenMS（Java v83服务端）
- ZLHSS2（Java v079服务端）
- cc-079-ms（Java v079模拟器）

---

## 📚 文档资源

| 文档 | 位置 |
|------|------|
| 完整技术方案 | `PROJECT_PLAN.md` |
| API 测试指南 | `API_TEST.md` |
| 项目说明 | `README.md` |
| 客户端说明 | `client/README.md` |
| 开发状态报告 | `DEVELOPMENT_STATUS.md`（本文件） |
| 参考源码 | `../mapleStory079-external/05-HeavenMS-v83参考-服务端架构-已归档/`、`../mapleStory079-external/06-ZLHSS2-079参考-中文全栈私服/` |
| 开源资源指引 | `../mapleStory079-external/docs-OPEN_SOURCE_RESOURCES.md` |

---

## ⚠️ 已知问题

1. **首次编译依赖下载**：首次 `go mod tidy` / `flutter pub get` 需联网下载依赖
2. **数据库手动创建**：需要手动 `CREATE DATABASE IF NOT EXISTS maplestory DEFAULT CHARSET utf8mb4`
3. **Redis 可选**：当前使用内存缓存，生产环境可替换 Redis 实现（pkg/cache 已有统一接口）
4. **游戏渲染资源**：Flame 引擎骨架已完成，地图瓦片 / 精灵图尚需导入 wz 或 CC0 资源
5. **main.go 路由职责过大**：`cmd/server/main.go` 中 `registerXXXRoutes` 函数共近 90 行，建议后期迁移到 `internal/handler/routes.go` 统一管理
6. **路由-handler 绑定**：`/game/state → ListMaps` 与 `/game/gain-exp → Attack` 属于快速原型遗留，建议拆分为独立 handler 方法

---

## 💡 架构优化建议

### 性能优化
1. 引入 Redis 替代内存缓存（pkg/cache 已设计统一接口）
2. 为 Character / Mob / Map 表添加二级索引
3. WebSocket 消息启用 gzip 压缩
4. 怪物 AI 与战斗逻辑移至独立 goroutine 池

### 安全性
1. 密码哈希从 MD5 升级为 bcrypt / argon2
2. WebSocket 消息签名验证
3. API 请求签名（HMAC-SHA256）
4. 速率限制细化（按 IP / 按 user_id / 按 endpoint）

### 扩展性
1. 拆分微服务（auth-server / game-server / chat-server）
2. 引入 RabbitMQ 异步任务（技能冷却 / 战斗日志）
3. 容器化部署（Dockerfile 已有，可扩展 docker-compose 生产版）
4. Redis Pub/Sub 替代内存广播实现集群 WebSocket

---

## 🎉 成就
- ✅ 完成完整的 MVC 分层架构（handler → service → repository → database）
- ✅ 实现 GORM 自动数据库迁移（17+ 表）
- ✅ 完成 27+ 个 RESTful API + WebSocket
- ✅ 10 个 service 服务 + 10 个 repository + 9 个 handler + 7 个 middleware
- ✅ 5 个 pkg/utils 工具模块（constants / helpers / jwt / response / utils）
- ✅ Flutter 8 个 features 页面 + 6 个 providers + 完整 widgets 库
- ✅ Flame 游戏世界骨架 + 精灵加载器
- ✅ 编译验证通过：go vet / go build / go test
- ✅ Makefile 一键构建
- ✅ 自动化架构审计完成（定期执行）

---

**版本**: v0.9.19
**本周期 (#19) 已完成**:
- ✅ 架构定期审计：cmd/internal/pkg/config/scripts/docs/test/deploy/examples 目录完整；9 个 handler / 10 个 service / 10 个 repository / 7 个 middleware 全量覆盖
- ✅ `go vet ./...` 通过（无 warning 无 error）
- ✅ `go build ./cmd/server/` 通过（无 warning 无错误）
- ✅ `go test ./...` 全部通过（`test/combat_formula_test.go` + `test/game_service_test.go`）
- ✅ 代码量统计：Go 52 文件 / 8408 行；Dart 43 文件 / 9851 行；资源文件 7 个
- ✅ Flutter features/ 8 个页面完整；providers/ 6 个完整注册在 `main.dart`；services/ 2 个；widgets/ 8 个；game/engine/ 2 个；core/ 4 个；config/ 1 个
- ✅ `routes.go` 路由拆分 + 中间件链显式装配（RequestID / Recovery / CORS / Logger / RateLimit）
- ✅ `/api/v1/guilds` `/api/v1/parties` `/api/v1/friends` 社交组路由验证
- ✅ pkg/utils/constants.go、helpers.go、jwt.go、response.go、utils.go 五模块工具函数齐全
- ✅ 游戏核心逻辑审计：HP/MP/EXP/STR/DEX/INT/LUK/AP/SP/Mesos/Fame 齐全；PlayerAttackMob/MobAttackPlayer/升级流程/WASD+J+Space 完整
- ✅ 资源清单审计：audio/images/sprites 三类资源 README 齐全；城镇 BGM 15 首 + 野外 8 首 + BOSS/副本 8 首 + SFX 13 项；玩家/怪物/NPC/坐骑/宠物/传送门精灵清单齐全
- ✅ 游戏核心逻辑修复确认：AP/SP 自动分配在 `LevelUp()` 和 `ProcessLevelUp()` 中已确认实现；职业差异化 HP/MP 增量通过 `getLevelUpHPMP()` 和 `JobLevelUpStatsMap` 已确认实现
- ✅ API联调审计：对比 `api_service.dart` 和 `routes.go`，发现 6 个客户端调用但后端缺失的接口
- ✅ WebSocket协议审计：对比 `websocket_handler.go` 和 `websocket_service.dart`，发现 12 类消息格式不匹配（嵌套 payload vs 顶层字段）
- ✅ 版本一致性检查：16 项检查中 14 项 ✅，2 项 ⚠️（API完整性、WebSocket协议）

**下一步 (周期 #20)**:
1. **补充缺失后端路由接口（高优先级）** — `POST /api/v1/combat/calculate-damage` / `player-attack-mob` / `mob-attack-player`、`GET /api/v1/combat/stats`、`GET /api/v1/items`、`GET /api/v1/npcs/map/:id`
2. **统一 WebSocket 消息协议格式（高优先级）** — 服务端接受 `{"type", "payload": {...}, "sender_id", "room"}`，与客户端 `WebSocketService` 一致
3. **补充缺失战斗接口 handler（高优先级）** — `GET /api/v1/combat/stats`、`POST /api/v1/combat/revive`
4. **放置 CC0 占位资源（中优先级）** — `client/assets/` 放置真实 OGG/PNG，`sprite_loader.dart` 真实加载 assets 资源
5. **GameProvider 双向绑定（中优先级）** — `game_scene_page.dart` 的 `_gameWorld` 运行时 HP/MP/等级/经验自动同步到 `GameProvider`
6. **完整任务清单与详细说明见 `.next_tasks.md`**

---

## 🧐 周期 #19 — 资源/接口/版本一致性联合检查（追加）

**检查时间**: 周期 #19 执行（本次）
**检查范围**: 客户端资源清单 × 079 游戏数据 × API 联调 × WebSocket 协议 × 游戏核心逻辑

### ✅ 通过项
- **资源清单完整性（audio/images/sprites）**: 三个 `README.md` 已详细列出全部资源名称/目录结构/预估数量
- **079 核心数据（地图/怪物/NPC/物品/技能/任务）**: `scripts/init_data.go` 中 6 个 `seed*()` 函数全部可用，`FirstOrCreate` 幂等
- **Flutter 页面与 Provider 完整性**: `features/` 8 页面 + `providers/` 6 个 + `widgets/` 8 个 + `services/` 2 个 + `game/engine/` 2 个
- **WebSocket 房间与 12 类消息**: `websocket_handler.go` 已涵盖 ping/pong/chat/position/move/attack/damage/exp/loot/dead/revive/system
- **编译与单测**: `go vet` / `go build` / `go test` 三项全通过
- **游戏核心逻辑**: AP/SP 自动分配已确认实现；职业差异化 HP/MP 增量已确认实现

### 🚨 发现的 5 个待修复问题（已写入 `.version_checklist.md`）
1. **客户端 API 与后端路由不匹配** — api_service.dart 调用了 6 个在 routes.go 中不存在的接口
2. **WebSocket 消息字段协议不一致** — Dart 嵌套 `payload{}`，Go 要求顶层字段
3. **资源实际文件缺失** — `client/assets/*/` 只有 README，缺失 OGG/PNG
4. **AP/SP 自动分配逻辑** — ✅ 已确认在 `game_service.go` 中实现
5. **职业差异化 HP/MP 增量** — ✅ 已确认在 `game_service.go` 中实现

### 📊 代码量统计（本次检查时）
- **Go 文件**: 52 个 / **8408 行**
- **Dart 文件**: 43 个 / **9851 行**
- **资源文件**: 7 个（全部为 README/清单文件）

### 📎 关联新增文件（本次检查产物）
- `.next_tasks.md` — 周期 #20 任务清单（共 9 个任务，3 高/3 中/3 低）
- `.version_checklist.md` — 版本一致性检查清单（16 项，87.5% 完成度）

