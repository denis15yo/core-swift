import Foundation

actor CurrencyStore {
  typealias ObservationClosure = (Event) -> Void
  enum Event {
    case didChangeCurrency(currency: Currency)
  }
  
  private let currencyService: CurrencyService
  
  init(currencyService: CurrencyService) {
    self.currencyService = currencyService
  }
  
  func setActiveCurrency(_ currency: Currency) {
    do {
      try currencyService.setActiveCurrency(currency)
      observations
        .values
        .forEach { $0(.didChangeCurrency(currency: currency)) }
    } catch {}
  }
  
  func getActiveCurrency() -> Currency {
    do {
      return try currencyService.getActiveCurrency()
    } catch {
      return .USD
    }
  }
  
  private var observations = [UUID: ObservationClosure]()
  
  func addEventObserver<T: AnyObject>(_ observer: T,
                                      closure: @escaping (T, Event) -> Void) -> ObservationToken {
    let id = UUID()
    let eventHandler: (Event) -> Void = { [weak self, weak observer] event in
      guard let self else { return }
      guard let observer else {
        Task { await self.removeObservation(key: id) }
        return
      }
      
      closure(observer, event)
    }
    observations[id] = eventHandler
    
    return ObservationToken { [weak self] in
      guard let self else { return }
      Task { await self.removeObservation(key: id) }
    }
  }
  
  func removeObservation(key: UUID) {
    observations.removeValue(forKey: key)
  }
}
