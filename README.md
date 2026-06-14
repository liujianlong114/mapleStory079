# 冒险岛079复刻项目 (MapleStory 079 Remake)

## 项目简介

本项目旨在完整复刻国服冒险岛Online 079版本，从登录界面音乐到游戏贴图、功能玩法实现一比一还原。

- **后端**: Golang 1.21+ / Gin 1.9.1 / GORM (自动建表，类似Hibernate)
- **客户端**: Flutter 3.x / Dart 3.x / Flame 1.10.1 (2D 游戏引擎)
- **数据库**: MySQL 8.0+
- **实时通信**: WebSocket
- **版本**: v0.9.15

⚠️ **重要提示**: 本项目仅供学习研究使用，不得用于商业用途，请尊重原作版权。

---

## 项目结构

```
mapleStory079/
├── cmd/                      # 应用入口
│   └── server/main.go       # 游戏服务器入口
├── config/                   # 配置文件
│   └── config.yaml          # 服务器配置
├── internal/                 # 内部包（业务逻辑）
│   ├── handler/             # HTTP处理器
│   │   ├── auth_handler.go       # 认证
│   │   ├── character_handler.go  # 角色
│   │   ├── game_handler.go       # 游戏核心
│   │   └── websocket_handler.go  # WebSocket实时通信
│   ├── service/             # 业务逻辑层
│   │   ├── auth_service.go
│   │   ├── character_service.go
│   │   └── game_service.go
│   ├── repository/          # 数据访问层 (Repository)
│   │   ├── account_repository.go
│   │   ├── character_repository.go
│   │   ├── game_repository.go
│   │   └── item_skill_repository.go
│   └── middleware/          # 中间件
├── pkg/                      # 公共库
│   ├── database/            # 数据库模块 (GORM)
│   │   ├── database.go      # 数据库连接和自动迁移
│   │   └── models.go        # 17个核心数据模型
│   ├── cache/               # 缓存模块
│   └── utils/               # 工具函数
├── scripts/                  # 脚本
│   └── init_data.go        # 数据初始化脚本
├── bin/                      # 编译输出（自动生成）
│   ├── server              # 游戏服务器
│   └── init_data           # 数据初始化工具
├── client/                   # Flutter客户端
│   ├── pubspec.yaml        # Flutter依赖配置
│   ├── README.md           # 客户端文档
│   └── lib/
│       ├── main.dart       # 客户端入口
│       ├── config/         # 配置
│       ├── core/           # 网络/存储/主题/资源
│       ├── models/         # 数据模型
│       ├── providers/      # 状态管理
│       ├── features/       # 功能页面（login/character/game/combat/inventory/skills/chat/social）
│       ├── game/           # Flame 游戏引擎层
│       ├── services/       # 网络服务
│       └── widgets/        # 组件库
├── EXTERNAL_REF.md  # 外部参考见 ../mapleStory079-external/                 # 开源项目参考
│   ├── HeavenMS/           # v83服务端
│   ├── ZLHSS2/             # v079服务端
│   └── OPEN_SOURCE_RESOURCES.md
├── PROJECT_PLAN.md          # 完整技术方案
├── DEVELOPMENT_STATUS.md    # 开发进度报告
├── API_TEST.md             # API测试指南
└── README.md               # 本文件
```

---

## 快速开始（5分钟启动）

### 1. 前置条件

确保已安装以下软件：

| 软件 | 版本要求 | 验证命令 |
|------|---------|---------|
| Go | 1.21+ | `go version` |
| MySQL | 8.0+ | `mysql --version` |
| Flutter | 3.44+ | `flutter --version` |

### 2. 克隆项目

```bash
git clone <your-repo-url>
cd mapleStory079
```

### 3. 配置数据库

```bash
# 登录MySQL并创建数据库
mysql -u root -p

# 在MySQL中执行
CREATE DATABASE IF NOT EXISTS maplestory DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 4. 修改配置文件

编辑 `config/config.yaml`：

```yaml
server:
  host: 0.0.0.0
  port: 8080
  mode: debug  # 生产环境改为 release

