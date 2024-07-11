//
//  TonConnectUrlParser.swift
//  
//
//  Created by Grigory Serebryanyy on 18.10.2023.
//

import Foundation

struct TonConnectUrlParser {
    enum Error: Swift.Error {
        case incorrectUrl
    }
    
    func parseString(_ string: String) throws -> TonConnectParameters {
        let string = string.replacingPlusSignWithSpace()
        
        guard
            let url = URL(string: string),
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            components.scheme == .tcScheme,
            let queryItems = components.queryItems,
            let versionValue = queryItems.first(where: { $0.name == .versionKey })?.value,
            let version = TonConnectParameters.Version(rawValue: versionValue),
            let clientId = queryItems.first(where: { $0.name == .clientIdKey })?.value,
            let requestPayloadValue = queryItems.first(where: { $0.name == .requestPayloadKey })?.value,
            let requestPayloadData = requestPayloadValue.data(using: .utf8),
            let requestPayload = try? JSONDecoder().decode(TonConnectRequestPayload.self, from: requestPayloadData)
        else {
            throw Error.incorrectUrl
        }
        
        let ret: TonConnectRet?
        if let retValue = queryItems.first(where: { $0.name == .retKey })?.value {
            ret = TonConnectRet(string: retValue)
        } else {
            ret = nil
        }
        
        return TonConnectParameters(
            version: version,
            clientId: clientId,
            requestPayload: requestPayload,
            ret: ret
        )
    }
}

private extension String {
    static let tcScheme = "tc"
    static let versionKey = "v"
    static let clientIdKey = "id"
    static let requestPayloadKey = "r"
    static let retKey = "ret"
}

private extension String {
    func replacingPlusSignWithSpace() -> String {
        guard var components = URLComponents(string: self) else {
            return self
        }
        
        components.query = components.query?.replacingOccurrences(
            of: "+",
            with: " "
        )
        
        return components.string ?? self
    }
}
