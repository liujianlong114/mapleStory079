# 自动推进进度 — 2026-06-14 18:20 UTC

## 对照 PROJECT_PLAN §2.5 / §11.2 / §12

| 缺口 | 本轮状态 |
|------|----------|
| P0 UIWindow 背包/装备/属性/技能 | ✅ 上轮已完成；本轮未改 |
| P0 彩虹村 1000000 脚点可玩 | ⏳ 待验收 enH0/enV0 贴图与 spawn 对齐 |
| P1 彩虹岛任务/升级/打怪经验 | ✅ **本轮实现任务链骨架** |
| 物品贴图 403xxxx | ⏳ 下轮（无 WZ 客户端，云环境无法 extract） |

## 本轮完成

- [x] **CharacterQuest** 表 + `QuestService`（接取/完成/击杀进度）
- [x] 彩虹岛官方任务 **1000→1001**（希娜 2101 ↔ 莎丽 2100）NPC 多轮对话
- [x] 任务 **400001 击退蜗牛**（击杀 mob 100100 ×10 自动记进度）
- [x] API：`GET /api/v1/quests/character/:id`、`POST accept/complete`
- [x] 客户端 `game_scene_page` 对接服务端 `/npc/dialogue` 多轮对话 + 任务奖励 SnackBar
- [x] `go build` / `go vet`（主包）通过

## 下轮优先

1. 地图 1000000：enH0/enV0/edU 真实贴图或占位 origin 校验；spawn/NPC/portal 脚点截图验收
2. 任务链延伸：1005/1006 信件任务、南门 out00→20000 传送后任务 NPC
3. 物品贴图：有 WZ 环境时跑 `extract_item_icons.py` 补 403xxxx
4. HUD 细调：quickSlot、聊天条 hover 态

## 自检

| 项 | 结果 |
|----|------|
| `go build ./cmd/server/...` | ✅ |
| `go vet ./cmd/server ./internal ./pkg` | ✅ |
| `curl localhost:8080/health` | ❌ MySQL 未就绪（云环境无 DB） |
| `:5173` | ❌ Flutter 未安装（云环境） |
| `flutter analyze` | ⏭ 跳过（无 flutter CLI） |

## 操作提示

- 本地：`go run cmd/server/main.go` + `flutter run -d chrome --web-port=5173`
- 进彩虹村与希娜对话 → 接「借来莎丽的镜子」→ 找莎丽交付 → 莎丽处接「给希娜弄来镜子」→ 回希娜交付
- 击杀蜗牛时任务 400001 进度自动 +1，满 10 只后可找路卡斯(12100) 交付（需该 NPC 在图内）