database:
  driver: mysql
  host: localhost
  port: 3306
  username: root
  password: your_password  # 修改为你的MySQL密码
  database: maplestory
  charset: utf8mb4
  parseTime: true
  autoMigrate: true  # 自动建表（类似Hibernate）

redis:
  host: localhost
  port: 6379
  password: ""
  db: 0
```

### 5. 编译并运行

```bash
# 设置Go代理（国内用户推荐）
export GOPROXY=https://goproxy.cn,direct

# 编译服务器
go build -o bin/server ./cmd/server/

# 编译数据初始化工具
go build -o bin/init_data ./scripts/

# 启动服务器（会自动创建17个数据表）
./bin/server
```

如果看到以下输出，说明启动成功：

```
Database connected successfully
Starting auto migration...
Auto migration completed successfully
Server is running on http://0.0.0.0:8080
```

### 6. 初始化游戏数据（可选但推荐）

```bash
# 另开一个终端，运行数据初始化工具
# 这会插入地图、NPC、怪物、物品、技能、任务等基础数据
./bin/init_data
```

输出示例：
```
Starting data initialization...
Created map: 彩虹岛
Created map: 射手村
...
Created NPC: 导航宠物
...
Created Mob: 绿蜗牛
...
Data initialization completed!
```

### 7. 验证服务

打开浏览器或使用curl测试：

```bash
# 健康检查
curl http://localhost:8080/health

# 预期输出
{"status":"ok","message":"MapleStory 079 Server is running"}
```

---

## 完整API接口列表（30+接口）

### 🔐 认证接口

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | `/api/v1/auth/register` | 用户注册 |
| POST | `/api/v1/auth/login` | 用户登录 |

### 👤 角色接口

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | `/api/v1/characters/` | 创建角色 |
| GET | `/api/v1/characters/?account_id=1` | 获取账号角色列表 |
| GET | `/api/v1/characters/:id` | 获取角色详情 |
| PUT | `/api/v1/characters/:id` | 更新角色 |
| DELETE | `/api/v1/characters/:id` | 删除角色 |

### 🗺️ 地图接口

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/api/v1/maps/` | 获取所有地图 |
| GET | `/api/v1/maps/:id` | 获取地图详情 |
| POST | `/api/v1/maps/` | 创建地图 |

### 👥 NPC接口

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/api/v1/npcs/:id` | 获取NPC详情 |
| GET | `/api/v1/npcs/map/:map_id` | 获取地图上的NPC列表 |
| POST | `/api/v1/npcs/interact/:id` | 与NPC交互 |

### 👹 怪物接口

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/api/v1/mobs/` | 获取所有怪物 |
| GET | `/api/v1/mobs/:id` | 获取怪物详情 |

### 🎒 物品接口

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/api/v1/items/` | 获取所有物品 |
| GET | `/api/v1/items/:id` | 获取物品详情 |

### ⚔️ 技能接口

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/api/v1/skills/` | 获取所有技能 |
| GET | `/api/v1/skills/:id` | 获取技能详情 |

### 📋 任务接口

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/api/v1/quests/` | 获取所有任务 |
| GET | `/api/v1/quests/:id` | 获取任务详情 |

### ⚔️ 战斗系统接口

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | `/api/v1/combat/calculate-damage` | 计算伤害 |
| POST | `/api/v1/combat/calculate-levelup` | 计算升级 |

### 🎮 游戏核心接口（新增）

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/api/v1/game/state?character_id=1` | 获取角色游戏状态（地图、位置、属性） |
| POST | `/api/v1/game/move` | 更新角色位置坐标 |
| POST | `/api/v1/game/gain-exp` | 获取经验值（击杀怪物后调用） |
| POST | `/api/v1/game/levelup/:id` | 角色升级（GM/测试用） |
| POST | `/api/v1/game/add-ap` | 添加能力点（STR/DEX/INT/LUK） |
| POST | `/api/v1/game/restore` | 恢复HP/MP |

### 🌐 WebSocket实时通信

