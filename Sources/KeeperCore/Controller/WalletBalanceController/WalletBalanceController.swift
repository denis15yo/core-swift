import Foundation

public final class WalletBalanceController {
  
  actor State {
    var totalBalanceState: TotalBalanceState?
    var backgroundUpdateState: BackgroundUpdateState = .disconnected
    
    func setTotalBalanceState(_ totalBalanceState: TotalBalanceState?) {
      self.totalBalanceState = totalBalanceState
    }
    
    func setBackgroundUpdateState(_ backgroundUpdateState: BackgroundUpdateState) {
      self.backgroundUpdateState = backgroundUpdateState
    }
  }
  
  actor BalanceState {
    var walletBalance: WalletBalance?
    
    func setWalletBalance(_ walletBalance: WalletBalance) {
      self.walletBalance = walletBalance
    }
  }
  
  public struct StateModel {
    public let totalBalance: String
    public let stateDate: String?
    public let backgroundUpdateState: BackgroundUpdateState
    public let walletType: WalletModel.WalletType
    public let shortAddress: String?
    public let fullAddress: String?
  }
  
  private var didUpdateState: ((StateModel) -> Void)?
  private var didUpdateBalanceState: ((WalletBalanceItemsModel) -> Void)?
  private var didUpdateSetupState: ((WalletBalanceSetupModel?) -> Void)?

  private let state = State()
  private let balanceState = BalanceState()
  
  private let wallet: Wallet
  private let walletsStore: WalletsStore
  private let walletBalanceStore: WalletBalanceStore
  private let walletTotalBalanceStore: WalletTotalBalanceStore
  private let tonRatesStore: TonRatesStore
  private let currencyStore: CurrencyStore
  private let setupStore: SetupStore
  private let securityStore: SecurityStore
  private let backgroundUpdateStore: BackgroundUpdateStore
  private let walletBalanceMapper: WalletBalanceMapper
  
  init(wallet: Wallet,
       walletsStore: WalletsStore,
       walletBalanceStore: WalletBalanceStore,
       walletTotalBalanceStore: WalletTotalBalanceStore,
       tonRatesStore: TonRatesStore,
       currencyStore: CurrencyStore,
       setupStore: SetupStore,
       securityStore: SecurityStore,
       backgroundUpdateStore: BackgroundUpdateStore,
       walletBalanceMapper: WalletBalanceMapper) {
    self.wallet = wallet
    self.walletsStore = walletsStore
    self.walletBalanceStore = walletBalanceStore
    self.walletTotalBalanceStore = walletTotalBalanceStore
    self.tonRatesStore = tonRatesStore
    self.currencyStore = currencyStore
    self.setupStore = setupStore
    self.securityStore = securityStore
    self.backgroundUpdateStore = backgroundUpdateStore
    self.walletBalanceMapper = walletBalanceMapper
  }
  
  public func start(didUpdateState: ((StateModel) -> Void)?,
                    didUpdateBalanceState: ((WalletBalanceItemsModel) -> Void)?,
                    didUpdateSetupState: ((WalletBalanceSetupModel?) -> Void)?) async {
    self.didUpdateState = didUpdateState
    self.didUpdateBalanceState = didUpdateBalanceState
    self.didUpdateSetupState = didUpdateSetupState
    await startObservations()
    await setInitialState()
  }
  
  public func setIsBiometryEnabled(_ isBiometryEnabled: Bool) async -> Bool {
    do {
      try await securityStore.setIsBiometryEnabled(isBiometryEnabled)
      return isBiometryEnabled
    } catch {
      return !isBiometryEnabled
    }
  }
  
  public func finishSetup() async {
    try? await setupStore.setSetupIsFinished()
  }
}

private extension WalletBalanceController {
  func startObservations() async {
    _ = await walletTotalBalanceStore.addEventObserver(self) { observer, event in
      switch event {
      case .didUpdateTotalBalance(let totalBalanceState, let address):
        guard let walletAddress = try? observer.wallet.address else { return }
        guard walletAddress == address else { return }
        Task { await observer.didUpdateTotalBalanceState(totalBalanceState) }
      }
    }
    
    _ = await backgroundUpdateStore.addEventObserver(self) { observer, event in
      switch event {
      case .didUpdateState(let backgroundUpdateState):
        Task { await observer.didUpdateBackgroundUpdateState(backgroundUpdateState) }
      default: break
      }
    }
    
    _ = await walletBalanceStore.addEventObserver(self) { observer, event in
      switch event {
      case .balanceUpdate(let balance, let address):
        guard let walletAddress = try? observer.wallet.address else { return }
        guard walletAddress == address else { return }
        Task { await observer.didUpdateBalanceState(balance)}
      }
    }
    
    _ = await tonRatesStore.addEventObserver(self) { observer, event in
      switch event {
      case .didUpdateRates(let rates):
        Task { await observer.didUpdateTonRates(rates)}
      }
    }
    
    _ = await setupStore.addEventObserver(self) { observer, event in
      switch event {
      case .didUpdateSetupIsFinished:
        Task { await observer.didUpdateSetup(wallet: observer.wallet) }
      }
    }
    
    _ = await securityStore.addEventObserver(self) { observer, event in
      switch event {
      case .didUpdateSecuritySettings:
        Task { await observer.didUpdateSetup(wallet: observer.wallet) }
      }
    }
    
    _ = walletsStore.addEventObserver(self) { observer, event in
      switch event {
      case .didUpdateWalletBackupState(let wallet):
        guard wallet == self.wallet else { return }
        Task { await observer.didUpdateSetup(wallet: wallet) }
      default: break
      }
    }
  }
  
