# iOS 社交与私信实现说明

日期：2026-10-05。对应共享契约：`GdeiAssistant/docs/SOCIAL_MESSAGING_DESIGN.zh-CN.md`。

## 范围

本仓实现 SwiftUI / MVVM / URLSession 客户端社交接入：

- DTO / Mapper / Domain / Repository / mock-remote 切换
- 全局单连接 `URLSessionWebSocket` 实时管理（认证首帧、ready 后才收业务事件、登出清理、前台恢复）
- 用户搜索、公开主页、关注/粉丝/好友、拉黑/黑名单
- 会话列表、文字聊天、四档私信设置
- 个人中心统计入口；资讯页私信入口
- 实名社区作者 `authorId` 主页入口；匿名树洞不加身份入口
- 二手 / 失物招领 / 摄影 / 话题 / 卖室友：公开可选 `authorId`；有 UUID 才链到 `SocialPublicProfileRoute`，无 UUID 保持原展示、不猜造
- 二手 / 失物详情发布者头像改用 `SocialAvatarView`（兼容 `/api/social/users/{uuid}/avatar` Bearer）；商品/内容图仍走原 `DSRemoteImageView`
- 卖室友 `authorId` 仅表示发布者，不是被介绍人；树洞 / 表白不加身份入口
- 图片私信：`type` TEXT|IMAGE、`imageMessagingEnabled`（缺省 false）、multipart `/messages/image`、鉴权 `.../messages/{id}/image`；JPEG≤5MiB；pending/failed 保留原 `clientMessageId`+本地 Data 重试；WS 已 SENT 不因晚到 HTTP 失败降级
- 六语言文案；Release 强制 remote（沿用既有 `AppEnvironment` 消毒）

## 关键路径

- `Features/Social/**`：模型、DTO、Mapper、Repository、Realtime、ViewModel、Views
- `App/Assembly/SocialAssembly.swift`：注入与工厂
- `Core/Networking`：新增 PUT；`errorCode` / `NetworkError.contract`
- `Features/Messages/Views/MessagesView.swift`：私信分区入口
- `Features/Profile/Views/ProfileView.swift`：统计与社交菜单
- `Features/Community/**` + `Mock/MockSeedData.swift`：可选 `authorId`
- `Features/{Marketplace,LostFound,Photograph,Topic,Dating}/**`：可选 `authorId` / 发布者入口；Marketplace/LostFound 详情 `SocialAvatarView`

主 App target 使用 `PBXFileSystemSynchronizedRootGroup`，`GdeiAssistant-iOS/**` 新文件自动入编。测试文件已手工加入 `project.pbxproj`。

## 契约路径约定

`AppEnvironment.baseURL` 已含 `/api`，因此 REST 调用使用 `/social/...`（等价契约 `/api/social/...`）。WebSocket 为 `wss(s)://{host}{basePath}/social/realtime`。

## 已知环境阻塞

本机仅 Command Line Tools，`xcodebuild` 不可用：

```text
xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory
'/Library/Developer/CommandLineTools' is a command line tools instance
```

因此未能执行真实 Xcode 构建 / 单元测试 / 模拟器验证。可用 `swiftc -parse` 做语法检查，不代表 typecheck/build/test 或设备验证完成。

## 关键修正（第二轮）

- Mapper：关键 `id` / `clientMessageId` / `peer` / `createdAt` 等缺失时显式失败；分页过滤坏项，不再生成 UUID / justNow。
- 消息长度：`unicodeScalars.count`（对齐 Java/Android code point）。
- Realtime：同 token 不重开；`connectionGeneration` 忽略旧回调；logout 抬升 generation 防污染。
- 头像：`AuthenticatedImageLoader` + `SocialAvatarView`，相对/同主机 API 路径走 Bearer；`null` 仅占位，不造头像 URL。
- 私信图片：`chatImage(for:)` 仅精确 same-origin `social/conversations/{id}/messages/{messageId}/image` 加 Bearer；外链不加凭据；点击用 item-driven sheet；保留 prepend 锚点滚动策略。

