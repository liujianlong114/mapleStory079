# scripts 目录说明

本目录存放用于项目相关的可执行脚本。

---

## 一、init_data.go —— 数据初始化工具

用途：向 `maplestory` 数据库写入地图、NPC、怪物、物品、技能、任务等基础数据，并在表不存在时执行 `AutoMigrate`。

### 编译：

```bash
cd /Users/lijianjun/GolandProjects/mapleStory079
go build -o ../bin/init_data .
```

### 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `--config` | string | `config/config.yaml` | 指定 MySQL 配置文件，读取 `database.*` 字段作为 DSN |
| `--reset` | bool | `false` | 若为 `true`，在迁移前清空所有 seed 表（`DELETE FROM maps/npcs/mobs/items/skills/quests）后再写入；用于重置数据 |
| `--seed` | string | `all` | 选择需要初始化的数据集合，支持 `all` / `map` / `mob` / `item` / `quest` / `skill`；多个用英文逗号分隔 |

> 当前实现为 `go run scripts/init_data.go`，参数解析以简化实现：

```go
// 示例
./bin/init_data --config=config/config.yaml --reset --seed=map,mob
./bin/init_data --reset
```

### 使用方式

1. 确保 MySQL 已启动，并已创建数据库：

   ```sql
   CREATE DATABASE IF NOT EXISTS maplestory DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

2. 修改 `config/config.yaml` 中的数据库账号密码。

3. 执行初始化：

   ```bash
   # 1. 编译（可选）
   go build -o bin/init_data ./scripts

   # 2. 运行（可运行时自动建表并插入数据
   ./bin/init_data
   # 或者不编译直接运行
   go run ./scripts/init_data.go
   ```

4. 可选操作：

   ```bash
   # 仅重置并重新插入所有数据
   ./bin/init_data --reset

   # 指定配置文件
   ./bin/init_data --config=config/config.yaml

   # 只初始化地图和怪物
   ./bin/init_data --seed=map,mob
   ```

---

## 二、从 WZ 资源提取提示

冒险岛 079 客户端资源（`*.wz`）包含全部 BGM、贴图、精灵、脚本等内容。常见工具与流程参考如下：

### 工具

| 工具 | 用途 |
|------|------|
| `HaRepacker` / `WzRepacker` | 打开 `.wz` 文件，按层级浏览与导出 PNG/MP3/OGG |
| `KMSExtractor` | 批量导出资源 |
| `nxconvert` | 将导出的 `nx` 文件转换为 JSON |

### 音频（BGM / SFX

- 源：`Sound.wz`（Bgm00.img / Bgm01.img ...`）
- 建议：将提取为 `OGG (Vorbis)` 放到 `client/assets/audio/`
- 命名：`[类型]_[地图ID|名称].ogg`

### 贴图（UI / Tile / Icon）

- 源：`UI.wz / Map.wz / Item.wz / Skill.wz`
- 建议：PNG-32（带 Alpha）放到 `client/assets/images/`

### 精灵（角色 / 怪物 / NPC / 坐骑）

- 源：`Character.wz / Mob.wz / NPC.wz`
- 建议：spritesheet + JSON 放到 `client/assets/sprites/`

> 版权：请仅用于学习与研究用途。

---

## 三、运行服务端 / 客户端简明说明

### 服务端

```bash
# 编译
go build -o bin/server ./cmd/server

# 运行（会自动建表）
./bin/server

# 健康检查
curl http://localhost:8080/health
```

默认监听 `0.0.0.0:8080`。

### 客户端

```bash
cd client
flutter pub get
flutter run           # 运行在模拟器/真机
flutter run -d chrome  # 或者在 Web 运行
```

> 注意：若使用 Web 运行时，请在 `client/lib/config/app_config.dart` 中修改服务器地址为 `localhost` 或你的开发机 IP。

---

**文件列表**

- `scripts/init_data.go —— 数据初始化工具
- `scripts/README.md` —— 本文件
