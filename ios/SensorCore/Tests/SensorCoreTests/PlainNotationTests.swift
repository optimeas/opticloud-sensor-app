import Foundation
import Testing
@testable import SensorCore

@Suite struct PlainNotationTests {
    @Test(arguments: [
        (63.0, "63"),
        (-0.0, "0"),
        (0.5, "0.5"),
        (0.00001, "0.00001"),
        (-0.00003, "-0.00003"),
        (47.12345, "47.12345"),
        (1e16, "10000000000000000"),
        (1.5e21, "1500000000000000000000"),
        (123.456e-10, "0.0000000123456"),
        (0.1 + 0.2, "0.30000000000000004"),
    ])
    func writesWithoutExponent(value: Double, expected: String) {
        #expect(TelemetryValue.plainNotation(value) == expected)
    }

    @Test func payloadUsesPlainNotation() throws {
        let payload = try Telemetry.payload([Sample(ts: 1, values: ["longitude": 0.00001, "dataWifiMonth": 1e16])])
        #expect(String(decoding: payload, as: UTF8.self)
            == #"[{"ts":1,"values":{"dataWifiMonth":10000000000000000,"longitude":0.00001}}]"#)
    }
}
