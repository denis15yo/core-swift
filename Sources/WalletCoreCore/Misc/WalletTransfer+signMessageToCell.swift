import Foundation
import TonSwift

public extension WalletTransfer {
    func signMessageToCell(signer: WalletTransferSigner, hashModifier: ((Data) -> Data)? = nil) throws -> Cell {
        let signature = try signMessage(signer: signer, hashModifier: hashModifier)
        
        let body = Builder()
        switch signaturePosition {
        case .front:
            try body.store(data: signature)
            try body.store(signingMessage)
        case .tail:
            try body.store(signingMessage)
            try body.store(data: signature)
        }
        return try body.endCell()
    }
}
