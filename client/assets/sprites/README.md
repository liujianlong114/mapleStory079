# 冒险岛 079 精灵（Sprite）资源清单

> 记录冒险岛 079 版本中的角色 / 怪物 / NPC / 坐骑 / 宠物 等精灵动画资源。
> 资源路径：`client/assets/sprites/`
> 原始数据参考：HeavenMS handbook Mob.txt / Map.txt / Skill.txt
> 所有精灵建议使用 **PNG 序列帧 + JSON 描述** 格式；战斗动画建议使用 Spritesheet + Frame Metadata。

---

## 一、角色精灵（玩家角色）

> 角色精灵由多部件叠加合成：`Body（身体）+ Hair（发型）+ Face（表情）+ 装备（Cap / Coat / Pants / Shoes / Weapon / Shield / Cape / Accessory）`。每个部件独立一个 spritesheet。

### 1.1 基础动作（全职业通用）

| 动作名 | 帧数 | 帧速率 | 说明 | 状态 |
|--------|------|--------|------|------|
| `stand` | 4 | 1 fps | 待机动画（站立呼吸） | ⏳ 待获取 |
| `walk` | 4 | 8 fps | 行走动画（左右翻转） | ⏳ 待获取 |
| `jump` | 3 | 10 fps | 跳跃上升 | ⏳ 待获取 |
| `fall` | 2 | 8 fps | 下落中 | ⏳ 待获取 |
| `alert` | 3 | 2 fps | 警戒/惊讶表情循环 | ⏳ 待获取 |
| `prone` | 2 | 1 fps | 匍匐姿态 | ⏳ 待获取 |
| `dead` | 4 | 2 fps | 倒地死亡 | ⏳ 待获取 |
| `ladder` | 3 | 4 fps | 爬梯子（上下） | ⏳ 待获取 |
| `rope` | 3 | 4 fps | 爬绳子 | ⏳ 待获取 |
| `hurt` | 2 | 4 fps | 受击后仰 | ⏳ 待获取 |
| `sit` | 3 | 2 fps | 坐下/起身 | ⏳ 待获取 |
| `portal_in` | 4 | 10 fps | 进入传送门 | ⏳ 待获取 |
| `portal_out` | 4 | 10 fps | 从传送门出现 | ⏳ 待获取 |
| `levelup` | 6 | 8 fps | 升级姿势（双手高举） | ⏳ 待获取 |
| `cheer` | 6 | 6 fps | 欢呼/成功姿势 | ⏳ 待获取 |

### 1.2 职业专属攻击动作（每职业独立动画）

