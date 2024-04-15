import Foundation
import TonSwift

public final class CollectiblesListController {
  public enum Event {
    case updateNFTs(nfts: [NFT])
  }
  
  public var didGetEvent: ((PaginationEvent<NFT>) -> Void)?
  
  // MARK: - Dependencies
  
  private let nftsListPaginator: NftsListPaginator

  // MARK: - Init
  
  init(nftsListPaginator: NftsListPaginator) {
    self.nftsListPaginator = nftsListPaginator
  }
  
  // MARK: - Logic
  
  public func start() async {
    await nftsListPaginator.setEventHandler { [weak self] event in
      self?.didGetEvent?(event)
    }
    await nftsListPaginator.start()
  }
  
  public func loadNext() async {}
  
  public func setDidGetEventHandler(_ handler: ((PaginationEvent<NFT>) -> Void)?) {
    self.didGetEvent = handler
  }
  
  public func nftAt(index: Int) async -> NFT {
    await nftsListPaginator.nfts[index]
  }
}

private extension CollectiblesListController {
  func handleUpdatedNfts(_ nfts: [NFT]) {
  }
}
