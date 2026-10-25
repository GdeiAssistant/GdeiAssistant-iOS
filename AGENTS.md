# AGENTS.md

## 项目是什么

广东第二师范学院校园助手的 iOS 客户端。SwiftUI，支持 iOS 17 及以上。

## 技术栈

Swift / SwiftUI，Xcode 工程 `GdeiAssistant-iOS.xcodeproj`。

## 目录

- `GdeiAssistant-iOS/` — 应用源码，按 Feature 分目录。
- `GdeiAssistant-iOSTests/` — 单元测试。
- `GdeiAssistant-iOSUITests/` — UI 测试。
- `Tools/` — `check_style.sh` 风格检查，`check_localization.py` 本地化检查，`build_simulator.sh` 模拟器构建。
- `Configs/` — 构建配置。

## 本地验证

按改动选择相关离线检查，命令以仓库当前 CI 为准。先区分代码问题与环境条件，不为通过检查降低保护。

**风格检查**

```bash
./Tools/check_style.sh
```

**本地化检查**

```bash
python3 Tools/check_localization.py
```

**模拟器构建**

```bash
./Tools/build_simulator.sh
```

**单元测试与 UI 测试**

使用 `.github/workflows/ios-ci.yml` 中实际选择的模拟器 UDID 执行测试；不写死本机不存在的设备名。

## 命名与文档

- 新增文档文件名小写、`-` 连接，中文版后缀 `.zh-CN.md`；`README.md`、`AGENTS.md` 等工具约定文件保留固定名称。源码沿用现有语言命名。
- 不提交审计报告、复盘、交接单、进度快照、升级计划。要追溯看 commit 历史。
- 改文件名时同一次提交改完所有引用。
- 提交前跑 `python scripts/check_hygiene.py`。

## 不要做

- 不要跳过 `check_localization.py`。新增文案必须同时进本地化文件。
- 不要改 `Tools/` 下的检查脚本让它们通过，改被检查的代码。
- 不要单方面改接口契约。服务端、Android、微信小程序共用同一套。

## 提交与 PR

Conventional Commits，标题中文，不超过 50 字。类型只用 `feat` `fix` `docs` `refactor` `test` `chore` `perf` `ci`。

分支名 `<type>/<主题>`，例如 `docs/normalize-filenames`。不直接推默认分支，不 force push 已 review 的分支。

提交、推送、合并及生产动作按用户已明确授权的范围执行；同范围已有授权不重复确认。

PR 描述写改了什么、为什么改、怎么验证。
