import Testing
@testable import Revora

struct LegalTextTests {
    @Test func joinsWrappedLinesIntoOneParagraph() {
        let text = """
               Licensed under the Apache License,
            Version 2.0 (the "License");
            """
        #expect(LegalText.blocks(from: text) == [
            .paragraph(#"Licensed under the Apache License, Version 2.0 (the "License");"#),
        ])
    }

    @Test func blankLinesSeparateParagraphs() {
        let text = "First one.\n\n   \nSecond one."
        #expect(LegalText.blocks(from: text) == [.paragraph("First one."), .paragraph("Second one.")])
    }

    @Test func readsHeadingsAndListItems() {
        let text = """
            ## What Revora stores

            - **Your account:** your email
              address and password.
            - **Your recipes**
            """
        #expect(LegalText.blocks(from: text) == [
            .heading("What Revora stores"),
            .listItem("**Your account:** your email address and password."),
            .listItem("**Your recipes**"),
        ])
    }

    @Test func listItemsCanFollowEachOtherWithoutBlankLines() {
        let text = """
            met:

               * Redistributions of source code must retain the above copyright
            notice, this list of conditions and the following disclaimer.
               * Redistributions in binary form must reproduce the above
            copyright notice.
            """
        #expect(LegalText.blocks(from: text) == [
            .paragraph("met:"),
            .listItem("Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer."),
            .listItem("Redistributions in binary form must reproduce the above copyright notice."),
        ])
    }

    @Test func italicLineIsNotAListItem() {
        #expect(LegalText.blocks(from: "*Last updated: October 3, 2026*") == [
            .paragraph("*Last updated: October 3, 2026*"),
        ])
    }

    @Test func dropsSeparatorLines() {
        let text = """
            -----------------------------------------------------------
            SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
            -----------------------------------------------------------
            """
        #expect(LegalText.blocks(from: text) == [.paragraph("SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007")])
    }

    @Test func shortCapitalizedTitleStandsAlone() {
        let text = """
            PREAMBLE
            The goals of the Open Font License (OFL) are
            to stimulate worldwide development.
            """
        #expect(LegalText.blocks(from: text) == [
            .paragraph("PREAMBLE"),
            .paragraph("The goals of the Open Font License (OFL) are to stimulate worldwide development."),
        ])
    }

    @Test func capitalizedDisclaimerStaysOneParagraph() {
        let text = """
            THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
            "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES ARE DISCLAIMED.
            SUCH DAMAGE.
            """
        #expect(LegalText.blocks(from: text) == [
            .paragraph(#"THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES ARE DISCLAIMED. SUCH DAMAGE."#),
        ])
    }

    @Test func handlesWindowsLineEndings() {
        #expect(LegalText.blocks(from: "One\r\ntwo.\r\n\r\nThree.") == [.paragraph("One two."), .paragraph("Three.")])
    }

    @Test(arguments: LegalPage.allCases)
    func legalPageIsBundled(page: LegalPage) throws {
        let text = try #require(page.text)
        #expect(LegalText.blocks(from: text).contains { if case .heading = $0 { true } else { false } })
    }

    @Test(arguments: OpenSourceComponent.all)
    func licenseIsBundled(component: OpenSourceComponent) throws {
        let text = try #require(component.licenseText)
        #expect(!LegalText.blocks(from: text).isEmpty)
    }
}
