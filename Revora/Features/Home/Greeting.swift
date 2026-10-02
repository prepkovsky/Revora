import Foundation

/// The time-of-day greeting at the top of Home.
enum Greeting: Equatable {
    case morning
    case afternoon
    case evening
    case lateNight

    init(hour: Int) {
        switch hour {
        case 5..<12: self = .morning
        case 12..<17: self = .afternoon
        case 17..<22: self = .evening
        default: self = .lateNight
        }
    }

    init(date: Date, calendar: Calendar = .current) {
        self.init(hour: calendar.component(.hour, from: date))
    }

    /// Late night still says "Good evening": "Good night" is a goodbye, not a hello.
    var title: LocalizedStringResource {
        switch self {
        case .morning: "Good morning"
        case .afternoon: "Good afternoon"
        case .evening, .lateNight: "Good evening"
        }
    }

    /// The meal people are most likely planning, which Surprise Me looks for first.
    var mealType: MealType {
        switch self {
        case .morning: .breakfast
        case .afternoon: .lunch
        case .evening: .dinner
        case .lateNight: .snack
        }
    }

    /// The line under the greeting, for the meal people are most likely planning.
    var prompt: LocalizedStringResource {
        switch self {
        case .morning: "What's for breakfast?"
        case .afternoon: "What's cooking today?"
        case .evening: "What's for dinner?"
        case .lateNight: "Time for a midnight snack?"
        }
    }
}
