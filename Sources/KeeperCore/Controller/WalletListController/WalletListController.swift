import Foundation
import CoreComponents
import TonSwift

public final class WalletListController {
  actor State {
    var wallets = [Wallet]()
    var selectedWallet: Wallet?
    var totalBalanceStates = [Wallet: TotalBalanceState]()
    
    func setWallets(_ wallets: [Wallet]) {
      self.wallets = wallets
    }
    
    func setTotalBalanceState(_ totalBalanceState: TotalBalanceState, 
                              wallet: Wallet) {
      totalBalanceStates[wallet] = totalBalanceState
    }
    
    func setSelectedWallet(_ wallet: Wallet?) {
      selectedWallet = wallet
    }
  }
  
  public struct Model {
    public let items: [ItemModel]
    public let selectedIndex: Int?
    public let isEditable: Bool
    
    public init(items: [ItemModel], selectedIndex: Int?, isEditable: Bool) {
      self.items = items
      self.selectedIndex = selectedIndex
      self.isEditable = isEditable
    }
  }
  
  public struct ItemModel {
    public let id: String
    public let walletModel: WalletModel
    public let totalBalance: String
  }
  
  public var didUpdateState: ((Model) -> Void)?
  
  private let state = State()
  
  private let walletsStore: WalletsStore
  private let walletTotalBalanceStore: WalletTotalBalanceStore
  private let currencyStore: CurrencyStore
  private let configurator: WalletListControllerConfigurator
  private let walletListMapper: WalletListMapper
  
  init(walletsStore: WalletsStore, 
       walletTotalBalanceStore: WalletTotalBalanceStore,
       currencyStore: CurrencyStore,
       configurator: WalletListControllerConfigurator,
       walletListMapper: WalletListMapper) {
    self.walletsStore = walletsStore
    self.walletTotalBalanceStore = walletTotalBalanceStore
    self.currencyStore = currencyStore
    self.configurator = configurator
    self.walletListMapper = walletListMapper
  }
  
  public func start() async {
    await startObservations()
    await setInitialState()
  }
  
  public func selectWallet(identifier: String) async {
    guard let index = await state.wallets.firstIndex(where: { $0.id == identifier }) else { return }
    configurator.selectWallet(at: index)
  }
  
  public func moveWallet(from: Int, to: Int) async {
    do {
      try configurator.moveWallet(fromIndex: from, toIndex: to)
    } catch {
      await didUpdateState()
    }
  }
  
  public func getWallet(at index: Int) async -> Wallet? {
    let wallets = await state.wallets
    guard index < wallets.count else { return nil }
    return wallets[index]
  }
}

private extension WalletListController {
  func startObservations() async {
    _ = await walletTotalBalanceStore.addEventObserver(self) { observer, event in
      switch event {
      case .didUpdateTotalBalance(let totalBalanceState, let walletAddress):
        Task { await observer.didUpdateTotalBalanceState(totalBalanceState,
                                                         walletAddress: walletAddress)
        }
      }
    }

    configurator.didUpdateWallets = { [weak self] in
      guard let self else { return }
      Task {
        await self.didUpdateWalletsOrder()
      }
    }
  }
  
  func setInitialState() async {
    let wallets = configurator.getWallets()
    await state.setWallets(wallets)
    await state.setSelectedWallet(configurator.getSelectedWallet())
    await didUpdateState()
    for wallet in wallets {
      do {
        if let walletTotalBalanceState = try await walletTotalBalanceStore.getTotalBalanceState(
          walletAddress: wallet.address
        ) {
          await state.setTotalBalanceState(
            walletTotalBalanceState,
            wallet: wallet
          )
        }
      } catch {
        continue
      }
    }
    await didUpdateState()
  }
  
  func didUpdateTotalBalanceState(_ totalBalanceState: TotalBalanceState,
                                  walletAddress: TonSwift.Address) async {
    let wallets = await state.wallets
      .filter {
        guard let address = try? $0.address else { return false }
        return address == walletAddress
      }
    for wallet in wallets {
      await state.setTotalBalanceState(totalBalanceState, wallet: wallet)
    }
    await didUpdateState()
  }
  
  func didUpdateWalletsOrder() async {
    await setInitialState()
  }
  
  func didUpdateState() async {
    let itemsModels = await getItemModels()
    
    let selectedIndex: Int?
    if let selectedWallet = await state.selectedWallet {
      selectedIndex = await state.wallets.firstIndex(of: selectedWallet)
    } else {
      selectedIndex = nil
    }
    
    let model = Model(
      items: itemsModels,
      selectedIndex: selectedIndex,
      isEditable: itemsModels.count > 1 && configurator.isEditable
    )
    didUpdateState?(model)
  }
  
  func getItemModels() async -> [ItemModel] {
    let currency = await currencyStore.activeCurrency
    let wallets = await state.wallets
    let totalBalanceStates = await state.totalBalanceStates
    let itemModels = wallets.map { wallet in
      var balance = ""
      if let walletTotalBalance = totalBalanceStates[wallet] {
        balance = walletListMapper.mapTotalBalance(
          walletTotalBalance.totalBalance,
          currency: currency
        )
      }
      return walletListMapper.mapWalletModel(
        wallet: wallet,
        balance: balance
      )
    }
    return itemModels
  }
}
