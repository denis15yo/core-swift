import Foundation
import TonSwift

actor NftsListPaginator {
  enum State {
    case idle
    case isLoading
  }
  
  var eventHandler: ((PaginationEvent<NFT>) -> Void)?
  func setEventHandler(_ eventHandler: @escaping ((PaginationEvent<NFT>) -> Void)) { self.eventHandler = eventHandler }
  
  // MARK: - State
  
  private let limit = 25
  private var offset: Int = 0
  private var hasMore = true
  private var state: State = .idle
  
  private(set) var nfts = [NFT]()
  
  // MARK: - Dependencies
  
  private let wallet: Wallet
  private let accountNftsService: AccountNFTService
  
  // MARK: - Init
  
  init(wallet: Wallet,
       accountNftsService: AccountNFTService) {
    self.wallet = wallet
    self.accountNftsService = accountNftsService
  }
  
  // MARK: - Logic
  
  func start() async {
    state = .isLoading
    offset = 0
    nfts = []
    if let cached = try? accountNftsService.getAccountNfts(accountAddress: wallet.address) {
      eventHandler?(.cached(cached))
      self.nfts = cached
    } else {
      eventHandler?(.loading)
    }
    
    do {
      let nfts = try await loadNextPage()
      if nfts.isEmpty {
        eventHandler?(.empty)
      } else {
        eventHandler?(.loaded(nfts))
      }
      self.nfts = nfts
    } catch {
      nfts = []
      eventHandler?(.empty)
    }
    state = .idle
    await loadNext()
  }
  
  func loadNext() async {
    switch state {
    case .idle:
      guard hasMore else { return }
      state = .isLoading
      eventHandler?(.pageLoading)
      do {
        let nfts = try await loadNextPage()
        eventHandler?(.nextPage(nfts))
        self.nfts.append(contentsOf: nfts)
      } catch {
        eventHandler?(.pageLoadingFailed)
      }
      state = .idle
    case .isLoading:
      return
    }
  }
}

private extension NftsListPaginator {
  private func loadNextPage() async throws -> [NFT] {
    let nfts = try await accountNftsService.loadAccountNFTs(
      accountAddress: wallet.address,
      collectionAddress: nil,
      limit: nil,
      offset: nil,
      isIndirectOwnership: true
    )
    try Task.checkCancellation()
    if nfts.count > limit {
      hasMore = false
    }
    offset += limit
    return nfts
  }
}
