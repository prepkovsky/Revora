import Testing
import UIKit
@testable import Revora

struct DisplayFontTests {
    /// The fonts are registered in Info.plist. If that breaks, titles quietly fall back to the
    /// system font instead of failing, so nothing else would notice.
    @Test func fontsAreRegistered() {
        #expect(UIFont(name: DisplayFont.semibold, size: 17) != nil)
        #expect(UIFont(name: DisplayFont.italic, size: 17) != nil)
    }
}