| 协议 | 路径 | 描述 |
|------|------|------|
| WS | `/ws?character_id=1&room=default` | 实时聊天、位置同步、消息广播 |

---

## API快速测试指南（curl示例）

### 1. 用户注册

```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123",
    "email": "test@example.com"
  }'

# 预期输出
{"message":"registration successful"}
```

### 2. 用户登录

```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'

# 预期输出（包含account_id）
{"message":"login successful","data":{"id":1,"username":"testuser",...}}
```

### 3. 创建角色（6种职业可选）

```bash
# 职业代码: 0=新手, 1=战士, 2=法师, 3=弓箭手, 4=飞侠, 5=海盗
curl -X POST http://localhost:8080/api/v1/characters/ \
  -H "Content-Type: application/json" \
  -d '{
    "account_id": 1,
    "name": "战神",
    "class": 1,
    "gender": 0
  }'

# 预期输出
{
  "message": "character created",
  "data": {
    "id": 1,
    "name": "战神",
    "class": 1,
    "level": 1,
    "hp": 80,
    "max_hp": 80,
    "mp": 4,
    "max_mp": 4,
    "str": 35,
    "dex": 15,
    "int": 4,
    "luk": 4,
    "mesos": 500
  }
}
```

### 4. 获取游戏状态

```bash
curl "http://localhost:8080/api/v1/game/state?character_id=1"

# 预期输出（包含角色完整信息、地图、位置、经验进度）
{
  "character": {...},
  "map": {"id": 10000, "name": "彩虹岛", ...},
  "npcs": [...],
  "state": {
    "required_exp": 10,
    "exp_progress": 0.0,
    "critical_rate": ...,
    "hp_percentage": 100.0,
    "mp_percentage": 100.0,
    "position": {"x": 0, "y": 0},
    "class_name": "战士"
  }
}
```

### 5. 获取经验值（模拟击杀怪物）

```bash
curl -X POST http://localhost:8080/api/v1/game/gain-exp \
  -H "Content-Type: application/json" \
  -d '{
    "character_id": 1,
    "exp_amount": 15
  }'

# 预期输出
{
  "gained_exp": 15,
  "current_level": 2,
  "current_exp": 5,
  "leveled_up": true,
  "hp_bonus": 20,
  "mp_bonus": 2,
  "ap_bonus": 5,
  "sp_bonus": 0,
  "max_hp": 100,
  "max_mp": 6
}
```

### 6. 移动角色

```bash
curl -X POST http://localhost:8080/api/v1/game/move \
  -H "Content-Type: application/json" \
  -d '{
    "character_id": 1,
    "position_x": 100,
    "position_y": 200
  }'
```

### 7. 添加能力点

```bash
curl -X POST http://localhost:8080/api/v1/game/add-ap \
  -H "Content-Type: application/json" \
  -d '{
    "character_id": 1,
    "str": 3,
    "dex": 2
  }'
```

### 8. 恢复HP/MP

```bash
curl -X POST http://localhost:8080/api/v1/game/restore \
  -H "Content-Type: application/json" \
  -d '{
    "character_id": 1,
    "hp": 50,
    "mp": 10
  }'
```

### 9. 获取地图列表

```bash
curl http://localhost:8080/api/v1/maps/
```

### 10. 获取怪物列表

```bash
curl http://localhost:8080/api/v1/mobs/
```

---

## WebSocket测试指南

### 使用wscat测试

```bash
# 安装wscat (如果没有)
npm install -g wscat

# 连接WebSocket
wscat -c "ws://localhost:8080/ws?character_id=1&room=default"

# 在连接后发送消息
> Hello world!
< 收到广播消息
```

### 使用Postman

1. 新建请求，选择WebSocket协议
2. 输入URL: `ws://localhost:8080/ws?character_id=1&room=default`
3. 点击Connect
4. 发送任意文本消息测试

---

## Flutter客户端启动

### 1. 安装依赖

```bash
cd client
flutter pub get
```

### 2. 运行客户端

```bash
# 运行在模拟器/真机上
flutter run

# 或者运行在Web上
flutter run -d chrome
```

