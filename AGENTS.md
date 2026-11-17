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

- 文档语言按项目读者和现有约定选择，可使用英文、中文或其他语言；通用开发者资料默认优先英文，业务和本地化资料使用目标读者的语言。保持同一文档用语一致，不顺带整篇翻译或新增无维护需求的多语副本。
- 新增文档文件名小写、`-` 连接，单语文档不加语言后缀；仅中英双语对照副本使用 `.zh-CN.md` / `.en.md`。`README.md`、`AGENTS.md` 等工具约定文件保留固定名称。源码沿用现有语言命名。
- 不提交审计报告、复盘、交接单、进度快照、升级计划。要追溯看 commit 历史。
- 改文件名时同一次提交改完所有引用。
- 仓库卫生检查统一由共享基线 `GdeiAssistant/.github/actions/repository-hygiene` 执行。

<!-- repository-files:begin -->
- 公开仓库（有 `LICENSE`）要有 `CONTRIBUTING.md`、`SECURITY.md` 和 issue / PR 模板（`CODE_OF_CONDUCT.md` 继承自 `GdeiAssistant/.github`）；私有仓库至少要有 `SECURITY.md`。
- 公开的 `SECURITY.md` 写对外披露流程，不写凭据放在哪、怎么轮换；私有仓库反过来写。两套不合并。
- 模板文件名用下划线：`pull_request_template.md`、`issue_template.md`，写成连字符不会被 GitHub 识别。
<!-- repository-files:end -->

## 不要做

- 不要跳过 `check_localization.py`。新增文案必须同时进本地化文件。
- 不要改 `Tools/` 下的检查脚本让它们通过，改被检查的代码。
- 不要单方面改接口契约。服务端、Android、微信小程序共用同一套。

<!-- content-boundary:begin -->
- 公开材料不出现真实资源名与账号：桶写 `gs://<bucket>/...`，账号写 `<account-id>`，示例用合成值。
- 桶名、账号、主机名从 `vars.*`、环境变量或受保护配置读，不写死在源码、workflow 和文档里。
- 哈希不是匿名手段：提交号、摘要、截断的 ID 只要能反查到真实对象，就不进公开材料。
- 判断一次改动是否干净看 `git diff` 和 `git ls-files`；`.gitignore` 只影响未跟踪文件，不能当证据。
<!-- content-boundary:end -->

## 提交与 PR

- Commit 与 PR 标题遵循 Conventional Commits（`feat`、`fix`、`docs`、`refactor`、`test`、`chore`、`perf`、`ci`，<= 72 字符）。
- PR 按中文模板填写变更摘要、AI 参与说明与实际验证；仅在用户可见的安装、配置或接口行为改变时更新 README，不把补丁过程写入 README。
- 高风险路径须取得独立 AI 审查完成证据（`@codex review` 或回退 `@claude review`）并满足 `risk-gate`；所有者使用 `owner-approved`，编码智能体放行仅使用 `agent-approved`。
- 通过正常检查后经 PR 合并到默认分支，不直推默认分支，不 force-push 已审查分支，不以删测试或管理员绕过通过门禁；交付仅报告实际核实结果。
