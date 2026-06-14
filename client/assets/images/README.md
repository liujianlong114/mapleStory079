# 冒险岛 079 贴图（UI / Tile / Icon）资源清单

> 记录冒险岛 079 版本中的 UI 贴图、地图瓦片、物品图标、技能图标等图片资源。
> 资源路径：`client/assets/images/`
> 原始数据参考：HeavenMS Map.txt / Mob.txt / Skill.txt / Use.txt

---

## 一、UI 系统贴图（UI.wz / MobBook / QuestBook）

| 文件路径 | 组件 | 功能说明 | 规格 | 状态 |
|---------|------|---------|------|------|
| `ui/title_logo.png` | 游戏标题 LOGO | 079 版本经典 "MapleStory" 彩色 Logo | 800x200 PNG | ⏳ 待获取 |
| `ui/title_bg.png` | 标题界面背景 | 彩虹村 / 经典天空蓝背景 | 1920x1080 PNG | ⏳ 待获取 |
| `ui/login_bg.png` | 登录界面背景 | 魔法师森林风格夜景 | 1920x1080 PNG | ⏳ 待获取 |
| `ui/select_bg.png` | 角色选择界面背景 | 5 个职业展示台 | 1920x1080 PNG | ⏳ 待获取 |
| `ui/btn_normal.png` | 按钮普通状态 | 经典木纹按钮 | 9-slice PNG | ⏳ 待获取 |
| `ui/btn_hover.png` | 按钮悬停状态 | 高亮金色描边 | 9-slice PNG | ⏳ 待获取 |
| `ui/btn_pressed.png` | 按钮按下状态 | 凹陷木纹 | 9-slice PNG | ⏳ 待获取 |
| `ui/btn_disabled.png` | 按钮禁用状态 | 灰色按钮 | 9-slice PNG | ⏳ 待获取 |
| `ui/panel_window.png` | 通用窗口面板 | 对话框 / NPC 对话 / 任务面板 | 9-slice PNG | ⏳ 待获取 |
| `ui/panel_dark.png` | 暗色窗口面板 | 背包 / 技能 / 装备栏 | 9-slice PNG | ⏳ 待获取 |
| `ui/slot_empty.png` | 空物品槽 | 2x2 圆角物品格 | 36x36 PNG | ⏳ 待获取 |
| `ui/slot_equipped.png` | 已装备物品槽 | 金色描边高亮 | 36x36 PNG | ⏳ 待获取 |
| `ui/slot_cash.png` | 点券物品专用格 | 绿色标题现金装备 | 36x36 PNG | ⏳ 待获取 |
| `ui/hp_bar.png` | HP 血条 | 红色渐变条 | 9-slice PNG | ⏳ 待获取 |
| `ui/mp_bar.png` | MP 蓝条 | 蓝色渐变条 | 9-slice PNG | ⏳ 待获取 |
| `ui/exp_bar.png` | EXP 经验条 | 黄色渐变条 | 9-slice PNG | ⏳ 待获取 |
| `ui/scroll_bg.png` | 滚动面板背景 | 像素风可平铺纹理 | 可平铺 | ⏳ 待获取 |
| `ui/scroll_up.png` | 向上滚动按钮 | 三角箭头 | 16x16 PNG | ⏳ 待获取 |
| `ui/scroll_down.png` | 向下滚动按钮 | 三角箭头 | 16x16 PNG | ⏳ 待获取 |
| `ui/icon_meso.png` | 金币图标 | 金色圆形硬币 | 24x24 PNG | ⏳ 待获取 |
| `ui/icon_cash.png` | 点券图标 | 绿色现金点卡 | 24x24 PNG | ⏳ 待获取 |
| `ui/hud_status.png` | HUD 状态栏 | 角色 HP/MP/EXP/头像复合面板 | 9-slice PNG | ⏳ 待获取 |
| `ui/minimap.png` | 小地图窗口 | 可拖动的 160x160 地图缩略图窗口 | 9-slice PNG | ⏳ 待获取 |
| `ui/quest_icon.png` | 任务图标 | Q 字母气泡 / NPC 头上感叹号 | 24x24 PNG | ⏳ 待获取 |
| `ui/damage_font.png` | 伤害数字字体 | 白色主伤害 + 红色暴击 | 位图字体 | ⏳ 待获取 |

