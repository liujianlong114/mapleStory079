# 自动推进进度 — 2026-06-14 首轮

## 本轮完成
- [x] 创建 Cursor 定时 Automation（每 30 分钟，`*/30 * * * *`），已打开 Glass 编辑器待你确认保存
- [x] 本地循环脚本 `.cursor/automation/local-loop.sh`（30 分钟健康检查 + 计划缺口记录）
- [x] 导出 UIWindow 窗口贴图 40 张 → `client/assets/images/ui/windows/`
- [x] 游戏内 WZ 叠加面板：背包/装备/属性/技能（`maple_game_panels.dart`），不再跳转 Material 全屏页
- [x] 状态栏 EXP 条宽度修正为 WZ 实际 340px；装备键与背包键分离
- [x] 物品图标导出脚本 `extract_item_icons.py`（Consume/Etc 路径已对齐 079 分卷规则）

## 下轮优先（按 PROJECT_PLAN §11）
1. 地图 1000000：补全 enH0/enV0/edU 真实贴图或确认 fallback 视觉可接受；脚点与 spawn/NPC/portal 验收
2. 物品贴图：装备类 Install 分卷路径探测 + 彩虹岛任务道具 403xxxx
3. 彩虹岛任务链：希娜对话 → 接任务 → 打蜗牛经验 → 南门传送（对照 ms079 Java Handler）
4. HUD 细调：quickSlot 快捷栏、聊天条、商城/菜单按钮 hover 态

## 自检
- backend :8080 — 200
- frontend :5173 — 200

## 操作提示
- Glass Automations 里确认 cron 已启用并保存（需登录 GitHub repo `liujianlong114/mapleStory079`）
- 游戏内按 I/装备键/属性键/技能键打开 WZ 面板；Cmd+Shift+R 强刷看新贴图
