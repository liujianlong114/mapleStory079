# 冒险岛079 API 接口文档

## 基础信息

- **Base URL**: `http://localhost:8080/api/v1`
- **WebSocket**: `ws://localhost:8080/ws?character_id={id}&room=default`
- **认证方式**: Bearer Token (JWT)，通过 `Authorization` 头携带
- **响应格式**: `application/json`

## 1. 认证接口

### 1.1 注册
```
POST /auth/register
Content-Type: application/json

{
  "username": "player001",
  "password": "password123",
  "email": "player@example.com"
}

200 OK:
{
  "code": 0,
  "message": "注册成功",
  "data": {
    "id": 1,
    "username": "player001"
  }
}
```

### 1.2 登录
```
POST /auth/login
Content-Type: application/json

{
  "username": "player001",
  "password": "password123"
}

200 OK:
{
  "code": 0,
  "message": "登录成功",
  "data": {
    "token": "eyJhbGciOi...",
    "account_id": 1,
    "username": "player001"
  }
}
```

## 2. 角色接口

### 2.1 创建角色
```
POST /characters/
Authorization: Bearer {token}

{
  "account_id": 1,
  "name": "新手冒险家",
  "class": 0,
  "gender": 0
}
```

### 2.2 获取角色列表
```
GET /characters/?account_id=1
Authorization: Bearer {token}

200 OK:
{
  "code": 0,
  "data": {
    "characters": [
      {
        "id": 1,
        "name": "新手冒险家",
        "class": 0,
        "level": 1,
        "hp": 50,
        "max_hp": 50
      }
    ]
  }
}
```

### 2.3 获取角色详情
```
GET /characters/{id}
Authorization: Bearer {token}
```

### 2.4 更新角色
```
PUT /characters/{id}
Authorization: Bearer {token}

{ "name": "新名字" }
```

### 2.5 删除角色
```
DELETE /characters/{id}
Authorization: Bearer {token}
```

## 3. 游戏核心接口

### 3.1 获取游戏状态
```
GET /game/state?character_id=1
Authorization: Bearer {token}

200 OK:
{
  "code": 0,
  "data": {
    "character": { ... },
    "current_map": { ... },
    "nearby_npcs": [...],
    "hp_percent": 100,
    "mp_percent": 100,
    "required_exp": 100,
    "exp_progress": 0
  }
}
```

### 3.2 移动角色
```
POST /game/move
Authorization: Bearer {token}

{
  "character_id": 1,
  "x": 100,
  "y": 50
}
```

### 3.3 获得经验
```
POST /game/gain-exp
Authorization: Bearer {token}

{ "character_id": 1, "exp": 50 }
```

### 3.4 升级
```
POST /game/levelup/{characterId}
Authorization: Bearer {token}
```

### 3.5 分配能力点
```
POST /game/add-ap
Authorization: Bearer {token}

{ "character_id": 1, "stat": "str", "points": 1 }
```

### 3.6 恢复 HP/MP
```
POST /game/restore
Authorization: Bearer {token}

{ "character_id": 1, "hp": 10, "mp": 5 }
```

## 4. 战斗接口

### 4.1 玩家攻击怪物
```
POST /combat/player-attack-mob
Authorization: Bearer {token}

{
  "character_id": 1,
  "mob_id": 1001,
  "skill_id": null
}

200 OK:
{
  "code": 0,
  "data": {
    "damage": 25,
    "is_critical": false,
    "is_hit": true,
    "target_hp": 75,
    "target_max_hp": 100,
    "target_dead": false,
    "exp_gained": 0,
    "meso_gained": 0,
    "message": "对 绿水灵 造成 25 伤害"
  }
}
```

### 4.2 怪物攻击玩家
```
POST /combat/mob-attack-player
Authorization: Bearer {token}

{ "character_id": 1, "mob_id": 1001 }
```

