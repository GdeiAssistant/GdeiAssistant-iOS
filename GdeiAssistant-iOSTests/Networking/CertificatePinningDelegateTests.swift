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

    func testDynamicSPKIHeadersSupportMultipleRSASizesAndECCurves() throws {
        let delegate = CertificatePinningDelegate(pinnedHashes: [])

        let rsa2048 = try makePublicKey(type: kSecAttrKeyTypeRSA, sizeInBits: 2048)
        let rsa2048SPKI = try XCTUnwrap(delegate.publicKeySPKIData(for: rsa2048))
        XCTAssertTrue(rsa2048SPKI.starts(with: [
            0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09,
            0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
            0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
        ]))

        let rsa3072 = try makePublicKey(type: kSecAttrKeyTypeRSA, sizeInBits: 3072)
        let rsa3072SPKI = try XCTUnwrap(delegate.publicKeySPKIData(for: rsa3072))
        XCTAssertTrue(rsa3072SPKI.starts(with: [
            0x30, 0x82, 0x01, 0xa2, 0x30, 0x0d, 0x06, 0x09,
            0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
            0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x8f, 0x00
        ]))

        let ec256 = try makePublicKey(type: kSecAttrKeyTypeECSECPrimeRandom, sizeInBits: 256)
        let ec256SPKI = try XCTUnwrap(delegate.publicKeySPKIData(for: ec256))
        XCTAssertEqual(ec256SPKI.count, 91)
        XCTAssertTrue(ec256SPKI.starts(with: [
            0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86,
            0x48, 0xce, 0x3d, 0x02, 0x01, 0x06, 0x08, 0x2a,
            0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03,
            0x42, 0x00
        ]))

        let ec384 = try makePublicKey(type: kSecAttrKeyTypeECSECPrimeRandom, sizeInBits: 384)
        let ec384SPKI = try XCTUnwrap(delegate.publicKeySPKIData(for: ec384))
        XCTAssertEqual(ec384SPKI.count, 120)
        XCTAssertTrue(ec384SPKI.starts(with: [
            0x30, 0x76, 0x30, 0x10, 0x06, 0x07, 0x2a, 0x86,
            0x48, 0xce, 0x3d, 0x02, 0x01, 0x06, 0x05, 0x2b,
            0x81, 0x04, 0x00, 0x22, 0x03, 0x62, 0x00
        ]))

        let ec521 = try makePublicKey(type: kSecAttrKeyTypeECSECPrimeRandom, sizeInBits: 521)
        let ec521SPKI = try XCTUnwrap(delegate.publicKeySPKIData(for: ec521))
        XCTAssertEqual(ec521SPKI.count, 158)
        XCTAssertTrue(ec521SPKI.starts(with: [
            0x30, 0x81, 0x9b, 0x30, 0x10, 0x06, 0x07, 0x2a,
            0x86, 0x48, 0xce, 0x3d, 0x02, 0x01, 0x06, 0x05,
            0x2b, 0x81, 0x04, 0x00, 0x23, 0x03, 0x81, 0x86,
            0x00
        ]))
    }

    private func makePublicKey(type: CFString, sizeInBits: Int) throws -> SecKey {
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: type,
            kSecAttrKeySizeInBits: sizeInBits,
            kSecAttrIsPermanent: false
        ]
        var error: Unmanaged<CFError>?
        let privateKey = try XCTUnwrap(SecKeyCreateRandomKey(attributes as CFDictionary, &error))
        return try XCTUnwrap(SecKeyCopyPublicKey(privateKey))
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
