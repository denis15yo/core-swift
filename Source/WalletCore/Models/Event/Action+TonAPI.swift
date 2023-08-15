//
//  Action+TonAPI.swift
//  
//
//  Created by Grigory on 4.8.23..
//

import Foundation
import TonSwift
import TonAPI
import BigInt

extension Action.SimplePreview {
    init(simplePreview: ActionSimplePreview) throws {
        self.name = simplePreview.name
        self.description = simplePreview.description
        self.value = simplePreview.value
        
        var image: URL?
        if let actionImage = simplePreview.actionImage {
            image = URL(string: actionImage)
        }
        self.image = image
        
        var valueImage: URL?
        if let valueImageString = simplePreview.valueImage {
            valueImage = URL(string: valueImageString)
        }
        self.valueImage = valueImage
        
        self.accounts = simplePreview.accounts.compactMap { account in
            guard let walletAccount = try? WalletAccount(accountAddress: account) else { return nil }
            return walletAccount
        }
    }
}

extension Action.TonTransfer {
    init(tonTransfer: TonTransferAction) throws {
        self.sender = try WalletAccount(accountAddress: tonTransfer.sender)
        self.recipient = try WalletAccount(accountAddress: tonTransfer.recipient)
        self.amount = tonTransfer.amount
        self.comment = tonTransfer.comment
    }
}

extension Action.JettonTransfer {
    init(jettonTransfer: JettonTransferAction) throws {
        var sender: WalletAccount?
        var recipient: WalletAccount?
        if let senderAccountAddress = jettonTransfer.sender {
            sender = try? WalletAccount(accountAddress: senderAccountAddress)
        }
        if let recipientAccountAddress = jettonTransfer.recipient {
            recipient = try? WalletAccount(accountAddress: recipientAccountAddress)
        }
        
        self.sender = sender
        self.recipient = recipient
        self.senderAddress = try Address.parse(jettonTransfer.sendersWallet)
        self.recipientAddress = try Address.parse(jettonTransfer.recipientsWallet)
        self.amount = BigInt(stringLiteral: jettonTransfer.amount)
        self.tokenInfo = try TokenInfo(jettonPreview: jettonTransfer.jetton)
        self.comment = jettonTransfer.comment
    }
}

extension Action.ContractDeploy {
    init(contractDeploy: ContractDeployAction) throws {
        self.address = try Address.parse(contractDeploy.address)
    }
}

extension Action.NFTItemTransfer {
    init(nftItemTransfer: NFTItemTransferAction) throws {
        var sender: WalletAccount?
        var recipient: WalletAccount?
        if let senderAccountAddress = nftItemTransfer.sender {
            sender = try? WalletAccount(accountAddress: senderAccountAddress)
        }
        if let recipientAccountAddress = nftItemTransfer.recipient {
            recipient = try? WalletAccount(accountAddress: recipientAccountAddress)
        }
        
        self.sender = sender
        self.recipient = recipient
        self.nftAddress = try Address.parse(nftItemTransfer.nft)
        self.comment = nftItemTransfer.comment
        self.payload = nftItemTransfer.payload
    }
}

extension Action.Subscription {
    init(subscription: SubscriptionAction) throws {
        self.subscriber = try WalletAccount(accountAddress: subscription.subscriber)
        self.subscriptionAddress = try Address.parse(subscription.subscription)
        self.beneficiary = try WalletAccount(accountAddress: subscription.beneficiary)
        self.amount = subscription.amount
        self.isInitial = subscription.isInitial
    }
}

extension Action.Unsubscription {
    init(unsubscription: UnSubscriptionAction) throws {
        self.subscriber = try WalletAccount(accountAddress: unsubscription.subscriber)
        self.subscriptionAddress = try Address.parse(unsubscription.subscription)
        self.beneficiary = try WalletAccount(accountAddress: unsubscription.beneficiary)
    }
}

extension Action.AuctionBid {
    init(auctionBid: AuctionBidAction) throws {
        self.auctionType = auctionBid.auctionType
        self.bidder = try WalletAccount(accountAddress: auctionBid.bidder)
        self.auction = try WalletAccount(accountAddress: auctionBid.auction)
        
        var collectible: Collectible?
        if let nft = auctionBid.nft {
            collectible = try Collectible(nftItem: nft)
        }
        self.collectible = collectible
    }
}

extension Action.NFTPurchase {
    init(nftPurchase: NFTPurchaseAction) throws {
        self.auctionType = nftPurchase.auctionType
        self.collectible = try Collectible(nftItem: nftPurchase.nft)
        self.seller = try WalletAccount(accountAddress: nftPurchase.seller)
        self.buyer = try WalletAccount(accountAddress: nftPurchase.buyer)
        self.price = BigInt(stringLiteral: nftPurchase.amount.value)
    }
}

extension Action.DepositStake {
    init(depositStake: DepositStakeAction) throws {
        self.amount = depositStake.amount
        self.staker = try WalletAccount(accountAddress: depositStake.staker)
    }
}

extension Action.RecoverStake {
    init(recoverStake: RecoverStakeAction) throws {
        self.amount = recoverStake.amount
        self.staker = try WalletAccount(accountAddress: recoverStake.staker)
    }
}

extension Action.JettonSwap {
    init(jettonSwap: JettonSwapAction) throws {
        self.dex = jettonSwap.dex
        self.amountIn = BigInt(stringLiteral: jettonSwap.amountIn)
        self.amountOut = BigInt(stringLiteral: jettonSwap.amountOut)
        self.user = try WalletAccount(accountAddress: jettonSwap.userWallet)
        self.router = try WalletAccount(accountAddress: jettonSwap.router)
        self.tokenWalletIn = try Address.parse(jettonSwap.jettonWalletIn)
        self.tokenWalletOut = try Address.parse(jettonSwap.jettonWalletOut)
        self.tokenInfoIn = try TokenInfo(jettonPreview: jettonSwap.jettonMasterIn)
        self.tokenInfoOut = try TokenInfo(jettonPreview: jettonSwap.jettonMasterOut)
    }
}

extension Action.SmartContractExec {
    init(smartContractExec: SmartContractAction) throws {
        self.executor = try WalletAccount(accountAddress: smartContractExec.executor)
        self.contract = try WalletAccount(accountAddress: smartContractExec.contract)
        self.tonAttached = smartContractExec.tonAttached
        self.operation = smartContractExec.operation
        self.payload = smartContractExec.payload
    }
}