### 4.3 获取战斗属性
```
GET /combat/stats?character_id=1
Authorization: Bearer {token}

200 OK:
{
  "code": 0,
  "data": {
    "attack": 15,
    "defense": 8,
    "hit_rate": 0.85,
    "critical_rate": 0.08,
    "hp": 45,
    "max_hp": 50,
    "hp_percent": 90
  }
}
```

### 4.4 复活
```
POST /combat/revive
Authorization: Bearer {token}

{ "character_id": 1 }
```

### 4.5 技能战斗使用
```
POST /combat/use-skill
Authorization: Bearer {token}

{ "character_id": 1, "skill_id": 100, "target_mob_id": 1001 }
```

## 5. 聊天接口

### 5.1 发送消息
```
POST /chat/send
Authorization: Bearer {token}

{
  "sender_id": 1,
  "sender_name": "玩家A",
  "channel": 0,       // 0=世界, 1=公会, 2=组队, 3=私聊
  "receiver_id": 0,   // 私聊时指定目标
  "content": "你好，冒险岛！"
}
```

### 5.2 获取聊天历史
```
GET /chat/history?channel=0&limit=50
Authorization: Bearer {token}
```

### 5.3 广播消息（系统/管理员用）
```
POST /chat/broadcast
Authorization: Bearer {token}

{ "content": "系统公告：双倍经验活动开启！" }
```

### 5.4 获取可用频道
```
GET /chat/channels
Authorization: Bearer {token}
```

## 6. 地图/NPC/怪物/物品/技能接口

### 6.1 地图
```
GET    /maps/              # 所有地图
GET    /maps/{id}          # 地图详情
POST   /maps/              # 创建地图
```

### 6.2 NPC
```
GET    /npcs/{id}               # NPC详情
GET    /npcs/map/{mapId}        # 地图上的NPC
POST   /npcs/interact/{id}      # 与NPC交互
POST   /npc/dialogue            # 开启对话
POST   /npc/dialogue/continue   # 继续对话
GET    /npc/scripts             # 对话脚本列表
```

### 6.3 怪物
```
GET    /mobs/          # 所有怪物
GET    /mobs/{id}      # 怪物详情
```

### 6.4 物品
```
GET    /items/         # 所有物品
GET    /items/{id}     # 物品详情
```

### 6.5 技能
```
GET    /skills/        # 所有技能
GET    /skills/{id}    # 技能详情
POST   /skills/use     # 使用技能（非战斗）
```

### 6.6 任务
```
GET    /quests/        # 所有任务
GET    /quests/{id}    # 任务详情
```

### 6.7 背包
```
GET    /inventory?character_id=1
POST   /inventory/add
POST   /inventory/use
POST   /inventory/equip
POST   /inventory/drop
GET    /inventory/equipped?character_id=1
```

## 7. WebSocket 实时通信

### 7.1 连接
```
ws://localhost:8080/ws?character_id=1&room=default
```

### 7.2 消息格式
```json
{
  "type": "chat",
  "sender_id": 1,
  "sender_name": "玩家A",
  "room": "default",
  "channel": 0,
  "payload": {
    "content": "你好！"
  },
  "timestamp": 1718000000
}
```

### 7.3 消息类型
| type | 说明 |
|-----|-----|
| `system` | 系统消息（欢迎、进入、离开） |
| `chat` | 聊天消息 |
| `move` | 角色位置同步 |
| `attack` | 攻击动作同步 |
| `levelup` | 升级公告 |
| `ping` / `pong` | 心跳保活 |

## 8. 错误码规范

| 错误码 | HTTP状态 | 说明 |
|-------|---------|-----|
| 0 | 200 | 成功 |
| 40001 | 400 | 参数错误 |
| 40101 | 401 | Token无效/过期 |
| 40301 | 403 | 无权限 |
| 40401 | 404 | 资源不存在 |
| 40901 | 409 | 冲突（如用户名已存在） |
| 42901 | 429 | 请求过于频繁 |
| 50001 | 500 | 服务器内部错误 |
