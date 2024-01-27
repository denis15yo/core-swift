import Foundation
import TonSwift
import CoreComponents

public struct ActiveWalletModel {
  public let revision: WalletContractVersion
  public let address: Address
  public let isActive: Bool
  public let balance: Balance
}

protocol ActiveWalletsService {
  func loadActiveWallets(mnemonic: CoreComponents.Mnemonic) async throws -> [ActiveWalletModel]
}

final class ActiveWalletsServiceImplementation: ActiveWalletsService {
  private let api: API
  private let jettonsBalanceService: JettonBalanceService
  
  init(api: API,
       jettonsBalanceService: JettonBalanceService) {
    self.api = api
    self.jettonsBalanceService = jettonsBalanceService
  }
  
  func loadActiveWallets(mnemonic: CoreComponents.Mnemonic) async throws -> [ActiveWalletModel] {
    let keyPair = try TonSwift.Mnemonic.mnemonicToPrivateKey(
      mnemonicArray: mnemonic.mnemonicWords
    )
    let revisions = WalletContractVersion.allCases
    
    let models = try await withThrowingTaskGroup(of: ActiveWalletModel.self, returning: [ActiveWalletModel].self) { taskGroup in
      for revision in revisions {
        let address = try createAddress(
          publicKey: keyPair.publicKey,
          revision: revision
        )
        taskGroup.addTask {
          async let accountTask = self.api.getAccountInfo(address: address.toRaw())
          async let jettonsBalanceTask = self.jettonsBalanceService.loadJettonsBalance(address: address)
          
          let isActive: Bool
          let balance: Balance
          do {
            let account = try await accountTask
            let jettonsBalance = try await jettonsBalanceTask
            let tonBalance = TonBalance(walletAddress: address, amount: account.balance)
            balance = Balance(tonBalance: tonBalance, jettonsBalance: jettonsBalance)
            isActive = account.status == "active" || !balance.isEmpty
          } catch {
            isActive = revision == .currentVersion
            balance = Balance(
              tonBalance: TonBalance(walletAddress: address, amount: 0),
              jettonsBalance: []
            )
          }
          
          return ActiveWalletModel(
            revision: revision,
            address: address,
            isActive: isActive,
            balance: balance)
        }
      }
      
      var resultModels = [ActiveWalletModel]()
      for try await result in taskGroup {
        guard result.revision != WalletContractVersion.currentVersion else {
          resultModels.append(result)
          continue
        }
        guard result.isActive else {
          continue
        }
        resultModels.append(result)
      }
      return resultModels
    }
    return models
  }
}

private extension ActiveWalletsServiceImplementation {
  func createAddress(publicKey: TonSwift.PublicKey, revision: WalletContractVersion) throws -> Address {
    let contract: WalletContract
    switch revision {
    case .v4R2:
      contract = WalletV4R2(publicKey: publicKey.data)
    case .v4R1:
      contract = WalletV4R1(publicKey: publicKey.data)
    case .v3R2:
      contract = try WalletV3(
        workchain: 0,
        publicKey: publicKey.data,
        revision: .r2)
    case .v3R1:
      contract = try WalletV3(
        workchain: 0,
        publicKey: publicKey.data,
        revision: .r1
      )
    }
    return try contract.address()
  }
}