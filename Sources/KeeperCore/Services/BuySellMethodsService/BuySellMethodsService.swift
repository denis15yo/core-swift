import Foundation
import TonAPI

protocol BuySellMethodsService {
  func loadFiatMethods() async throws -> FiatMethods
  func getFiatMethods() throws -> FiatMethods
}

final class BuySellMethodsServiceImplementation: BuySellMethodsService {
  private let api: TonkeeperAPI
  private let buySellMethodsRepository: BuySellMethodsRepository
  
  init(api: TonkeeperAPI,
       buySellMethodsRepository: BuySellMethodsRepository) {
    self.api = api
    self.buySellMethodsRepository = buySellMethodsRepository
  }
  
  func loadFiatMethods() async throws -> FiatMethods {
    let methods = try await api.loadFiatMethods()
    try? buySellMethodsRepository.saveFiatMethods(methods)
    return methods
  }
  
  func getFiatMethods() throws -> FiatMethods {
    try buySellMethodsRepository.getFiatMethods()
  }
}
