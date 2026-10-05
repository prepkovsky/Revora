import Foundation

/// The accounts a confirmation link has gone out to, kept across launches. Per account,
/// so a second account on the same device still gets offered a link of its own.
nonisolated struct SentVerifications {
    private static let key = "verificationSentUserIDs"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func contains(_ userID: String) -> Bool {
        userIDs.contains(userID)
    }

    func insert(_ userID: String) {
        save(userIDs.union([userID]))
    }

    func remove(_ userID: String) {
        guard contains(userID) else { return }
        save(userIDs.subtracting([userID]))
    }

    private var userIDs: Set<String> {
        Set(defaults.stringArray(forKey: Self.key) ?? [])
    }

    private func save(_ userIDs: Set<String>) {
        if userIDs.isEmpty {
            defaults.removeObject(forKey: Self.key)
        } else {
            defaults.set(userIDs.sorted(), forKey: Self.key)
        }
    }
}
