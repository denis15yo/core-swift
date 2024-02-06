import Foundation

enum TonkeeperAPIError: Swift.Error {
  case incorrectUrl
}

protocol TonkeeperAPI {
  func loadConfiguration(lang: String,
                         build: String,
                         chainName: String,
                         platform: String) async throws -> RemoteConfiguration
  func loadChart(period: Period) async throws -> [Coordinate]
  func loadFiatMethods() async throws -> FiatMethods
}

struct TonkeeperAPIImplementation: TonkeeperAPI {
  private let urlSession: URLSession
  private let host: URL
  
  init(urlSession: URLSession, host: URL) {
    self.urlSession = urlSession
    self.host = host
  }
  
  func loadConfiguration(lang: String,
                         build: String,
                         chainName: String,
                         platform: String) async throws -> RemoteConfiguration {
    let url = host.appendingPathComponent("/keys")
    guard var components = URLComponents(
        url: url,
        resolvingAgainstBaseURL: false
    ) else { throw TonkeeperAPIError.incorrectUrl }
    
    components.queryItems = [
        .init(name: "lang", value: lang),
        .init(name: "build", value: build),
        .init(name: "chainName", value: chainName),
        .init(name: "platform", value: platform)
    ]
    guard let url = components.url else { throw TonkeeperAPIError.incorrectUrl }
    let (data, _) = try await urlSession.data(from: url)
    let entity = try JSONDecoder().decode(RemoteConfiguration.self, from: data)
    return entity
  }
  
  func loadChart(period: Period) async throws -> [Coordinate] {
      let url = host.appendingPathComponent("/stock/chart-new")
      guard var components = URLComponents(
          url: url,
          resolvingAgainstBaseURL: false
      ) else { return [] }
      
      components.queryItems = [
          .init(name: "period", value: period.stringValue)
      ]
      guard let url = components.url else { return [] }
      let (data, _) = try await urlSession.data(from: url)
      let entity = try JSONDecoder().decode(ChartEntity.self, from: data)
      return entity.coordinates
  }
  
  func loadFiatMethods() async throws -> FiatMethods {
      let url = host.appendingPathComponent("/fiat/methods")
      guard var components = URLComponents(
          url: url,
          resolvingAgainstBaseURL: false
      ) else { throw TonkeeperAPIError.incorrectUrl }
      
      components.queryItems = [
          .init(name: "lang", value: "en"),
          .init(name: "build", value: "3.4.0"),
          .init(name: "chainName", value: "mainnet")
      ]
      guard let url = components.url else { throw TonkeeperAPIError.incorrectUrl }
      let (data, _) = try await urlSession.data(from: url)
      let entity = try JSONDecoder().decode(FiatMethodsResponse.self, from: data)
      return entity.data
  }
}
