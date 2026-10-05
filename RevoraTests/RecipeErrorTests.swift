import FirebaseFirestore
import Foundation
import Testing
@testable import Revora

struct RecipeErrorTests {
    @Test(arguments: [
        (FirestoreErrorCode.Code.unavailable, RecipeError.offline),
        (.unauthenticated, .signedOut),
        (.resourceExhausted, .quotaExceeded),
        (.permissionDenied, .unknown),
        (.internal, .unknown),
    ])
    func mapsFirestoreCodes(code: FirestoreErrorCode.Code, expected: RecipeError) {
        #expect(RecipeError(NSError(domain: FirestoreErrorDomain, code: code.rawValue)) == expected)
    }

    @Test(arguments: [
        (PhotoError.offline, RecipeError.offline),
        (.timedOut, .timedOut),
        (.signedOut, .signedOut),
        (.quotaExceeded, .quotaExceeded),
        (.notFound, .unknown),
    ])
    func mapsPhotoErrors(photoError: PhotoError, expected: RecipeError) {
        #expect(RecipeError(photoError) == expected)
    }

    @Test func mapsTimeouts() {
        #expect(RecipeError(TimeoutError()) == .timedOut)
    }

    @Test func treatsOtherDomainsAsUnknown() {
        let error = NSError(domain: NSURLErrorDomain, code: FirestoreErrorCode.Code.unavailable.rawValue)
        #expect(RecipeError(error) == .unknown)
    }
}
