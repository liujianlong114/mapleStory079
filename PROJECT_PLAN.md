# 冒险岛079复刻项目技术方案

## 项目概述

本项目旨在完整复刻国服冒险岛Online 079版本，包括登录界面音乐、游戏贴图、所有功能玩法，实现一比一还原。

## 技术栈架构

### 后端服务 (Golang + Gin)

#### 核心框架
- **Web框架**: Gin (高性能HTTP框架)
- **ORM框架**: GORM (类似Hibernate的自动建表功能)
- **数据库**: MySQL 8.0+
- **缓存**: Redis 6.0+
- **消息队列**: RabbitMQ (可选，用于异步任务处理)

#### 数据库设计原则
采用GORM的AutoMigrate功能，实现：
- 启动时自动检测表结构
- 自动创建不存在的表
- 自动添加缺失的字段
- 自动修正字段类型
- 保留现有数据，不删除字段

#### 服务架构
```
mapleStory079/
├── cmd/                    # 应用入口
│   └── server/
│       └── main.go
├── internal/               # 私有应用代码
│   ├── handler/           # HTTP处理器
│   ├── service/           # 业务逻辑层
│   ├── repository/        # 数据访问层
│   ├── model/             # 数据模型
│   └── middleware/        # 中间件
├── pkg/                    # 公共库
│   ├── database/          # 数据库连接
│   ├── cache/             # 缓存封装
│   └── utils/             # 工具函数
├── config/                 # 配置文件
├── scripts/                # 脚本文件
└── sql/                     # SQL文件
```

#### 核心模块
1. **登录服务器** (Login Server)
   - 账号验证
   - 角色选择
   - 服务器列表

2. **游戏服务器** (Game Server)
   - 角色管理
   - 地图系统
   - 战斗系统
   - 物品系统
   - 技能系统
   - 任务系统
   - 交易系统
   - 社交系统

3. **聊天服务器** (Chat Server)
   - 世界频道
   - 私聊
   - 组队聊天
   - 公会聊天

### 客户端 (Flutter)

#### 核心技术
- **框架**: Flutter 3.x
- **语言**: Dart
- **状态管理**: Riverpod/Provider
- **网络请求**: Dio
- **本地存储**: Hive/SQLite
- **游戏引擎**: Flame (2D游戏引擎)

#### 支持平台
- Android
- iOS
- Web
- Windows
- macOS
- Linux

#### 客户端架构
```
maple_client/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   └── routes.dart
│   ├── core/
│   │   ├── network/
│   │   ├── storage/
│   │   └── constants/
│   ├── features/
│   │   ├── login/
│   │   ├── character/
│   │   ├── game/
│   │   └── social/
│   ├── shared/
│   │   ├── widgets/
│   │   └── utils/
│   └── data/
│       ├── models/
│       ├── repositories/
│       └── datasources/
├── assets/
│   ├── images/
│   ├── audio/
│   └── fonts/
└── pubspec.yaml
```

#### 核心功能模块
1. **登录模块**
   - 账号登录
   - 角色创建/选择
   - 服务器选择

2. **游戏场景**
   - 地图渲染
   - 角色移动
   - NPC交互
   - 怪物AI
   - 技能特效

3. **UI系统**
   - 主界面
   - 背包系统
   - 技能栏
   - 任务追踪
   - 聊天窗口

4. **音效系统**
   - BGM播放
   - 音效播放
   - 语音聊天

## 游戏资源

### WZ文件结构
冒险岛的游戏资源存储在WZ文件中，主要包括：

1. **Base.wz** - 基础资源
2. **Character.wz** - 角色相关资源
3. **Effect.wz** - 特效资源
4. **Item.wz** - 物品资源
5. **Map.wz** - 地图资源
6. **Mob.wz** - 怪物资源
7. **Npc.wz** - NPC资源
8. **Quest.wz** - 任务资源
9. **Skill.wz** - 技能资源
10. **Sound.wz** - 音效资源
11. **String.wz** - 字符串资源
12. **UI.wz** - 界面资源

### 资源解析
需要开发WZ文件解析器，支持：
- 读取WZ文件格式
- 解析图片资源
- 解析音频资源
- 解析配置数据

## 数据库设计

### 核心表结构

#### 账号相关
- `accounts` - 账号表
- `characters` - 角色表
- `character_stats` - 角色属性表
- `character_inventory` - 角色背包表

#### 游戏数据
- `items` - 物品表
- `skills` - 技能表
- `quests` - 任务表
- `maps` - 地图表
- `npcs` - NPC表
- `mobs` - 怪物表

#### 社交系统
- `guilds` - 公会表
- `parties` - 组队表
- `friends` - 好友表

#### 日志系统
- `login_logs` - 登录日志
- `trade_logs` - 交易日志
- `chat_logs` - 聊天日志

## 网络协议

### 数据包格式
```
[Header][Length][Opcode][Data]
- Header: 2字节 (0x00 0x00)
- Length: 2字节
- Opcode: 2字节
- Data: 变长数据
```

### 加密方式
- AES加密
- 自定义加密算法
- 数据包混淆