## 接口偏差

无主动契约字段/枚举/端点修改。若后端尚未返回社区 `authorId`，客户端按可选字段处理，不猜测身份。

## 主助手最终离线验收

- `swiftc -parse`：最终 345 个应用及单元测试 Swift 文件通过；工程文件及六语言 `.strings` 的 `plutil -lint` 通过。
- 使用原始 `SocialModels`/`ChatMessageMerge` 和最小离线本地化标记完成纯逻辑编译与断言；按项目 Swift 5 和默认 MainActor 隔离参数再次编译通过。覆盖发送方区分、WS/REST 去重、pending 不推进已读、已提交状态不被超时降级。
- 主助手补上 Combine 导入、会话结束统一清理、头像 origin 校验和 token 换会话后的缓存/旧回调隔离。
- 完整 Xcode App 构建、XCTest、模拟器和真机仍未执行；新增作者 mapper 测试仅落地并通过语法检查，未冒充 XCTest 已通过。

## 本轮测试与设计审查追加

修复加载更早历史导致自动跳最新的问题：ChatThreadAutoScroll 按尾部身份区分初次加载/真正追加与 prepend，prepend 保持原首条锚点。新增 5 个调用生产判定函数的 XCTest 用例，放在已入编 ChatMessageMergeTests 中；新生产模型自动归入应用 synchronized group。重试保持原 clientMessageId，不被新 canSend 权限挡在客户端。

主助手实际 swiftc -parse 检查 347 个 App/测试 Swift 文件成功，project.pbxproj plist 校验成功。使用项目 Swift 5 + 默认 MainActor 设置独立编译并执行生产 SocialModels/ChatMessageMerge/ChatThreadAutoScroll，5 项滚动判定和原去重/游标/状态断言通过，无编译警告。它是纯逻辑验证，完整 App 构建、XCTest 和 Simulator/真机仍缺完整 Xcode，未执行。

## 图片私信追加（本仓）

对齐共享契约「图片私信追加契约」：

- 选图：`PhotosPicker` 用户触发；`SocialChatImageSupport` → `UploadImageAsset` JPEG≤5MiB；发送前预览/取消。
- 会话 `imageMessagingEnabled` 缺省 false；未启用时隐藏发图入口。
- 发送：`POST .../messages/image` multipart（`clientMessageId` + `image`）；pending/failed 保留原 ID 与本地 Data 重试；`hasCommittedSend` / `updateLocalBubbleState` 禁止把已 SENT 降为 failed。
- 加载：`AuthenticatedImageLoader.chatImage` 仅 exact same-origin chat-image path + Bearer；禁止裸 `AsyncImage`；点击 `sheet(item:)` 查看。
- Mock：真实 JPEG 字节、SHA 幂等、冲突、lastMessage 本地化 `[图片]` 摘要。
- UI：会话列表头像/时间/未读、聊天顶栏头像+昵称、气泡层次、44pt 控件；不编造在线/已读回执/陌生人申请。
- 测试落在已入编 `SocialRemoteMapperTests` / `AuthenticatedImageLoaderTests` / `ChatMessageMergeTests` / `MockSocialRepositoryTests`；未新增无 membership 测试文件。
- 本机仍仅 Command Line Tools（`simctl`/`xcodebuild` 不可用），不冒充 Simulator / App Build / XCTest 已通过。


## 图片私信实际离线复核（2026-10-06）

