import Foundation

public final class BuyListController {
  public var didUpdateMethods: (([[BuySellItem]]) -> Void)?
  
  public struct BuySellItem {
    public struct Button {
      public let title: String
      public let url: String?
    }
    
    public let id: String
    public let title: String
    public let description: String?
    public let token: String?
    public let iconURL: URL?
    public let actionButton: Button?
    public let infoButtons: [Button]
    public let actionURL: URL?
  }
  
  private let wallet: Wallet
  private let buySellMethodsService: BuySellMethodsService
  private let locationService: LocationService
  private let configurationStore: ConfigurationStore
  private let currencyStore: CurrencyStore
  private let isMarketRegionPickerAvailable: () async -> Bool
  
  init(wallet: Wallet,
       buySellMethodsService: BuySellMethodsService,
       locationService: LocationService,
       configurationStore: ConfigurationStore,
       currencyStore: CurrencyStore,
       isMarketRegionPickerAvailable: @escaping () async -> Bool) {
    self.wallet = wallet
    self.buySellMethodsService = buySellMethodsService
    self.locationService = locationService
    self.configurationStore = configurationStore
    self.currencyStore = currencyStore
    self.isMarketRegionPickerAvailable = isMarketRegionPickerAvailable
  }
  
  public func start() async {
    if let cachedMethods = try? buySellMethodsService.getFiatMethods() {
      let models = await mapFiatMethods(cachedMethods)
      didUpdateMethods?(models)
    }
    
    do {
      let models = try await loadFiatMethods()
      didUpdateMethods?(models)
    } catch {
      didUpdateMethods?([])
    }
  }
}

private extension BuyListController {
  func loadFiatMethods() async throws -> [[BuySellItem]] {
    if await !isMarketRegionPickerAvailable() {
      return try await loadFiatMethodsByLocationRequired()
    } else {
      return try await loadDefaultFiatMethods()
    }
  }
  
  func loadFiatMethodsByLocationRequired() async throws -> [[BuySellItem]]  {
    do {
      let countryCode = try await locationService.getCountryCodeByIp()
      let methods = try await buySellMethodsService.loadFiatMethods(countryCode: countryCode)
      try? buySellMethodsService.saveFiatMethods(methods)
      return await mapFiatMethods(methods)
    } catch {
      return []
    }
  }
  
  func loadDefaultFiatMethods() async throws -> [[BuySellItem]]  {
    let methods = try await buySellMethodsService.loadFiatMethods(countryCode: nil)
    try? buySellMethodsService.saveFiatMethods(methods)
    return await mapFiatMethods(methods)
  }
  
  func mapFiatMethods(_ fiatMethods: FiatMethods) async -> [[BuySellItem]] {
    let currency = await currencyStore.getActiveCurrency()
    var sections = [[BuySellItem]]()
    for category in fiatMethods.categories {
      var items = [BuySellItem]()
      for categoryItem in category.items {
        guard availableFiatMethods.contains(categoryItem.id) else {
          continue
        }
        let item = BuySellItem(
          id: categoryItem.id,
          title: categoryItem.title,
          description: categoryItem.description,
          token: categoryItem.badge,
          iconURL: categoryItem.iconURL,
          actionButton: .init(title: categoryItem.actionButton.title, url: categoryItem.actionButton.url),
          infoButtons: categoryItem.infoButtons.map { .init(title: $0.title, url: $0.url) },
          actionURL: await actionUrl(for: categoryItem, currency: currency)
        )
        items.append(item)
      }
      sections.append(items)
    }
    return sections
  }
  
  func actionUrl(for item: FiatMethodItem, currency: Currency) async -> URL? {
  
    guard let address = try? wallet.address.toString(bounceable: false) else { return nil }
    var urlString = item.actionButton.url
    
    let currTo: String
    switch item.id {
    case "neocrypto", "moonpay":
      currTo = "TON"
    case "mercuryo":
      await handleUrlForMercuryo(urlString: &urlString, walletAddress: address)
      currTo = "TONCOIN"
    default:
      return nil
    }
    
    urlString = urlString.replacingOccurrences(of: "{CUR_FROM}", with: currency.code)
    urlString = urlString.replacingOccurrences(of: "{CUR_TO}", with: currTo)
    urlString = urlString.replacingOccurrences(of: "{ADDRESS}", with: address)
    
    guard let url = URL(string: urlString) else { return nil }
    return url
  }
  
  func handleUrlForMercuryo(urlString: inout String,
                            walletAddress: String) async {
    urlString = urlString.replacingOccurrences(of: "{TX_ID}", with: "mercuryo_\(UUID().uuidString)")
    
    let mercuryoSecret = (try? await configurationStore.getConfiguration().mercuryoSecret) ?? ""

    guard let signature = (walletAddress + mercuryoSecret).data(using: .utf8)?.sha256().hexString() else { return }
    urlString += "&signature=\(signature)"
  }
  
  private var availableFiatMethods: [FiatMethodItem.ID] {
      ["mercuryo", "neocrypto", "moonpay"]
  }
}
