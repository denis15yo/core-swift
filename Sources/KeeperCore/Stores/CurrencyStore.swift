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
  
  var activeCurrency: Currency {
    get {
      do {
        return try currencyService.getActiveCurrency()
      } catch {
        return .USD
      }
    }
    set {
      do {
        try currencyService.setActiveCurrency(newValue)
        observations
          .values
          .forEach { $0(.didChangeCurrency(currency: newValue)) }
      } catch {}
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