| 职业 | 动作 | 帧数 | 说明 | 状态 |
|------|------|------|------|------|
| **战士（Fighter / Page / Spearman）** | `attack_sword_1h` | 4 | 单手剑挥砍 | ⏳ 待获取 |
| **战士** | `attack_sword_2h` | 4 | 双手剑劈砍 | ⏳ 待获取 |
| **战士** | `attack_axe_1h` | 4 | 单手斧攻击 | ⏳ 待获取 |
| **战士** | `attack_axe_2h` | 4 | 双手斧重击 | ⏳ 待获取 |
| **战士** | `attack_spear` | 4 | 长枪突刺 | ⏳ 待获取 |
| **战士** | `attack_polearm` | 4 | 长矛横扫 | ⏳ 待获取 |
| **战士** | `skill_power_strike` | 6 | Power Strike 技能动作 | ⏳ 待获取 |
| **战士** | `skill_slash_blast` | 6 | Slash Blast 范围攻击 | ⏳ 待获取 |
| **战士** | `skill_rage` | 4 | Rage 怒吼加攻 | ⏳ 待获取 |
| **法师（Mage - I/L / F/P / Priest）** | `cast_wand` | 5 | 魔杖施法（前推/抬起） | ⏳ 待获取 |
| **法师** | `cast_staff` | 5 | 法杖施法（举向天空） | ⏳ 待获取 |
| **法师** | `skill_magic_claw` | 6 | 紫色魔力之爪（特效叠加） | ⏳ 待获取 |
| **法师** | `skill_heal` | 4 | 治疗光效（绿色圆环） | ⏳ 待获取 |
| **弓箭手（Hunter / Crossbowman）** | `shoot_bow` | 6 | 弓射箭动作（拉弦-释放） | ⏳ 待获取 |
| **弓箭手** | `shoot_crossbow` | 5 | 弩射击（上弦-发射） | ⏳ 待获取 |
| **弓箭手** | `skill_arrow_rain` | 6 | 箭矢雨下落动作 | ⏳ 待获取 |
| **飞侠（Assassin / Bandit）** | `attack_dagger` | 5 | 短剑快速连刺 | ⏳ 待获取 |
| **飞侠** | `throw_star` | 4 | 投掷飞镖（飞侠） | ⏳ 待获取 |
| **飞侠** | `skill_lucky_seven` | 6 | Lucky Seven 技能动作 | ⏳ 待获取 |
| **飞侠** | `skill_savage_blow` | 8 | Savage Blow 六连刺 | ⏳ 待获取 |
| **海盗（Infighter / Gunslinger）** | `attack_knuckle` | 4 | 指节拳击 | ⏳ 待获取 |
| **海盗** | `attack_gun` | 5 | 火枪射击 | ⏳ 待获取 |
| **海盗** | `skill_somersault_kick` | 6 | 翻踢攻击 | ⏳ 待获取 |
| **海盗** | `skill_double_shot` | 6 | Double Shot 双发 | ⏳ 待获取 |

### 1.3 角色部件分层（每个部件独立 spritesheet）

| 部件 | 说明 | 推荐尺寸 | 状态 |
|------|------|---------|------|
| `body` | 身体（基础服装） | 60x96 | ⏳ 待获取 |
| `hair_001` ~ `hair_030` | 发型（约 30 种经典样式） | 60x96 | ⏳ 待获取 |
| `face_normal` / `face_hurt` / `face_smile` | 表情（眨眼/受击/笑） | 60x96 | ⏳ 待获取 |
| `cap_001` ~ `cap_050` | 帽子（装备类） | 60x96 | ⏳ 待获取 |
| `coat_001` ~ `coat_050` | 上衣（装备类） | 60x96 | ⏳ 待获取 |
| `pants_001` ~ `pants_050` | 下装（装备类） | 60x96 | ⏳ 待获取 |
| `shoes_001` ~ `shoes_030` | 鞋子（装备类） | 60x96 | ⏳ 待获取 |
| `weapon_sword_001` ~ `weapon_gun_030` | 武器（每职业对应 spritesheet） | 60x96 | ⏳ 待获取 |
| `shield_001` ~ `shield_020` | 盾牌（战士 / 法师专属） | 60x96 | ⏳ 待获取 |
| `cape_001` ~ `cape_030` | 披风（动态飘动） | 60x96 | ⏳ 待获取 |
| `accessory_ring_earring_pendant` | 饰品（戒指/耳环/项链，可合并） | 60x96 | ⏳ 待获取 |
| `belt_001` ~ `belt_010` | 腰带 | 60x96 | ⏳ 待获取 |

### 1.4 坐骑（Mount）

| 坐骑 ID | 名称 | 职业/等级限制 | 推荐尺寸 | 状态 |
|---------|------|---------------|---------|------|
| `mount_001` | 小野猪 Pig | 全职业 Lv 70+ | 80x64 | ⏳ 待获取 |
| `mount_002` | 银色野猪 Silver Mane | 全职业 Lv 120+ | 100x72 | ⏳ 待获取 |
| `mount_003` | 红飞龙 Red Draco | 全职业 Lv 200 | 120x96 | ⏳ 待获取 |
| `mount_004` | 蓝色飞龙 Blue Draco | 全职业 Lv 200 | 120x96 | ⏳ 待获取 |
| `mount_005` | 黑色飞龙 Black Draco | 全职业 Lv 200 | 120x96 | ⏳ 待获取 |

