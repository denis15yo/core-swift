import Foundation

public final class ChartV2Controller {
  private let token: Token
  private let loader: ChartV2Loader
  private let chartService: ChartService
  private let currencyStore: CurrencyStore
  private let decimalAmountFormatter: DecimalAmountFormatter
  private let dateFormatter = DateFormatter()
  
  init(token: Token,
       loader: ChartV2Loader,
       chartService: ChartService,
       currencyStore: CurrencyStore,
       decimalAmountFormatter: DecimalAmountFormatter) {
    self.token = token
    self.loader = loader
    self.chartService = chartService
    self.currencyStore = currencyStore
    self.decimalAmountFormatter = decimalAmountFormatter
  }
  
  public func getCachedChartData(period: Period, currency: Currency) -> [Coordinate] {
    let coordinates = chartService.getChartData(
      period: period,
      token: token.tokenSymbol,
      currency: currency
    )
    return coordinates
  }
  
  public func loadChartData(period: Period, currency: Currency) async throws -> [Coordinate] {
    let coordinates = try await chartService.loadChartData(
      period: period,
      token: token.tokenSymbol,
      currency: currency
    )
    return coordinates
  }
}

private extension Token {
  var tokenSymbol: String {
    switch self {
    case .ton:
      return "ton"
    case .jetton(let item):
      return item.jettonInfo.address.toRaw()
    }
  }
}
