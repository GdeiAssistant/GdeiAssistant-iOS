import Foundation
import CommonCrypto

/// URLSession delegate that enforces TLS certificate pinning by comparing
/// the server certificate's public-key SHA-256 hash against a known set of pins.
///
/// When the server's public key does not match any of the pins, the connection
/// is cancelled — protecting against certificate misissuance and MITM proxies.
final class CertificatePinningDelegate: NSObject, URLSessionDelegate {

    /// Base64-encoded SHA-256 hashes of the allowed server public keys.
    /// Generate with:
    /// ```
    /// openssl s_client -connect <host>:443 | openssl x509 -pubkey -noout |
    ///   openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
    /// ```
    private let fallbackPinnedHashes: Set<String>
    private let pinnedHashesByHost: [String: Set<String>]

    init(pinnedHashes: Set<String>) {
        self.fallbackPinnedHashes = pinnedHashes
        self.pinnedHashesByHost = [:]
    }

    init(pinnedHashesByHost: [String: Set<String>]) {
        self.fallbackPinnedHashes = []
        self.pinnedHashesByHost = Dictionary(
            uniqueKeysWithValues: pinnedHashesByHost.map { key, value in
                (key.lowercased(), value)
            }
        )
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let pinnedHashes = hashes(for: challenge.protectionSpace.host)

        // If no pins configured (dev/mock), fall through to default
        guard !pinnedHashes.isEmpty else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        if certificateMatchesPins(serverTrust: serverTrust, pinnedHashes: pinnedHashes) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    func hashes(for host: String) -> Set<String> {
        pinnedHashesByHost[host.lowercased()] ?? fallbackPinnedHashes
    }

    func certificateMatchesPins(serverTrust: SecTrust) -> Bool {
        certificateMatchesPins(serverTrust: serverTrust, pinnedHashes: fallbackPinnedHashes)
    }

    func certificateMatchesPins(serverTrust: SecTrust, pinnedHashes: Set<String>) -> Bool {
        // Use modern API (iOS 15+) with fallback
        let certificates: [SecCertificate]
        if #available(iOS 15.0, *) {
            certificates = (SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate]) ?? []
        } else {
            let count = SecTrustGetCertificateCount(serverTrust)
            guard count > 0 else { return false }
            certificates = (0 ..< count).compactMap { SecTrustGetCertificateAtIndex(serverTrust, $0) }
        }
        for certificate in certificates {
            if let publicKeyData = publicKeyData(for: certificate) {
                let hash = sha256Base64(publicKeyData)
                if pinnedHashes.contains(hash) {
                    return true
                }
            }
        }
        return false
    }

    func publicKeyData(for certificate: SecCertificate) -> Data? {
        guard let publicKey = SecCertificateCopyKey(certificate) else { return nil }
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else { return nil }
        return data
    }

    func sha256Base64(_ data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, UInt32(data.count), &hash)
        }
        return Data(hash).base64EncodedString()
    }
}