### 1.5 宠物（Pet）

| 宠物 ID | 名称 | 说明 | 推荐尺寸 | 状态 |
|---------|------|------|---------|------|
| `pet_001` | 小白猫（White Kitty） | 经典白色猫宠物 | 40x40 | ⏳ 待获取 |
| `pet_002` | 棕色小狗（Brown Puppy） | 可爱小狗 | 40x40 | ⏳ 待获取 |
| `pet_003` | 粉色小兔（Pink Bunny） | 粉色兔子 | 40x40 | ⏳ 待获取 |
| `pet_004` | 雪狐（Snow Fox） | 极地白狐 | 40x40 | ⏳ 待获取 |
| `pet_005` | 幼龙（Baby Dragon） | 新手龙宠物 | 48x48 | ⏳ 待获取 |

---

## 二、怪物精灵（Mob）

> 参考数据：HeavenMS Mob.txt（怪物 ID 与名称映射）。
> 每只怪物需要至少 4 种动作：`stand / move / attack / hit / dead`。

### 2.1 新手区域（Lv 1 - 10，Snail / Mushroom 系列）

| 怪物 ID | 名称 | 等级 | 推荐动作 | 状态 |
|---------|------|------|---------|------|
| `100100` | Snail（蜗牛） | 1 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `100101` | Blue Snail（蓝蜗牛） | 2 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `1110100` | Green Mushroom（绿蘑菇） | 3 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `1110101` | Dark Stump（黑树桩） | 4 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `1210100` | Pig（小猪） | 5 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `1210101` | Ribbon Pig（红丝带猪） | 6 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `1210102` | Orange Mushroom（橙蘑菇） | 7 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `130100` | Stump（树桩） | 8 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `130101` | Red Snail（红蜗牛） | 9 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `210100` | Slime（绿水灵） | 10 | stand/move/attack/hit/dead | ⏳ 待获取 |

### 2.2 初级区域（Lv 11 - 30，Ellinia / Henesys 近郊）

| 怪物 ID | 名称 | 等级 | 推荐动作 | 状态 |
|---------|------|------|---------|------|
| `1140100` | Ghost Stump（幽灵树桩） | 12 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `1130100` | Axe Stump（斧树桩） | 14 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `1120100` | Octopus（章鱼） | 15 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `2100100` | Desert Rabbit F（沙漠兔♀） | 15 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `2100101` | Desert Rabbit M（沙漠兔♂） | 16 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `2100102` | Jr. Cactus（小仙人掌） | 17 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `2100103` | Cactus（仙人掌） | 18 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `2110200` | Horny Mushroom（毒蘑菇） | 20 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `2110300` | Sand Rat（沙鼠） | 22 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `2110301` | Scorpion（蝎子） | 25 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `2220100` | Blue Mushroom（蓝蘑菇） | 28 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `2230100` | Evil Eye（邪眼） | 25 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `2230101` | Zombie Mushroom（僵尸蘑菇） | 26 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `2230102` | Wild Boar（野猪） | 30 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `2220000` | Mano（蘑菇王 BOSS） | 30 | stand/move/attack/hit/dead | ⏳ 待获取 |

### 2.3 中级区域（Lv 30 - 60，Perion / 废弃都市周边）

