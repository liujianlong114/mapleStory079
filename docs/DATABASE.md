# 冒险岛079 数据库设计文档

## 1. 数据库配置

- **数据库类型**: MySQL 8.0+
- **字符集**: utf8mb4
- **排序规则**: utf8mb4_unicode_ci
- **数据库名**: maplestory

配置文件位置: `config/config.yaml`

```yaml
database:
  host: 127.0.0.1
  port: 3306
  user: maplestory
  password: maplestory
  name: maplestory
  max_open_conns: 100
  max_idle_conns: 10
  conn_max_lifetime: 3600
```

## 2. 核心数据表

### 2.1 accounts - 账号表

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | uint PK | 账号ID |
| username | varchar(32) UNIQUE | 用户名 |
| password | varchar(128) | 密码（MD5哈希，实际生产应bcrypt） |
| email | varchar(64) | 邮箱 |
| status | int | 状态: 1=正常, 0=禁用 |
| last_login | datetime | 最近登录时间 |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |

### 2.2 characters - 角色表

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | uint PK | 角色ID |
| account_id | uint FK | 账号ID |
| name | varchar(12) UNIQUE | 角色名 |
| class | int | 职业: 0=新手,1=战士,2=法师,3=弓箭手,4=飞侠,5=海盗 |
| gender | int | 性别: 0=男, 1=女 |
| level | int | 等级（初始: 1） |
| exp | int | 当前经验 |
| hp | int | 当前HP |
| max_hp | int | 最大HP |
| mp | int | 当前MP |
| max_mp | int | 最大MP |
| str | int | 力量 |
| dex | int | 敏捷 |
| int | int | 智力 |
| luk | int | 幸运 |
| ability_point | int | 可分配AP |
| skill_point | int | 可分配SP |
| mesos | int | 金币 |
| map_id | uint | 当前地图ID |
| position_x | int | 坐标X |
| position_y | int | 坐标Y |
| fame | int | 名望 |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |

### 2.3 character_stats - 角色扩展属性

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | uint PK | 主键 |
| character_id | uint FK | 角色ID |
| physical_attack | int | 物理攻击 |
| magic_attack | int | 魔法攻击 |
| physical_defense | int | 物理防御 |
| magic_defense | int | 魔法防御 |
| accuracy | int | 命中 |
| avoidability | int | 回避 |
| speed | int | 速度（默认100，范围0-140） |
| jump | int | 跳跃（默认100） |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |

### 2.4 character_inventory - 角色背包

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | uint PK | 背包条目ID |
| character_id | uint FK | 角色ID |
| item_id | int | 物品ID |
| slot_index | int | 背包槽位 |
| quantity | int | 数量 |
| is_equipped | bool | 是否已装备 |
| equip_slot | varchar(16) | 装备槽位: weapon/armor/helmet/shoes/cape/accessory |
| stats | text | JSON附加属性 |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |

### 2.5 items - 物品表

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | uint PK | 物品ID |
| name | varchar(64) | 物品名称 |
| item_type | int | 类型: 0=消耗, 1=装备, 2=其他 |
| description | text | 描述 |
| price | int | 商店价格 |
| level_req | int | 等级要求 |
| str/dex/int/luk | int | 四维属性加成 |
| hp_recovery | int | HP恢复量 |
| mp_recovery | int | MP恢复量 |
| stackable | bool | 是否可堆叠 |
| image | varchar(128) | 图标路径 |
| created_at | datetime | 创建时间 |

### 2.6 skills - 技能表

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | uint PK | 技能ID |
| name | varchar(64) | 技能名称 |
| job_class | int | 职业限制 |
| level_req | int | 等级要求 |
| max_level | int | 最大等级 |
| mp_cost | int | MP消耗 |
| damage_ratio | float | 伤害倍率 |
| description | text | 描述 |
| is_passive | bool | 是否被动技能 |
| cool_down_ms | int | 冷却时间(ms) |
| created_at | datetime | 创建时间 |

### 2.7 mobs - 怪物表

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | uint PK | 怪物ID |
| name | varchar(32) | 名称 |
| level | int | 等级 |
| hp | int | 当前HP |
| max_hp | int | 最大HP |
| mp | int | MP |
| physical_attack | int | 物理攻击 |
| magic_attack | int | 魔法攻击 |
| physical_defense | int | 物理防御 |
| magic_defense | int | 魔法防御 |
| exp_reward | int | 经验奖励 |
| mesos_reward | int | 金币奖励 |
| speed | int | 移动速度 |
| image | varchar(128) | 图像路径 |
| created_at | datetime | 创建时间 |

### 2.8 maps - 地图表

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | uint PK | 地图ID |
| name | varchar(64) | 地图名称 |
| description | text | 描述 |
| width | int | 地图宽度(像素) |
| height | int | 地图高度(像素) |
| monster_pool | text | 怪物池(JSON) |
| background | varchar(128) | 背景图 |
| music | varchar(128) | BGM路径 |
| created_at | datetime | 创建时间 |

