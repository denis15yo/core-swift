import Foundation

public final class ChartV2Controller {
  public struct ChartDataModel {
    public let coordinates: [Coordinate]
    public let period: Period
    public let minimumValue: String
    public let maximumValue: String
  }
  
  public struct PeriodModel {
    public let periods: [Period]
    public let selectedPeriod: Period
  }
  
  public var didUpdateChartData: ((Result<ChartDataModel, Swift.Error>) -> Void)?
  public var didUpdatePeriodConfiguration: ((PeriodModel) -> Void)?
  
  actor State {
    var currency: Currency
    var period: Period
    var chartData: Result<ChartDataModel, Swift.Error>
    
    init(currency: Currency, 
         period: Period,
         chartData: Result<ChartDataModel, Error>) {
      self.currency = currency
      self.period = period
      self.chartData = chartData
    }
    
    func setCurrency(_ currency: Currency) {
      self.currency = currency
    }
    
    func setPeriod(_ period: Period) {
      self.period = period
    }
    
    func setChartData(_ chartData: Result<ChartDataModel, Swift.Error>) {
      self.chartData = chartData
    }
  }
  
  private var state = State(
    currency: .USD,
    period: .halfYear,
    chartData: .success(ChartDataModel(coordinates: [], period: .month, minimumValue: "", maximumValue: ""))
  )
  
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
  
  public func start() async {
    await setInitialState()
  }
  
  public func selectPeriodAt(index: Int) async {
    await state.setPeriod(Period.allCases[index])
    await updateChartFromCache()
    await updateChart()
  }
  
  private func setInitialState() async {
    let currency = await currencyStore.getActiveCurrency()
    let period = Period.month
    
    await state.setCurrency(currency)
    await state.setPeriod(period)
    await updatePeriods()
    await updateChartFromCache()
    await updateChart()
  }
  
  private func updateChart() async {
    let currency = await state.currency
    let period = await state.period
    
    do {
      let coordinates = try await chartService.loadChartData(
        period: period,
        token: token.tokenSymbol,
        currency: currency
      )
      let model = prepareChartModel(coordinates: coordinates, period: period)
      await state.setChartData(.success(model))
      didUpdateChartData?(.success(model))
    } catch {
      await state.setChartData(.failure(error))
      didUpdateChartData?(.failure(error))
    }
  }
  
  private func updatePeriods() async {
    let model = PeriodModel(
      periods: Period.allCases,
      selectedPeriod: await state.period
    )
    didUpdatePeriodConfiguration?(model)
  }
  
  private func updateChartFromCache() async {
    let currency = await state.currency
    let period = await state.period
    
    let coordinates = chartService.getChartData(
      period: period,
      token: token.tokenSymbol,
      currency: currency
    )
    let model = prepareChartModel(coordinates: coordinates, period: period)
    await state.setChartData(.success(model))
    didUpdateChartData?(.success(model))
  }
  
  private func prepareChartModel(coordinates: [Coordinate], period: Period) -> ChartDataModel {
    ChartDataModel(
      coordinates: coordinates,
      period: period,
      minimumValue: "1",
      maximumValue: "2"
    )
  }
}

private extension Token {
  var tokenSymbol: String {
    switch self {
    case .ton:
      return "ton"
    case .jetton(let item):
      return item.jettonInfo.symbol ?? ""
    }
  }
}