## 二、地图瓦片集合（Tile / 背景分层）

| 目录 | 主题 | 瓦片大小 | 对应地图 | 状态 |
|------|------|---------|---------|------|
| `tiles/victoria/grass/` | 彩虹村 / 射手村 - 草地 | 64x64 | `0 – 100000000` | ⏳ 待获取 |
| `tiles/victoria/stone/` | 勇士部落 - 岩石 / 石地 | 64x64 | `102000000` | ⏳ 待获取 |
| `tiles/victoria/tree/` | 魔法密林 - 树木 / 藤蔓 | 64x64 | `101000000` | ⏳ 待获取 |
| `tiles/victoria/metal/` | 废弃都市 - 金属 / 工厂 | 64x64 | `103000000` | ⏳ 待获取 |
| `tiles/victoria/sand/` | 明珠港 - 沙滩 / 港口 | 64x64 | `104000000` | ⏳ 待获取 |
| `tiles/ossyria/snow/` | 冰峰雪域 - 雪地 / 冰山 | 64x64 | `211000000` | ⏳ 待获取 |
| `tiles/ossyria/cloud/` | 天空之城 - 云朵 / 浮岛 | 64x64 | `200000000` | ⏳ 待获取 |
| `tiles/ludi/toyblock/` | 玩具城 - 玩具砖 / 积木 | 64x64 | `220000000` | ⏳ 待获取 |
| `tiles/aqua/coral/` | 海底世界 - 珊瑚 / 水草 | 64x64 | `230000000` | ⏳ 待获取 |
| `tiles/kft/folk/` | 童话村 - 韩屋 / 古木 | 64x64 | `250000000` | ⏳ 待获取 |
| `tiles/mulung/bamboo/` | 武陵 - 竹林 / 山石 | 64x64 | `250000100` | ⏳ 待获取 |
| `tiles/herbtown/herb/` | 百草堂 - 草地 / 湿地 | 64x64 | `251000000` | ⏳ 待获取 |
| `tiles/omega/sci/` | 地球防御本部 - 金属走廊 | 64x64 | `221000000` | ⏳ 待获取 |
| `tiles/nautilus/ship/` | 海盗船 - 木质甲板 | 64x64 | `120000000` | ⏳ 待获取 |

## 三、地图背景图（整张 / 分层背景）

| 文件路径 | 地图名称 | MAP ID 参考 | 分辨率 | 状态 |
|---------|---------|------------|--------|------|
| `map/maple_road_000.png` | 枫叶之路（新手村） | `0 – 60001` | 1600x600 | ⏳ 待获取 |
| `map/henesys_100.png` | 射手村（Henesys） | `100000000` | 1600x800 | ⏳ 待获取 |
| `map/ellinia_100.png` | 魔法密林（Ellinia） | `101000000` | 1600x800 | ⏳ 待获取 |
| `map/perion_100.png` | 勇士部落（Perion） | `102000000` | 1600x800 | ⏳ 待获取 |
| `map/kerning_100.png` | 废弃都市（Kerning City） | `103000000` | 1600x800 | ⏳ 待获取 |
| `map/lith_harbor_100.png` | 明珠港（Lith Harbor） | `104000000` | 1600x600 | ⏳ 待获取 |
| `map/orbis_100.png` | 天空之城（Orbis） | `200000000` | 1600x900 | ⏳ 待获取 |
| `map/el_nath_100.png` | 冰峰雪域（El Nath） | `211000000` | 1600x900 | ⏳ 待获取 |
| `map/ludibrium_100.png` | 玩具城（Ludibrium） | `220000000` | 1600x900 | ⏳ 待获取 |
| `map/aqua_road_100.png` | 海底世界（Aqua Road） | `230000000` | 1600x900 | ⏳ 待获取 |
| `map/korean_folk_100.png` | 童话村（Korean Folk Town） | `250000000` | 1600x900 | ⏳ 待获取 |
| `map/mu_lung_100.png` | 武陵（Mu Lung） | `250000100` | 1600x900 | ⏳ 待获取 |
| `map/herb_town_100.png` | 百草堂（Herb Town） | `251000000` | 1600x900 | ⏳ 待获取 |
| `map/omega_100.png` | 地球防御本部（Omega Sector） | `221000000` | 1600x900 | ⏳ 待获取 |
| `map/nautilus_100.png` | 海盗船（Nautilus） | `120000000` | 1600x800 | ⏳ 待获取 |
| `map/golem_temple_100.png` | 石人寺院 | `105040301` | 1600x900 | ⏳ 待获取 |
| `map/drake_sleeping_100.png` | 龙之巢穴 | `240020100` | 1600x900 | ⏳ 待获取 |
| `map/zakum_entrance_100.png` | 扎昆入口 | `211040100` | 1600x900 | ⏳ 待获取 |

