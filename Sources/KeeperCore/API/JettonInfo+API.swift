import Foundation
import TonAPI
import TonSwift

extension JettonInfo {
  init(jettonPreview: Components.Schemas.JettonPreview) throws {
    let tokenAddress = try Address.parse(jettonPreview.address)
    address = tokenAddress
    fractionDigits = jettonPreview.decimals
    name = jettonPreview.name
    symbol = jettonPreview.symbol
    imageURL = URL(string: jettonPreview.image)
  }
}
