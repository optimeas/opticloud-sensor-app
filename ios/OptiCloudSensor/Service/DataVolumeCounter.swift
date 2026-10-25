import Foundation
import Network
import Observation
import SensorCore

/// Counts the app's own data volume and keeps the counters (see `docs/spec/connection.md`, Data volume).
///
/// The network is the one the system reports when a message is counted. Counts from other threads arrive
/// through `record`, which hands them to the main actor.
@Observable
final class DataVolumeCounter {
    private static let defaultsKey = "dataVolume"

    private(set) var volume: DataVolume
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let pathMonitor = NWPathMonitor()
    @ObservationIgnored private var network = DataNetwork.wifi
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        volume = defaults.data(forKey: Self.defaultsKey).flatMap { try? JSONDecoder().decode(DataVolume.self, from: $0) } ?? DataVolume()
        volume.removeOld(at: Date(), calendar: .current)
        pathMonitor.pathUpdateHandler = Self.pathHandler { [weak self] network in self?.network = network }
        pathMonitor.start(queue: .main)
    }

    deinit {
        pathMonitor.cancel()
    }

    /// Counts a message of `bytes`, without overhead. Can be called from any thread.
    nonisolated func record(_ direction: DataDirection, _ bytes: Int) {
        Task { @MainActor in self.count(direction, bytes) }
    }

    func total(_ period: DataVolume.Period) -> DataVolume.Counters {
        volume.total(period, at: Date(), calendar: .current)
    }

    /// The values of the item `dataVolume`.
    func telemetry() -> [String: TelemetryValue] {
        volume.telemetry(at: Date(), calendar: .current)
    }

    /// Writes the counters now, for example before the app goes to the background.
    func save() {
        saveTask?.cancel()
        saveTask = nil
        if let data = try? JSONEncoder().encode(volume) { defaults.set(data, forKey: Self.defaultsKey) }
    }

    private func count(_ direction: DataDirection, _ bytes: Int) {
        volume.count(bytes, direction, network, at: Date(), calendar: .current)
        // Writing after every packet would cost more than it saves; a short delay groups them.
        guard saveTask == nil else { return }
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            self?.save()
        }
    }

    private nonisolated static func pathHandler(_ update: @escaping @MainActor (DataNetwork) -> Void) -> @Sendable (NWPath) -> Void {
        { path in
            let network: DataNetwork = path.usesInterfaceType(.cellular) && !path.usesInterfaceType(.wifi) ? .mobile : .wifi
            MainActor.assumeIsolated { update(network) }
        }
    }
}

/// Sends REST requests through `URLSession` and counts them as the app sees them, with headers.
struct CountingTransport: HTTPTransport {
    let counter: DataVolumeCounter

    nonisolated func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let url = request.url
        let path = (url?.path(percentEncoded: true) ?? "/") + (url?.query(percentEncoded: true).map { "?" + $0 } ?? "")
        counter.record(.sent, HTTPMessageSize.request(
            method: request.httpMethod ?? "GET", path: path,
            headers: request.allHTTPHeaderFields ?? [:], bodyBytes: request.httpBody?.count ?? 0
        ))
        let (data, response) = try await URLSession.shared.send(request)
        let headers = response.allHeaderFields.reduce(into: [String: String]()) { result, field in
            result["\(field.key)"] = "\(field.value)"
        }
        counter.record(.received, HTTPMessageSize.response(status: response.statusCode, headers: headers, bodyBytes: data.count))
        return (data, response)
    }
}
