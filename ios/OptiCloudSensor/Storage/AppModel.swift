import Foundation
import Observation
import SensorCore

/// The device the phone sends to, as picked in device selection. The access token is in the Keychain.
struct SelectedDevice: Codable, Hashable {
    var id: String
    var name: String
    var tenantName: String
    var projectName: String
}

/// The state of the app that outlives a single screen: the server address, the user's session,
/// the selected device, and the installation identifier.
@Observable
final class AppModel {
    private enum DefaultsKey {
        static let address = "serverAddress"
        static let device = "selectedDevice"
    }

    private let defaults: UserDefaults

    /// The address of the optiCLOUD web application.
    private(set) var address: ServerAddress
    /// The REST client of the user's session. Nil while nobody is signed in.
    private(set) var client: OptiCloudClient?
    private(set) var device: SelectedDevice?
    /// The random identifier of this installation; it binds devices to this phone.
    let installationId: String

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        address = defaults.string(forKey: DefaultsKey.address).flatMap(ServerAddress.init(parsing:)) ?? .official
        device = defaults.data(forKey: DefaultsKey.device).flatMap { try? JSONDecoder().decode(SelectedDevice.self, from: $0) }

        if let id = Keychain.string(for: .installationId) {
            installationId = id
        } else {
            installationId = UUID().uuidString.lowercased()
            Keychain.set(installationId, for: .installationId)
        }

        if let tokens = Keychain.value(TokenPair.self, for: .session) {
            client = makeClient(address: address, tokens: tokens)
        }
        if device != nil && Keychain.string(for: .deviceToken) == nil {
            device = nil
        }
    }

    var isSignedIn: Bool { client != nil }

    /// Starts a session for an address. Changing the address forgets the device, because it belongs to the old server.
    func startSession(at newAddress: ServerAddress) -> OptiCloudClient {
        if newAddress != address {
            forgetDevice()
            address = newAddress
            defaults.set(newAddress.text, forKey: DefaultsKey.address)
        }
        let client = makeClient(address: newAddress, tokens: nil)
        self.client = client
        return client
    }

    /// Called when sign-in did not finish. The tokens, if any, are dropped.
    func abandonSession() {
        guard let client else { return }
        Task { await client.signOut() }
        self.client = nil
        Keychain.set(nil as Data?, for: .session)
    }

    /// Deletes the session tokens. The device, its token, and the settings stay.
    func signOut() {
        abandonSession()
    }

    func select(_ device: SelectedDevice, token: String) {
        Keychain.set(token, for: .deviceToken)
        self.device = device
        defaults.set(try? JSONEncoder().encode(device), forKey: DefaultsKey.device)
    }

    func forgetDevice() {
        Keychain.set(nil as Data?, for: .deviceToken)
        device = nil
        defaults.removeObject(forKey: DefaultsKey.device)
    }

    private func makeClient(address: ServerAddress, tokens: TokenPair?) -> OptiCloudClient {
        OptiCloudClient(address: address, tokens: tokens, tokensChanged: { pair in
            Keychain.set(pair, for: .session)
        })
    }
}
