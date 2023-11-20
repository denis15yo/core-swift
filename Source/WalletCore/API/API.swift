//
//  API.swift
//  
//
//  Created by Grigory Serebryanyy on 24.10.2023.
//

import Foundation
import TonAPI
import TonSwift
import BigInt
import OpenAPIRuntime

struct API {
    private let tonAPIClient: TonAPI.Client
    
    init(tonAPIClient: TonAPI.Client) {
        self.tonAPIClient = tonAPIClient
    }
}

// MARK: - Account

extension API {
    func getAccountInfo(address: Address) async throws -> Account {
        let response = try await tonAPIClient
            .getAccount(.init(path: .init(account_id: address.toRaw())))
        return try Account(account: try response.ok.body.json)
    }
    
    func getAccountJettonsBalances(address: Address) async throws -> [TokenBalance] {
        let response = try await tonAPIClient
            .getAccountJettonsBalances(path: .init(account_id: address.toRaw()))
        return try response.ok.body.json.balances
            .compactMap { jetton in
                do {
                    let quantity = BigInt(stringLiteral: jetton.balance)
                    let walletAddress = try Address.parse(jetton.wallet_address.address)
                    let tokenInfo = try TokenInfo(jettonPreview: jetton.jetton)
                    let tokenAmount = TokenAmount(tokenInfo: tokenInfo,
                                                  quantity: quantity)
                    let tokenBalance = TokenBalance(walletAddress: walletAddress, amount: tokenAmount)
                    return tokenBalance
                } catch {
                    return nil
                }
            }
    }
}

// MARK: - Events

extension API {
    func getAccountEvents(address: Address,
                          beforeLt: Int64?,
                          limit: Int) async throws -> ActivityEvents {
        let response = try await tonAPIClient.getAccountEvents(
            path: .init(account_id: address.toRaw()),
            query: .init(before_lt: beforeLt,
                         limit: limit,
                         start_date: nil,
                         end_date: nil)
        )
        let entity = try response.ok.body.json
        let events: [AccountEvent] = entity.events.compactMap {
            guard let activityEvent = try? AccountEvent(accountEvent: $0) else { return nil }
            return activityEvent
        }
        return ActivityEvents(events: events,
                              startFrom: beforeLt ?? 0,
                              nextFrom: entity.next_from)
    }
    
    func getAccountJettonEvents(address: Address,
                                tokenInfo: TokenInfo,
                                beforeLt: Int64?,
                                limit: Int) async throws -> ActivityEvents {
        let response = try await tonAPIClient.getAccountJettonHistoryByID(
            path: .init(account_id: address.toRaw(),
                        jetton_id: tokenInfo.address.toRaw()),
            query: .init(before_lt: beforeLt,
                         limit: limit,
                         start_date: nil,
                         end_date: nil)
        )
        let entity = try response.ok.body.json
        let events: [AccountEvent] = entity.events.compactMap {
            guard let activityEvent = try? AccountEvent(accountEvent: $0) else { return nil }
            return activityEvent
        }
        return ActivityEvents(events: events,
                              startFrom: beforeLt ?? 0,
                              nextFrom: entity.next_from)
    }
    
    func getEvent(address: Address,
                  eventId: String) async throws -> AccountEvent {
        let response = try await tonAPIClient
            .getAccountEvent(path: .init(account_id: address.toRaw(),
                                         event_id: eventId))
        return try AccountEvent(accountEvent: try response.ok.body.json)
    }
}

// MARK: - Wallet

extension API {
    func getSeqno(address: Address) async throws -> Int {
        let response = try await tonAPIClient
            .getAccountSeqno(path: .init(account_id: address.toRaw()))
        return try response.ok.body.json.seqno
    }
    
    func emulateMessageWallet(boc: String) async throws -> Components.Schemas.MessageConsequences {
        let response = try await tonAPIClient
            .emulateMessageToWallet(body: .json(.init(boc: boc)))
        return try response.ok.body.json
    }
    
    func sendTransaction(boc: String) async throws {
        let response = try await tonAPIClient
            .sendBlockchainMessage(body: .json(.init(boc: boc)))
        _ = try response.ok
    }
}