## 四、物品图标（Item / Consume / Equip / Etc）

> 冒险岛 079 物品 ID 系统：`Consume (2xxx) / Equip (1xxx) / Setup (3xxx) / Etc (4xxx) / Cash (5xxx)`。图标大小统一 **32x32**。

### 4.1 消耗品（Consume：药水/食物/卷轴）

| 图标文件 | 物品名 | 物品 ID 示例 | 用途 | 状态 |
|---------|-------|-------------|------|------|
| `items/consume/red_potion.png` | 红色药水 | `2000000` | 回复 50 HP | ⏳ 待获取 |
| `items/consume/orange_potion.png` | 橙色药水 | `2000001` | 回复 150 HP | ⏳ 待获取 |
| `items/consume/white_potion.png` | 白色药水 | `2000002` | 回复 300 HP | ⏳ 待获取 |
| `items/consume/blue_potion.png` | 蓝色药水 | `2000003` | 回复 100 MP | ⏳ 待获取 |
| `items/consume/elixir.png` | 艾利克塞 | `2000004` | 回复 50% HP+MP | ⏳ 待获取 |
| `items/consume/power_elixir.png` | 强力艾利克塞 | `2000005` | 完全回复 | ⏳ 待获取 |
| `items/consume/apple.png` | 苹果 | `2010000` | 回复 30 HP | ⏳ 待获取 |
| `items/consume/honey.png` | 蜂蜜 | `2010005` | 回复 30% HP+MP | ⏳ 待获取 |
| `items/consume/scroll_armor.png` | 装备强化卷轴 | `2040000` | 随机属性强化 | ⏳ 待获取 |
| `items/consume/scroll_weapon.png` | 武器强化卷轴 | `2040100` | 武器攻击强化 | ⏳ 待获取 |
| `items/consume/summon_bag.png` | 召唤包 | `2022138` | 召唤怪物到身边 | ⏳ 待获取 |

### 4.2 装备（Equip）

