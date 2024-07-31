import Foundation
import TonSwift

extension TonError: LocalizedError {
    public var errorDescription: String? {
        debugDescription
    }
}
