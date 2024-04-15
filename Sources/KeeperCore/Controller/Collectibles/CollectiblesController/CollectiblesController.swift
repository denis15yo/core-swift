import Foundation

public final class CollectiblesController {
  
  public var didUpdateIsConnecting: ((Bool) -> Void)?
  public var didUpdateActiveWallet: (() -> Void)?

  private let walletsStore: WalletsStore
  private let backgroundUpdateStore: BackgroundUpdateStore
  
  init(walletsStore: WalletsStore,
       backgroundUpdateStore: BackgroundUpdateStore) {
    self.walletsStore = walletsStore
    self.backgroundUpdateStore = backgroundUpdateStore
  }
  
  public var wallet: Wallet {
    walletsStore.activeWallet
  }
  
  public func start() async {
    _ = walletsStore.addEventObserver(self) { observer, event in
      switch event {
      case .didUpdateActiveWallet:
        observer.didChangeActiveWallet()
      default: break
      }
    }
    
    _ = await backgroundUpdateStore.addEventObserver(self) { observer, event in
      switch event {
      case .didUpdateState(let backgroundUpdateState):
        observer.handleBackgroundUpdateState(backgroundUpdateState)
      case .didReceiveUpdateEvent:
        break
      }
    }
  }
  
  public func updateConnectingState() async {
    let state = await backgroundUpdateStore.state
    handleBackgroundUpdateState(state)
  }
}

private extension CollectiblesController {
  func didChangeActiveWallet() {
    didUpdateActiveWallet?()
  }
  
  func handleBackgroundUpdateState(_ state: BackgroundUpdateState) {
    let isConnecting: Bool
    switch state {
    case .connecting:
      isConnecting = true
    case .connected:
      isConnecting = false
    case .disconnected:
      isConnecting = true
    case .noConnection:
      isConnecting = false
    }
    didUpdateIsConnecting?(isConnecting)
  }
}
