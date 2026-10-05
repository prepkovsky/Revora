import Testing
@testable import Revora

struct TimeoutTests {
    private struct Failure: Error {}

    @Test func returnsTheResultInTime() async throws {
        let value = try await withTimeout(.seconds(5)) { 42 }
        #expect(value == 42)
    }

    @Test func passesOnTheOperationsError() async {
        await #expect(throws: Failure.self) {
            try await withTimeout(.seconds(5)) { throw Failure() }
        }
    }

    /// Doesn't wait for the slow operation, which keeps running like a Firebase request would.
    @Test func givesUpAfterTheTimeout() async {
        let start = ContinuousClock.now
        await #expect(throws: TimeoutError.self) {
            try await withTimeout(.milliseconds(50)) {
                try await Task.sleep(for: .seconds(10))
            }
        }
        #expect(ContinuousClock.now - start < .seconds(5))
    }
}
