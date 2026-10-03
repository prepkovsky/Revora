import SwiftUI
import Testing
@testable import Revora

struct AppearanceTests {
    @Test func systemFollowsTheDevice() {
        #expect(Appearance.system.colorScheme == nil)
    }

    @Test func lightAndDarkOverrideTheDevice() {
        #expect(Appearance.light.colorScheme == .light)
        #expect(Appearance.dark.colorScheme == .dark)
    }

    /// They're saved on the device, so changing one would reset people's choice.
    @Test func rawValuesStayTheSame() {
        #expect(Appearance.allCases.map(\.rawValue) == ["system", "light", "dark"])
    }
}
