# 冒险岛 079 精灵（Sprite）资源清单

> 记录冒险岛 079 版本中的角色 / 怪物 / NPC / 坐骑 等精灵动画资源。
> 资源路径：`client/assets/sprites/`
> 所有精灵建议使用 **PNG 序列帧 / Aseprite / Spritesheet + JSON** 格式。

---

## 一、角色精灵（玩家角色）

### 1.1 基础动作（全职业通用）

| 动作名称 | 帧数 | 说明 | 状态 |
|---------|------|------|------|
| `stand` / `idle` | 4 | 站立待机 | ⏳ 待获取 |
| `walk` | 4 | 行走（左右方向需翻转） | ⏳ 待获取 |
| `jump` | 4 | 跳跃上升 | ⏳ 待获取 |
| `fall` | 2 | 下落 | ⏳ 待获取 |
| `alert` | 3 | 警戒 / 惊讶 | ⏳ 待获取 |
| `prone` | 2 | 匍匐 | ⏳ 待获取 |
| `dead` | 4 | 死亡 | ⏳ 待获取 |
| `ladder` | 4 | 爬梯子 | ⏳ 待获取 |
| `rope` | 4 | 爬绳子 | ⏳ 待获取 |
| `hurt` | 2 | 受伤 | ⏳ 待获取 |
| `sit` | 3 | 坐下 | ⏳ 待获取 |
| `portal` | 4 | 进传送门 | ⏳ 待获取 |

### 1.2 职业动作

| 动作 | 职业 | 说明 | 状态 |
|------|------|------|------|
| `attack_sword` | 战士 | 单手剑攻击 | ⏳ 待获取 |
| `attack_spear` | 战士 | 长枪/矛攻击 | ⏳ 待获取 |
| `attack_polearm` | 战士 | 斧/锤攻击 | ⏳ 待获取 |
| `shoot_bow` | 弓箭手 | 弓射击 | ⏳ 待获取 |
| `shoot_crossbow` | 弓箭手 | 弩射击 | ⏳ 待获取 |
| `cast_magic` | 法师 | 施法动作 | ⏳ 待获取 |
| `attack_dagger` | 飞侠 | 短剑攻击 | ⏳ 待获取 |
| `throw_star` | 飞侠 | 投掷飞镖 | ⏳ 待获取 |
| `attack_gun` | 海盗 | 火枪射击 | ⏳ 待获取 |
| `attack_knuckle` | 海盗 | 指节拳击 | ⏳ 待获取 |

### 1.3 装备部位（Body / Hair / Face / Weapon）

冒险岛的角色精灵由多个部件叠加合成：

| 部件 | 说明 | 尺寸 | 状态 |
|------|------|------|------|
| `body` | 身体（基础服装） | ~ 60x96 | ⏳ 待获取 |
| `hair` | 发型（需多种款式） | ~ 60x96 | ⏳ 待获取 |
| `face` | 表情（眨眼/笑/怒等） | ~ 60x96 | ⏳ 待获取 |
| `cap` | 帽子 | ~ 60x96 | ⏳ 待获取 |
| `coat` | 上衣 | ~ 60x96 | ⏳ 待获取 |
| `pants` | 下装 | ~ 60x96 | ⏳ 待获取 |
| `shoes` | 鞋子 | ~ 60x96 | ⏳ 待获取 |
| `weapon` | 武器 | ~ 60x96 | ⏳ 待获取 |
| `shield` | 盾牌 | ~ 60x96 | ⏳ 待获取 |
| `cape` | 披风 | ~ 60x96 | ⏳ 待获取 |
| `accessory` | 饰品（戒指/耳环等） | ~ 60x96 | ⏳ 待获取 |
| `mount` | 坐骑（可叠加） | ~ 120x96 | ⏳ 待获取 |

> 建议每个角色精灵以 **spritesheet** 形式发布：
> ```
> warrior/walk.png (4 frames, 每帧 60x96)
> warrior/walk.json  (frame metadata)
> ```

## 二、怪物精灵

### 2.1 新手 / 初级怪物

