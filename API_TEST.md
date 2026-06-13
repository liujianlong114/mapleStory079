# MapleStory 079 API 测试指南

本文档提供完整的API测试指南，帮助你测试冒险岛079服务端的所有功能。

## 启动服务

### 1. 启动服务器
```bash
cd /Users/lijianjun/GolandProjects/mapleStory079
./bin/server
```

服务器将在 `http://localhost:8080` 启动

### 2. 初始化数据 (可选)
首次运行时，可以初始化一些基础数据：
```bash
./bin/init_data
```

这将创建：
- 8个地图 (彩虹岛、射手村、明珠港等)
- 7个NPC (导航宠物、杂货商、武器商等)
- 10种怪物 (绿蜗牛、红蜗牛、野猪等)
- 23种物品 (武器、防具、药水等)
- 14个技能 (冲抵、恢复术、魔法箭等)
- 4个任务

---

## 认证接口

### 注册账号
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "123456",
    "email": "test@example.com"
  }'
```

**响应示例：**
```json
{
  "message": "registration successful"
}
```

### 登录
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "123456"
  }'
```

**响应示例：**
```json
{
  "message": "login successful",
  "data": {
    "id": 1,
    "username": "testuser",
    "email": "test@example.com"
  }
}
```

---

## 角色接口

### 创建角色
```bash
curl -X POST http://localhost:8080/api/v1/characters \
  -H "Content-Type: application/json" \
  -d '{
    "account_id": 1,
    "name": "MapleHero",
    "class": 1,
    "gender": 0
  }'
```

**参数说明：**
- `account_id`: 账号ID (必填)
- `name`: 角色名称 (必填，最大12字符)
- `class`: 职业 (必填，1=战士，2=魔法师，3=弓箭手，4=飞侠，5=海盗)
- `gender`: 性别 (必填，0=男，1=女)

**响应示例：**
```json
{
  "message": "character created",
  "data": {
    "id": 1,
    "account_id": 1,
    "name": "MapleHero",
    "class": 1,
    "gender": 0,
    "level": 1,
    "hp": 100,
    "max_hp": 100,
    "mp": 50,
    "max_mp": 50,
    "str": 4,
    "dex": 4,
    "int": 4,
    "luk": 4,
    "mesos": 0
  }
}
```

### 获取账号下的所有角色
```bash
curl -X GET "http://localhost:8080/api/v1/characters?account_id=1"
```

### 获取单个角色
```bash
curl -X GET http://localhost:8080/api/v1/characters/1
```

### 更新角色
```bash
curl -X PUT http://localhost:8080/api/v1/characters/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Hero123",
    "str": 10,
    "dex": 5,
    "hp": 150,
    "mp": 80
  }'
```

### 删除角色
```bash
curl -X DELETE http://localhost:8080/api/v1/characters/1
```

---

## 地图接口

### 获取所有地图
```bash
curl -X GET http://localhost:8080/api/v1/maps/
```

**响应示例：**
```json
{
  "data": [
    {
      "id": 10000,
      "name": "彩虹岛",
      "description": "新手出生的岛屿",
      "width": 900,
      "height": 600,
      "music": "midi/arioso"
    },
    {
      "id": 100000000,
      "name": "射手村",
      "description": "射手村广场",
      "width": 1200,
      "height": 800,
      "music": "musical/nothing"
    }
  ]
}
```

### 获取单个地图
```bash
curl -X GET http://localhost:8080/api/v1/maps/10000
```

### 创建地图
```bash
curl -X POST http://localhost:8080/api/v1/maps/ \
  -H "Content-Type: application/json" \
  -d '{
    "name": "神秘洞穴",
    "description": "充满危险的神秘洞穴",
    "width": 1000,
    "height": 800,
    "music": "dungeon",
    "background": "cave_bg"
  }'
```

---

## NPC接口

### 获取NPC
```bash
curl -X GET http://localhost:8080/api/v1/npcs/9000021
```

**响应示例：**
```json
{
  "data": {
    "id": 9000021,
    "name": "导航宠物",
    "map_id": 10000,
    "position_x": 100,
    "position_y": 100,
    "script_name": "guide.js"
  }
}
```

### 获取地图上的所有NPC
```bash
curl -X GET "http://localhost:8080/api/v1/npcs/map/100000000"
```

