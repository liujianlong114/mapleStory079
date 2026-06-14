# MapleStory079 夜间自动推进（每轮必读）

## 成功标准（明早验收）
玩家在彩虹岛完成**去金银岛之前**的全部新手流程可跑通：建角→彩虹村→希娜等 NPC 对话/任务→打蜗牛升级→南门传送→关键任务状态与经验/升级逻辑正确。

## 每轮执行顺序（不可跳步）

### 0. 读计划
- 打开 `PROJECT_PLAN.md` §2.5、§11.2、§12
- 对照 `EXTERNAL_REF.md` 找参考路径
- **禁止凭空猜坐标/规则**，必须先读 HeavenClient 或 ms079 Java/XML

### 1. P0 界面还原（当前最高优先）
对照 `04-HeavenClient/IO/UITypes/UIStatusBar.cpp`（**StatusBar3.img**，800×600）：
- [ ] 底部状态栏：EXP/HP/MP/快捷键/商城菜单按钮位置与 WZ 贴图
- [ ] 小地图 UIWindow.img/MiniMap 边框与缩略图
- [ ] 背包 UIWindow.img/Item（Inventory）
- [ ] 技能 UIWindow.img/Skill
- [ ] 人物属性 UIWindow.img/Stat
- [ ] 装备 UIWindow.img/Equip
- [ ] 物品贴图 Item.wz → `client/assets/sprites/item/`

资源脚本：`scripts/extract_wz_py/extract_hud_ui.py`、HeavenClient 对应 UI*.cpp

### 2. P0 地图可玩
- [ ] 彩虹村 1000000：脚点与贴图对齐（FootholdTree + tile 非占位）
- [ ] 导出真实 tile：MAX3 Data + `export_map_from_wz.py --back-client MAX3`
- [ ] 玩家能明确走在平台上，下跳/趴下正常
- [ ] 验收点：spawn、希娜 NPC、out00 传送门

### 3. P1 彩虹岛任务与战斗（界面达标后）
对照 `02-ms079-main` Java Handler + `String.wz/Quest.img`：
- [ ] 希娜等 NPC 对话与任务接取/完成
- [ ] 打怪经验、升级 AP/SP
- [ ] 地图链 1000000→20000→30000 传送

### 4. 每轮必做自检
```bash
curl -s http://localhost:8080/health
curl -s -o /dev/null -w "%{http_code}" http://localhost:5173/
cd client && flutter analyze 2>&1 | tail -5
go build -o /dev/null ./cmd/server/ 2>&1 | tail -3
```
服务挂了则重启：
```bash
lsof -ti:8080 | xargs kill -9 2>/dev/null
lsof -ti:5173 | xargs kill -9 2>/dev/null
cd /Users/lijianjun/GolandProjects/mapleStory079 && go run cmd/server/main.go &
cd client && flutter run -d web-server --web-hostname=localhost --web-port=5173 &
```

### 5. 每轮结束
- 更新 `PROJECT_PLAN.md` §11 勾选已完成项
- 写简短进度到 `.cursor/automation/last-run.md`（本轮做了什么、下轮做什么）
- 提交代码仅当用户明确要求；否则只改文件留待审查

## 关键参考（本机绝对路径）
- HeavenClient UI：`~/GolandProjects/mapleStory079-external/04-HeavenClient-C++参考-UI坐标与渲染逻辑/IO/UITypes/`
- ms079 XML：`~/GolandProjects/mapleStory079-external/02-★ms079-main-…/wz/`
- MAX3 Data：`~/GolandProjects/mapleStory079-external/03-★maple-client-ingest…/extracted/max3/…/怀旧岛079MAX3_客户端`
