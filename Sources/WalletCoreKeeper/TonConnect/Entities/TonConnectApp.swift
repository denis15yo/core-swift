//
//  TonConnectApp.swift
//  
//
//  Created by Grigory Serebryanyy on 26.10.2023.
//

import Foundation
import TonSwift

struct TonConnectApps: Codable {
    let apps: [TonConnectApp]
    
    func addApp(_ app: TonConnectApp) -> TonConnectApps {
        var mutableApps = apps.filter { $0.manifest != app.manifest }
        mutableApps.append(app)
        return TonConnectApps(apps: mutableApps)
    }
}

public struct TonConnectApp: Codable {
    public let clientId: String
    public let manifest: TonConnectManifest
    public let keyPair: TonSwift.KeyPair
    public let walletAddress: Address?
}
