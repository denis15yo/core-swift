//
//  TonConnectManifestLoader.swift
//  
//
//  Created by Grigory Serebryanyy on 25.10.2023.
//

import Foundation

public struct TonConnectManifestLoader {
    private let urlSession: URLSession
    
    public init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    public func loadManifest(manifestURL: URL) async throws -> TonConnectManifest {
        let (data, _) = try await urlSession.data(from: manifestURL)
        let jsonDecoder = JSONDecoder()
        return try jsonDecoder.decode(TonConnectManifest.self, from: data)
    }
}
