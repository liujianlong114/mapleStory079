# 冒险岛079复刻项目 - 架构设计文档

## 1. 整体架构

本项目采用前后端分离架构，后端使用 Go + Gin 提供 REST API 和 WebSocket 实时通信服务，前端使用 Flutter 构建跨平台的 2D 横版卷轴游戏客户端。

```
┌─────────────────────────────────────────────────────────────┐
│                        Flutter 客户端                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ 登录模块  │  │ 游戏场景 │  │ 战斗系统 │  │ 社交系统 │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│         ↓ HTTP + WebSocket (Dart: http / web_socket_channel) │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      Gin Web 服务器                           │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │ 中间件层    │  │  Handler 层 │  │  WebSocket │            │
│  │ JWT/CORS/  │  │ 路由分发    │  │ 实时消息   │            │
│  │ RateLimit  │  │            │  │ 房间管理   │            │
│  └────────────┘  └────────────┘  └────────────┘            │
│                              ↓                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   Service 层 (业务逻辑)               │   │
│  │  auth/character/game/combat/chat/npc/skill/inventory │   │
│  └─────────────────────────────────────────────────────┘   │
│                              ↓                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                Repository 层 (数据访问)                │   │
│  │  character/game/quest/social/log/item/skill/account │   │
│  └─────────────────────────────────────────────────────┘   │
│                              ↓                               │
│  ┌─────────────┐   ┌─────────────┐   ┌───────────────┐     │
│  │   MySQL 8.0 │   │   Redis 6.0 │   │   pkg/utils   │     │
│  │ 游戏数据/用户 │   │  会话/缓存   │   │   工具函数集  │     │
│  └─────────────┘   └─────────────┘   └───────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

## 2. 分层架构说明

### 2.1 中间件层 (internal/middleware)
- **JWT Auth**: Bearer token 验证，会话黑名单管理
- **CORS**: 跨域请求处理，可配置源
- **Rate Limit**: IP 限流，防止接口滥用
- **Request ID**: 请求链路追踪
- **Panic Recovery**: 服务器异常恢复
- **Logger**: 结构化日志记录

### 2.2 Handler 层 (internal/handler)
- **auth_handler**: 注册 / 登录 / 登出
- **character_handler**: 角色 CRUD / 列表
- **game_handler**: 地图/NPC/怪物/物品/技能/任务/升级/移动/状态/WebSocket
- **combat_handler**: 战斗攻击/伤害计算/复活
- **chat_handler**: 频道消息/私聊/广播
- **inventory_handler**: 背包/装备/消耗/丢弃
- **skill_handler**: 技能列表/使用/战斗技能
- **npc_handler**: NPC对话/脚本/商店
- **websocket_handler**: 房间管理/消息广播/心跳保活

### 2.3 Service 层 (internal/service)
负责核心业务逻辑实现。关键服务：
- **combat_service**: PlayerAttackMob / MobAttackPlayer / 伤害公式 / 暴击 / 命中率 / 掉落
- **game_service**: 地图管理/NPC交互/经验升级/移动/属性点/状态
- **chat_service**: 多频道聊天/私聊历史/速率限制
- **inventory_service**: 物品背包管理/装备系统
- **skill_service**: 技能释放/MP消耗/冷却
- **npc_service**: NPC对话脚本/转职/商店

### 2.4 Repository 层 (internal/repository)
负责数据访问与持久化：
- **character_repository**: 角色CRUD/位置更新/属性更新
- **game_repository**: 地图/NPC/怪物 统合管理
- **quest_repository**: 任务CRUD/按NPC筛选
- **social_repository**: 公会/组队/好友
- **log_repository**: 登录/交易/聊天日志
- **item_repository**: 物品CRUD/分页/类型筛选
- **skill_repository**: 技能数据管理
- **account_repository**: 账号/密码哈希

### 2.5 公共包 (pkg/)
- **database**: GORM 模型定义 / DB 初始化 / 健康检查
- **cache**: 内存缓存 / 命中率统计
- **utils**: JWT / 响应格式 / 字符串 / 数字 / 切片 / 时间 / 反射 / 职业工具

## 3. 数据库设计核心

### 3.1 核心表
| 表名 | 用途 | 主要字段 |
|-----|-----|---------|
| accounts | 账号 | username/password/email/status |
| characters | 角色 | name/class/level/exp/hp/mp/str/dex/int/luk |
| character_stats | 角色扩展属性 | attack/defense/accuracy/avoidability/speed/jump |
| character_inventory | 背包 | item_id/slot/quantity/is_equipped |
| items | 物品表 | name/type/price/level_req/属性 |
| skills | 技能表 | name/job_class/level_req/mp_cost/damage_ratio |
| mobs | 怪物表 | name/level/hp/attack/defense/exp_reward |
| maps | 地图表 | name/width/height/background/music |
| npcs | NPC表 | name/map_id/pos/scripts/has_shop |
| quests | 任务表 | name/npc_id/level_req/exp/mesos |
| guilds | 公会表 | name/master_id/members/level/point |
| parties | 组队表 | leader_id/members/map_id |
| friends | 好友表 | character_id/friend_id/group |
| login_logs | 登录日志 | ip/user_agent/status |
| trade_logs | 交易日志 | sender/receiver/item_id/mesos |
| chat_logs | 聊天日志 | character_id/channel/message |

### 3.2 角色属性设计
- **主要属性**: STR(力量) / DEX(敏捷) / INT(智力) / LUK(幸运)
- **次要属性**: HP / MP / 攻击力 / 防御力 / 命中率 / 回避率 / 速度 / 跳跃
- **升级公式**: 每个职业有独立的 HP/MP 成长曲线和 AP/SP 分配策略

## 4. 战斗系统设计

### 4.1 伤害公式
```
基础攻击 = 职业公式(等级, 主属性, 副属性)
实际攻击 = 基础攻击 - 随机浮动(±20%)
伤害 = (实际攻击 - 防御/2) × 技能倍率 × 暴击倍率(1.5~2.0)
最小伤害 = 1
```

### 4.2 命中率公式
```
基础命中率 = 0.75 + DEX/200
等级差修正: 目标等级高时降低3%/级，目标等级低时增加2%/级
范围: 10% ~ 95%
```

### 4.3 暴击率公式
```
基础暴击率 = 0.03 + LUK/200
职业修正: 弓箭手+5%, 飞侠+8%
等级加成: 每级+0.2%
上限: 40%
```

## 5. 网络协议

### 5.1 REST API 路径规范
```
POST   /api/v1/auth/register     # 注册
POST   /api/v1/auth/login        # 登录
GET    /api/v1/game/state        # 游戏状态
POST   /api/v1/combat/player-attack-mob  # 玩家攻击怪物
POST   /api/v1/game/move         # 移动
GET    /ws?character_id=1&room=default  # WebSocket连接
```

### 5.2 WebSocket消息协议
```json
{
  "type": "chat|move|attack|system",
  "sender_id": 1,
  "room": "default",
  "payload": { ... },
  "timestamp": 1718000000
}
```

## 6. 项目目录规范

```
mapleStory079/
├── cmd/server/           # 应用入口
├── internal/             # 私有应用代码
│   ├── handler/          # HTTP处理器
│   ├── service/          # 业务逻辑层
│   ├── repository/       # 数据访问层
│   ├── model/            # 内部数据模型
│   └── middleware/       # 中间件
├── pkg/                  # 公共库
│   ├── database/         # 数据库模块
│   ├── cache/            # 缓存模块
│   └── utils/            # 工具函数
├── config/               # 配置文件
├── scripts/              # 脚本/初始化数据
├── client/               # Flutter客户端
│   ├── lib/
│   │   ├── features/     # 功能模块
│   │   ├── providers/    # 状态管理
│   │   ├── models/       # 数据模型
│   │   ├── services/     # 网络服务
│   │   ├── widgets/      # 组件库
│   │   └── config/       # 配置
│   └── assets/           # 静态资源
├── docs/                 # 文档（新增）
├── test/                 # 测试（新增）
├── deploy/               # 部署（新增）
├── examples/             # 参考项目
├── bin/                  # 编译输出
├── Makefile              # 构建工具
├── Dockerfile            # Docker镜像
├── docker-compose.yml    # 本地编排
├── PROJECT_PLAN.md       # 完整技术方案
├── DEVELOPMENT_STATUS.md # 开发进度
├── API_TEST.md           # 接口测试指南
└── README.md             # 项目说明
```

## 7. 技术栈版本

| 组件 | 版本 | 用途 |
|-----|-----|-----|
| Go | 1.21+ | 后端语言 |
| Gin | v1.9.1 | Web框架 |
| GORM | v1.9.16 | ORM |
| gorilla/websocket | v1.5.3 | WebSocket |
| Viper | v1.15.0 | 配置管理 |
| MySQL | 8.0+ | 关系型数据库 |
| Redis | 6.0+ | 缓存/会话 |
| Flutter | 3.x+ | 客户端框架 |
| Dart | 3.x+ | 客户端语言 |
| Provider | 6.0.5 | 状态管理 |
| http | 1.1.0 | HTTP请求 |
| web_socket_channel | 2.4.0 | WebSocket |
| audioplayers | 5.1.0 | 音频播放 |
| flame | 1.10.1 | 2D游戏引擎 |
| shared_preferences | 2.2.0 | 本地存储 |