| 怪物 ID | 名称 | 等级 | 推荐动作 | 状态 |
|---------|------|------|---------|------|
| `2130100` | Dark Axe Stump（黑斧树桩） | 32 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `2130103` | Jr. Necki（小僵尸猴） | 35 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `2300100` | Stirge（斯丁吉 / 吸血虫） | 30 | fly/attack/hit/dead | ⏳ 待获取 |
| `3100101` | Sand Dwarf（沙漠矮人） | 38 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3110100` | Ligator（鳄鱼人） | 40 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3110101` | Pink Teddy（粉色泰迪熊） | 42 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3110102` | Ratz（玩具老鼠） | 40 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3110300` | Cube Slime（方块史莱姆） | 38 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3210100` | Fire Boar（火独眼兽） | 40 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3210200` | Jr. Cellion（小狮子） | 45 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3210201` | Jr. Lioner（小狮王） | 48 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3210202` | Jr. Grupin（小狮鹫） | 50 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3210203` | Panda Teddy（熊猫泰迪） | 52 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3210204` | Roloduck（玩具鸭） | 45 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3210205` | Black Ratz（黑色玩具鼠） | 42 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3210800` | Lupin（猴子战士） | 55 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3220001` | Deo（恶魔 BOSS 候选） | 50 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3230100` | Curse Eye（诅咒邪眼） | 52 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3230101` | Jr. Wraith（小幽灵） | 55 | float/attack/hit/dead | ⏳ 待获取 |
| `3230102` | Lorang（玩具飞机） | 55 | fly/attack/hit/dead | ⏳ 待获取 |
| `3230103` | King Bloctopus（墨鱼王） | 58 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3230104` | Mask Fish（面具鱼） | 55 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3230200` | Star Pixie（星光精灵） | 60 | float/attack/hit/dead | ⏳ 待获取 |
| `3230301` | Jr. Boogie 2（小布基 2） | 60 | float/attack/hit/dead | ⏳ 待获取 |
| `3230303` | Propelly（螺旋桨飞机） | 55 | fly/attack/hit/dead | ⏳ 待获取 |
| `3230304` | Planey（玩具飞机） | 55 | fly/attack/hit/dead | ⏳ 待获取 |
| `3230305` | Toy Trojan（木马兵） | 55 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3230306` | Chronos（时空机器） | 58 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3230400` | Drumming Bunny（打鼓兔子） | 55 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3230405` | Jr. Seal（小海豹） | 60 | stand/move/attack/hit/dead | ⏳ 待获取 |

### 2.4 中高级区域（Lv 60 - 100，Ludibrium / El Nath / Orbis）

| 怪物 ID | 名称 | 等级 | 推荐动作 | 状态 |
|---------|------|------|---------|------|
| `4090000` | Iron Hook（铁钩海盗） | 60 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `4110300` | Iron Mutae（铁皮变种） | 65 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `4110301` | Reinforced Iron Mutae（强化铁皮变种） | 70 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `4110302` | Mithril Mutae（秘银变种） | 75 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `4130100` | Copper Drake（铜龙） | 70 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `4130101` | Tortie（乌龟战士） | 72 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `4130102` | Dark Nependeath（黑暗食花怪） | 75 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `4130103` | Rombot（龙机甲） | 80 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `4230100` | Cold Eye（冰邪眼） | 72 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `4230101` | Zombie Lupin（僵尸猴） | 75 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `4230102` | Wraith（大幽灵） | 78 | float/attack/hit/dead | ⏳ 待获取 |
| `4230103` | Iron Hog（铁野猪） | 80 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `4230104` | Clang（铁叮当） | 80 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `4230105` | Nependeath（食花怪） | 85 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `4230106` | Lunar Pixie（月光精灵） | 90 | float/attack/hit/dead | ⏳ 待获取 |
| `4230107` | Flyeye（飞眼怪） | 88 | fly/attack/hit/dead | ⏳ 待获取 |
| `3000003` / `3000004` | 棕色/金色 Teddy（Boss 级泰迪熊） | 70 / 80 | stand/move/attack/hit/dead | ⏳ 待获取 |
| `3000001` | Fairy（妖精士兵） | 65 | fly/attack/hit/dead | ⏳ 待获取 |
| `3000002` | Fairy（妖精法师） | 68 | float/attack/hit/dead | ⏳ 待获取 |

### 2.5 高级 BOSS（Lv 80 - 120）

