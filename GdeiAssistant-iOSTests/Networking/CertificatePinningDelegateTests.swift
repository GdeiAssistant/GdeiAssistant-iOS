import XCTest
import Security
@testable import GdeiAssistant_iOS

final class CertificatePinningDelegateTests: XCTestCase {
    func testChallengeFallsBackToDefaultHandlingForNonServerTrustAuthentication() {
        let delegate = CertificatePinningDelegate(pinnedHashes: ["ignored"])
        let sender = DummyChallengeSender()
        let protectionSpace = URLProtectionSpace(
            host: "example.com",
            port: 443,
            protocol: "https",
            realm: nil,
            authenticationMethod: NSURLAuthenticationMethodHTTPBasic
        )
        let challenge = URLAuthenticationChallenge(
            protectionSpace: protectionSpace,
            proposedCredential: nil,
            previousFailureCount: 0,
            failureResponse: nil,
            error: nil,
            sender: sender
        )

        var disposition: URLSession.AuthChallengeDisposition?
        var credential: URLCredential?
        delegate.urlSession(URLSession.shared, didReceive: challenge) { receivedDisposition, receivedCredential in
            disposition = receivedDisposition
            credential = receivedCredential
        }

        XCTAssertEqual(disposition, .performDefaultHandling)
        XCTAssertNil(credential)
    }

    func testCertificateMatchesPinsAcceptsMatchingPublicKeyHash() throws {
        let certificate = try sampleCertificate()
        let trust = try sampleTrust(certificate: certificate)
        let hasher = CertificatePinningDelegate(pinnedHashes: [])
        let publicKeyData = try XCTUnwrap(hasher.publicKeyData(for: certificate))
        let matchingPin = hasher.sha256Base64(publicKeyData)
        let delegate = CertificatePinningDelegate(pinnedHashes: [matchingPin])

        XCTAssertTrue(delegate.certificateMatchesPins(serverTrust: trust))
    }

    func testCertificateMatchesPinsRejectsMismatchedPublicKeyHash() throws {
        let certificate = try sampleCertificate()
        let trust = try sampleTrust(certificate: certificate)
        let delegate = CertificatePinningDelegate(pinnedHashes: ["not-a-real-pin"])

        XCTAssertFalse(delegate.certificateMatchesPins(serverTrust: trust))
    }

    func testHostSpecificPinsOnlyApplyToMatchingHost() {
        let delegate = CertificatePinningDelegate(pinnedHashesByHost: [
            "example.com": ["pin-a"],
            "api.example.com": ["pin-b"]
        ])

        XCTAssertEqual(delegate.hashes(for: "EXAMPLE.com"), ["pin-a"])
        XCTAssertEqual(delegate.hashes(for: "api.example.com"), ["pin-b"])
        XCTAssertTrue(delegate.hashes(for: "other.example.com").isEmpty)
    }

    private func sampleCertificate() throws -> SecCertificate {
        let data = try XCTUnwrap(Data(base64Encoded: sampleCertificateDERBase64))
        return try XCTUnwrap(
            SecCertificateCreateWithData(nil, data as CFData),
            "Expected sample certificate to decode"
        )
    }

    private func sampleTrust(certificate: SecCertificate) throws -> SecTrust {
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates(certificate, SecPolicyCreateBasicX509(), &trust)
        XCTAssertEqual(status, errSecSuccess)
        return try XCTUnwrap(trust, "Expected SecTrust to be created")
    }

    private let sampleCertificateDERBase64 =
        "MIIDDTCCAfWgAwIBAgIUS7Y3dfr/Q5JthOgMY9B3fxKFxuUwDQYJKoZIhvcNAQELBQAwFjEUMBIGA1UEAwwLZXhhbXBsZS5jb20wHhcNMjYwNDAzMTMxMjE2WhcNMjcwNDAzMTMxMjE2WjAWMRQwEgYDVQQDDAtleGFtcGxlLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMbgKocDPWL0Yf+nKtX6J9jPXz7h+Rm8pNaSOTR7CCubmfBGz1pVQgL6pvZBdrse/mEQdPVxnO383xrl/sgpteMBcHZZoG1CVg2olEYaNAsPXLRwXFiwa+l9A3b6amC/oJH2JexY9AKhvAVtr7ObAmBA5hcvuNkln2EJvLE8yAdy4MfzXMisrHnVHuZMmiPNUhGA0lFasNVcbF5ruSyaP82caiJJ1jINS7tu8AukWBnOdp6q3sH2IUF6tFnN4JPZbs5Z0MhmpRPglDNiWdzvLdD/v2wveDlD/7g0kh14N7Bec2RuOBxIyj8Lhsih5Rs0TQkGgp9RIE1C7Abusz0mf4ECAwEAAaNTMFEwHQYDVR0OBBYEFCxz5VPjRtNRiEvK/YJQSEzPDpYUMB8GA1UdIwQYMBaAFCxz5VPjRtNRiEvK/YJQSEzPDpYUMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAArFXLA8tPfTY5ahjdV2OH7j+d8eNQxFKiAWxRfmfCklWYxfvwgh2qC3k/+hB2M+WBzeZBxzpLZq55YDCvukZPDBmj5rVoyte2WOWnrvwlW5g/Ulw60RJ1JjCXF2R255w/laXAr4cJzyeqZRQK25pcjq6q4qP/tFKmQzLaEGTtTHPg+Nx1vGJHy8DBhXqCqKcmM4g3PnJpgku26bzEYgEZYJIDVHBSweMyoKLMWZjLBQJSHzAkA0+qwqsx9pl3rowQxIQXhKpXEKHsd7E6XBzLWGT9e4Hz3dxamLpSvMw6QEsueJeRkxD0PvMQElakSVvyoVIJ0tyzCR2p7oPXp3qr0="
}

private final class DummyChallengeSender: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}

    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}

    func cancel(_ challenge: URLAuthenticationChallenge) {}

    func performDefaultHandling(for challenge: URLAuthenticationChallenge) {}

    func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge) {}
}
