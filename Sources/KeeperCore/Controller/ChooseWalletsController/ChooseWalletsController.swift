import Foundation
import TonSwift

public final class ChooseWalletsController {
  public struct WalletModel: Equatable {
    public let identifier: String
    public let address: String
    public let subtitle: String
    public let isSelected: Bool
  }

  public var models: [WalletModel] {
    getModels()
  }
  
  private let activeWalletModels: [ActiveWalletModel]
  
  init(activeWalletModels: [ActiveWalletModel]) {
    self.activeWalletModels = activeWalletModels
      .sorted(by: { $0.revision > $1.revision })
  }
  
  public func revisions(indexes: [Int]) -> [WalletContractVersion] {
    indexes
      .filter { activeWalletModels.count > $0 }
      .map { activeWalletModels[$0] }
      .map { $0.revision }
  }
}
 
private extension ChooseWalletsController {
  func getModels() -> [WalletModel] {
    activeWalletModels
      .map { mapActiveWallet($0) }
  }
  
  func mapActiveWallet(_ activeWallet: ActiveWalletModel) -> WalletModel {
    let identifier = activeWallet.address.toRaw()
    let address = activeWallet.address.toShortString(bounceable: false)
    var subtitle = "\(activeWallet.revision.rawValue) · 0 TON"
    if !activeWallet.balance.jettonsBalance.isEmpty {
      subtitle.append(", tokens")
    }
    
    let isSelected = activeWallet.revision == .currentVersion || !activeWallet.balance.isEmpty
    
    return WalletModel(
      identifier: identifier,
      address: address,
      subtitle: subtitle,
      isSelected: isSelected
    )
  }
}