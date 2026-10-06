import Foundation

enum ChatMessageMerge {
    /// Committed server seq only. Pending/failed must not invent or advance cursors.
    nonisolated static func committedSeq(of message: ChatMessage) -> Int64? {
        guard message.deliveryState == .sent,
              let value = Int64(message.seq),
              value > 0 else {
            return nil
        }
        return value
    }

    nonisolated static func sendIdentityKey(of message: ChatMessage) -> String {
        "\(message.conversationId)|\(message.senderId)|\(message.clientMessageId)"
    }

    /// Prefer a submitted server copy over local pending/failed for the same sender identity.
    nonisolated static func prefer(_ lhs: ChatMessage, _ rhs: ChatMessage) -> ChatMessage {
        switch (lhs.deliveryState, rhs.deliveryState) {
        case (.sent, .sent):
            if lhs.id == rhs.id {
                return lhs
            }
            // Same send identity should collapse to one submitted message; keep higher seq when both valid.
            let lhsSeq = committedSeq(of: lhs)
            let rhsSeq = committedSeq(of: rhs)
            if let lhsSeq, let rhsSeq {
                return rhsSeq >= lhsSeq ? rhs : lhs
            }
            return rhs
        case (.sent, _):
            return lhs
        case (_, .sent):
            return rhs
        case (.pending, .failed), (.pending, .pending):
            return rhs
        case (.failed, .pending):
            return rhs
        default:
            return rhs
        }
    }

    /// Deduplicate by server `id` and by `(conversationId, senderId, clientMessageId)`.
    /// Two senders sharing a clientMessageId remain two rows.
    nonisolated static func merge(_ items: [ChatMessage]) -> [ChatMessage] {
        var byID: [String: ChatMessage] = [:]
        var identityToID: [String: String] = [:]

        for item in items {
            let identity = sendIdentityKey(of: item)

            if let existingIdentityID = identityToID[identity],
               let existing = byID[existingIdentityID] {
                let chosen = prefer(existing, item)
                if chosen.id != existing.id {
                    byID.removeValue(forKey: existing.id)
                }
                // If chosen shares an id with another distinct identity row, fold that too.
                if let collision = byID[chosen.id], sendIdentityKey(of: collision) != identity {
                    let folded = prefer(collision, chosen)
                    byID[chosen.id] = folded
                    identityToID[sendIdentityKey(of: folded)] = folded.id
                    identityToID[identity] = folded.id
                } else {
                    byID[chosen.id] = chosen
                    identityToID[identity] = chosen.id
                }
                continue
            }

            if let existingByID = byID[item.id] {
                let chosen = prefer(existingByID, item)
                byID[item.id] = chosen
                identityToID[sendIdentityKey(of: chosen)] = chosen.id
                continue
            }

            byID[item.id] = item
            identityToID[identity] = item.id
        }

        return sorted(Array(byID.values))
    }

    /// Replace only the current sender's local pending/failed bubble for a clientMessageId.
    nonisolated static func replaceLocalBubble(
        in items: [ChatMessage],
        senderId: String,
        clientMessageId: String,
        with replacement: ChatMessage
    ) -> [ChatMessage] {
        let filtered = items.filter { message in
            let isSameSenderAttempt =
                message.senderId == senderId
                && message.clientMessageId == clientMessageId
                && message.deliveryState != .sent
            return !isSameSenderAttempt
        }
        return merge(filtered + [replacement])
    }

    nonisolated static func updateLocalBubbleState(
        in items: [ChatMessage],
        senderId: String,
        clientMessageId: String,
        deliveryState: ChatDeliveryState
    ) -> [ChatMessage] {
        let updated = items.map { message in
            guard message.senderId == senderId,
                  message.clientMessageId == clientMessageId,
                  message.deliveryState != .sent else {
                // Never demote an already-sent (e.g. WS-confirmed) bubble.
                return message
            }
            return message.updating(deliveryState: deliveryState)
        }
        return merge(updated)
    }

    /// True when the local bubble for this send identity is already server-confirmed.
    nonisolated static func hasCommittedSend(
        in items: [ChatMessage],
        senderId: String,
        clientMessageId: String
    ) -> Bool {
        items.contains {
            $0.senderId == senderId
                && $0.clientMessageId == clientMessageId
                && $0.deliveryState == .sent
                && committedSeq(of: $0) != nil
        }
    }

    nonisolated static func latestCommittedSeq(_ items: [ChatMessage]) -> String? {
        items.compactMap(committedSeq(of:)).max().map(String.init)
    }

    nonisolated static func latestCommittedPeerSeq(
        _ items: [ChatMessage],
        excludingSenderId: String?
    ) -> String? {
        items
            .filter { message in
                guard committedSeq(of: message) != nil else { return false }
                if let excludingSenderId {
                    return message.senderId != excludingSenderId
                }
                return true
            }
            .compactMap(committedSeq(of:))
            .max()
            .map(String.init)
    }

    nonisolated static func sorted(_ items: [ChatMessage]) -> [ChatMessage] {
        let committed = items
            .filter { committedSeq(of: $0) != nil }
            .sorted { lhs, rhs in
                let left = committedSeq(of: lhs) ?? 0
                let right = committedSeq(of: rhs) ?? 0
                if left == right {
                    return lhs.createdAt < rhs.createdAt
                }
                return left < right
            }
        let local = items
            .filter { committedSeq(of: $0) == nil }
            .sorted { lhs, rhs in
                if lhs.createdAt == rhs.createdAt {
                    return lhs.id < rhs.id
                }
                return lhs.createdAt < rhs.createdAt
            }
        return committed + local
    }
}
