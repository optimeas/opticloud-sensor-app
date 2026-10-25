import Foundation
import Security

/// Secrets of the app in the Keychain: the session tokens, the device access token, and the installation identifier.
///
/// Items are readable after the first unlock, so that transmission can go on in the background,
/// and never leave this phone, not even in a backup.
nonisolated enum Keychain {
    enum Key: String {
        case session
        case deviceToken
        case installationId
    }

    private static let service = "ch.optimeas.opticloudsensor"

    static func data(for key: Key) -> Data? {
        var query = baseQuery(key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    static func set(_ data: Data?, for key: Key) {
        guard let data else {
            SecItemDelete(baseQuery(key) as CFDictionary)
            return
        }
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let status = SecItemUpdate(baseQuery(key) as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            SecItemAdd(baseQuery(key).merging(attributes) { $1 } as CFDictionary, nil)
        }
    }

    static func string(for key: Key) -> String? {
        data(for: key).map { String(decoding: $0, as: UTF8.self) }
    }

    static func set(_ string: String?, for key: Key) {
        set(string.map { Data($0.utf8) }, for: key)
    }

    static func value<Value: Decodable>(_ type: Value.Type, for key: Key) -> Value? {
        data(for: key).flatMap { try? JSONDecoder().decode(Value.self, from: $0) }
    }

    static func set(_ value: (some Encodable)?, for key: Key) {
        set(value.flatMap { try? JSONEncoder().encode($0) }, for: key)
    }

    private static func baseQuery(_ key: Key) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]
    }
}
