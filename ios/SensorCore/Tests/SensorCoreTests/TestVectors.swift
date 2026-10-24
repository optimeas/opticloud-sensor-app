import Foundation
import SensorCore

/// Access to the shared test vectors in `docs/spec/vectors/`.
enum TestVectors {
    static let directory: URL = URL(filePath: #filePath)
        .deletingLastPathComponent() // SensorCoreTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // SensorCore
        .deletingLastPathComponent() // ios
        .deletingLastPathComponent() // repository root
        .appending(path: "docs/spec/vectors")

    /// The names of all vector files, without the extension.
    static func fileNames() throws -> [String] {
        try FileManager.default
            .contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }

    static func data(_ name: String) throws -> Data {
        try Data(contentsOf: directory.appending(path: "\(name).json"))
    }

    /// The cases of a vector file, decoded as `Case`.
    static func cases<Case: Decodable>(_ name: String, as type: Case.Type = Case.self) throws -> [Case] {
        try JSONDecoder().decode(File<Case>.self, from: data(name)).cases
    }

    private struct File<Case: Decodable>: Decodable {
        let cases: [Case]
    }
}

/// Decodes encoded output as a JSON value, for comparison with an expected value as the README requires:
/// as JSON values, not as text.
func jsonValue(_ data: Data) throws -> JSONValue {
    try JSONDecoder().decode(JSONValue.self, from: data)
}

func jsonValue(_ value: some Encodable) throws -> JSONValue {
    try jsonValue(JSONEncoder().encode(value))
}
