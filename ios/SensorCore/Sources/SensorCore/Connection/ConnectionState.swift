import Foundation

/// The state of the connection (see `docs/spec/connection.md`, States).
public enum ConnectionState: Hashable, Sendable {
    /// No connection and no attempt.
    case disconnected
    /// Opening the connection, signing on, subscribing, or checking the binding.
    case connecting
    /// Subscriptions confirmed and binding checked.
    case connected
    /// The connection was lost or failed; the next attempt starts at `retryAt`.
    case waiting(ConnectionProblem, retryAt: Date)
    /// The server refused the token, or the device belongs to another phone. No retry without the user.
    case refused(ConnectionProblem)

    public var problem: ConnectionProblem? {
        switch self {
        case .waiting(let problem, _), .refused(let problem): problem
        case .disconnected, .connecting, .connected: nil
        }
    }
}

/// Why the app is waiting or refused (see `docs/spec/connection.md`, States).
public enum ConnectionProblem: String, Hashable, Sendable {
    case noNetwork
    case serverNotReachable
    case certificateNotTrusted
    case connectionLost
    case tokenRefused
    case boundToAnotherPhone
    case notBound
}

/// The delay before the next attempt to connect (see `docs/spec/connection.md`, Reconnecting).
public struct Backoff: Sendable {
    public static let first: Double = 1
    public static let longest: Double = 60
    /// The largest random deviation from the delay, as a fraction of it.
    public static let jitter: Double = 0.2

    /// The number of failed attempts since the last successful connect.
    public private(set) var failures = 0

    public init() {}

    /// Counts a failed attempt and returns the delay in seconds before the next one.
    /// `random` is a number from 0 to 1; 0.5 gives the delay without deviation.
    public mutating func nextDelay(random: Double = .random(in: 0...1)) -> Double {
        let delay = Self.delay(afterFailures: failures, random: random)
        failures += 1
        return delay
    }

    /// Called after a successful connect.
    public mutating func reset() {
        failures = 0
    }

    public static func delay(afterFailures failures: Int, random: Double) -> Double {
        let base = min(first * pow(2, Double(min(failures, 16))), longest)
        return base * (1 + jitter * (2 * random - 1))
    }
}
