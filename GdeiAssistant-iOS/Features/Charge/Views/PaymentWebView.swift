import SwiftUI
import WebKit

struct PaymentWebView: View {
    let session: ChargePayment
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(localizedString("charge.backToForm"), action: onDismiss)
                    .font(.subheadline)
                Spacer()
                Text(localizedString("charge.alipay"))
                    .font(.headline)
                Spacer()
                // Balance the layout
                Button(localizedString("charge.backToForm")) {}.opacity(0)
            }
            .padding()

            AlipayWebViewRepresentable(session: session)
        }
        .navigationBarBackButtonHidden(true)
    }
}

private struct AlipayWebViewRepresentable: UIViewRepresentable {
    let session: ChargePayment

    private static let allowedCookieDomains: Set<String> = [
        "alipay.com", ".alipay.com",
        "alipayobjects.com", ".alipayobjects.com",
        "epay.gdei.edu.cn", ".epay.gdei.edu.cn",
        "ecard.gdei.edu.cn", ".ecard.gdei.edu.cn"
    ]

    private static let allowedExternalSchemes: Set<String> = [
        "alipays", "alipay", "weixin", "wechat"
    ]

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // Inject whitelisted cookies
        let store = webView.configuration.websiteDataStore.httpCookieStore
        for cookie in session.cookies {
            guard Self.isAllowedDomain(cookie.domain) else { continue }
            var properties: [HTTPCookiePropertyKey: Any] = [
                .name: cookie.name,
                .value: cookie.value,
                .domain: cookie.domain,
                .path: "/"
            ]
            if let httpCookie = HTTPCookie(properties: properties) {
                store.setCookie(httpCookie)
            }
        }

        if let url = URL(string: session.alipayURL) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    private static func isAllowedDomain(_ domain: String) -> Bool {
        let lower = domain.lowercased()
        return allowedCookieDomains.contains(where: { lower == $0 || lower.hasSuffix($0) })
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            let scheme = url.scheme?.lowercased() ?? ""
            if scheme == "http" || scheme == "https" {
                decisionHandler(.allow)
                return
            }
            // Only open whitelisted external schemes
            if AlipayWebViewRepresentable.allowedExternalSchemes.contains(scheme) {
                UIApplication.shared.open(url)
            }
            decisionHandler(.cancel)
        }
    }
}