- 私图 URL 在缓存读取前验证：只接受当前 API origin、数字会话/消息 ID 的完整路径，无 query、fragment、userinfo、编码路径、重复或多余 `/`；外域不会收到 Bearer，也不回退公开加载。GET 忽略 URLSession 本地缓存，并检查 JPEG/PNG MIME 与 5MiB 上限。
- `SocialChatImageSupport+UIKit` 绘制 UIImage 到新图形上下文后输出 JPEG，应用照片方向、去掉原元数据、单边≤4096/1600万像素；保留 `clientMessageId` 和同一 Data 重试。图片查看使用 fit 展示完整照片，失败显示重试。
- 退场清理草稿、待发/失败图片 Data 和展示状态，取消 picker 任务；聊天异步读取/发送使用页面 generation 与 token 比较，旧回调不重新填充已清理页面。未取得当前用户 ID 时不猜造发送者。
- Mock 图片有本地私有字节读取，包含会话/消息归属检查；remote 不回退 mock。Mock 会话/消息使用数字 ID，已提交的同图重试在拉黑后仍返回原消息，新的发送仍受当前权限限制。
- 全部 351 个 App/单测/UITest Swift 文件最终语法检查通过（`swiftc -frontend -parse`）；`project.pbxproj` 和六语言 strings 的 `plutil -lint` 通过。
- 按项目 `-swift-version 5 -default-isolation MainActor` 编译原始模型、DTO、Mapper、URL、merge、滚动、hash、配置源码，最终无编译诊断；实际执行 31 项新增图片 URL/旧载荷解码/元数据限制/merge/hash 断言以及原发送方去重、已提交状态和 5 项滚动断言，全部通过。离线入口仅使用本地化 key/偏好标记，未替换所测业务逻辑。
- 命令和结果保存在本轮 `/tmp/gdei-chat-images-20261005/ios-verification`。仅 CLT 可用；UIKit 图形编码、PhotosPicker、SwiftUI App、完整 XCTest、模拟器/真机、真实 API/R2 尚未运行。仓库新增回归 XCTest 只通过语法检查，不计作 XCTest 已执行。

## 系统 PhotosPicker 图片私信 UI 验证入口（2026-10-06）

新增测试入口供完整 Xcode/CI 执行；本节不把代码落地或语法检查算作模拟器通过：

- `MockUISmokeTests` 新增 3 个图片流程：系统选图 → 草稿预览/移除 → 再次选图发送/查看 → 原生返回后草稿清理；首次发送失败 → 查看本地原图 → 原 ID 重试只保留一条消息；失败图片与新草稿共存 → 正常 `AuthManager.logout()` → 登录后均已清理。
- UITest 仅通过真实 `PhotosPicker` 的系统相册网格选择图片、`PhotosPickerItem.loadTransferable` 读取，不以直接注入 Data 替代系统选图。`Tools/make_chat_picker_photo.py` 使用 Python 标准库生成 480×320 三色带/向上箭头 PNG，`Tools/seed_chat_picker_photo.sh` 向指定模拟器相册写入该合成图片，不重置相册。
- 测试会话入口为 `GDEI_UI_INITIAL_SCREEN=conversations`。`GDEI_UI_FAIL_FIRST_CHAT_IMAGE=1` 仅在测试运行且启用 mock 时触发一次提交前网络失败；remote 路径不受影响。聊天测试退出按钮调用现有认证与页面清理，不替换清理实现。
- `MockSocialRepositoryTests` 追加真实 UIKit 编码/真实 ViewModel 与 mock repository 的回归：失败后保留 JPEG，重试沿用原 `clientMessageId` 与完全相同 bytes，只提交一次；`stop()` 清除失败 JPEG 和新草稿。它们用于逻辑验证，不代替系统选图 UI 用例。
- `ios-ci.yml` 固定 Xcode 26.3/iOS 26.2，先启动选定模拟器并 `simctl addmedia`，再以 `-parallel-testing-enabled NO` 运行全部单测与 UITest，避免克隆模拟器缺少种入图片。`ios-test-results` artifact 保留完整 `.xcresult`、测试日志、导出的阶段截图/控件树、合成图片及 hash/尺寸清单、最终模拟器截图。
- 选图/预览/发送/失败/重试/登录后的检查点截图始终保留；失败时追加当前截图与 `XCUIApplication.debugDescription`，便于确认系统 picker 与 SwiftUI 的真实控件。
- 草稿、已发送图片和查看器检查实际解码尺寸 480×320，避免把空白占位或既有 8×8 mock 图片当作系统选图成功。
- Release workflow 仅将 runner/Xcode 固定值更新为与 CI 相同的 macos-26/Xcode 26.3；签名/上传参数保持原状。CodeQL 使用显式 Swift 源码构建，工具链同步更新，但保持既有禁用状态，不擅自恢复扫描。

