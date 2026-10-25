import Foundation
import Testing
@testable import SensorCore

@Suite struct DataVolumeTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Zurich")!
        return calendar
    }()

    func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @Test func keepsTheDaysUntilTheEndOfTheFollowingMonth() {
        var volume = DataVolume()
        for day in [date(2026, 8, 31), date(2026, 9, 1), date(2026, 10, 25)] {
            volume.count(100, .sent, .wifi, at: day, calendar: calendar)
        }
        volume.removeOld(at: date(2026, 10, 28), calendar: calendar)
        #expect(volume.days.keys.sorted() == ["2026-09-01", "2026-10-25"])
    }

    @Test func httpMessagesCountStartLineHeadersAndBody() {
        let request = HTTPMessageSize.request(method: "GET", path: "/api/auth/user", headers: ["Accept": "application/json"], bodyBytes: 0)
        #expect(request == "GET /api/auth/user HTTP/1.1\r\n".utf8.count + "Accept: application/json\r\n".utf8.count + 2)
        let response = HTTPMessageSize.response(status: 200, headers: [:], bodyBytes: 10)
        #expect(response == "HTTP/1.1 200\r\n".utf8.count + 2 + 10)
    }
}