### 核心操作码
- 登录相关: 0x0001 - 0x0010
- 角色操作: 0x0011 - 0x0020
- 移动相关: 0x0021 - 0x0030
- 战斗相关: 0x0031 - 0x0040
- 物品相关: 0x0041 - 0x0050
- 技能相关: 0x0051 - 0x0060

## 开发计划

### 第一阶段：基础架构 (2周)
- [ ] 搭建Gin后端框架
- [ ] 配置GORM自动建表
- [ ] 实现基础数据库模型
- [ ] 搭建Flutter客户端框架
- [ ] 实现网络通信模块

### 第二阶段：登录系统 (2周)
- [ ] 实现账号注册/登录
- [ ] 实现角色创建/选择
- [ ] 实现服务器列表
- [ ] 客户端登录界面开发

### 第三阶段：游戏核心 (4周)
- [ ] 地图系统
- [ ] 角色移动
- [ ] NPC交互
- [ ] 物品系统
- [ ] 背包系统

### 第四阶段：战斗系统 (3周)
- [ ] 怪物AI
- [ ] 战斗逻辑
- [ ] 技能系统
- [ ] 伤害计算

### 第五阶段：社交系统 (2周)
- [ ] 聊天系统
- [ ] 组队系统
- [ ] 公会系统
- [ ] 好友系统

### 第六阶段：任务系统 (2周)
- [ ] 任务框架
- [ ] 任务脚本
- [ ] 任务追踪
- [ ] 任务奖励

### 第七阶段：优化与测试 (2周)
- [ ] 性能优化
- [ ] 内存优化
- [ ] 网络优化
- [ ] 全面测试

## 开源资源参考

### 服务端项目
1. **HeavenMS** (Java)
   - GitHub: https://github.com/ronancpl/HeavenMS
   - 描述: MapleStory v83服务器模拟器，功能完整
   - 特点: 代码结构清晰，文档完善

2. **ZLHSS2** (Java)
   - GitHub: https://github.com/huangshushu/ZLHSS2
   - 描述: 冒险岛079服务端，中文项目
   - 特点: 包含客户端和工具包

3. **cc-079-ms** (Java)
   - Gitee: https://gitee.com/mmchichi/cc-079-ms
   - 描述: 完全开源的079冒险岛模拟器
   - 特点: 基于Java17，使用Graal-Js引擎

4. **Cosmic** (Java)
   - GitHub: https://github.com/P0nk/Cosmic
   - 描述: MapleStory Global v83服务器模拟器
   - 特点: 继承了OdinMS和HeavenMS的代码

### 客户端项目
1. **HeavenClient**
   - GitHub: https://github.com/ryantpayton/HeavenClient
   - 描述: HeavenMS配套客户端源码

### 资源文件
- WZ文件解析器
- 客户端资源提取工具
- 地图编辑器
- NPC脚本编辑器

## 技术难点

### 1. WZ文件解析
- 需要理解WZ文件格式
- 图片解码（多种格式）
- 音频解码
- 数据结构解析

### 2. 游戏逻辑
- 复杂的战斗系统
- 技能效果实现
- 怪物AI逻辑
- 任务脚本系统

### 3. 网络同步
- 实时游戏状态同步
- 延迟优化
- 防作弊机制

### 4. 性能优化
- 大量玩家在线
- 地图数据加载
- 资源内存管理

## 风险评估

### 法律风险
⚠️ **重要提示**: 本项目仅供学习研究使用
- 冒险岛是Nexon公司的注册商标
- 游戏资源受版权保护
- 不得用于商业用途
- 不得侵犯原作版权

### 技术风险
- 协议逆向难度大
- 游戏逻辑复杂
- 资源文件庞大
- 性能要求高

## 开发环境

### 后端环境
- Go 1.21+
- MySQL 8.0+
- Redis 6.0+
- Docker (可选)

### 客户端环境
- Flutter 3.x
- Dart 3.x
- Android Studio / VS Code

### 开发工具
- Git
- Postman (API测试)
- MySQL Workbench
- Redis Desktop Manager

## 部署方案

### Docker部署
```yaml
version: '3.8'
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: maplestory
    ports:
      - "3306:3306"
  
  redis:
    image: redis:6.0
    ports:
      - "6379:6379"
  
  login-server:
    build: ./login-server
    ports:
      - "8484:8484"
  
  game-server:
    build: ./game-server
    ports:
      - "7575:7575"
```

### Kubernetes部署
- 使用K8s进行容器编排
- 支持水平扩展
- 负载均衡
- 服务发现

## 后续规划

### 功能扩展
- [ ] 更多职业支持
- [ ] 更多地图开放
- [ ] 活动系统
- [ ] 商城系统
- [ ] 排行榜

### 性能优化
- [ ] 数据库分库分表
- [ ] 缓存优化
- [ ] 网络优化
- [ ] 资源预加载

### 运维监控
- [ ] 日志系统
- [ ] 监控告警
- [ ] 自动化部署
- [ ] 性能分析

## 贡献指南

欢迎开发者贡献代码，但请遵守以下原则：
1. 仅供学习研究使用
2. 不得用于商业用途
3. 尊重原作版权
4. 遵守开源协议

## 许可证

本项目采用 MIT 许可证，仅供学习和研究使用。

---

**注意**: 本文档会随着项目进展持续更新。