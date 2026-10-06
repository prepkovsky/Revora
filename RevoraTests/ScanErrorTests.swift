import FirebaseFunctions
import Foundation
import Testing
@testable import Revora

struct ScanErrorTests {
    private func functionsError(_ code: FunctionsErrorCode, details: Any? = nil) -> NSError {
        NSError(domain: FunctionsErrorDomain, code: code.rawValue, userInfo: details.map { [FunctionsErrorDetailsKey: $0] } ?? [:])
    }

    @Test(arguments: [
        (FunctionsErrorCode.unauthenticated, ScanError.signedOut),
        (.permissionDenied, .emailNotConfirmed),
        (.invalidArgument, .unreadableImage),
        (.resourceExhausted, .dailyLimitReached(resetsAt: nil)),
        (.failedPrecondition, .photoNotAllowed),
        (.notFound, .noRecipeFound),
        (.unavailable, .unavailable),
        (.deadlineExceeded, .timedOut),
        (.internal, .unknown),
        (.dataLoss, .unknown),
    ])
    func mapsFunctionCodes(code: FunctionsErrorCode, expected: ScanError) {
        #expect(ScanError(functionsError(code)) == expected)
    }

    @Test func readsWhenTheDailyLimitResets() {
        let error = functionsError(.resourceExhausted, details: ["resetsAt": "2026-10-07T00:00:00.000Z"])
        #expect(ScanError(error) == .dailyLimitReached(resetsAt: Date(timeIntervalSince1970: 1_791_331_200)))
    }

    @Test(arguments: ["tomorrow", "2026-10-07", ""])
    func ignoresAResetDateItCantRead(_ resetsAt: String) {
        #expect(ScanError(functionsError(.resourceExhausted, details: ["resetsAt": resetsAt])) == .dailyLimitReached(resetsAt: nil))
    }

    @Test func dailyLimitMessageSaysWhenItResets() {
        let soon = ScanError.dailyLimitReached(resetsAt: .now.addingTimeInterval(3 * 3600))
        #expect(!soon.message.contains("tomorrow"))
        #expect(ScanError.dailyLimitReached(resetsAt: nil).message.contains("tomorrow"))
        #expect(ScanError.dailyLimitReached(resetsAt: .now.addingTimeInterval(-60)).message.contains("tomorrow"))
    }

    @Test(arguments: [
        (URLError.Code.notConnectedToInternet, ScanError.offline),
        (.networkConnectionLost, .offline),
        (.cannotConnectToHost, .offline),
        (.timedOut, .timedOut),
        (.badServerResponse, .unknown),
    ])
    func mapsConnectionFailures(code: URLError.Code, expected: ScanError) {
        #expect(ScanError(NSError(domain: NSURLErrorDomain, code: code.rawValue)) == expected)
    }

    @Test func mapsPhotoErrors() {
        #expect(ScanError(PhotoError.unreadableImage) == .unreadableImage)
        #expect(ScanError(PhotoError.unknown) == .unknown)
    }

    @Test func treatsOtherErrorsAsUnknown() {
        #expect(ScanError(NSError(domain: "Other", code: FunctionsErrorCode.notFound.rawValue)) == .unknown)
        #expect(ScanError(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: ""))) == .unknown)
    }

    @Test func blockedPhotoMessageDoesntAccuse() {
        #expect(ScanError.photoNotAllowed.message == "This photo can't be scanned. Try a photo of a recipe.")
    }
}
