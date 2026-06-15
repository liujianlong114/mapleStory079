# next_plan.md

## 本轮状态（周期 #58）

**例行健康检查（维护期）**：项目保持**连续八轮零缺陷**状态，本轮无代码变更。

### 本轮执行内容
- `go build ./cmd/server` → ✅ exit 0
- `flutter analyze client` → ✅ **No issues found!**（0 error / 0 warning / 0 info，**连续八轮**）
- 资源统计（`client/assets/**/*.png`）→ 总量 **12,222 张**（与周期 #51~#57 完全一致，无新增无丢失）

### 当前健康状态（4 项全绿，连续八轮）
| 检查 | 结果 |
|------|------|
| `go build ./cmd/server` | ✅ exit 0 |
| `flutter analyze client` | ✅ **No issues found!**（0/0/0，连续八轮） |
| 资源 PNG 总量 | ✅ 12,222 张（与上轮持平） |
| `:8080/health` 端点 | ⏸ DOWN（本轮未启动后端） |

### 资源分布（与周期 #51~#57 一致）
- `sprites/`: 6,597（mob 3,783 + npc 2,188 + item 569 + effect 38 + player 10 + portal 9）
- `characters/`: 4,896（avatars 4,864 + parts 32）
- `maps/`: 526（obj 402 + tiles 66 + back 53 + miniMap 5）
- `images/`: 197（ui 194 + tiles 3 + map 0）
- `scenes/`: 6
- **合计 12,222 张真实 PNG**（无新增、无丢失）

### 已完成里程碑（累计）
- **P0 地图可玩性**：脚点/贴图验收、tile PNG 补全、怪物精灵全量提取、下跳穿板+绳梯
- **P1 079 体验对齐**：新手岛地图链、小地图、伤害特效、BGM、背包/装备 UI、NPC 对话/商店/转职、传送门、掉落系统、怪物 AI、HUD 金币、脚点错位修复、主城/训练场/BOSS 地图扩展
- **P2 登录与角色**：MapLogin2 镜头、Character 部件缓存、UI 音效、lint 清理
- **P3 维护期**：Flutter 0 issue（周期 #51）+ 连续八轮零缺陷（周期 #58）

---

## 下轮建议（待用户指定方向）

项目主线已交付，且**连续八轮零缺陷**。可选方向（需用户确认后启动）：
1. **资源补全**：导出更多地图 obj PNG / 剩余 BOSS 精灵（WZ decode 格式特殊）
2. **功能扩展**：技能系统、组队、聊天频道、好友列表
3. **性能优化**：资源预加载、渲染优化
4. **新地图导出**：扩展新手岛以外地图
5. **UI 精细化**：更多 UIWindow 部件对齐
6. **继续健康检查**：无指令时默认执行，确保零缺陷保持

**如无用户新增指令，下一轮仍进行健康检查（任务 H），保持 0 issue。**

---

## 下一轮任务清单（与 .next_tasks.md 同步）

> **周期编号**：#59（下一周期）
> **上次完成**：周期 #58（2026-06-15，维护期例行健康检查，连续八轮零缺陷）
> **当前状态**：所有 P0/P1/P2 主线任务已完成；`flutter analyze` 连续八轮 **0 error / 0 warning / 0 info**；`go build ./cmd/server` ✅；assets PNG 总量 12,222（稳定）。
> **下一执行**：默认执行「任务 H：定期健康检查」；如用户新增指令，立即替换为用户指定任务。

### 任务 H：定期健康检查（维护期默认）
- **说明**：保持项目主干零 error / 零 warning / 零 info，记录资源总量与分布变化。
- **具体内容**：
  - `go build ./cmd/server`
  - `flutter analyze client`
  - 统计 `client/assets` 下 PNG 总量与按子目录分布
  - 如引入新代码导致 warning/error/info，优先修复
- **参考**：`client/lib/**`，`internal/**`，`scripts/**`
- **验收标准**：exit 0；`flutter analyze` 0 issue；assets PNG 总量持平或稳步增长

### 可选扩展方向（需用户确认后启动）

- 资源补全：导出更多地图 obj PNG / 剩余 BOSS 精灵（WZ 解码格式特殊）
- 功能扩展：技能系统、组队、聊天频道、好友列表
- 性能优化：资源预加载、渲染优化
- 新地图导出：扩展新手岛以外地图
- UI 精细化：更多 UIWindow 部件对齐

_下一周期默认执行「任务 H：定期健康检查」；如用户新增指令，立即替换为用户指定任务。_
