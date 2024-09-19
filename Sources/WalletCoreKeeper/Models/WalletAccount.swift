//
//  WalletAccount.swift
//  
//
//  Created by Grigory on 3.8.23..
//

import Foundation
import TonSwift
import TonAPI

public struct WalletAccount: Equatable, Codable {
    public let address: Address
    public let name: String?
    public let icon: String?
    public let isScam: Bool
    public let isWallet: Bool
}

extension WalletAccount {
    init(accountAddress: Components.Schemas.AccountAddress) throws {
        address = try Address.parse(accountAddress.address)
        name = accountAddress.name
        icon = accountAddress.icon
        isScam = accountAddress.is_scam
        isWallet = accountAddress.is_wallet
    }
}
