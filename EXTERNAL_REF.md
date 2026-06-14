# 外部参考资源位置

示例代码、WZ 二进制、开源对照仓库已迁出本仓库，与项目**同级**存放：

```
GolandProjects/
├── mapleStory079/              ← 本仓库（Go 服务端 + Flutter 客户端）
└── mapleStory079-external/     ← 参考资源（勿提交进 git）
```

**完整说明**：`PROJECT_PLAN.md` §2（目录一览）、§2.5（按任务查参考）、§2.6（WZ→assets 解析表）。

详细目录索引：`../mapleStory079-external/README.md`

## 环境变量

| 变量 | 默认值 |
|------|--------|
| `MAPLE_EXTERNAL_ROOT` | `../mapleStory079-external` |
| `MAPLE_CLIENT_DIR` | `…/03-★maple-client-ingest工作目录-WZ副本-脚本自动复制` |
| `MXD079_CLIENT` | `…/00-官方客户端-…/extracted_client` |

解析函数：`scripts/lib/external_paths.sh`（`maple_ms079_main` `maple_mxd079_download` 等）

## 提取资源

```bash
./scripts/ingest_full.sh
```

单图导出示例：

```bash
python3 scripts/extract_wz_py/export_map_from_wz.py \
  --client "$MXD079_CLIENT" --map 000010000 --map-id 1000000 --force
```