  func setInitialState() async {
    if let totalBalanceState = try? await walletTotalBalanceStore.getTotalBalanceState(walletAddress: wallet.address) {
      await state.setTotalBalanceState(totalBalanceState)
    }
    await state.setBackgroundUpdateState(await backgroundUpdateStore.state)
    let model = await getStateModel()
    didUpdateState?(model)
    
    if let walletBalanceState = try? await walletBalanceStore.getBalanceState(walletAddress: wallet.address) {
      await balanceState.setWalletBalance(walletBalanceState.walletBalance)
    }
    let balanceModel = await getBalanceModel()
    didUpdateBalanceState?(balanceModel)
    
    let setupModel = await getSetupModel(wallet: wallet)
    didUpdateSetupState?(setupModel)
  }
  
  func didUpdateTotalBalanceState(_ totalBalanceState: TotalBalanceState) async {
    await state.setTotalBalanceState(totalBalanceState)
    let model = await getStateModel()
    didUpdateState?(model)
  }
  
  func didUpdateBackgroundUpdateState(_ backgroundUpdateState: BackgroundUpdateState) async {
    await state.setBackgroundUpdateState(backgroundUpdateState)
    let model = await getStateModel()
    didUpdateState?(model)
  }
  
  func didUpdateBalanceState(_ walletBalanceState: WalletBalanceState) async {
    await balanceState.setWalletBalance(walletBalanceState.walletBalance)
    let model = await getBalanceModel()
    didUpdateBalanceState?(model)
  }
  
  func didUpdateTonRates(_ tonRates: [Rates.Rate]) async {
    let model = await getBalanceModel()
    didUpdateBalanceState?(model)
  }
  
  func didUpdateSetup(wallet: Wallet) async {
    let setupModel = await getSetupModel(wallet: wallet)
    didUpdateSetupState?(setupModel)
  }
  
  func getStateModel() async -> StateModel {
    let formattedTotalBalance: String
    let stateDate: String?
    let currency = await currencyStore.activeCurrency
    switch await state.totalBalanceState {
    case .none:
      formattedTotalBalance = "-"
      stateDate = nil
    case .previous(let totalBalance):
      formattedTotalBalance = walletBalanceMapper.mapTotalBalance(totalBalance, currency: currency)
      stateDate = walletBalanceMapper.makeUpdatedDate(totalBalance.date)
    case .current(let totalBalance):
      formattedTotalBalance = walletBalanceMapper.mapTotalBalance(totalBalance, currency: currency)
      stateDate = nil
    }
    
    return StateModel(
      totalBalance: formattedTotalBalance,
      stateDate: stateDate,
      backgroundUpdateState: await state.backgroundUpdateState,
      walletType: wallet.model.walletType,
      shortAddress: try? wallet.address.toShortString(bounceable: false),
      fullAddress: try? wallet.address.toString(bounceable: false)
    )
  }
  
  func getBalanceModel() async -> WalletBalanceItemsModel {
    let balance: Balance
    if let walletBalance = await balanceState.walletBalance {
      balance = walletBalance.balance
    } else {
      balance = Balance(tonBalance: TonBalance(amount: 0), jettonsBalance: [])
    }

    let rates = await tonRatesStore.getTonRates()
    let currency = await currencyStore.activeCurrency
    return walletBalanceMapper.mapBalance(
      balance: balance,
      rates: Rates(
        ton: rates,
        jettonsRates: []
      ),
      currency: currency
    )
  }
  
  func getSetupModel(wallet: Wallet) async -> WalletBalanceSetupModel? {
    guard wallet.isRegular else { return nil }
    
    let didBackup = wallet.setupSettings.backupDate != nil
    let didFinishSetup = await setupStore.isSetupFinished
    let isBiometryEnabled = await securityStore.isBiometryEnabled
    let isFinishSetupAvailable = didBackup
    
    if (didBackup && didFinishSetup) {
      return nil
    }

    let model = WalletBalanceSetupModel(
      didBackup: didBackup,
      biometry: WalletBalanceSetupModel.Biometry(
        isBiometryEnabled: isBiometryEnabled,
        isRequired: !didFinishSetup && !isBiometryEnabled
      ),
      isFinishSetupAvailable: isFinishSetupAvailable
    )
    return model
  }
}