### 与NPC交互
```bash
curl -X POST "http://localhost:8080/api/v1/npcs/interact/9000021?character_id=1"
```

---

## 怪物接口

### 获取所有怪物
```bash
curl -X GET http://localhost:8080/api/v1/mobs/
```

**响应示例：**
```json
{
  "data": [
    {
      "id": 100,
      "name": "绿蜗牛",
      "hp": 12,
      "max_hp": 12,
      "level": 1,
      "exp": 10,
      "meso": 15,
      "attack": 5,
      "defense": 0,
      "speed": 50
    }
  ]
}
```

### 获取单个怪物
```bash
curl -X GET http://localhost:8080/api/v1/mobs/100
```

---

## 物品接口

### 获取所有物品
```bash
curl -X GET http://localhost:8080/api/v1/items/
```

**响应示例：**
```json
{
  "data": [
    {
      "id": 1302000,
      "name": "木棍",
      "type": 1,
      "sub_type": 1,
      "price": 100,
      "req_level": 0,
      "attack": 15,
      "description": "新手武器"
    }
  ]
}
```

### 获取单个物品
```bash
curl -X GET http://localhost:8080/api/v1/items/1302000
```

---

## 技能接口

### 获取所有技能
```bash
curl -X GET http://localhost:8080/api/v1/skills/
```

**响应示例：**
```json
{
  "data": [
    {
      "id": 1000,
      "name": "冲抵",
      "description": "向前冲抵一段距离",
      "max_level": 20,
      "req_level": 1,
      "mp_cost": 0,
      "cooldown": 0,
      "range": 100,
      "attack_count": 1
    }
  ]
}
```

### 获取单个技能
```bash
curl -X GET http://localhost:8080/api/v1/skills/1000
```

---

## 任务接口

### 获取所有任务
```bash
curl -X GET http://localhost:8080/api/v1/quests/
```

**响应示例：**
```json
{
  "data": [
    {
      "id": 29001,
      "name": "测试任务1",
      "description": "这是一个测试任务",
      "req_level": 1,
      "start_npc": 9000021,
      "end_npc": 9000021,
      "reward_exp": 100,
      "reward_mesos": 500
    }
  ]
}
```

### 获取单个任务
```bash
curl -X GET http://localhost:8080/api/v1/quests/29001
```

---

## 战斗接口

### 计算伤害
```bash
curl -X POST http://localhost:8080/api/v1/combat/calculate-damage \
  -H "Content-Type: application/json" \
  -d '{
    "attacker_level": 10,
    "attacker_attack": 50,
    "defender_defense": 20,
    "skill_multiplier": 2
  }'
```

**响应示例：**
```json
{
  "damage": 45
}
```

### 计算升级
```bash
curl -X POST http://localhost:8080/api/v1/combat/calculate-levelup \
  -H "Content-Type: application/json" \
  -d '{
    "current_level": 1,
    "current_exp": 100
  }'
```

**响应示例：**
```json
{
  "leveled_up": true,
  "new_level": 2,
  "new_exp": 17
}
```

---

## 健康检查

### 服务器健康状态
```bash
curl http://localhost:8080/health
```

**响应示例：**
```json
{
  "status": "ok",
  "message": "MapleStory 079 Server is running"
}
```

---

## 常见问题

### Q1: 如何查看所有API路由？
启动服务器后访问 `http://localhost:8080/` 可以看到路由信息

### Q2: 角色职业有哪些？
- 1 = 战士
- 2 = 魔法师
- 3 = 弓箭手
- 4 = 飞侠
- 5 = 海盗

### Q3: 物品类型有哪些？
- 1 = 武器
- 2 = 防具
- 3 = 药水
- 4 = 其他

### Q4: 如何添加自定义数据？
编辑 `scripts/init_data.go` 文件，然后重新编译并运行 `./bin/init_data`

### Q5: 数据库在哪里查看？
使用 MySQL 客户端连接：
```bash
mysql -u root -p
USE maplestory;
SHOW TABLES;
SELECT * FROM characters;
```

---

## 下一步

完成基本API测试后，可以开始：
1. 使用Flutter开发客户端
2. 实现WebSocket实时通信
3. 开发游戏核心逻辑
4. 参考 `examples/` 中的开源项目

祝你开发愉快！🎮