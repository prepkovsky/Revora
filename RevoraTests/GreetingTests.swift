import Foundation
import Testing
@testable import Revora

struct GreetingTests {
    @Test(arguments: [5, 8, 11])
    func morningRunsFromFiveUntilNoon(hour: Int) {
        #expect(Greeting(hour: hour) == .morning)
    }

    @Test(arguments: [12, 14, 16])
    func afternoonRunsFromNoonUntilFive(hour: Int) {
        #expect(Greeting(hour: hour) == .afternoon)
    }

    @Test(arguments: [17, 21, 23, 0, 4])
    func eveningCoversTheRestOfTheNight(hour: Int) {
        #expect(Greeting(hour: hour) == .evening)
    }

    @Test func usesTheHourInTheGivenTimeZone() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Bratislava"))
        // 07:30 UTC is 09:30 in Bratislava in summer.
        let date = Date(timeIntervalSince1970: 1_782_891_000)
        #expect(Greeting(date: date, calendar: calendar) == .morning)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        #expect(Greeting(date: date, calendar: calendar) == .evening)
    }
}
