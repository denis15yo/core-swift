//
//  TonConnectManifestLoader.swift
//  
//
//  Created by Grigory Serebryanyy on 25.10.2023.
//

import Foundation

struct TonConnectManifestLoader {
    private let urlSession: URLSession
    
    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    func loadManifest(manifestURL: URL) async throws -> TonConnectManifest {
        let (data, _) = try await urlSession.data(from: manifestURL)
        let jsonDecoder = JSONDecoder()
        return try jsonDecoder.decode(TonConnectManifest.self, from: data)
    }
}