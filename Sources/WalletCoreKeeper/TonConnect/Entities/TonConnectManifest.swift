//
//  TonConnectManifest.swift
//  
//
//  Created by Grigory Serebryanyy on 27.10.2023.
//

import Foundation

public struct TonConnectManifest: Codable, Equatable {
    public let url: URL
    public let name: String
    public let iconUrl: URL?
    public let termsOfUseUrl: URL?
    public let privacyPolicyUrl: URL?
    
    public var host: String {
        url.host ?? ""
    }
}
