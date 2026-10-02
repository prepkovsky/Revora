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

    @Test(arguments: [17, 19, 21])
    func eveningRunsFromFiveUntilTen(hour: Int) {
        #expect(Greeting(hour: hour) == .evening)
    }

    @Test(arguments: [22, 23, 0, 4])
    func lateNightCoversTheRestOfTheNight(hour: Int) {
        #expect(Greeting(hour: hour) == .lateNight)
    }

    @Test func lateNightStillSaysGoodEvening() {
        #expect(String(localized: Greeting.lateNight.title) == String(localized: Greeting.evening.title))
        #expect(String(localized: Greeting.lateNight.prompt) != String(localized: Greeting.evening.prompt))
    }

    @Test func usesTheHourInTheGivenTimeZone() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Bratislava"))
        // 07:30 UTC is 09:30 in Bratislava in summer, and 00:30 in Los Angeles.
        let date = Date(timeIntervalSince1970: 1_782_891_000)
        #expect(Greeting(date: date, calendar: calendar) == .morning)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        #expect(Greeting(date: date, calendar: calendar) == .lateNight)
    }
}