### 2.9 npcs - NPC表

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | uint PK | NPC ID |
| name | varchar(32) | 名称 |
| description | text | 描述 |
| map_id | uint FK | 所在地图 |
| position_x | int | X坐标 |
| position_y | int | Y坐标 |
| scripts | text | 对话脚本(JSON) |
| has_shop | bool | 是否有商店 |
| image | varchar(128) | 图像路径 |
| created_at | datetime | 创建时间 |

### 2.10 quests - 任务表

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | uint PK | 任务ID |
| name | varchar(128) | 任务名 |
| description | text | 描述 |
| npc_id | uint | 发起人NPC |
| level_req | int | 等级要求 |
| exp_reward | int | 经验奖励 |
| mesos_reward | int | 金币奖励 |
| item_rewards | text | 物品奖励(JSON数组) |
| created_at | datetime | 创建时间 |

### 2.11 guilds - 公会表

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | uint PK | 公会ID |
| name | varchar(16) UNIQUE | 公会名 |
| master_id | uint | 会长ID |
| members | int | 成员数 |
| level | int | 公会等级 |
| point | int | 公会积分 |
| notice | varchar(256) | 公告 |
| created_at/updated_at | datetime | 时间 |

### 2.12 parties - 组队表

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | uint PK | 组队ID |
| leader_id | uint UNIQUE | 队长ID |
| members | int | 成员数 |
| map_id | uint | 当前地图 |
| created_at/updated_at | datetime | 时间 |

### 2.13 friends - 好友表

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | uint PK | ID |
| character_id | uint INDEX | 角色ID |
| friend_id | uint INDEX | 好友ID |
| group | varchar(16) | 分组名称 |
| created_at | datetime | 创建时间 |

### 2.14 login_logs - 登录日志

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | uint PK | ID |
| account_id | uint INDEX | 账号ID |
| ip | varchar(45) | IP地址 |
| user_agent | varchar(256) | User Agent |
| status | int | 1=成功, 0=失败 |
| created_at | datetime | 时间 |

### 2.15 trade_logs - 交易日志

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | uint PK | ID |
| sender_id | uint INDEX | 发送者ID |
| receiver_id | uint INDEX | 接收者ID |
| item_id | int | 物品ID |
| quantity | int | 数量 |
| mesos | int | 金币 |
| created_at | datetime | 时间 |

### 2.16 chat_logs - 聊天日志

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | uint PK | ID |
| character_id | uint INDEX | 发送者ID |
| receiver_id | uint INDEX | 接收者ID(私聊) |
| channel | int | 频道: 0=世界, 1=公会, 2=组队, 3=私聊 |
| message | varchar(256) | 消息内容 |
| created_at | datetime | 时间 |

## 3. 索引建议

```sql
-- 账号查询
CREATE INDEX idx_accounts_username ON accounts(username);

-- 角色查询
CREATE INDEX idx_characters_account ON characters(account_id);
CREATE INDEX idx_characters_name ON characters(name);

-- 背包索引
CREATE INDEX idx_inventory_character ON character_inventory(character_id);

-- 聊天查询优化
CREATE INDEX idx_chat_logs_channel_time ON chat_logs(channel, created_at DESC);
CREATE INDEX idx_chat_logs_private ON chat_logs(character_id, receiver_id, created_at DESC);

-- 日志查询
CREATE INDEX idx_login_logs_account_time ON login_logs(account_id, created_at DESC);
```

## 4. 初始化流程

1. **启动应用** → `cmd/server/main.go` 启动 Gin
2. **DB 初始化** → `pkg/database/database.go` 连接 MySQL
3. **AutoMigrate** → GORM 自动创建/更新所有表结构
4. **数据初始化** → `scripts/init_data.go` 插入默认地图/NPC/怪物/物品/技能
5. **缓存启动** → `pkg/cache/cache.go` 启动内存缓存

### 一键初始化命令
```bash
# 方式1: 使用 init_data 工具
make build-init && ./bin/init_data

# 方式2: 使用 docker-compose
docker-compose up -d mysql
# 等待 mysql 启动后执行初始化工具

# 方式3: 手动创建数据库
mysql -u root -p -e "CREATE DATABASE maplestory CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

## 5. 数据完整性约束

- **账号名唯一**: `accounts.username` UNIQUE 索引
- **角色名唯一**: `characters.name` UNIQUE 索引
- **公会名唯一**: `guilds.name` UNIQUE 索引
- **外键约束**: 通过 GORM 模型关系自动建立（`index` tag）
- **软删除**: 账号禁用使用 `status` 字段，不使用物理删除

## 6. 性能优化建议

1. **连接池**: 使用 `SetMaxOpenConns(100)`, `SetMaxIdleConns(10)`
2. **读写分离**: 生产环境配置主从复制，读走从库
3. **缓存热点**: 地图/NPC/物品配置使用 Redis 缓存
4. **索引优化**: 所有 WHERE/JOIN 字段需有索引
5. **分区表**: 日志表(chat_logs/login_logs/trade_logs)按时间分区
6. **慢查询监控**: 开启 MySQL slow query log，阈值 1s
