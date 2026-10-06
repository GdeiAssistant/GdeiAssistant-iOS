import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class AuthenticatedImageLoaderTests: XCTestCase {
    func testLoaderAndEnvironmentReleaseSynchronously() {
        for _ in 0 ..< 20 {
            weak var releasedEnvironment: AppEnvironment?
            weak var releasedLoader: AuthenticatedImageLoader?
            do {
                let environment = AppEnvironment(
                    networkEnvironment: .prod,
                    dataSourceMode: .remote,
                    isDebug: false,
                    clientType: "IOS"
                )
                let loader = AuthenticatedImageLoader(
                    environment: environment,
                    session: .shared,
                    tokenProvider: { "test-token" },
                    onUnauthorized: {}
                )
                releasedEnvironment = environment
                releasedLoader = loader
                XCTAssertNotNil(releasedEnvironment)
                XCTAssertNotNil(releasedLoader)
            }
            XCTAssertNil(releasedLoader)
            XCTAssertNil(releasedEnvironment)
        }
    }

    func testResolveRelativeAPIPathStripsAPIPrefixAndRequiresAuthPath() {
        let loader = makeLoader(baseURL: URL(string: "https://gdeiassistant.cn/api")!)
        guard case .authenticatedPath(let path) = loader.resolve("/api/social/users/user-1/avatar") else {
            return XCTFail("Expected authenticated relative API path")
        }
        XCTAssertEqual(path, "social/users/user-1/avatar")
    }

    func testResolveSameHostAbsoluteURLUsesAuthenticatedPath() {
        let loader = makeLoader(baseURL: URL(string: "https://gdeiassistant.cn/api")!)
        guard case .authenticatedPath(let path) = loader.resolve(
            "https://gdeiassistant.cn/api/social/users/user-1/avatar"
        ) else {
            return XCTFail("Expected authenticated absolute same-host path")
        }
        XCTAssertEqual(path, "social/users/user-1/avatar")
    }

    func testResolveExternalAbsoluteURLStaysPublic() {
        let loader = makeLoader(baseURL: URL(string: "https://gdeiassistant.cn/api")!)
        guard case .publicURL(let url) = loader.resolve("https://cdn.example.com/avatar.png") else {
            return XCTFail("Expected public URL")
        }
        XCTAssertEqual(url.host, "cdn.example.com")
    }

    func testSameHostDifferentSchemeOrPortDoesNotUseAuthenticatedPath() {
        let loader = makeLoader(baseURL: URL(string: "https://gdeiassistant.cn/api")!)
        for raw in [
            "http://gdeiassistant.cn/api/social/users/user-1/avatar",
            "https://gdeiassistant.cn:8443/api/social/users/user-1/avatar"
        ] {
            guard case .publicURL = loader.resolve(raw) else {
                return XCTFail("Different origin must not receive API credentials")
            }
        }
    }

    func testUnsafeSchemeAndEmbeddedCredentialsAreRejected() {
        let loader = makeLoader(baseURL: URL(string: "https://gdeiassistant.cn/api")!)
        for raw in ["javascript:alert(1)", "https://user:demo@cdn.example.com/avatar", "//cdn.example.com/avatar"] {
            guard case .none = loader.resolve(raw) else {
                return XCTFail("Invalid image source must not produce a request")
            }
        }
    }

    func testResolveEmptyOrNilLikeValuesAreNone() {
        let loader = makeLoader(baseURL: URL(string: "https://gdeiassistant.cn/api")!)
        guard case .none = loader.resolve("   ") else {
            return XCTFail("Blank avatar must not invent a URL")
        }
    }

    func testExactChatImagePathRecognized() {
        XCTAssertTrue(
            SocialChatImageSupport.isExactChatImageAPIPath(
                "social/conversations/1/messages/9/image"
            )
        )
        XCTAssertFalse(
            SocialChatImageSupport.isExactChatImageAPIPath(
                "social/users/user-1/avatar"
            )
        )
        XCTAssertFalse(
            SocialChatImageSupport.isExactChatImageAPIPath(
                "social/conversations/1/messages/9/image?token=x"
            )
        )
    }

    func testChatImageResolveUsesAuthenticatedSameOriginPathOnly() {
        let loader = makeLoader(baseURL: URL(string: "https://gdeiassistant.cn/api")!)
        let path = "/api/social/conversations/1/messages/9/image"
        guard case .authenticatedPath(let resolved) = loader.resolve(path) else {
            return XCTFail("Chat image path must resolve authenticated")
        }
        XCTAssertTrue(SocialChatImageSupport.isExactChatImageAPIPath(resolved))
        guard case .publicURL = loader.resolve("https://cdn.example.com/chat.png") else {
            return XCTFail("External chat-like URL must stay public and never carry Bearer")
        }
    }

    func testPrivateImageURLRejectsQueryFragmentExternalAndMalformedPaths() {
        let base = URL(string: "https://gdeiassistant.cn/api")!
        for source in [
            "https://other.example/api/social/conversations/1/messages/9/image",
            "http://gdeiassistant.cn/api/social/conversations/1/messages/9/image",
            "https://gdeiassistant.cn:8443/api/social/conversations/1/messages/9/image",
            "https://user:password@gdeiassistant.cn/api/social/conversations/1/messages/9/image",
            "https://gdeiassistant.cn/api/social/conversations/1/messages/9/image?token=x",
            "/api/social/conversations/1/messages/9/image#preview",
            "/api/social/conversations/1/messages/9/image/",
            "/api/social/conversations/1//messages/9/image",
            "/api/social/conversations/abc/messages/9/image",
            "/api/social/conversations/%31/messages/9/image",
            "//gdeiassistant.cn/api/social/conversations/1/messages/9/image"
        ] {
            XCTAssertNil(SocialChatImageURL.relativePath(for: source, baseURL: base), source)
        }
        for source in [
            "/api/social/conversations/1/messages/9/image",
            "social/conversations/1/messages/9/image",
            "https://gdeiassistant.cn/api/social/conversations/1/messages/9/image"
        ] {
            XCTAssertEqual(SocialChatImageURL.relativePath(for: source, baseURL: base),
                           "social/conversations/1/messages/9/image")
        }
    }

    func testMultipartJpegBoundAndContentType() {
        XCTAssertEqual(SocialChatImageSupport.maxBytes, 5 * 1024 * 1024)
        XCTAssertTrue(SocialChatImageSupport.isAllowedContentType("image/jpeg"))
        XCTAssertTrue(SocialChatImageSupport.isAllowedContentType("image/png"))
        XCTAssertFalse(SocialChatImageSupport.isAllowedContentType("image/gif"))
        XCTAssertFalse(SocialChatImageSupport.isAllowedContentType("image/webp"))
        let digest = SocialChatImageSupport.sha256Hex(Data([1, 2, 3]))
        XCTAssertEqual(digest.count, 64)

        XCTAssertNil(SocialChatImageSupport.jpegUploadAsset(data: Data(), fileName: "empty.jpg"))
        let seed = MockSocialSeed.seedJPEGData
        let asset = SocialChatImageSupport.jpegUploadAsset(data: seed, fileName: "seed.jpg")
        XCTAssertEqual(asset?.mimeType, "image/jpeg")
        XCTAssertEqual(asset?.data.count, seed.count)
        XCTAssertLessThanOrEqual(asset?.data.count ?? Int.max, SocialChatImageSupport.maxBytes)
    }

    func testDisplayTimeKeepsUnparseableRaw() {
        XCTAssertEqual(SocialDisplayTime.format("not-a-date"), "not-a-date")
        let formatted = SocialDisplayTime.format("2026-10-05T12:05:00+08:00")
        XCTAssertFalse(formatted.isEmpty)
        XCTAssertNotEqual(formatted, "just now")
    }

    private func makeLoader(baseURL: URL) -> AuthenticatedImageLoader {
        let environment = AppEnvironment(
            networkEnvironment: .prod,
            dataSourceMode: .remote,
            isDebug: false,
            clientType: "IOS"
        )
        environment.baseURL = baseURL
        return AuthenticatedImageLoader(
            environment: environment,
            session: .shared,
            tokenProvider: { "test-token" },
            onUnauthorized: {}
        )
    }
}
