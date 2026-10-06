import Foundation
import Combine
import UIKit

enum SocialRealtimeEvent: Equatable {
    case ready
    case messageCreated(conversationId: String, messageId: String, seq: String)
    case conversationRead(conversationId: String, readerId: String, lastReadSeq: String)
    case socialChanged
    case disconnected
}

@MainActor
protocol SocialRealtimeManaging: AnyObject {
    var isReady: Bool { get }
    var latestEvent: SocialRealtimeEvent? { get }
    func start()
    func stop(clearState: Bool)
    func handleForegroundResume()
    func sendPing()
}

@MainActor
final class SocialRealtimeManager: ObservableObject, SocialRealtimeManaging {
    @Published private(set) var isReady = false
    @Published private(set) var latestEvent: SocialRealtimeEvent?
    @Published private(set) var connectionState: ConnectionState = .idle

    enum ConnectionState: Equatable {
        case idle
        case connecting
        case authenticating
        case ready
        case reconnecting
        case stopped
    }

    private let environment: AppEnvironment
    private let tokenProvider: () -> String?
    private let onUnauthorized: () -> Void
    private let isLoggedInProvider: () -> Bool

    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var receiveTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var authTimeoutTask: Task<Void, Never>?
    private var reconnectAttempt = 0
    private var shouldRun = false
    private var hasAuthenticated = false
    private var connectionGeneration: UInt64 = 0
    private var activeToken: String?

    init(
        environment: AppEnvironment,
        tokenProvider: @escaping () -> String?,
        isLoggedInProvider: @escaping () -> Bool,
        onUnauthorized: @escaping () -> Void
    ) {
        self.environment = environment
        self.tokenProvider = tokenProvider
        self.isLoggedInProvider = isLoggedInProvider
        self.onUnauthorized = onUnauthorized
    }

    func start() {
        guard environment.dataSourceMode != .mock else {
            connectionState = .ready
            isReady = true
            latestEvent = .ready
            return
        }
        guard isLoggedInProvider(), let token = tokenProvider(), !token.isEmpty else {
            stop(clearState: true)
            return
        }

        if shouldRun,
           activeToken == token,
           [.connecting, .authenticating, .ready, .reconnecting].contains(connectionState) {
            return
        }

        shouldRun = true
        reconnectAttempt = 0
        connect(token: token)
    }

    func stop(clearState: Bool) {
        shouldRun = false
        connectionGeneration &+= 1
        activeToken = nil
        reconnectTask?.cancel()
        reconnectTask = nil
        authTimeoutTask?.cancel()
        authTimeoutTask = nil
        receiveTask?.cancel()
        receiveTask = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        session?.invalidateAndCancel()
        session = nil
        hasAuthenticated = false
        isReady = false
        connectionState = .stopped
        if clearState {
            latestEvent = .disconnected
        }
    }

    func handleForegroundResume() {
        guard shouldRun || isLoggedInProvider() else { return }
        guard environment.dataSourceMode != .mock else {
            isReady = true
            connectionState = .ready
            latestEvent = .ready
            return
        }
        guard isLoggedInProvider(), let token = tokenProvider(), !token.isEmpty else {
            onUnauthorized()
            stop(clearState: true)
            return
        }
        if isReady {
            if activeToken == token {
                sendPing()
                latestEvent = .ready
                return
            }
            shouldRun = true
            reconnectAttempt = 0
            connect(token: token)
            return
        }
        start()
    }