| 怪物 ID | 名称 | 等级 | 说明 | 状态 |
|---------|------|------|------|------|
| `boss_mushmom` | Mushmom（蘑菇王 BOSS） | 30 | 蘑菇王国统治者 | ⏳ 待获取 |
| `boss_alishar` | Alishar（组队任务 BOSS） | 50 | 玩具城地下通道 BOSS | ⏳ 待获取 |
| `boss_papulatus` | Papulatus（皮亚努斯） | 80 | 玩具城时空裂缝 BOSS | ⏳ 待获取 |
| `boss_pianus_left` | Pianus Left（左皮亚纳斯） | 85 | 海底世界左 BOSS | ⏳ 待获取 |
| `boss_pianus_right` | Pianus Right（右皮亚纳斯） | 85 | 海底世界右 BOSS | ⏳ 待获取 |
| `boss_zakum_arm_01` ~ `boss_zakum_arm_08` | Zakum Arms（扎昆八只手） | 85 | 扎昆前置 BOSS | ⏳ 待获取 |
| `boss_zakum_body_1` | Zakum Body 1（扎昆主体 1） | 90 | 扎昆第一形态 | ⏳ 待获取 |
| `boss_zakum_body_2` | Zakum Body 2（扎昆主体 2） | 100 | 扎昆第二形态 | ⏳ 待获取 |
| `boss_zakum_body_3` | Zakum Body 3（扎昆主体 3） | 110 | 扎昆第三形态（终极 BOSS） | ⏳ 待获取 |
| `boss_ice_unicorn` | 玄冰独角兽 | 70 | 冰峰雪域 BOSS | ⏳ 待获取 |
| `boss_black_knight` | 暗黑骑士团将领 | 95 | 战士团 BOSS | ⏳ 待获取 |

---

## 三、NPC 精灵（Non-Player Character）

> 参考数据：HeavenMS NPC.txt。每个 NPC 需要至少 `stand` / `talk`（对话动画）两种状态。

### 3.1 新手村 NPC

| NPC ID | 名称 | 位置 | 推荐尺寸 | 状态 |
|--------|------|------|---------|------|
| `10000` | Sena（新手向导） | Maple Road | 60x96 | ⏳ 待获取 |
| `10100` | Lucas（明珠港传送员） | Lith Harbor | 60x96 | ⏳ 待获取 |
| `10200` | Perion Village Chief（勇士部落村长） | Perion | 60x96 | ⏳ 待获取 |
| `10300` | Ellinia Elder（魔法密林长老） | Ellinia | 60x96 | ⏳ 待获取 |
| `10400` | Henesys Village Chief（射手村长老） | Henesys | 60x96 | ⏳ 待获取 |
| `10500` | Kerning City Mayor（废弃都市市长） | Kerning City | 60x96 | ⏳ 待获取 |
| `10600` | General Store Merchant（杂货商店老板） | 全地图 | 60x96 | ⏳ 待获取 |
| `10700` | Weapon Shop Merchant（武器店老板） | 各村落 | 60x96 | ⏳ 待获取 |
| `10800` | Armor Shop Merchant（防具店老板） | 各村落 | 60x96 | ⏳ 待获取 |
| `10900` | Potion Shop Merchant（药水店老板） | 各村落 | 60x96 | ⏳ 待获取 |
| `20000` | Orbis Ticket Seller（天空之城售票员） | Orbis | 60x96 | ⏳ 待获取 |
| `20100` | El Nath Trader（冰峰雪域商人） | El Nath | 60x96 | ⏳ 待获取 |

### 3.2 关键任务 NPC（Quest NPCs）