在完整 Xcode 环境中可仅跑这组 UI 用例：

```bash
bash Tools/seed_chat_picker_photo.sh "$SIMULATOR_UDID"
xcodebuild test -project GdeiAssistant-iOS.xcodeproj -scheme GdeiAssistant-iOS \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -parallel-testing-enabled NO -only-testing:GdeiAssistant-iOSUITests/MockUISmokeTests \
  CODE_SIGNING_ALLOWED=NO -resultBundlePath ChatPickerResults.xcresult
```

本机仅 CLT，新增流程待 CI 真实执行。模拟器 mock 测试不验证真机相册权限/iCloud 照片下载、真实 API/R2 鉴权与上传、真实 WebSocket 网络、后台系统行为或发布签名。

CI 首次运行 `37415308165`（`ba3310b`）实际完成构建、159 项单测和原有 4 项 UI 用例；3 项新增图片 UI 用例都停在系统相册定位。三份控件树与截图确认种图和测试使用同一模拟器，合成箭头图片位于相册第一项，另有系统默认照片。iOS 26.2 的缩略图类型为 `Image`/`PXGGridLayout-Info`，不是 `Cell`。测试改为在系统 `photosView_content_scroll_view` 中定位该 Image，继续保留真实系统选图、480×320 解码尺寸和全部后续断言；这项定位修正仍须由下一次 CI 实际复验。

第二次 CI `37417003363`（`e12c6dd`）实际仍通过构建、159 项单测和原 4 项 UI；新增 3 项正确找到相册 Image，但 `Image.tap()` 自动计算命中点为 `{-1,-1}`，报 not hittable。真实截图确认首张合成照片完整显示、无遮挡，控件树实时 frame 为 `{{0,292},{132.9,133}}`、位于 402×874 屏幕内。helper 改为依据该已定位 Image 的实时 frame 中心发送真正的 `XCUICoordinate` 触摸，并检查 frame 非空且在窗口内；不硬编码屏幕坐标、不更换系统 picker、不调整超时或删改后续断言。实际选图与后续图片流程仍待下一次 CI 复验。

### 2026-10-06 个人页、隐私入口及完整语言资源检查

关注／粉丝／好友三项数量放入头像昵称下面的资料头部，点击仍分别进入原关系列表，互相关注才是好友。个人页只保留一个隐私设置入口；私信接收范围和黑名单都在 `PrivacySettingsView` 的同一组里。复用原导航和 ViewModel，数量入口至少 44pt，未引入新的页面或关系算法。SwiftUI UI Patterns 和 UIUXProMax 仅用于这一组布局、原生列表、文字尺寸及点击区域检查。

支持语言保持六种：zh-CN（资源目录 zh-Hans）、zh-HK、zh-TW、en、ja、ko。每种有 1760 项 Localizable 和 1 项本地化麦克风权限说明；完整结构检查的缺失、多余、空值、重复、格式参数不一致都为 0，1500 个静态本地化引用未发现缺 key，静态 UI 字面量检查为 0。资料选项字典另有每语言 86 项，键集合一致。专名、外部状态解析及用户内容不作为需要翻译的界面文案。

本次调整 zh-HK 394 项措辞，按完整提示句处理粤语表达，并统一私隱／電郵／短訊／登入等词；zh-TW 调整 66 项，使用追蹤／傳送／使用者／隱私權設定等台湾用语，全部资源中没有嘅／唔／咗／啲／撳／搵。简体中文 3 项、英语／日语／韩语各 2 项主要修正“关注了我”的关系描述或去除验证码提示里的实现路径。已有正确短标签及用户提交内容保留。

运行时解析先取 Accept-Language 第一项、去掉参数，再处理空白、下划线和大小写，保留港澳、台湾及简体变体；首项不支持时回到简体中文。首次系统语言检测立即保存，避免 SwiftUI、非 View 文案及 HTTP 语言不同。UI 测试 app 使用自己的 standard 存储，而单测继续使用独立 suite；聊天日期和二手商品入学年份格式使用应用语言。应用生成的跑腿默认标题复用已有资源，地址、取件地和备注原样提交。

