import CryptoKit
import Foundation

/// How often this device asks Firebase to send each kind of email. The free plan's daily
/// allowance is shared by everyone using the app, so a few quick taps shouldn't use it up.
/// This only stops accidents and casual repeats: a script that skips the app skips it too.
nonisolated struct EmailRateLimit {
    enum Kind: String {
        case passwordReset, verification, emailChange

        /// Resets have by far the smallest allowance: 150 a day on the free plan, against 1,000.
        var hourlyLimit: Int {
            self == .passwordReset ? 3 : 5
        }
    }

    struct Wait: Equatable {
        enum Reason {
            /// The same address got one less than `cooldown` ago.
            case recentlySent
            /// This device has sent `hourlyLimit` of this kind in the last hour.
            case hourlyLimit
        }

        let reason: Reason
        let until: Date
    }

    private struct Send: Codable {
        /// Hashed, since only whether two addresses match matters.
        let address: String
        let date: Date
    }

    /// Before the same address can get another email of the same kind.
    static let cooldown: TimeInterval = 60
    private static let window: TimeInterval = 60 * 60

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// How long until another email of this kind can go to this address, or `nil` if it can now.
    func wait(before kind: Kind, to address: String, now: Date = .now) -> Wait? {
        let sends = sends(of: kind, now: now)
        var waits: [Wait] = []

        let key = Self.key(for: address)
        if let last = sends.last(where: { $0.address == key }), now < last.date + Self.cooldown {
            waits.append(Wait(reason: .recentlySent, until: last.date + Self.cooldown))
        }
        if sends.count >= kind.hourlyLimit {
            // Room for one more once enough of the oldest have left the hour.
            let oldest = sends[sends.count - kind.hourlyLimit]
            waits.append(Wait(reason: .hourlyLimit, until: oldest.date + Self.window))
        }
        return waits.max { $0.until < $1.until }
    }

    func record(_ kind: Kind, to address: String, at date: Date = .now) {
        let sends = sends(of: kind, now: date) + [Send(address: Self.key(for: address), date: date)]
        defaults.set(try? JSONEncoder().encode(sends), forKey: Self.storageKey(kind))
    }

    /// The last hour's, oldest first. Ones from the future, after the clock was turned back, are dropped.
    private func sends(of kind: Kind, now: Date) -> [Send] {
        guard let data = defaults.data(forKey: Self.storageKey(kind)),
              let sends = try? JSONDecoder().decode([Send].self, from: data)
        else { return [] }
        return sends
            .filter { $0.date > now - Self.window && $0.date <= now }
            .sorted { $0.date < $1.date }
    }

    private static func storageKey(_ kind: Kind) -> String {
        "emailSends.\(kind.rawValue)"
    }

    private static func key(for address: String) -> String {
        let normalized = address.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return SHA256.hash(data: Data(normalized.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
