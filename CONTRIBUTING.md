# 参与贡献

这个仓库是 GdeiAssistant 的 iOS 客户端。感谢你愿意花时间改进它。

提交之前先确认一件事：你要改的是客户端还是后端。教务、校园卡这些数据来自 [GdeiAssistant 主仓](https://github.com/GdeiAssistant/GdeiAssistant)，接口或数据不对，问题通常在后端。

## 流程

1. 从最新的 `main` 拉出功能分支。
2. 改代码，同步改受影响的文档和测试。
3. 跑下面的检查，全部通过再提交。
4. 开 PR，说明改了什么、影响哪些页面、怎么验证的。

分支名带上主题，例如 `feat/theme-tokens`、`fix/login-401-loop`。

## 提交前检查

```bash
./scripts/check_style.sh
python3 scripts/check_localization.py
```

构建：

```bash
./scripts/build_simulator.sh
```

跑单元测试：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild test -project GdeiAssistant-iOS.xcodeproj \
  -scheme GdeiAssistant-iOS \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

改动了多语言文案，必须同时更新 `Localizable.strings` 和 `docs/location-names.md` 里对应的条目，否则 `check_localization.py` 会报错。

## 代码风格

- 跟着现有分层走：`Models` / `DTOs` / `Mappers` / `Repositories` / `ViewModels` / `Views`，远端结构不要直接进 View。
- 新业务放在 `Features/<模块>/` 下，复用 `Core/DesignSystem` 里的颜色、字号和间距，不要在页面里写死色值。
- 不引入新框架或重依赖，除非现有方案确实做不了。引入前在 PR 里说清楚理由和包体积影响。
- 网络请求走 `Core/Networking`，不要在 ViewModel 里直接拼 `URLSession` 调用。

## 关于 mock 数据

`mock` 只服务本地开发和界面联调。不要往 mock 里塞真实校园数据、真实用户信息或可用的测试账号。Staging / Release 构建固定走远程接口，不读 debug 期间留下的覆盖值。

## 不要提交的内容

- 真实用户数据、真实校园账号、密码、验证码、Cookie、JWT
- `.p12` 证书、provisioning profile、`.p8` 私钥、`Configs/*.local.xcconfig`
- 未脱敏的日志、抓包、截图
- 第三方 API Key

## 提交信息

用能看懂的话写，不要只写「update」：

```text
feat: 课表页支持周次切换
fix: 退出登录后 Keychain 未清理
docs: 补充 TestFlight 发布步骤
```

## 许可

向本仓库提交的代码和文档，默认按 [Apache License 2.0](LICENSE) 授权。提交前请确认你有权提交这些内容。

## AI 辅助维护

维护流程、文档更新和交付核对见 [AI 辅助维护约定](.github/engineering.md)，项目约束见 [AGENTS.md](AGENTS.md)。
