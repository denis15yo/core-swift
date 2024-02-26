import Foundation
import CoreComponents

public final class RepositoriesAssembly {
  
  private let coreAssembly: CoreAssembly
  
  init(coreAssembly: CoreAssembly) {
    self.coreAssembly = coreAssembly
  }
  
  func mnemonicRepository() -> WalletMnemonicRepository {
    coreAssembly.mnemonicVault()
  }
  
  func keeperInfoRepository() -> KeeperInfoRepository {
    coreAssembly.sharedFileSystemVault()
  }
  
  func walletBalanceRepository() -> WalletBalanceRepository {
    WalletBalanceRepositoryImplementation(fileSystemVault: coreAssembly.fileSystemVault())
  }
  
  func totalBalanceRepository() -> TotalBalanceRepository {
    TotalBalanceRepositoryImplementation(fileSystemVault: coreAssembly.fileSystemVault())
  }
  
  func ratesRepository() -> RatesRepository {
    RatesRepositoryImplementation(fileSystemVault: coreAssembly.fileSystemVault())
  }
  
  func historyRepository() -> HistoryRepository {
    HistoryRepositoryImplementation(fileSystemVault: coreAssembly.fileSystemVault())
  }
  
  func nftRepository() -> NFTRepository {
    NFTRepositoryImplementation(fileSystemVault: coreAssembly.fileSystemVault())
  }
  
  func accountsNftRepository() -> AccountNFTRepository {
    AccountNFTRepositoryImplementation(fileSystemVault: coreAssembly.fileSystemVault())
  }
  
  func passcodeRepository() -> PasscodeRepository {
    PasscodeRepositoryImplementation(passcodeVault: coreAssembly.passcodeVault())
  }
}
