import ComposableArchitecture
import Foundation
import Network

struct NetworkMonitor: Sendable, DependencyKey {
    var updates: @Sendable () -> AsyncStream<Bool>

    static let liveValue = Self(
        updates: {
            AsyncStream { continuation in
                let monitor = NWPathMonitor()
                monitor.pathUpdateHandler = { path in
                    continuation.yield(path.status == .satisfied)
                }
                continuation.onTermination = { _ in
                    monitor.cancel()
                }
                monitor.start(queue: DispatchQueue(label: "loop.network-monitor"))
            }
        }
    )

    static let testValue = Self(updates: { AsyncStream { $0.finish() } })
}