`Tools/check_localization.py` 以 Python 标准库检查全部资源及静态调用，已加入 CI 的 Style Check。新增回归覆盖：六语言资源／格式参数／权限文案／资料选项结构、语言参数解析、首次保存、切换语言且保留资料草稿、默认跑腿标题和用户内容、聊天日期；UI 新增资料头部／隐私分组导航，以及在同一外观页面切换全部六种语言后返回资料页。原有系统 PhotosPicker 图片流程保留。UI 每阶段保存截图，失败时保留截图和控件树。

本机 CLT 的 351 个 Swift 文件 parse、全部 strings 和 pbxproj 的 plutil、Style Check、资源扫描及 diff 检查通过。另将真实 AppLanguage／UserPreferences／LocalizationSupport／ProfileFormSupport 等源码编译为临时 macOS 检查程序，实际执行六语言查询、存储／参数解析、默认标题及聊天日期；没有替换业务实现。该程序验证可执行逻辑，不代表 iOS App 构建或 XCTest／模拟器通过。本轮实际 Xcode 26.3／iOS 26.2 的新增单测及 9 项 UI 流程交由 CI 执行。

### PR 64 首次 CI 返修

`37442929145`（`6711d44`）通过构建及 Style，但新语言测试出现三次实际 malloc 崩溃。新 `.xcresult` 内解出的 crash JSON 确认：聊天日期及首次语言保存测试在 `UserPreferences` 同步析构时进入 MainActor back-deployment 路径；六语言切换测试在 `ProfileViewModel` 释放 `MockProfileRepository` 时嵌套进入同一路径。三个类没有自定义 actor 清理，改用空 `nonisolated deinit`，仍由 ARC 释放属性及取消 Combine 订阅，不保留测试对象、不改 async 来避开同步释放。已有测试增加 20 次真实弱引用释放断言。语言测试每项先保存 standard locale、设置明确基线，结束时恢复原值（原值缺失则删除测试写入的键），避免后续 mapper／搜索测试读到韩语；原 mapper 和分页断言保持。

同一 CI 的 HK 资料页截图和控件树确认三项社交数量完全没有渲染。数量子视图初始返回空 `Group`，附加的 `.task` 没有实际子视图可承载；改用稳定 `VStack` 承载加载任务。资料头部显式使用 `.accessibilityElement(children: .contain)`，让头部标识保留在容器且不覆盖内部关注／粉丝／好友按钮标识。现有 9 项 UI 流程及断言保留，新增数量栏与隐私分组测试仍须由下一次完整 CI 实际复验。本机语法／资源检查与 macOS 逻辑执行不能替代 iOS 26.2 析构或模拟器 UI 验证。


### PR 64 第二次 CI 返修及系统地区显示

`37446742862`（`d4c0c4d`）的实际 `.xcresult` 解包确认，语言切换用例这次在 `SessionState.__deallocating_deinit` 进入 `MainActorBackDeploy` 后发生 malloc 崩溃。此前 `UserPreferences`、资料 ViewModel 和 mock repository 的修正保留；`SessionState` 同样只有自动 ARC 属性清理，增加空 `nonisolated deinit`。同步 20 次 weak 释放、六语言切换及原 mapper／搜索断言全部保留。崩溃使 locale 恢复代码未执行，因此后续出现韩语年级及中文搜索失败；不修改这些断言来掩盖原因。

同次 HK UI 的社交数量栏三个按钮已显示。隐私导航失败时的截图和控件树仍在个人页，按钮正常可见、标签正确、系统已合成 tap；自定义 `NavigationLink` 的 label 包含 `Spacer` 却未声明完整点击区域。菜单 label 增加 `.contentShape(Rectangle())`，使整行空白可点击。现有私隱設定／私訊规则／黑名單导航断言及全部 9 项 UI 流程保持。

