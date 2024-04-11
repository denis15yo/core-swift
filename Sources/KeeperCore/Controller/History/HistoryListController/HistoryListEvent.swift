import Foundation

public enum HistoryListEvent {
  case cached([HistoryListSection])
  case loading
  case empty
  case loaded([HistoryListSection])
  case nextPage([HistoryListSection])
  case pageLoading
  case pageLoadingFailed
}
