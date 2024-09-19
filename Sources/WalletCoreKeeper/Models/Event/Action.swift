//
//  Action.swift
//  
//
//  Created by Grigory on 3.8.23..
//

import Foundation
import TonSwift
import BigInt
import TonAPI

public struct Action: Codable {
    public let type: ActionType
    public let status: Status
    public let preview: SimplePreview
    
    public struct SimplePreview: Codable {
        public let name: String
        public let description: String
        public let image: URL?
        public let value: String?
        public let valueImage: URL?
        public let accounts: [WalletAccount]
    }
    
    public enum ActionType: Codable {
        case tonTransfer(TonTransfer)
        case contractDeploy(ContractDeploy)
        case jettonTransfer(JettonTransfer)
        case nftItemTransfer(NFTItemTransfer)
        case subscribe(Subscription)
        case unsubscribe(Unsubscription)
        case auctionBid(AuctionBid)
        case nftPurchase(NFTPurchase)
        case depositStake(DepositStake)
        case withdrawStake(WithdrawStake)
        case withdrawStakeRequest(WithdrawStakeRequest)
        case jettonSwap(JettonSwap)
        case jettonMint(JettonMint)
        case jettonBurn(JettonBurn)
        case smartContractExec(SmartContractExec)
        case domainRenew(DomainRenew)
        case unknown
    }
    
    public struct TonTransfer: Codable {
        public let sender: WalletAccount
        public let recipient: WalletAccount
        public let amount: Int64
        public let comment: String?
    }

    public struct ContractDeploy: Codable {
        public let address: Address
    }

    public struct JettonTransfer: Codable {
        public let sender: WalletAccount?
        public let recipient: WalletAccount?
        public let senderAddress: Address
        public let recipientAddress: Address
        public let amount: BigInt
        public let tokenInfo: TokenInfo
        public let comment: String?
    }

    public struct NFTItemTransfer: Codable {
        public let sender: WalletAccount?
        public let recipient: WalletAccount?
        public let nftAddress: Address
        public let comment: String?
        public let payload: String?
    }

    public struct Subscription: Codable {
        public let subscriber: WalletAccount
        public let subscriptionAddress: Address
        public let beneficiary: WalletAccount
        public let amount: Int64
        public let isInitial: Bool
    }

    public struct Unsubscription: Codable {
        public let subscriber: WalletAccount
        public let subscriptionAddress: Address
        public let beneficiary: WalletAccount
    }

    public struct AuctionBid: Codable {
        public let auctionType: String
        public let price: Price
        public let collectible: Collectible?
        public let bidder: WalletAccount
        public let auction: WalletAccount
    }

    public struct NFTPurchase: Codable {
        public let auctionType: String
        public let collectible: Collectible
        public let seller: WalletAccount
        public let buyer: WalletAccount
        public let price: BigInt
    }

    public struct DepositStake: Codable {
        public let amount: Int64
        public let staker: WalletAccount
        public let pool: WalletAccount
    }
    
    public struct WithdrawStake: Codable {
        public let amount: Int64
        public let staker: WalletAccount
        public let pool: WalletAccount
    }

    public struct WithdrawStakeRequest: Codable {
        public let amount: Int64?
        public let staker: WalletAccount
        public let pool: WalletAccount
    }

    public struct RecoverStake: Codable {
        public let amount: Int64
        public let staker: WalletAccount
    }

    public struct JettonSwap: Codable {
        public let dex: String
        public let amountIn: BigInt
        public let amountOut: BigInt
        public let tonIn: Int64?
        public let tonOut: Int64?
        public let user: WalletAccount
        public let router: WalletAccount
        public let tokenInfoIn: TokenInfo?
        public let tokenInfoOut: TokenInfo?
    }
    
    public struct JettonMint: Codable {
        public let recipient: WalletAccount
        public let recipientsWallet: Address
        public let amount: BigInt
        public let tokenInfo: TokenInfo
    }
    
    public struct JettonBurn: Codable {
        public let sender: WalletAccount
        public let senderWallet: Address
        public let amount: BigInt
        public let tokenInfo: TokenInfo
    }

    public struct SmartContractExec: Codable {
        public let executor: WalletAccount
        public let contract: WalletAccount
        public let tonAttached: Int64
        public let operation: String
        public let payload: String?
    }
    
    public struct DomainRenew: Codable {
        public let domain: String
        public let contractAddress: String
        public let renewer: WalletAccount
    }
    
    public struct Price: Codable {
        public let amount: BigInt
        public let tokenName: String
    }
}

extension Action.Price {
    init(price: Components.Schemas.Price) {
        amount = BigInt(stringLiteral: price.value)
        tokenName = price.token_name
    }
}