    func sendPing() {
        guard hasAuthenticated, let webSocketTask else { return }
        let generation = connectionGeneration
        let payload = #"{"type":"ping"}"#
        webSocketTask.send(.string(payload)) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.connectionGeneration == generation else { return }
            }
        }
    }

    private func connect(token: String) {
        reconnectTask?.cancel()
        receiveTask?.cancel()
        authTimeoutTask?.cancel()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        session?.invalidateAndCancel()

        guard let url = realtimeURL() else {
            connectionState = .idle
            return
        }

        connectionGeneration &+= 1
        let generation = connectionGeneration
        activeToken = token
        connectionState = reconnectAttempt == 0 ? .connecting : .reconnecting
        isReady = false
        hasAuthenticated = false

        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        let session = URLSession(configuration: configuration)
        self.session = session
        let task = session.webSocketTask(with: url)
        webSocketTask = task
        task.resume()
        connectionState = .authenticating
        sendAuth(token: token, generation: generation)
        startReceiveLoop(generation: generation)
        authTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard let self, !Task.isCancelled else { return }
            guard self.connectionGeneration == generation else { return }
            if !self.hasAuthenticated {
                self.handleAuthFailure(generation: generation)
            }
        }
    }

    private func sendAuth(token: String, generation: UInt64) {
        guard let webSocketTask else { return }
        // Token must not be logged.
        let payload = #"{"type":"auth","token":"\#(token.jsonEscaped)"}"#
        webSocketTask.send(.string(payload)) { [weak self] error in
            Task { @MainActor in
                guard let self, self.connectionGeneration == generation else { return }
                if error != nil {
                    self.handleAuthFailure(generation: generation)
                }
            }
        }
    }

    private func startReceiveLoop(generation: UInt64) {
        receiveTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                guard self.connectionGeneration == generation else { return }
                guard let task = self.webSocketTask else { break }
                do {
                    let message = try await task.receive()
                    guard self.connectionGeneration == generation else { return }
                    await self.handle(message: message, generation: generation)
                } catch {
                    guard self.connectionGeneration == generation else { return }
                    await self.handleReceiveFailure(generation: generation)
                    break
                }
            }
        }
    }

    private func handle(message: URLSessionWebSocketTask.Message, generation: UInt64) async {
        guard connectionGeneration == generation else { return }

        let text: String
        switch message {
        case .string(let value):
            text = value
        case .data(let data):
            text = String(decoding: data, as: UTF8.self)
        @unknown default:
            return
        }

        guard let data = text.data(using: .utf8),
              let envelope = try? JSONDecoder().decode(SocialRealtimeEnvelopeDTO.self, from: data),
              let type = envelope.type?.lowercased() else {
            return
        }

        switch type {
        case "ready":
            guard connectionGeneration == generation else { return }
            hasAuthenticated = true
            isReady = true
            connectionState = .ready
            reconnectAttempt = 0
            authTimeoutTask?.cancel()
            latestEvent = .ready
        case "pong":
            break
        case "message.created":
            guard hasAuthenticated,
                  connectionGeneration == generation,
                  let conversationId = RemoteMapperSupport.sanitizedText(envelope.conversationId),
                  let messageId = RemoteMapperSupport.sanitizedText(envelope.messageId),
                  let seq = RemoteMapperSupport.sanitizedText(envelope.seq?.rawValue) else { return }
            latestEvent = .messageCreated(conversationId: conversationId, messageId: messageId, seq: seq)
        case "conversation.read":
            guard hasAuthenticated,
                  connectionGeneration == generation,
                  let conversationId = RemoteMapperSupport.sanitizedText(envelope.conversationId),
                  let readerId = RemoteMapperSupport.sanitizedText(envelope.readerId),
                  let lastReadSeq = RemoteMapperSupport.sanitizedText(envelope.lastReadSeq?.rawValue) else { return }
            latestEvent = .conversationRead(
                conversationId: conversationId,
                readerId: readerId,
                lastReadSeq: lastReadSeq
            )
        case "social.changed":
            guard hasAuthenticated, connectionGeneration == generation else { return }
            latestEvent = .socialChanged
        default:
            break
        }
    }

    private func handleReceiveFailure(generation: UInt64) async {
        guard connectionGeneration == generation else { return }
        isReady = false
        hasAuthenticated = false
        latestEvent = .disconnected
        scheduleReconnect(generation: generation)
    }

    private func handleAuthFailure(generation: UInt64) {
        guard connectionGeneration == generation else { return }
        isReady = false
        hasAuthenticated = false
        guard isLoggedInProvider(), let token = tokenProvider(), !token.isEmpty else {
            onUnauthorized()
            stop(clearState: true)
            return
        }
        scheduleReconnect(generation: generation)
    }

    private func scheduleReconnect(generation: UInt64) {
        guard connectionGeneration == generation else { return }
        guard shouldRun, isLoggedInProvider() else {
            stop(clearState: true)
            return
        }
        guard let token = tokenProvider(), !token.isEmpty else {
            onUnauthorized()
            stop(clearState: true)
            return
        }

        // Token rotated while this generation was active: start a fresh connection identity.
        if activeToken != token {
            connect(token: token)
            return
        }

        receiveTask?.cancel()
        receiveTask = nil
        authTimeoutTask?.cancel()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        session?.invalidateAndCancel()
        session = nil

        reconnectAttempt += 1
        let delay = min(pow(2.0, Double(min(reconnectAttempt, 5))), 30.0)
        connectionState = .reconnecting
        reconnectTask?.cancel()
        let scheduledGeneration = connectionGeneration
        reconnectTask = Task { [weak self] in
            let nanoseconds = UInt64(delay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard let self, !Task.isCancelled else { return }
            guard self.connectionGeneration == scheduledGeneration, self.shouldRun else { return }
            guard self.isLoggedInProvider(), let currentToken = self.tokenProvider(), !currentToken.isEmpty else {
                self.onUnauthorized()
                self.stop(clearState: true)
                return
            }
            self.connect(token: currentToken)
        }
    }

    private func realtimeURL() -> URL? {
        var components = URLComponents(url: environment.baseURL, resolvingAgainstBaseURL: false)
        let scheme = (components?.scheme?.lowercased() == "https") ? "wss" : "ws"
        components?.scheme = scheme
        let basePath = components?.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? "api"
        components?.path = "/" + basePath + "/social/realtime"
        components?.query = nil
        return components?.url
    }
}

private extension String {
    var jsonEscaped: String {
        replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

@MainActor
final class NoopSocialRealtimeManager: SocialRealtimeManaging {
    var isReady = true
    var latestEvent: SocialRealtimeEvent? = .ready

    func start() {}
    func stop(clearState: Bool) {}
    func handleForegroundResume() {}
    func sendPing() {}
}