// MARK: - NFTs

extension API {
    func getAccountNftItems(address: Address,
                            collectionAddress: Address?,
                            limit: Int,
                            offset: Int,
                            isIndirectOwnership: Bool) async throws -> [Collectible] {
        let response = try await tonAPIClient.getAccountNftItems(
            path: .init(account_id: address.toRaw()),
            query: .init(collection: collectionAddress?.toRaw(),
                         limit: limit,
                         offset: offset,
                         indirect_ownership: isIndirectOwnership)
        )
        let entity = try response.ok.body.json
        let collectibles = entity.nft_items.compactMap {
            try? Collectible(nftItem: $0)
        }

        return collectibles
    }
    
    func getNftItemsByAddresses(_ addresses: [Address]) async throws -> [Collectible] {
        let response = try await tonAPIClient
            .getNftItemsByAddresses(
                .init(
                    body: .json(.init(account_ids: addresses.map { $0.toRaw() })))
            )
        let entity = try response.ok.body.json
        let nfts = entity.nft_items.compactMap {
            try? Collectible(nftItem: $0)
        }
        return nfts
    }
}

// MARK: - Rates

extension API {
    func getRates(tonInfo: TonInfo,
                  tokens: [TokenInfo],
                  currencies: [Currency]) async throws -> Rates {
        let requestTokens = ([tonInfo.symbol.lowercased()] + tokens.map { $0.address.toRaw() })
            .joined(separator: ",")
        let requestCurrencies = currencies.map { $0.code }
            .joined(separator: ",")
        let response = try await tonAPIClient
            .getRates(query: .init(tokens: requestTokens, currencies: requestCurrencies))
        let entity = try response.ok.body.json
        
        
        let rates = entity.rates.additionalProperties.value as [String: AnyObject]
        return parseResponse(rates: rates, tonInfo: tonInfo, tokens: tokens)
    }
    
    private func parseResponse(rates: [String: AnyObject],
                               tonInfo: TonInfo,
                               tokens: [TokenInfo]) -> Rates {
        var tonRates = [Rates.Rate]()
        var tokensRates = [Rates.TokenRate]()
        for key in rates.keys {
            guard let tokenRates = rates[key] as? [String: AnyObject] else { continue }
            if key.lowercased() == tonInfo.symbol.lowercased() {
                guard let prices = tokenRates["prices"] as? [String: Double] else { continue }
                tonRates = prices.compactMap {
                    guard let currency = Currency(rawValue: $0.key) else { return nil }
                    return Rates.Rate(currency: currency, rate: Decimal($0.value))
                }
                continue
            }
            guard let tokenInfo = tokens.first(where: { $0.address.toRaw() == key.lowercased()}) else { continue }
            guard let prices = tokenRates["prices"] as? [String: Double] else { continue }
            let rates: [Rates.Rate] = prices.compactMap {
                guard let currency = Currency(rawValue: $0.key) else { return nil }
                return Rates.Rate(currency: currency, rate: Decimal($0.value))
            }
            tokensRates.append(.init(tokenInfo: tokenInfo, rates: rates))
            
        }
        return Rates(ton: tonRates, tokens: tokensRates)
    }
}

// MARK: - DNS

extension API {
    enum DNSError: Swift.Error {
        case noWalletData
    }
    
    func resolveDomainName(_ domainName: String) async throws -> Recipient {
        let response = try await tonAPIClient.dnsResolve(path: .init(domain_name: domainName))
        let entity = try response.ok.body.json
        guard let wallet = entity.wallet else {
            throw DNSError.noWalletData
        }
        let address = try Address.parse(wallet.address)
        return Recipient(address: address, domain: domainName)
    }
    
    func getDomainExpirationDate(_ domainName: String) async throws -> Date? {
        let response = try await tonAPIClient.getDnsInfo(path: .init(domain_name: domainName))
        let entity = try response.ok.body.json
        guard let expiringAt = entity.expiring_at else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(integerLiteral: Int64(expiringAt)))
    }
}