### 3. 客户端功能

- 登录/注册界面
- 角色选择界面
- 游戏主界面
- 玩家状态栏（HP/MP/经验/金币）
- 聊天系统（实时WebSocket）
- 地图显示

---

## 数据库结构（17个核心数据表）

| 表名 | 用途 |
|------|------|
| accounts | 账号表 |
| characters | 角色表 |
| character_stats | 角色扩展属性 |
| character_inventories | 角色背包 |
| items | 物品表 |
| skills | 技能表 |
| quests | 任务表 |
| maps | 地图表 |
| npcs | NPC表 |
| mobs | 怪物表 |
| guilds | 公会表 |
| parties | 队伍表 |
| friends | 好友表 |
| login_logs | 登录日志 |
| trade_logs | 交易日志 |
| chat_logs | 聊天日志 |

### 自动建表说明

- 使用GORM的 `AutoMigrate` 功能，类似Hibernate
- 服务器启动时自动检测并创建表结构
- 如果表已存在，会自动添加新字段
- 配置文件中的 `autoMigrate: true` 控制此功能

---

## 游戏核心逻辑

### 1. 职业差异化初始属性

| 职业 | 初始HP | 初始MP | STR | DEX | INT | LUK |
|------|--------|--------|-----|-----|-----|-----|
| 新手 | 50 | 5 | 12 | 5 | 4 | 4 |
| 战士 | 80 | 4 | 35 | 15 | 4 | 4 |
| 法师 | 40 | 80 | 4 | 4 | 35 | 20 |
| 弓箭手 | 60 | 8 | 25 | 35 | 4 | 4 |
| 飞侠 | 55 | 10 | 4 | 25 | 4 | 35 |
| 海盗 | 70 | 12 | 20 | 20 | 4 | 15 |

### 2. 升级系统

- 每次升级HP/MP根据职业增加
- 每次升级获得5点能力点(AP)
- 10级及以上每次升级获得3点技能点(SP)
- 升级满血满蓝
- 经验公式: 10 + level² × 8 (前期)

### 3. 属性加成

- STR(力量): 影响战士伤害
- DEX(敏捷): 影响弓箭手伤害、命中率
- INT(智力): 影响法师伤害、魔法量
- LUK(幸运): 影响飞侠暴击率、掉落

---

## 核心文档

### [PROJECT_PLAN.md](PROJECT_PLAN.md)
完整的项目技术方案，包含：
- 技术栈架构
- 数据库设计
- 网络协议
- 开发计划
- 技术难点分析

### [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)
详细开发进度报告，包含：
- 已完成功能清单
- API接口列表
- 下一步计划
- 已知问题

### [API_TEST.md](API_TEST.md)
完整的API测试指南，包含：
- 所有接口的curl示例
- 请求/响应格式详解
- 测试用例

### [../mapleStory079-external/docs-OPEN_SOURCE_RESOURCES.md](../mapleStory079-external/docs-OPEN_SOURCE_RESOURCES.md)
全网开源资源汇总：
- 服务端项目参考 (HeavenMS, ZLHSS2, cc-079-ms)
- 客户端项目
- 工具和资源
- 学习路径建议

---

## 开发进度

### ✅ 已完成
- ✅ 项目技术方案文档
- ✅ 后端Gin框架搭建
- ✅ GORM自动建表实现（17个数据表）
- ✅ 30+ RESTful API接口
- ✅ WebSocket实时通信
- ✅ 用户认证系统
- ✅ 角色管理系统（6种职业）
- ✅ 地图/NPC/怪物/物品/技能/任务系统
- ✅ 升级系统和经验计算
- ✅ 战斗系统（伤害、暴击、命中率）
- ✅ 完整的游戏状态API
- ✅ 数据初始化脚本（完整测试数据）
- ✅ Flutter客户端框架搭建
- ✅ 客户端登录/角色选择/游戏界面

### ⏳ 进行中
- ⏳ Flutter Flame游戏引擎集成
- ⏳ 地图渲染系统
- ⏳ 角色移动动画
- ⏳ 战斗UI

