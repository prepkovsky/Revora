import Foundation
import Testing
@testable import Revora

struct SentVerificationsTests {
    private let defaults: UserDefaults
    private let sent: SentVerifications

    init() {
        let suiteName = "SentVerificationsTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        sent = SentVerifications(defaults: defaults)
    }

    @Test func remembersEachAccountSeparately() {
        sent.insert("a")
        #expect(sent.contains("a"))
        #expect(!sent.contains("b"))
    }

    @Test func survivesANewInstance() {
        sent.insert("a")
        #expect(SentVerifications(defaults: defaults).contains("a"))
    }

    @Test func removingForgetsOnlyThatAccount() {
        sent.insert("a")
        sent.insert("b")
        sent.remove("a")
        #expect(!sent.contains("a"))
        #expect(sent.contains("b"))
    }

    @Test func removingAnUnknownAccountChangesNothing() {
        sent.remove("a")
        #expect(!sent.contains("a"))
    }
}
