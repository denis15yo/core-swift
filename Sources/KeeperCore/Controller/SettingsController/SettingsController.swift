import Foundation

public final class SettingsController {
  
  public var didUpdateActiveWallet: (() -> Void)?
  public var didUpdateActiveCurrency: (() -> Void)?
  
  private var walletsStoreToken: ObservationToken?
  private var currencyStoreToken: ObservationToken?
  
  private let walletsStore: WalletsStore
  private let currencyStore: CurrencyStore
  private let configurationStore: ConfigurationStore
  
  init(walletsStore: WalletsStore,
       currencyStore: CurrencyStore,
       configurationStore: ConfigurationStore) {
    self.walletsStore = walletsStore
    self.currencyStore = currencyStore
    self.configurationStore = configurationStore
    
    walletsStoreToken = walletsStore.addEventObserver(self) { observer, event in
      observer.didGetWalletsStoreEvent(event)
    }
    
//    currencyStoreToken = currencyStore.addEventObserver(self) { observer, event in
//      observer.didGetCurrencyStoreEvent(event)
//    }
  }
  
  public func activeWallet() -> Wallet {
    walletsStore.activeWallet
  }
  
  public func activeWalletModel() -> WalletModel {
    let wallet = walletsStore.activeWallet
    return wallet.model
  }
  
  public func activeCurrency() async -> Currency {
    await currencyStore.getActiveCurrency()
  }
  
  public func getAvailableCurrencies() -> [Currency] {
    Currency.allCases
  }
  
  public func setCurrency(_ currency: Currency) async {
    await currencyStore.setActiveCurrency(currency)
  }
  
  public var supportURL: URL? {
    get async throws {
      guard let string = try await configurationStore.getConfiguration().directSupportUrl else { return nil }
      return URL(string: string)
    }
  }
  
  public var contactUsURL: URL? {
    get async throws {
      guard let string = try await configurationStore.getConfiguration().supportLink else { return nil }
      return URL(string: string)
    }
  }
  
  public var tonkeeperNewsURL: URL? {
    get async throws {
      guard let string = try await configurationStore.getConfiguration().tonkeeperNewsUrl else { return nil }
      return URL(string: string)
    }
  }
}

private extension SettingsController {
  func didGetWalletsStoreEvent(_ event: WalletsStore.Event) {
    switch event {
    case .didUpdateWalletMetadata(let wallet):
      guard wallet == walletsStore.activeWallet else { return }
      didUpdateActiveWallet?()
    default:
      break
    }
  }
  
  func didGetCurrencyStoreEvent(_ event: CurrencyStore.Event) {
    didUpdateActiveCurrency?()
  }
}
