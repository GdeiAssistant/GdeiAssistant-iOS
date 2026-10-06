import Foundation

/// Pure scroll policy for chat threads: stick to newest on first load / tail append,
/// but keep the user's place when earlier history is prepended.
enum ChatThreadAutoScroll {
    enum Action: Equatable {
        case none
        /// Jump to the newest bubble (initial load, send, pull-newer, WS append).
        case scrollToBottom(messageID: String)
        /// Keep the previously first visible row after an earlier-page prepend.
        case preserve(messageID: String)
    }

    /// Trailing bubble identity used to detect true appends vs prepend-only growth.
    nonisolated static func trailingIdentity(of messages: [ChatMessage]) -> String? {
        messages.last.map(\.id)
    }

    nonisolated static func action(
        previous: [ChatMessage],
        current: [ChatMessage]
    ) -> Action {
        guard let currentTrailing = trailingIdentity(of: current) else {
            return .none
        }

        if previous.isEmpty {
            return .scrollToBottom(messageID: currentTrailing)
        }

        let previousTrailing = trailingIdentity(of: previous)
        if previousTrailing != currentTrailing {
            return .scrollToBottom(messageID: currentTrailing)
        }

        // Same trailing identity with a larger list ⇒ earlier history was prepended.
        if current.count > previous.count, let oldFirstID = previous.first?.id {
            return .preserve(messageID: oldFirstID)
        }

        return .none
    }
}
