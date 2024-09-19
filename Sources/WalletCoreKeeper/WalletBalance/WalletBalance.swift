//
//  Balance.swift
//  
//
//  Created by Grigory on 1.7.23..
//

import Foundation
import TonSwift
import BigInt

struct WalletBalance: Codable, LocalStorable {
    let walletAddress: Address
    let tonBalance: TonBalance
    let tokensBalance: [TokenBalance]
    let previousRevisionsBalances: [TonBalance]
    let collectibles: [Collectible]
    
    typealias KeyType = String
    
    var key: String {
        walletAddress.toRaw()
    }
}

struct TonBalance: Codable {
    let walletAddress: Address
    let amount: TonAmount
}

struct TokenBalance: Codable {
    let walletAddress: Address
    let amount: TokenAmount
}

struct TonAmount: Codable {
    private(set) var tonInfo = TonInfo()
    let quantity: Int64
}

struct TokenAmount: Codable {
    let tokenInfo: TokenInfo
    let quantity: BigInt
}

struct TonInfo: Codable {
    private(set) var name = "Toncoin"
    private(set) var symbol = "TON"
    private(set) var fractionDigits = 9
}

public struct TokenInfo: Codable, Equatable {
    public var address: Address
    public var fractionDigits: Int
    public var name: String
    public var symbol: String?
    public var description: String?
    public var imageURL: URL?
    public let verification: VerificationType
    
    public enum VerificationType: String, Codable {
        case whitelist
        case blacklist
        case none
    }
    
    public init(address: Address, fractionDigits: Int, name: String, symbol: String? = nil, description: String? = nil, imageURL: URL? = nil, verification: VerificationType = .none) {
        self.address = address
        self.fractionDigits = fractionDigits
        self.name = name
        self.symbol = symbol
        self.description = description
        self.imageURL = imageURL
        self.verification = verification
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.address == rhs.address
    }
}

struct AppBalance {
    let appId: String
    
    let title: String?
    let subtitle: String?
    let iconURL: URL?
    let description: String?
    
    let value: AppValue?
    let subvalue: AppValue?
    
    let appURL: URL?
}

enum AppValue {
    case plain(String)
    case appAmount(AppAmount)
    case tokenAmount(AppTokenAmount)
}

struct AppAmount {
    let quantity: BigInt
    let decimals: Int
}

enum AppTokenAmount {
    case ton(TonBalance)
    case token(TokenBalance)
}

public struct Collectible: Codable {
    public let address: Address
    public let owner: WalletAccount?
    public let name: String?
    public let imageURL: URL?
    public let preview: Preview
    public let description: String?
    public let attributes: [Attribute]
    public let collection: Collection?
    public let dns: String?
    public let sale: Sale?
    public let isHidden: Bool

    public struct Marketplace {
        let name: String
        let url: URL?
    }
    
    public struct Attribute: Codable {
        public let key: String
        public let value: String
    }
    
    public enum Trust {
        public struct Approval {
            let name: String
        }
        case approvedBy([Approval])
    }
    
    public struct Preview: Codable {
        public let size5: URL?
        public let size100: URL?
        public let size500: URL?
        public let size1500: URL?
    }
    
    public struct Sale: Codable {
        public let address: Address
        public let market: WalletAccount
        public let owner: WalletAccount?
    }
}

public struct Collection: Codable {
    public let address: Address
    public let name: String?
    public let description: String?
}
