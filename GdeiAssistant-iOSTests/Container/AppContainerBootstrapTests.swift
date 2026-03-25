import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class AppContainerBootstrapTests: XCTestCase {

    func testMockContainerBootstrapsWithoutCrash() async {
        let container = AppContainer.testing
        await container.bootstrapIfNeeded()

        // Assemblies are accessible
        XCTAssertNotNil(container.coreAssembly)
        XCTAssertNotNil(container.campusServicesAssembly)
        XCTAssertNotNil(container.communityAssembly)
        XCTAssertNotNil(container.profileAssembly)
    }

    func testMockContainerCanCreateSampleViewModels() async {
        let container = AppContainer.preview

        // Core — delegates to CoreAssembly
        let homeVM = container.makeHomeViewModel()
        XCTAssertNotNil(homeVM)

        // Campus services — delegates to CampusServicesAssembly
        let scheduleVM = container.makeScheduleViewModel()
        XCTAssertNotNil(scheduleVM)

        // Community — delegates to CommunityAssembly
        let communityVM = container.makeCommunityViewModel()
        XCTAssertNotNil(communityVM)

        // Profile — delegates to ProfileAssembly
        let settingsVM = container.makeSettingsViewModel()
        XCTAssertNotNil(settingsVM)
    }

    func testProdEnvironmentUsesCanonicalAPIHost() {
        XCTAssertEqual(
            NetworkEnvironment.prod.baseURL.absoluteString,
            "https://gdeiassistant.cn/api"
        )
    }

    func testAppearanceEntryLivesInProfileMoreInsteadOfSettings() throws {
        let profileSource = try sourceFileContents(
            at: "GdeiAssistant-iOS/Features/Profile/Views/ProfileView.swift"
        )
        let settingsSource = try sourceFileContents(
            at: "GdeiAssistant-iOS/Features/Profile/Views/SettingsView.swift"
        )

        XCTAssertTrue(
            profileSource.contains("profileMenuLink(title: localizedString(\"appearance.title\")"),
            "Appearance 应该保留在个人中心 More 区域。"
        )
        XCTAssertFalse(
            settingsSource.contains("AppearanceView()"),
            "Settings 不应再直接暴露 Appearance 入口。"
        )
    }

    func testKnownHardCodedLocalizedStringsAreRemovedFromSharedUI() throws {
        let expectations: [(String, [String])] = [
            (
                "GdeiAssistant-iOS/Core/DesignSystem/CaptchaImageView.swift",
                ["点击刷新", "刷新验证码"]
            ),
            (
                "GdeiAssistant-iOS/Core/DesignSystem/PasswordInputSheet.swift",
                ["安全验证", "取消"]
            ),
            (
                "GdeiAssistant-iOS/Core/DesignSystem/DSInputField.swift",
                ["显示密码", "隐藏密码"]
            ),
            (
                "GdeiAssistant-iOS/Core/DesignSystem/DSLoadingView.swift",
                ["加载中..."]
            ),
            (
                "GdeiAssistant-iOS/Features/Profile/Views/BindPhoneView.swift",
                ["后重试"]
            ),
            (
                "GdeiAssistant-iOS/Features/Profile/Views/BindEmailView.swift",
                ["后重试"]
            ),
            (
                "GdeiAssistant-iOS/Features/Collection/ViewModels/CollectionViewModel.swift",
                ["请输入图书馆密码"]
            ),
            (
                "GdeiAssistant-iOS/Features/News/ViewModels/NewsViewModel.swift",
                ["新闻加载失败"]
            ),
            (
                "GdeiAssistant-iOS/Features/Photograph/Views/PhotographView.swift",
                ["当前分类下还没有内容，去发布第一张校园照片", "当前分类下还没有发布作品", "\"提交\""]
            )
        ]

        for (path, disallowedSnippets) in expectations {
            let source = try sourceFileContents(at: path)

            for snippet in disallowedSnippets {
                XCTAssertFalse(
                    source.contains(snippet),
                    "\(path) still contains hard-coded copy: \(snippet)"
                )
            }
        }
    }

    func testKnownHardCodedLocalizedStringsAreRemovedFromRepositoriesAndInfrastructure() throws {
        let expectations: [(String, [String])] = [
            (
                "GdeiAssistant-iOS/Core/Auth/AuthManager.swift",
                ["认证仓储未配置", "恢复登录态失败", "登录状态已过期，请重新登录"]
            ),
            (
                "GdeiAssistant-iOS/Core/Auth/KeychainTokenStorage.swift",
                ["Keychain 操作失败"]
            ),
            (
                "GdeiAssistant-iOS/Core/Networking/NetworkError.swift",
                ["请求地址无效", "服务响应异常", "网络连接失败，请检查网络后重试", "登录状态已过期，请重新登录", "服务暂时不可用，请稍后重试", "服务返回数据为空", "数据解析失败"]
            ),
            (
                "GdeiAssistant-iOS/Features/Auth/Repositories/MockAuthRepository.swift",
                ["账号或密码错误，请检查后重试"]
            ),
            (
                "GdeiAssistant-iOS/Features/Card/Repositories/MockCardRepository.swift",
                ["请输入校园卡查询密码", "模拟挂失失败：校园卡查询密码不正确"]
            ),
            (
                "GdeiAssistant-iOS/Features/Charge/Repositories/MockChargeRepository.swift",
                ["密码不能为空"]
            ),
            (
                "GdeiAssistant-iOS/Features/GraduateExam/Repositories/MockGraduateExamRepository.swift",
                ["请完整填写考研查询信息"]
            ),
            (
                "GdeiAssistant-iOS/Features/News/Repositories/RemoteNewsRepository.swift",
                ["新闻不存在"]
            ),
            (
                "GdeiAssistant-iOS/Features/News/Repositories/MockNewsRepository.swift",
                ["新闻不存在"]
            ),
            (
                "GdeiAssistant-iOS/Features/Secret/Repositories/RemoteSecretRepository.swift",
                ["语音内容不能为空"]
            ),
            (
                "GdeiAssistant-iOS/Features/Secret/Repositories/MockSecretRepository.swift",
                ["内容不存在", "评论内容不能为空", "评论内容不能超过 50 个字"]
            ),
            (
                "GdeiAssistant-iOS/Features/Collection/Repositories/MockCollectionRepository.swift",
                ["图书馆密码不正确", "未找到可续借记录"]
            ),
            (
                "GdeiAssistant-iOS/Features/DataCenter/Repositories/MockDataCenterRepository.swift",
                ["请完整填写姓名和学号"]
            ),
            (
                "GdeiAssistant-iOS/Features/Messages/Repositories/MockMessagesRepository.swift",
                ["公告不存在"]
            ),
            (
                "GdeiAssistant-iOS/Features/Profile/Models/AccountCenterModels.swift",
                ["未开始", "正在导出", "已生成"]
            ),
            (
                "GdeiAssistant-iOS/Features/Profile/Mappers/AccountCenterRemoteMapper.swift",
                ["尚未绑定手机号", "已绑定手机号（+", "尚未绑定邮箱", "已绑定邮箱，可用于接收验证码与服务通知", "未知地区", "刚刚", "未知 IP", "登录成功", "系统正在打包你的数据", "数据已打包完成", "未绑定", "未知设备"]
            ),
            (
                "GdeiAssistant-iOS/Features/Profile/Repositories/MockAccountCenterRepository.swift",
                ["已绑定常用手机号（+86）", "已绑定邮箱，可接收验证码与服务通知", "你可以随时导出个人数据副本。", "登录成功", "中国大陆", "验证码不正确", "数据已打包完成，可立即下载。", "密码校验失败，无法注销账号"]
            ),
            (
                "GdeiAssistant-iOS/Features/Marketplace/ViewModels/PublishMarketplaceViewModel.swift",
                ["手机号：", "请填写商品名称", "商品名称不能超过 25 个字", "请填写有效的商品价格", "请填写商品描述", "商品描述不能超过 100 个字", "请填写交易地点", "交易地点不能超过 30 个字", "请填写 QQ 号", "QQ 号不能超过 20 位", "手机号不能超过 11 位"]
            ),
            (
                "GdeiAssistant-iOS/Features/Marketplace/Repositories/MockMarketplaceRepository.swift",
                ["商品不存在", "请至少上传一张商品图片"]
            ),
            (
                "GdeiAssistant-iOS/Features/Marketplace/Mappers/MarketplaceRemoteMapper.swift",
                ["手机号：", "后端详情页未提供可展示联系方式"]
            ),
            (
                "GdeiAssistant-iOS/Features/Profile/Views/SettingsView.swift",
                ["Copyright © GdeiAssistant 2016-2026"]
            )
        ]

        for (path, disallowedSnippets) in expectations {
            let source = try sourceFileContents(at: path)

            for snippet in disallowedSnippets {
                XCTAssertFalse(
                    source.contains(snippet),
                    "\(path) still contains hard-coded copy: \(snippet)"
                )
            }
        }
    }

    private func sourceFileContents(at relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(relativePath)

        return try String(contentsOf: url, encoding: .utf8)
    }
}
