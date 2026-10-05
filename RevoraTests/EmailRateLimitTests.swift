import Foundation
import Testing
@testable import Revora

struct EmailRateLimitTests {
    private let defaults: UserDefaults
    private let limit: EmailRateLimit
    private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    init() {
        let suiteName = "EmailRateLimitTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        limit = EmailRateLimit(defaults: defaults)
    }

    @Test func allowsTheFirstEmail() {
        #expect(limit.wait(before: .passwordReset, to: "a@example.com", now: start) == nil)
    }

    @Test func waitsBeforeTheSameAddressGetsAnother() {
        limit.record(.passwordReset, to: "a@example.com", at: start)
        let wait = limit.wait(before: .passwordReset, to: "a@example.com", now: start + 20)
        #expect(wait == .init(reason: .recentlySent, until: start + EmailRateLimit.cooldown))
        #expect(limit.wait(before: .passwordReset, to: "a@example.com", now: start + EmailRateLimit.cooldown) == nil)
    }

    @Test func matchesAddressesWhateverTheirCase() {
        limit.record(.passwordReset, to: "Name@Example.com", at: start)
        #expect(limit.wait(before: .passwordReset, to: " name@example.com ", now: start + 1) != nil)
    }

    @Test func letsAnotherAddressThrough() {
        limit.record(.passwordReset, to: "a@example.com", at: start)
        #expect(limit.wait(before: .passwordReset, to: "b@example.com", now: start + 1) == nil)
    }

    @Test func keepsEachKindSeparate() {
        limit.record(.passwordReset, to: "a@example.com", at: start)
        #expect(limit.wait(before: .verification, to: "a@example.com", now: start + 1) == nil)
    }

    @Test func capsResetsPerHourUntilTheOldestLeavesTheHour() {
        for minute in 0..<3 {
            limit.record(.passwordReset, to: "\(minute)@example.com", at: start + Double(minute) * 60)
        }
        let now = start + 10 * 60
        let wait = limit.wait(before: .passwordReset, to: "new@example.com", now: now)
        #expect(wait == .init(reason: .hourlyLimit, until: start + 60 * 60))
        #expect(limit.wait(before: .passwordReset, to: "new@example.com", now: start + 60 * 60) == nil)
    }

    @Test func allowsMoreVerificationsThanResets() {
        for minute in 0..<3 {
            limit.record(.verification, to: "a@example.com", at: start + Double(minute) * 60)
        }
        #expect(limit.wait(before: .verification, to: "a@example.com", now: start + 10 * 60) == nil)
    }

    @Test func showsTheLongerWaitWhenBothApply() {
        for second in [0.0, 10, 20] {
            limit.record(.passwordReset, to: "a@example.com", at: start + second)
        }
        let wait = limit.wait(before: .passwordReset, to: "a@example.com", now: start + 30)
        #expect(wait?.reason == .hourlyLimit)
    }

    @Test func survivesANewInstance() {
        limit.record(.emailChange, to: "a@example.com", at: start)
        #expect(EmailRateLimit(defaults: defaults).wait(before: .emailChange, to: "a@example.com", now: start + 1) != nil)
    }

    @Test func ignoresSendsFromTheFuture() {
        // As if the clock was turned back after sending.
        limit.record(.passwordReset, to: "a@example.com", at: start + 60 * 60)
        #expect(limit.wait(before: .passwordReset, to: "a@example.com", now: start) == nil)
    }

    @Test func doesNotStoreAddressesAsTyped() {
        limit.record(.passwordReset, to: "a@example.com", at: start)
        let stored = defaults.dictionaryRepresentation().values.compactMap { $0 as? Data }
        #expect(!stored.isEmpty)
        #expect(stored.allSatisfy { String(decoding: $0, as: UTF8.self).contains("example.com") == false })
    }
}
