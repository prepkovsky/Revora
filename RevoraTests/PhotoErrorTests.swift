import FirebaseFirestore
import Foundation
import Testing
@testable import Revora

struct PhotoErrorTests {
    @Test(arguments: [
        (FirestoreErrorCode.Code.unavailable, PhotoError.offline),
        (.notFound, .notFound),
        (.resourceExhausted, .quotaExceeded),
        (.unauthenticated, .signedOut),
        (.permissionDenied, .unknown),
        (.internal, .unknown),
    ])
    func mapsFirestoreCodes(code: FirestoreErrorCode.Code, expected: PhotoError) {
        #expect(PhotoError(NSError(domain: FirestoreErrorDomain, code: code.rawValue)) == expected)
    }

    @Test func treatsOtherDomainsAsUnknown() {
        let error = NSError(domain: NSURLErrorDomain, code: FirestoreErrorCode.Code.unavailable.rawValue)
        #expect(PhotoError(error) == .unknown)
    }
}
