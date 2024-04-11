import Foundation
import TonSwift

public final class HistoryListController {
  
  public var didGetEvent: ((HistoryListEvent) -> Void)?
  
  private let paginator: HistoryListPaginator
  
  init(paginator: HistoryListPaginator) {
    self.paginator = paginator
  }
  
  public func start() async {
    await paginator.setEventHandler { [weak self] event in
      self?.didGetEvent(event)
    }
    await paginator.start()
  }
  
  public func loadNext() async {
    await paginator.loadNext()
  }
}

private extension HistoryListController {
  func didGetEvent(_ event: HistoryListEvent) {
    didGetEvent?(event)
  }
}