| 目录 | 装备类型 | 等级分层 | 示例装备 | 状态 |
|------|---------|---------|---------|------|
| `items/equip/cap/` | 帽子 (Cap) | Lv 0-100 | Basic Cap / Red Bandana / Gold Dragon Vein | ⏳ 待获取 |
| `items/equip/coat/` | 上衣 (Coat) | Lv 0-80 | Green Adventurer / Ninja Coat | ⏳ 待获取 |
| `items/equip/pants/` | 下装 (Pants) | Lv 0-80 | White Pants / Ninja Pants | ⏳ 待获取 |
| `items/equip/shoes/` | 鞋子 (Shoes) | Lv 0-80 | Snowshoes / Leather Boots | ⏳ 待获取 |
| `items/equip/shield/` | 盾 (Shield) | Lv 10-80 | Wooden Shield / Steel Shield | ⏳ 待获取 |
| `items/equip/weapon_sword1h/` | 单手剑 (1H Sword) | Lv 0-80 | Short Sword / Red Snow Sword | ⏳ 待获取 |
| `items/equip/weapon_sword2h/` | 双手剑 (2H Sword) | Lv 0-80 | Red Katana / Dragon Blade | ⏳ 待获取 |
| `items/equip/weapon_axe1h/` | 单手斧 (1H Axe) | Lv 0-80 | Wooden Axe / Steel Axe | ⏳ 待获取 |
| `items/equip/weapon_mace1h/` | 单手钝器 (1H Mace) | Lv 0-80 | Wooden Club / Silver Mace | ⏳ 待获取 |
| `items/equip/weapon_polearm/` | 枪矛 (Polearm/Spear) | Lv 10-80 | Long Spear / Ice Fang | ⏳ 待获取 |
| `items/equip/weapon_bow/` | 弓 (Bow) | Lv 0-80 | Hunter's Bow / Maple Bow | ⏳ 待获取 |
| `items/equip/weapon_crossbow/` | 弩 (Crossbow) | Lv 0-80 | Light Crossbow / Steel Crossbow | ⏳ 待获取 |
| `items/equip/weapon_wand/` | 魔杖 (Wand) | Lv 10-80 | Wooden Wand / Blood Wand | ⏳ 待获取 |
| `items/equip/weapon_staff/` | 法杖 (Staff) | Lv 10-80 | Maple Staff / Wizard Staff | ⏳ 待获取 |
| `items/equip/weapon_dagger/` | 短剑 (Dagger) | Lv 0-80 | Dagger / Steel Dagger | ⏳ 待获取 |
| `items/equip/weapon_knuckle/` | 指节 (Knuckle) | Lv 0-80 | Copper Knuckle / Red Knuckle | ⏳ 待获取 |
| `items/equip/weapon_gun/` | 火枪 (Gun) | Lv 10-80 | Iron Pistol / Musketeer Gun | ⏳ 待获取 |
| `items/equip/cape/` | 披风 (Cape) | Lv 0-100 | Red Cape / White Cape / Pink Gaia | ⏳ 待获取 |
| `items/equip/gloves/` | 手套 (Gloves) | Lv 10-80 | Leather Gloves / Work Gloves / Stormcaster | ⏳ 待获取 |
| `items/equip/earring/` | 耳环 (Earring) | Lv 15-100 | Yellow Earring / Blue Earring | ⏳ 待获取 |
| `items/equip/ring/` | 戒指 (Ring) | Lv 10-100 | Silver Ring / Gold Ring | ⏳ 待获取 |
| `items/equip/pendant/` | 项链 (Pendant) | Lv 20-100 | Silver Necklace / Gold Necklace | ⏳ 待获取 |

### 4.3 Etc / 杂物材料

