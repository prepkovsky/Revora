import FirebaseFirestore
import Foundation
import Testing
@testable import Revora

struct RecipeErrorTests {
    @Test(arguments: [
        (FirestoreErrorCode.Code.unavailable, RecipeError.offline),
        (.unauthenticated, .signedOut),
        (.permissionDenied, .unknown),
        (.internal, .unknown),
    ])
    func mapsFirestoreCodes(code: FirestoreErrorCode.Code, expected: RecipeError) {
        #expect(RecipeError(NSError(domain: FirestoreErrorDomain, code: code.rawValue)) == expected)
    }

    @Test(arguments: [
        (PhotoError.offline, RecipeError.offline),
        (.signedOut, .signedOut),
        (.quotaExceeded, .unknown),
        (.notFound, .unknown),
    ])
    func mapsPhotoErrors(photoError: PhotoError, expected: RecipeError) {
        #expect(RecipeError(photoError) == expected)
    }

    @Test func treatsOtherDomainsAsUnknown() {
        let error = NSError(domain: NSURLErrorDomain, code: FirestoreErrorCode.Code.unavailable.rawValue)
        #expect(RecipeError(error) == .unknown)
    }
}
