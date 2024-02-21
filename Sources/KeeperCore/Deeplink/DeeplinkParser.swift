import Foundation
import TonSwift

enum DeeplinkParserError: Swift.Error {
  case unsupportedDeeplink(string: String?)
}

public protocol DeeplinkParser {
  func parse(string: String?) throws -> Deeplink
}

public struct DefaultDeeplinkParser: DeeplinkParser {
  
  private let parsers: [DeeplinkParser]
  
  init(parsers: [DeeplinkParser]) {
    self.parsers = parsers
  }
  
  public func parse(string: String?) throws -> Deeplink {
    guard let string else { throw DeeplinkParserError.unsupportedDeeplink(string: string) }
    let deeplink = parsers
        .compactMap { handler -> Deeplink? in try? handler.parse(string: string) }
        .first
    guard let deeplink = deeplink else { throw DeeplinkParserError.unsupportedDeeplink(string: string) }
    return deeplink
  }
}

struct TonDeeplinkParser: DeeplinkParser {
  func parse(string: String?) throws -> Deeplink {
    guard let string else { throw DeeplinkParserError.unsupportedDeeplink(string: string) }
    guard let url = URL(string: string),
          let scheme = url.scheme,
          let host = url.host,
          !url.lastPathComponent.isEmpty else {
      throw DeeplinkParserError.unsupportedDeeplink(string: string)
    }
    
    switch scheme {
    case "ton":
      switch host {
      case "transfer":
        let address = url.lastPathComponent
        return .ton(.transfer(recipient: address))
      default:
        throw DeeplinkParserError.unsupportedDeeplink(string: string)
      }
    default: throw DeeplinkParserError.unsupportedDeeplink(string: string)
    }
  }
}

struct TonConnectDeeplinkParser: DeeplinkParser {
  func parse(string: String?) throws -> Deeplink {
    guard let string else { throw DeeplinkParserError.unsupportedDeeplink(string: string) }
    if let deeplink = try? parseTonConnectDeeplink(string: string) {
      return deeplink
    }
    if let universalLink = try? parseTonConnectUniversalLink(string: string) {
      return universalLink
    }
    throw DeeplinkParserError.unsupportedDeeplink(string: string)
  }
  
  private func parseTonConnectDeeplink(string: String) throws -> Deeplink {
    guard let url = URL(string: string),
          let scheme = url.scheme
    else { throw DeeplinkParserError.unsupportedDeeplink(string: string) }
    switch scheme {
    case "tc":
      return .tonConnect(.init(string: string))
    default: throw DeeplinkParserError.unsupportedDeeplink(string: string)
    }
  }
  
  private func parseTonConnectUniversalLink(string: String) throws -> Deeplink {
    guard let url = URL(string: string),
          let components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: true
          ) else { throw DeeplinkParserError.unsupportedDeeplink(string: string) }
    switch url.path {
    case "/ton-connect":
      var tcComponents = URLComponents()
      tcComponents.scheme = "tc"
      tcComponents.queryItems = components.queryItems
      guard let string = tcComponents.string else {
        throw DeeplinkParserError.unsupportedDeeplink(string: string)
      }
      return .tonConnect(.init(string: string))
    default:
      throw DeeplinkParserError.unsupportedDeeplink(string: string)
    }
  }
}