| 图标文件 | 物品名 | 物品 ID 示例 | 说明 | 状态 |
|---------|-------|-------------|------|------|
| `items/etc/snail_shell.png` | 蜗牛壳 | `4000000 – 4000002` | 新手任务材料（Red/Blue Snail） | ⏳ 待获取 |
| `items/etc/mushroom_cap.png` | 蘑菇盖 | `4000008 – 4000010` | Orange Mushroom 掉落 | ⏳ 待获取 |
| `items/etc/horn_mushroom.png` | 毒蘑菇孢子 | `4000011 – 4000012` | Horny Mushroom 掉落 | ⏳ 待获取 |
| `items/etc/pig_head.png` | 猪头（道具） | `4000017` | Pig 掉落 | ⏳ 待获取 |
| `items/etc/ribbon.png` | 红丝带 | `4000018` | Ribbon Pig 掉落 | ⏳ 待获取 |
| `items/etc/stump_branch.png` | 树桩树枝 | `4000022 – 4000024` | Stump / Dark Axe Stump | ⏳ 待获取 |
| `items/etc/fire_boar_skin.png` | 火独眼兽皮 | `4000106` | Fire Boar 掉落 | ⏳ 待获取 |
| `items/etc/golem_bone.png` | 石巨人骨片 | `4000122 – 4000126` | Black Golem / Dark Golem | ⏳ 待获取 |
| `items/etc/zombie_mushmom.png` | 僵尸蘑菇菌 | `4000107 – 4000109` | Zombie Mushroom / Zombie Mushmom | ⏳ 待获取 |
| `items/etc/wraith_darkness.png` | 幽灵碎片 | `4000130` | Wraith / Jr. Wraith 掉落 | ⏳ 待获取 |
| `items/etc/star_essence.png` | 星光精华 | `4000201 – 4000205` | Star Pixie / Lunar Pixie | ⏳ 待获取 |
| `items/etc/drake_skull.png` | 龙骷髅头 | `4000300 – 4000305` | Copper Drake / Dark Drake | ⏳ 待获取 |
| `items/etc/teddy_bear.png` | 玩具熊零件 | `4000400 – 4000405` | Brown Teddy / Pink Teddy | ⏳ 待获取 |
| `items/etc/ice_piece.png` | 冰块 | `4000500 – 4000510` | Jr. Pepe / Ice Mammoth | ⏳ 待获取 |
| `items/etc/zombie_teeth.png` | 僵尸牙 | `4000600 – 4000605` | Zombie / Coolie Zombie | ⏳ 待获取 |

## 五、技能图标（Skill Icon 全职业）

> 技能 ID 体系：`Warrior 100xxx / Magician 200xxx / Bowman 300xxx / Thief 400xxx / Pirate 500xxx`。图标统一 **32x32**。

| 目录 | 职业 | 1 转（Lv 10+） | 2 转（Lv 30+） | 3 转（Lv 60+） | 4 转（Lv 100+） | 状态 |
|------|------|----------------|----------------|----------------|-----------------|------|
| `skills/beginner/` | 新手 | Three Snails / Recovery / Nimble Feet | - | - | Monster Rider | ⏳ 待获取 |
| `skills/warrior/` | 战士 | Improved HP Rec / Endure / Iron Body / Power Strike / Slash Blast | Sword/Axe/Polearm Mastery + Booster / Final Attack / Rage / Power Guard | Crash / Shout / Combo / Dragon Blood / Sacrifice | Enrage / Rush / Brandish / Maple Warrior / Achilles / Berserk / Stance | ⏳ 待获取 |
| `skills/magician/` | 法师 | Improved MP Rec / Magic Guard / Magic Armor / Energy Bolt / Magic Claw | MP Eater + Meditation + Teleport + Slow + (Fire Arrow/Poison) / (Cold/Thunder) / (Heal/Bless/Holy Arrow) | Fire/Poison Element / Ice/Lightning Element / Holy / Dispel / Doom / Myst Door / Mana Reflection | Big Bang / Genesis / Maple Warrior / Angel Bless / Infinity | ⏳ 待获取 |
| `skills/bowman/` | 弓箭手 | Blessing of Amazon + Critical Shot + Focus + Arrow Blow + Double Shot | Bow / Crossbow Mastery + Booster + Soul Arrow + Arrow Bomb / Iron Arrow | Bow / Crossbow Expertise + Puppet + Silver Hawk / Golden Eagle + Arrow Rain | Hurricane / Pierce / Dragon Breath / Maple Warrior / Sharp Eyes / Concentration | ⏳ 待获取 |
| `skills/thief/` | 飞侠 | Nimble Body + Keen Eyes + Disorder + Dark Sight + Double Stab + Lucky Seven | Claw Mastery + Critical Throw + Haste + Drain / Dagger Mastery + Steal + Savage Blow | Claw / Dagger Expertise + Dark Flare + Shadow Meso + Shadow Partner / Band of Thief + Chakra | Triple Throw / Shadow Stars / Venom / Taunt / Ninja Storm / Assassinate / Maple Warrior | ⏳ 待获取 |
| `skills/pirate/` | 海盗 | Nimble Feet + Eye of Pirate + Oak Barrel + Double Shot + Somersault Kick + Dash | Knuckle Mastery + Oak Cask + Energy Charge + Energy Blast / Gun Mastery + Gun Booster + Invisible Shot | Knuckle / Gun Expertise + Transform + Shockwave + Time Leap + Dragon Strike / Rapid Fire + Ice Splitter | Nautilus Strike / Pirate Banner / Time Leap / Maple Warrior / Barrage / Roll of the Dice | ⏳ 待获取 |

