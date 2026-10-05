import Testing
@testable import Revora

struct MealTypeTests {
    /// They're saved in every recipe, so changing one would drop it from recipes already saved.
    @Test func rawValuesStayTheSame() {
        #expect(MealType.allCases.map(\.rawValue) == ["breakfast", "lunch", "dinner", "snack", "dessert", "drink"])
    }

    @Test func displayOrderFollowsTheDayWithoutRepeats() {
        #expect([MealType.drink, .breakfast, .drink, .dinner].inDisplayOrder() == [.breakfast, .dinner, .drink])
    }

    @Test func displayOrderOfNoneIsEmpty() {
        #expect([MealType]().inDisplayOrder().isEmpty)
    }
}