系统地区采用四端共享字典，按真实 code 合并到原 `states`／`cities`：236 个国家或地区、266 个省级节点、3777 个城市都有 `zh-HK` 和 `zh-TW` 标签，原 `name`、code、层级及顺序保持。广东、广州、汕头、佛山的日语／韩语及 `Foshan` 拼写采用共享标签。所在地、家乡按已存 selection 的 code 实时绘制；选择器只重新显示 repository 返回的选项，保持其代码集合、顺序及未知节点。country-only 和 state-only 的有效选择也保留，不要求不存在的城市 code。未知代码及没有结构化 selection 的自由文字原样显示。

IP 和登录地区仅对完整的已知节点名称或父路径后缀进行精确匹配。接受原名称、六语言标签、latin 名称、locale 正常显示串、按父到子顺序的空格串以及中文／港澳／台湾紧凑串；按原路径层级输出当前语言，不补国家。若多个候选在目标语言有不同显示值，保留原文。未知文字、句子、带额外后缀的非目录格式不做 substring 替换。节点的六语言标签在索引内只解析一次，后续别名及查询复用。

同类检查修正了个人资料院系／专业的旧标签缓存：展示根据 `collegeCode`／`majorCode`，下拉选项按原代码显示当前语言但保留选值；恢复草稿优先用 faculty code。保存前按缓存选项代码生成当前语言标签，配合 repository 每次保存获取当前语言 options 的既有流程，避免切换语言后提交旧标签失败。昵称、简介、地址及未知自由内容不因本地化重写。

新增 6 项单测覆盖保留同一资料的六语言显示、稀疏选择器代码、country／state-only 与未知值、IP 完整路径／歧义，以及未先刷新缓存 options 的语言切换、真实 ViewModel 保存和 mapper DTO code。原六语言 UI 流程回到资料页后增加韩语所在地／家乡断言与截图，仍为 9 项 UI。Dating／Express 性别、Delivery／Marketplace 状态、LostFound 类型／状态及社交规则的系统枚举均已有计算型本地化；Marketplace 原先在映射时丢失后端数字分类 code，本轮追加可选 `typeID`（旧记录默认 nil）、mapper 保留及详情补图复制时透传；列表及详情按已知 code 显示当前语言分类。未知 code／旧记录的 tags 和 condition 原文保留，商品标题和正文不做猜译；回归覆盖同一 mapped detail 在六语言之间切换及新旧 Codable 记录。

本轮本机可执行检查将真实地区 catalog、资料／偏好／SessionState、ProfileViewModel、mapper 源码编译为临时 macOS 程序。ViewModel 的受控数据使用仓库既有 XCTest recording fixture，生产逻辑未替换；验证实际保存请求及 code、六语言显示、未知完整地区保持、IP 精确路径和 20 次同步 weak 释放。首次完整路径索引实测 CPU 约 4.35 秒，本轮改为轻量单节点索引加完整字符串候选匹配／结果缓存；最终 debug 两次检查首个地区查询 wall 约 0.60～1.56 秒、CPU 约 0.36～0.74 秒，后续查询约 0.001 秒。前缀／后缀仅筛候选，最终仍要求完整 alias 等于输入。该计时来自本机 x86_64 macOS，不代表模拟器或真机性能。

351 个 Swift 文件全量 parse 已通过，后续新增写集做定向 parse；1760×6 资源检查、格式参数、权限键、静态引用及 plutil 保持通过。本机没有完整 Xcode 和 XCTest 模块，真实 Xcode 26.3／iOS 26.2 的全部单测与 9 项 UI、析构及点按回归由最终精确 head CI 执行，不能用本机结果替代。

追加的真实 Marketplace mapper／model 也已在同一 macOS 检查程序实际通过六语言分类、新旧 Codable、未知标签及用户文字保持检查。host 编译出现两处既有 `nonisolated` mapper 读取 `LocalizedProfileCatalog.current` 的 MainActor 警告（itemTypes 和 facultyName）；不是本轮新增字段或显示方法的错误，Swift 5 编译退出 0，未为此扩展隔离结构调整。