| 怪物 ID | 名称 | 等级 | 动作 | 状态 |
|---------|------|------|------|------|
| `0100100` | 蜗牛 Snail | 1 | move/attack/dead/hit | ⏳ 待获取 |
| `0100101` | 蓝蜗牛 Blue Snail | 2 | move/attack/dead/hit | ⏳ 待获取 |
| `0100102` | 红蜗牛 Red Snail | 3 | move/attack/dead/hit | ⏳ 待获取 |
| `0100200` | 蘑菇仔 Orange Mushroom | 5 | move/attack/dead/hit | ⏳ 待获取 |
| `0100300` | 绿水灵 Slime | 5 | move/attack/dead/hit | ⏳ 待获取 |
| `0100400` | 花蘑菇 Pig | 6 | move/attack/dead/hit | ⏳ 待获取 |
| `0100500` | 猪猪 Ribbon Pig | 8 | move/attack/dead/hit | ⏳ 待获取 |

### 2.2 中级怪物

| 怪物 ID | 名称 | 等级 | 状态 |
|---------|------|------|------|
| `0200100` | 石球 Stone Golem | 15 | ⏳ 待获取 |
| `0200200` | 火独眼兽 Fire Boar | 22 | ⏳ 待获取 |
| `0200300` | 冰独眼兽 Ice Boar | 25 | ⏳ 待获取 |
| `0300100` | 僵尸猴 Zombie Mushmom | 35 | ⏳ 待获取 |
| `0300200` | 大幽灵 Wraith | 45 | ⏳ 待获取 |
| `0400100` | 灰狼 Werewolf | 55 | ⏳ 待获取 |
| `0500100` | 白狼 White Fang | 60 | ⏳ 待获取 |

### 2.3 BOSS

| BOSS ID | 名称 | 等级 | 状态 |
|---------|------|------|------|
| `boss_001` | 蘑菇王 Mushmom | 30 | ⏳ 待获取 |
| `boss_002` | 阿丽莎乐 Alishar | 45 | ⏳ 待获取 |
| `boss_003` | 皮亚努斯 Papulatus | 80 | ⏳ 待获取 |
| `boss_004` | 扎昆 Zakum | 90 | ⏳ 待获取 |
| `boss_005` | 皮亚纳斯 Pianus | 85 | ⏳ 待获取 |
| `boss_006` | 玄冰独角兽 | 70 | ⏳ 待获取 |

## 三、NPC 精灵

| NPC ID | 名称 | 场景 | 状态 |
|--------|------|------|------|
| `10000` | 希娜（新手向导） | 彩虹村 | ⏳ 待获取 |
| `10100` | 露西娅（明珠港向导） | 明珠港 | ⏳ 待获取 |
| `10200` | 勇士部落村长 | 勇士部落 | ⏳ 待获取 |
| `10300` | 魔法密林长老 | 魔法密林 | ⏳ 待获取 |
| `10400` | 射手村长老 | 射手村 | ⏳ 待获取 |
| `10500` | 废弃都市老板 | 废弃都市 | ⏳ 待获取 |
| `10600` | 商店老板（通用） | 全地图 | ⏳ 待获取 |
| `10700` | 武器店老板 | 全地图 | ⏳ 待获取 |
| `10800` | 防具店老板 | 全地图 | ⏳ 待获取 |
| `10900` | 药水店老板 | 全地图 | ⏳ 待获取 |
| `20000` | 飞天术师（天空之城） | 天空之城 | ⏳ 待获取 |

## 四、其他精灵

| 类别 | 描述 | 状态 |
|------|------|------|
| `mount/001` | 坐骑 1（小猪） | ⏳ 待获取 |
| `mount/002` | 坐骑 2（银色野猪） | ⏳ 待获取 |
| `mount/003` | 坐骑 3（飞龙） | ⏳ 待获取 |
| `pet/001` | 宠物（白色小猫） | ⏳ 待获取 |
| `pet/002` | 宠物（棕色小狗） | ⏳ 待获取 |
| `pet/003` | 宠物（粉色小兔） | ⏳ 待获取 |
| `portal/normal` | 普通传送门动画 | ⏳ 待获取 |
| `portal/party` | 组队传送门 | ⏳ 待获取 |
| `portal/cashshop` | 商城传送门 | ⏳ 待获取 |