## 六、特效 / 粒子（Effects / Particles）

| 目录 | 功能 | 说明 | 状态 |
|------|------|------|------|
| `effects/hit/` | 击中特效 | 白色 / 红色 / 黄色 Spark 粒子 | ⏳ 待获取 |
| `effects/skill_warrior/` | 战士技能特效 | Power Strike / Slash Blast / Rage 动画 | ⏳ 待获取 |
| `effects/skill_magician/` | 法师技能特效 | Magic Claw / Heal / Holy Arrow 粒子 | ⏳ 待获取 |
| `effects/skill_bowman/` | 弓手技能特效 | Arrow Blow / Double Shot / Soul Arrow 轨迹 | ⏳ 待获取 |
| `effects/skill_thief/` | 飞侠技能特效 | Lucky Seven / Dark Sight / Shadow Partner | ⏳ 待获取 |
| `effects/skill_pirate/` | 海盗技能特效 | Double Shot / Somersault / Energy Blast | ⏳ 待获取 |
| `effects/levelup/` | 升级光环 | 环形金色升级动画 + 粒子 | ⏳ 待获取 |
| `effects/skill_4th/` | 4 转大招特效 | Maple Warrior / Howling / Genesis | ⏳ 待获取 |
| `particles/meso/` | 金币掉落粒子 | 10 / 50 / 100 / 500 金币闪光 | ⏳ 待获取 |
| `particles/snow/` | 雪花粒子 | 冰峰雪域 3D 雪花 | ⏳ 待获取 |
| `particles/leaf/` | 落叶粒子 | 魔法密林飘动叶子 | ⏳ 待获取 |
| `particles/sparkle/` | 传送门闪光粒子 | 金色闪烁门星 | ⏳ 待获取 |
| `particles/smoke/` | 烟雾粒子 | 飞侠隐身 / 海盗爆炸烟雾 | ⏳ 待获取 |

## 七、图片规范

- **格式**：PNG-32（带 Alpha 通道）
- **色深**：24-bit RGB + 8-bit Alpha
- **推荐工具**：
  - `WzRepacker` / `HaRepacker`（从 wz 解包）
  - `TexturePacker`（生成精灵图集）
  - `Aseprite`（像素风修改）
- **总大小预估**：约 500–800 MB（原始资源），可压缩至 200 MB 左右
- **加载配置**：已在 `pubspec.yaml` 中声明 `assets/images/`

## 八、开源替代资源

若无法获取原版资源，可使用以下开源素材作为替代：

| 资源站 | 说明 | 许可证 |
|--------|------|--------|
| [opengameart.org](https://opengameart.org) | 游戏美术素材大全 | CC0 / CC-BY / GPL |
| [itch.io/game-assets](https://itch.io/game-assets) | 独立游戏美术商店，有大量免费资源 | 各独立作者 |
| [kenney.nl/assets](https://kenney.nl/assets) | Kenney 的 CC0 素材（UI、Tiles） | CC0 |
| [craftpix.net](https://craftpix.net) | RPG 免费素材 | 免费 / 付费 |

---

> **版权说明**：本项目为学习复刻研究，若部署商业版本，请使用自有或已获授权的美术资源。
