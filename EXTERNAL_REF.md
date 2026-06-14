# 外部参考资源位置

示例代码、WZ 二进制、开源对照仓库已迁出本仓库，与项目**同级**存放：

```
GolandProjects/
├── mapleStory079/              ← 本仓库（Go 服务端 + Flutter 客户端）
└── mapleStory079-external/     ← 参考资源（勿提交进 git）
```

详细目录说明见：`../mapleStory079-external/README.md`

## 环境变量

| 变量 | 默认值 |
|------|--------|
| `MAPLE_EXTERNAL_ROOT` | `../mapleStory079-external` |
| `MAPLE_CLIENT_DIR` | `…/03-★maple-client-ingest工作目录-WZ副本-脚本自动复制` |
| `MXD079_CLIENT` | `…/00-官方客户端-…/extracted_client` |

## 提取资源

```bash
./scripts/ingest_full.sh
```

脚本通过 `scripts/lib/external_paths.sh` 解析路径，无需再使用仓库内的 `examples/`。
