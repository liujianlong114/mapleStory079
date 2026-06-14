# 自动推进进度 — 2026-06-14 第二轮

## 本轮完成
- [x] **彩虹岛新手任务链（服务端）**
  - 新增 `CharacterQuest` 进度表（接取/进行中/已完成 + progress 计数）
  - `quest_service.go`：接取、完成、道具校验、击杀进度（蜗牛 10 只）
  - `beginner_quest_npc.go`：希娜(2101) 镜子任务 1000→1001、初来乍到 400000；莎丽(2100) 借镜子；麦加(12100) 击退蜗牛 400001；船长(22000) 出航 400003
  - API：`GET /quests/character/:id`、`POST /quests/accept`、`POST /quests/complete`
  - 击杀怪物时自动更新任务进度
- [x] **客户端 NPC 对话对接 API**
  - `game_scene_page.dart` 调用 `/npc/dialogue` + `/npc/dialogue/continue` 多轮选项
  - 任务奖励后自动 `loadCharacterState` 刷新经验/金币
- [x] **物品贴图路径修正**
  - `extract_item_icons.py`：武器走 `Item.wz/Weapon/`、防具走 `Install/`
  - seed 补全 4031013/4031014/4031015 任务道具定义

## 下轮优先（按 PROJECT_PLAN §11）
1. 地图 1000000：enH0/enV0 真实贴图 + spawn/NPC/portal 脚点验收
2. 任务链延伸：2103 信件 → 路卡斯 1005/1006、皮奥回收 1008
3. HUD 细调：quickSlot 快捷栏、聊天条 hover 态
4. 运行 `extract_item_icons.py` 补 1302000/1372005 武器图标（需 WZ 客户端）

## 自检
- `go build ./cmd/server/main.go` — ✅
- `go test ./test/...` — ✅（DB 不可用时 quest 测试 skip）
- backend :8080 — ❌ 环境无 MySQL/Docker，未能启动
- frontend :5173 — ❌ 环境无 Flutter CLI
- `flutter analyze` — 跳过（未安装）

## 新手任务测试路径
1. 彩虹村找希娜 →「我是新来的冒险家」→ 完成 400000
2. 「有什么需要帮忙的吗？」→ 接 1000 → 找莎丽借镜子 → 自动接 1001 → 回希娜交镜子
3. 训练场找麦加 → 接 400001 → 打 10 只蜗牛 → 回麦加交任务
4. 等级 5+ 明珠港找船长 → 完成 400003
