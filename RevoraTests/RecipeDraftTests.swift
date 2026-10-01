import Testing
@testable import Revora

struct RecipeDraftTests {
    @Test func newDraftCantBeSaved() {
        #expect(!RecipeDraft().canSave)
    }

    @Test(arguments: ["", " ", "  \n\t"])
    func blankTitleCantBeSaved(_ title: String) {
        #expect(!RecipeDraft(title: title).canSave)
    }

    @Test func titleIsTrimmed() {
        let draft = RecipeDraft(title: "  Banana Bread \n")
        #expect(draft.canSave)
        #expect(draft.trimmedTitle == "Banana Bread")
    }
}
