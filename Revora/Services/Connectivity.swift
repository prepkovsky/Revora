import Network
import Observation
import os

/// Whether the device has a network connection. Recipes keep working offline,
/// so this only drives a quiet indicator and retries, and never blocks anything.
@Observable
final class Connectivity {
    private static let logger = Logger(subsystem: "Revora", category: "Connectivity")

    private(set) var isOnline = true {
        didSet {
            if isOnline != oldValue {
                Self.logger.info("\(self.isOnline ? "Online" : "Offline", privacy: .public)")
            }
        }
    }

    /// Runs for as long as the calling task lives.
    func observe() async {
        while !Task.isCancelled {
            let monitor = NWPathMonitor()
            for await path in monitor {
                isOnline = path.status == .satisfied
                // A monitor doesn't always report the connection coming back (the Simulator's never
                // does), so while offline a new one checks every few seconds. Its first path is current.
                if !isOnline { break }
            }
            monitor.cancel()
            try? await Task.sleep(for: .seconds(3))
        }
    }
}
