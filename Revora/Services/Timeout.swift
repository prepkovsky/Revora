/// Thrown when a request takes longer than `withTimeout` allows.
struct TimeoutError: Error {}

/// Gives up on a request after `timeout`, so a spinner never runs long enough to look frozen.
/// Firebase waits up to a minute on a connection that's there but not getting through.
///
/// Firebase's requests can't be cancelled, so a request that's given up on may still finish
/// later. Only use this where that's harmless, like a login that then signs in anyway.
func withTimeout<T: Sendable>(
    _ timeout: Duration = .seconds(15),
    operation: sending @escaping @concurrent () async throws -> T
) async throws -> T {
    // Not a task group: it would wait for the request to finish even after giving up on it.
    try await withCheckedThrowingContinuation { continuation in
        let race = Race(continuation)
        let timer = Task {
            try await Task.sleep(for: timeout)
            race.finish(.failure(TimeoutError()))
        }
        Task {
            do {
                race.finish(.success(try await operation()))
            } catch {
                race.finish(.failure(error))
            }
            timer.cancel()
        }
    }
}

/// Resumes the continuation with whichever result comes first.
private final class Race<T: Sendable> {
    private var continuation: CheckedContinuation<T, any Error>?

    init(_ continuation: CheckedContinuation<T, any Error>) {
        self.continuation = continuation
    }

    func finish(_ result: Result<T, any Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}
