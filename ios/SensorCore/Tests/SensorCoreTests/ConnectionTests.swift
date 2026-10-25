import Foundation
import Testing
@testable import SensorCore

@Suite struct BackoffTests {
    @Test func doublesFromOneSecondUpToSixtySeconds() {
        let delays = (0..<9).map { Backoff.delay(afterFailures: $0, random: 0.5) }
        #expect(delays == [1, 2, 4, 8, 16, 32, 60, 60, 60])
    }

    @Test func variesByUpToTwentyPercent() {
        #expect(Backoff.delay(afterFailures: 0, random: 0) == 0.8)
        #expect(Backoff.delay(afterFailures: 0, random: 1) == 1.2)
        #expect(Backoff.delay(afterFailures: 10, random: 1) == 72)
    }

    @Test func resetStartsAgainAtOneSecond() {
        var backoff = Backoff()
        _ = backoff.nextDelay(random: 0.5)
        _ = backoff.nextDelay(random: 0.5)
        #expect(backoff.nextDelay(random: 0.5) == 4)
        backoff.reset()
        #expect(backoff.nextDelay(random: 0.5) == 1)
    }
}

@Suite struct DeviceMessagesTests {
    @Test func attributeRequestListsKeysAsOneString() throws {
        let payload = try DeviceMessages.attributeRequest(sharedKeys: DeviceMessages.requestedSharedKeys)
        #expect(String(decoding: payload, as: UTF8.self) == #"{"sharedKeys":"sendRate,sensors,dashboard,sensorAppInstallation"}"#)
    }

    @Test func clientAttributesLeaveOutNumbersThatAreNotFinite() throws {
        let payload = try DeviceMessages.clientAttributes(["appVersion": "1.0", "sendRate": 2, "bad": .number(.nan)])
        #expect(String(decoding: payload, as: UTF8.self) == #"{"appVersion":"1.0","sendRate":2}"#)
    }

    @Test func readsSharedAttributesOfAnswerAndChange() throws {
        let answer = Data(#"{"client":{"appVersion":"1.0"},"shared":{"sendRate":5,"sensorAppInstallation":"abc"}}"#.utf8)
        #expect(try DeviceMessages.sharedAttributes(from: answer) == ["sendRate": .number(5), "sensorAppInstallation": .string("abc")])
        #expect(try DeviceMessages.sharedAttributes(from: Data("{}".utf8)) == [:])
        let change = Data(#"{"shared":{"oldKey":null}}"#.utf8)
        #expect(try DeviceMessages.sharedAttributes(from: change) == ["oldKey": .null])
    }

    @Test func requestIdIsAPositiveNumberAtTheEndOfTheTopic() {
        let prefix = DeviceMessages.attributeResponsePrefix
        #expect(DeviceMessages.requestId(topic: prefix + "7", prefix: prefix) == 7)
        #expect(DeviceMessages.requestId(topic: prefix + "0", prefix: prefix) == nil)
        #expect(DeviceMessages.requestId(topic: prefix + "x", prefix: prefix) == nil)
        #expect(DeviceMessages.requestId(topic: DeviceMessages.rpcRequestPrefix + "7", prefix: prefix) == nil)
    }

    @Test func readsCommandsWithAndWithoutParameters() {
        let topic = DeviceMessages.rpcRequestPrefix + "12"
        let ping = DeviceMessages.command(topic: topic, payload: Data(#"{"method":"ping","params":{}}"#.utf8))
        #expect(ping == .init(id: 12, method: "ping", params: .object([:])))
        let rate = DeviceMessages.command(topic: topic, payload: Data(#"{"method":"setSendRate","params":{"seconds":5}}"#.utf8))
        #expect(rate?.params == .object(["seconds": .number(5)]))
        #expect(DeviceMessages.command(topic: topic, payload: Data(#"{"method":"ping"}"#.utf8))?.params == nil)
        #expect(DeviceMessages.command(topic: topic, payload: Data("{}".utf8)) == nil)
    }

    @Test func bindingCheck() {
        #expect(BindingCheck(sharedAttributes: ["sensorAppInstallation": .string("a")], installationId: "a") == .same)
        #expect(BindingCheck(sharedAttributes: ["sensorAppInstallation": .string("b")], installationId: "a") == .other)
        #expect(BindingCheck(sharedAttributes: ["sensorAppInstallation": .number(1)], installationId: "a") == .other)
        #expect(BindingCheck(sharedAttributes: ["sensorAppInstallation": .null], installationId: "a") == .missing)
        #expect(BindingCheck(sharedAttributes: [:], installationId: "a") == .missing)
    }
}