| NPC ID | 名称 | 相关任务 | 状态 |
|--------|------|---------|------|
| `20200` | Athena Pierce（弓箭手导师） | 弓箭手 1-3 转转职 | ⏳ 待获取 |
| `20300` | Grendel the Really Old（法师导师） | 法师 1-3 转转职 | ⏳ 待获取 |
| `20400` | Dark Lord（飞侠导师） | 飞侠 1-3 转转职 | ⏳ 待获取 |
| `20500` | Dances with Balrog（战士导师） | 战士 1-3 转转职 | ⏳ 待获取 |
| `20600` | Kyrin（海盗导师） | 海盗 1-3 转转职 | ⏳ 待获取 |
| `20800` | 4th Job Instructor（四转导师） | 四转终极任务 | ⏳ 待获取 |
| `21000` | 扎昆祭台祭司 | 扎昆前置任务 | ⏳ 待获取 |
| `22000` | 时空门守卫（皮亚努斯） | 玩具城组队任务 | ⏳ 待获取 |

---

## 四、传送门 / 特效精灵（Portal / Effects）

| 精灵文件 | 描述 | 推荐尺寸 | 状态 |
|---------|------|---------|------|
| `portal_normal.png` | 普通传送门（发光蓝色圈） | 64x96 | ⏳ 待获取 |
| `portal_hidden.png` | 隐藏传送门（闪烁金色粒子） | 64x96 | ⏳ 待获取 |
| `portal_party.png` | 组队传送门（红色光环） | 64x96 | ⏳ 待获取 |
| `portal_cashshop.png` | 现金商城传送门 | 64x96 | ⏳ 待获取 |
| `portal_town.png` | 回城传送门（绿色图腾） | 64x96 | ⏳ 待获取 |
| `effect_hit_spark.png` | 击中火星特效 | 48x48 | ⏳ 待获取 |
| `effect_critical_hit.png` | 暴击闪光（红色大光爆） | 64x64 | ⏳ 待获取 |
| `effect_damage_number.png` | 伤害数字字体 | 位图字体 | ⏳ 待获取 |
| `effect_levelup_halo.png` | 升级光环（金色环上升） | 128x128 | ⏳ 待获取 |

---

## 五、精灵格式规范

### 5.1 推荐：Spritesheet + JSON Metadata

每个精灵资源需要一个 PNG 图集 + 一个 JSON 描述文件：

```json
{
  "image": "mob/100100.png",
  "frame_width": 60,
  "frame_height": 60,
  "origin_x": 30,
  "origin_y": 55,
  "fps": 8,
  "actions": {
    "stand":    { "frames": [0, 1, 2, 3], "loop": true },
    "move":     { "frames": [4, 5, 6, 7], "loop": true },
    "attack":   { "frames": [8, 9, 10, 11, 12], "loop": false },
    "hit":      { "frames": [13, 14], "loop": false },
    "dead":     { "frames": [15, 16, 17, 18], "loop": false }
  }
}
```

### 5.2 图像参数

| 参数 | 推荐值 |
|------|--------|
| 格式 | PNG-32（带 Alpha 通道） |
| 色板 | 保留原始 16-bit 色板以保持风格 |
| 缩放 | 建议 1x 原始像素，在引擎中使用最近邻缩放 |
| 角色帧大小 | 60x96（全职业统一） |
| 怪物帧大小 | 60x60（普通）/ 100x100（大型）/ 200x200（BOSS） |
| NPC 帧大小 | 60x96 |

---

## 六、开源替代资源

| 资源 | 说明 | 许可证 |
|------|------|--------|
| [opengameart.org - 2D RPG sprites](https://opengameart.org) | 2D RPG 角色 / 怪物精灵合集 | CC0 / CC-BY |
| [itch.io - Free 2D Assets](https://itch.io/game-assets/free/tag-2d) | 免费 2D 精灵合集（支持 spritesheet） | 各独立作者 |
| [kenney.nl/assets](https://kenney.nl/assets) | Kenney 的 CC0 1-Bit / Roguelike 素材 | CC0 |
| [ansimuz.com](https://ansimuz.com) | Ansimuz 的免费 RPG 角色 / 怪物集合 | Free / Paid |

---

> **版权说明**：本项目为学习复刻研究，若部署商业版本，请使用自有或已获授权的精灵资源。