## 五、精灵格式规范

### 5.1 推荐：Spritesheet + JSON

```json
{
  "image": "warrior_walk.png",
  "frame_width": 60,
  "frame_height": 96,
  "origin_x": 30,
  "origin_y": 90,
  "frames": 4,
  "fps": 8,
  "loop": true
}
```

### 5.2 备用：Aseprite .aseprite 文件

直接保存源文件，后续用 `aseprite --batch ...` 自动导出序列帧。

### 5.3 图像参数

| 参数 | 推荐值 |
|------|--------|
| 格式 | PNG-32 (带 Alpha) |
| 缩放 | 建议 1x（原始像素），在客户端用最近邻缩放放大 |
| 色板 | 建议保留原始 16-bit 色板以保持风格 |
| 单帧大小 | 60x96（角色）/ 100x100（怪物） |

## 六、开源替代资源

| 资源 | 说明 | 许可证 |
|------|------|--------|
| [opengameart.org - 2D RPG sprites](https://opengameart.org) | 2D RPG 角色 / 怪物 精灵 | CC0 / CC-BY |
| [itch.io - Free 2D Assets](https://itch.io/game-assets/free/tag-2d) | 免费 2D 精灵合集 | 各作者 |
| [kenney.nl/assets](https://kenney.nl/assets) | Kenney 的 CC0 1-Bit / Roguelike 素材 | CC0 |
| [Ansimuz / SecretAncientTech Pack](https://ansimuz.itch.io) | 多款免费 RPG 素材 | Free / Paid |

## 七、Flutter 渲染建议

- 使用 `flame` 的 `SpriteAnimation` 加载 spritesheet
- 角色合成：使用 `Canvas.drawAtlas` 进行多部件叠加绘制
- 行走动画帧速率：8–12 FPS（与原版一致）
- 伤害数字 / 浮动文字：叠加在角色头顶 30 px 处

---

## 八、自动导入清单

以下内容可直接粘贴到 Dart 文件中作为资源加载器使用的字符串常量清单（以精灵目录+关键动作为主）。

```dart
// === 一、角色精灵（玩家角色）===
// 基础动作（全职业通用）
static const String playerSpriteStand      = 'assets/sprites/player/common/stand.png';
static const String playerSpriteWalk        = 'assets/sprites/player/common/walk.png';
static const String playerSpriteJump        = 'assets/sprites/player/common/jump.png';
static const String playerSpriteFall        = 'assets/sprites/player/common/fall.png';
static const String playerSpriteAlert       = 'assets/sprites/player/common/alert.png';
static const String playerSpriteProne       = 'assets/sprites/player/common/prone.png';
static const String playerSpriteDead        = 'assets/sprites/player/common/dead.png';
static const String playerSpriteLadder      = 'assets/sprites/player/common/ladder.png';
static const String playerSpriteRope        = 'assets/sprites/player/common/rope.png';
static const String playerSpriteHurt        = 'assets/sprites/player/common/hurt.png';
static const String playerSpriteSit          = 'assets/sprites/player/common/sit.png';
static const String playerSpritePortal     = 'assets/sprites/player/common/portal.png';

// 职业动作
static const String playerSpriteAttackSword   = 'assets/sprites/player/warrior/attack_sword.png';
static const String playerSpriteAttackSpear   = 'assets/sprites/player/warrior/attack_spear.png';
static const String playerSpriteAttackPolearm = 'assets/sprites/player/warrior/attack_polearm.png';
static const String playerSpriteShootBow       = 'assets/sprites/player/bowman/shoot_bow.png';
static const String playerSpriteShootCrossbow   = 'assets/sprites/player/bowman/shoot_crossbow.png';
static const String playerSpriteCastMagic      = 'assets/sprites/player/magician/cast_magic.png';
static const String playerSpriteAttackDagger    = 'assets/sprites/player/thief/attack_dagger.png';
static const String playerSpriteThrowStar       = 'assets/sprites/player/thief/throw_star.png';
static const String playerSpriteAttackGun       = 'assets/sprites/player/pirate/attack_gun.png';
static const String playerSpriteAttackKnuckle   = 'assets/sprites/player/pirate/attack_knuckle.png';

// 装备部件
static const String playerBody      = 'assets/sprites/player/parts/body.png';
static const String playerHair      = 'assets/sprites/player/parts/hair.png';
static const String playerFace      = 'assets/sprites/player/parts/face.png';
static const String playerCap       = 'assets/sprites/player/parts/cap.png';
static const String playerCoat      = 'assets/sprites/player/parts/coat.png';
static const String playerPants     = 'assets/sprites/player/parts/pants.png';
static const String playerShoes     = 'assets/sprites/player/parts/shoes.png';
static const String playerWeapon     = 'assets/sprites/player/parts/weapon.png';
static const String playerShield     = 'assets/sprites/player/parts/shield.png';
static const String playerCape       = 'assets/sprites/player/parts/cape.png';
static const String playerAccessory   = 'assets/sprites/player/parts/accessory.png';
static const String playerMount       = 'assets/sprites/player/parts/mount.png';

// === 二、怪物精灵 ===
static const String mobSnail            = 'assets/sprites/mob/0100100.png';
static const String mobBlueSnail        = 'assets/sprites/mob/0100101.png';
static const String mobRedSnail         = 'assets/sprites/mob/0100102.png';
static const String mobOrangeMushroom  = 'assets/sprites/mob/0100200.png';
static const String mobSlime            = 'assets/sprites/mob/0100300.png';
static const String mobPig              = 'assets/sprites/mob/0100400.png';
static const String mobRibbonPig        = 'assets/sprites/mob/0100500.png';
static const String mobStoneGolem      = 'assets/sprites/mob/0200100.png';
static const String mobFireBoar         = 'assets/sprites/mob/0200200.png';
static const String mobIceBoar         = 'assets/sprites/mob/0200300.png';
static const String mobZombieMushmom   = 'assets/sprites/mob/0300100.png';
static const String mobWraith           = 'assets/sprites/mob/0300200.png';
static const String mobWerewolf         = 'assets/sprites/mob/0400100.png';
static const String mobWhiteFang       = 'assets/sprites/mob/0500100.png';
static const String mobBossMushmom      = 'assets/sprites/mob/boss_001.png';
static const String mobBossAlishar       = 'assets/sprites/mob/boss_002.png';
static const String mobBossPapulatus     = 'assets/sprites/mob/boss_003.png';
static const String mobBossZakum        = 'assets/sprites/mob/boss_004.png';
static const String mobBossPianus       = 'assets/sprites/mob/boss_005.png';
static const String mobBossUnicorn      = 'assets/sprites/mob/boss_006.png';

// === 三、NPC 精灵 ===
static const String npc10000              = 'assets/sprites/npc/10000.png';
static const String npc10100              = 'assets/sprites/npc/10100.png';
static const String npc10200              = 'assets/sprites/npc/10200.png';
static const String npc10300              = 'assets/sprites/npc/10300.png';
static const String npc10400              = 'assets/sprites/npc/10400.png';
static const String npc10500              = 'assets/sprites/npc/10500.png';
static const String npc10600              = 'assets/sprites/npc/10600.png';
static const String npc10700              = 'assets/sprites/npc/10700.png';
static const String npc10800              = 'assets/sprites/npc/10800.png';
static const String npc10900              = 'assets/sprites/npc/10900.png';
static const String npc20000              = 'assets/sprites/npc/20000.png';

// === 四、其他精灵（坐骑 / 宠物 / 传送门）===
static const String mount001              = 'assets/sprites/mount/001.png';
static const String mount002              = 'assets/sprites/mount/002.png';
static const String mount003              = 'assets/sprites/mount/003.png';
static const String pet001                = 'assets/sprites/pet/001.png';
static const String pet002                = 'assets/sprites/pet/002.png';
static const String pet003                = 'assets/sprites/pet/003.png';
static const String portalNormal         = 'assets/sprites/portal/normal.png';
static const String portalParty           = 'assets/sprites/portal/party.png';
static const String portalCashShop       = 'assets/sprites/portal/cashshop.png';
```

---

> **版权说明**：本项目为学习复刻研究，若部署商业版本，请使用自有或已获授权的精灵资源。
