//
//  WalletBalanceModel.swift
//  
//
//  Created by Grigory on 3.7.23..
//

import Foundation
import UIKit

public struct WalletBalanceModel {
    public struct Header {
        public let amount: String
        public let fullAddress: String
        public let shortAddress: String
    }
    
    public struct Token {
        public enum TokenType {
            case ton
            case oldWallet
            case token(TokenInfo)
        }
        public let title: String
        public let shortTitle: String?
        public let price: String?
        public let priceDiff: String?
        public let topAmount: String?
        public let bottomAmount: String?
        public let image: Image
        public let type: TokenType
    }
    
    public struct Collectible {
        public let title: String?
        public let subtitle: String?
        public let imageURL: URL?
    }
    
    public enum Section {
        case token([Token])
        case collectibles([Collectible])
    }
    
    public struct Page {
        public let title: String
        public let sections: [Section]
    }
    
    public let header: Header
    public let pages: [Page]
}

public enum Image: Equatable, Hashable {
    case url(URL?)
    case ton
    case oldWallet
}
