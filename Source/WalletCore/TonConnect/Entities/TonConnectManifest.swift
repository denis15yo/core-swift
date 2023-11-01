//
//  TonConnectManifest.swift
//  
//
//  Created by Grigory Serebryanyy on 27.10.2023.
//

import Foundation

public struct TonConnectManifest: Codable, Equatable {
    let url: URL
    let name: String
    let iconUrl: URL?
    let termsOfUseUrl: URL?
    let privacyPolicyUrl: URL?
    
    var host: String {
        url.host ?? ""
    }
}
