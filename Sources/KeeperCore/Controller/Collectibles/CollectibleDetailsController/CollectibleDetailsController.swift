import Foundation
import TonSwift

public final class CollectibleDetailsController {
    
  public var didUpdateModel: ((CollectibleDetailsModel) -> Void)?
  
  public let collectibleAddress: Address
  private let walletsStore: WalletsStore
  private let nftService: NFTService
  private let dnsService: DNSService
  private let collectibleDetailsMapper: CollectibleDetailsMapper
  
  init(collectibleAddress: Address,
       walletsStore: WalletsStore,
       nftService: NFTService,
       dnsService: DNSService,
       collectibleDetailsMapper: CollectibleDetailsMapper) {
    self.collectibleAddress = collectibleAddress
    self.walletsStore = walletsStore
    self.nftService = nftService
    self.dnsService = dnsService
    self.collectibleDetailsMapper = collectibleDetailsMapper
  }
  
  public func prepareCollectibleDetails() throws {
    let nft = try nftService.getNFT(address: collectibleAddress)
    let model = buildInitialViewModel(nft: nft)
    didUpdateModel?(model)
    guard nft.dns != nil else { return }
    Task {
      async let linkedAddressTask = getDNSLinkedAddress(nft: nft)
      async let expirationDateTask = getDNSExpirationDate(nft: nft)
      
      let linkedAddress = try? await linkedAddressTask
      let expirationDate = try? await expirationDateTask
      
      let model = buildDNSInfoLoadedViewModel(
        nft: nft,
        linkedAddress: linkedAddress,
        expirationDate: expirationDate)
      
      await MainActor.run {
        didUpdateModel?(model)
      }
    }
  }
}

private extension CollectibleDetailsController {
  func buildInitialViewModel(nft: NFT) -> CollectibleDetailsModel {
    return collectibleDetailsMapper.map(
      nft: nft,
      isOwner: isOwner(nft),
      linkedAddress: nil,
      expirationDate: nil,
      isInitial: true)
  }
  
  func buildDNSInfoLoadedViewModel(nft: NFT,
                                   linkedAddress: FriendlyAddress?,
                                   expirationDate: Date?) -> CollectibleDetailsModel {
    return collectibleDetailsMapper.map(
      nft: nft,
      isOwner: isOwner(nft),
      linkedAddress: linkedAddress,
      expirationDate: expirationDate,
      isInitial: false)
  }
  
  func isOwner(_ nft: NFT) -> Bool {
    guard let address = try? walletsStore.activeWallet.address else { return false }
    return nft.owner?.address == address
  }
  
  func getDNSLinkedAddress(nft: NFT) async throws -> FriendlyAddress? {
    guard let dns = nft.dns else { return nil }
    let linkedAddress = try await dnsService.resolveDomainName(dns)
    return linkedAddress.friendlyAddress
  }
  
  func getDNSExpirationDate(nft: NFT) async throws -> Date? {
    guard let dns = nft.dns else { return nil }
    let date = try await dnsService.loadDomainExpirationDate(dns)
    return date
  }
}