### 🔜 待开发
- ⏳ 多人在线同步
- ⏳ 完整的NPC对话系统
- ⏳ 物品装备系统
- ⏳ 技能释放系统
- ⏳ 任务系统UI
- ⏳ 公会系统
- ⏳ 队伍系统
- ⏳ 交易系统
- ⏳ 聊天系统完善

---

## 常见问题 FAQ

### Q1: 编译时出现 "dial tcp 127.0.0.1:3306: connect: connection refused"
**A**: MySQL服务未启动，请启动MySQL并确保端口3306可用。

```bash
# macOS
brew services start mysql

# Linux
sudo systemctl start mysql
```

### Q2: Access denied for user 'root'@'localhost'
**A**: MySQL密码错误，请在 `config/config.yaml` 中修改 `database.password`。

### Q3: 如何重置游戏数据？
**A**: 删除数据库重新创建即可：

```bash
mysql -u root -p -e "DROP DATABASE maplestory; CREATE DATABASE maplestory;"
```

### Q4: 如何创建新角色？
**A**: 先注册账号 -> 登录获取account_id -> 创建角色。

### Q5: Flutter客户端如何连接到服务器？
**A**: 修改 `client/lib/config/app_config.dart` 中的服务器地址：

```dart
static const String apiBaseUrl = 'http://localhost:8080/api/v1';
static const String wsUrl = 'ws://localhost:8080/ws';
```

### Q6: 如何支持多人在线？
**A**: WebSocket已实现，多个客户端连接同一个服务器即可。
使用 `/ws?character_id=1&room=default` 路由加入房间。

---

## 技术栈详解

### 后端架构 (MVC)
```
请求 -> Middleware -> Handler -> Service -> Repository -> Database
```
- **Handler层**: 处理HTTP请求和响应
- **Service层**: 业务逻辑实现
- **Repository层**: 数据库CRUD操作

### 前端架构 (Provider)
```
UI -> Provider -> API Service -> Backend Server
```
- **Provider**: 状态管理（用户信息、游戏状态）
- **Pages**: UI页面
- **Widgets**: 可复用组件

### 实时通信
- **WebSocket**: 玩家位置同步、聊天广播
- **房间系统**: 支持多房间/多地图
- **心跳保活**: 自动检测断线

---

## 学习建议

### 初学者
1. 先从API测试开始，了解完整流程：注册→登录→创建角色→获取经验→升级
2. 查看 `internal/handler/game_handler.go` 了解接口实现
3. 查看 `internal/service/game_service.go` 理解游戏逻辑
4. 查看 `pkg/database/models.go` 理解数据模型

### 进阶者
1. 研究WebSocket实时通信实现 `internal/handler/websocket_handler.go`
2. 研究Flutter客户端状态管理 `client/lib/providers/`
3. 添加新的游戏功能（如NPC对话、物品使用）
4. 优化性能，添加Redis缓存

### 高级开发者
1. 参考 `../mapleStory079-external/` 下的开源项目（见 `EXTERNAL_REF.md`），研究原版游戏协议
2. 实现完整的地图渲染系统
3. 添加多人在线同步功能
4. 实现完整的战斗系统（PVE/PVP）

---

## 法律声明

⚠️ **本项目仅供学习研究使用**

- 冒险岛(MapleStory)是Nexon公司的注册商标
- 游戏资源、音乐、贴图等受版权保护
- 不得用于商业用途
- 不得用于运营私服
- 请遵守当地法律法规

---

## 许可证

MIT License (仅供学习和研究使用)

---

## 更新日志

- **2024-06-13 (v0.2.0)**: 完善游戏核心API，添加升级系统、移动系统、状态系统，完善WebSocket，Flutter客户端框架完成
- **2024-06-12 (v0.1.0)**: 项目初始化，后端框架搭建，基础API完成

---

## 联系方式

如有问题或建议，请通过 GitHub Issues 联系。

---

**最后提醒**: 请务必遵守法律法规，尊重知识产权，本项目仅供学习研究使用！
