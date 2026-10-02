import Foundation

/// The time-of-day greeting at the top of Home.
enum Greeting: Equatable {
    case morning
    case afternoon
    case evening

    /// Late night counts as evening: "Good night" is a goodbye, not a hello.
    init(hour: Int) {
        switch hour {
        case 5..<12: self = .morning
        case 12..<17: self = .afternoon
        default: self = .evening
        }
    }

    init(date: Date, calendar: Calendar = .current) {
        self.init(hour: calendar.component(.hour, from: date))
    }

    var title: LocalizedStringResource {
        switch self {
        case .morning: "Good morning"
        case .afternoon: "Good afternoon"
        case .evening: "Good evening"
        }
    }
}
