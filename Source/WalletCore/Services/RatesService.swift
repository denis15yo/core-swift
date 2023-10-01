//
//  RatesService.swift
//
//
//  Created by Grigory on 2.7.23..
//

import Foundation
import TonSwift
import TonAPI

protocol RatesService {
    func loadRates(tonInfo: TonInfo, tokens: [TokenInfo], currencies: [Currency]) async throws -> Rates
    func getRates() throws -> Rates
}

actor RatesServiceImplementation: RatesService {
    
    private let api: API
    private let localRepository: any LocalRepository<Rates>
    
    init(api: API,
         localRepository: any LocalRepository<Rates>) {
        self.api = api
        self.localRepository = localRepository
    }
    
    nonisolated func getRates() throws -> Rates {
        return try localRepository.load(fileName: Rates.fileName)
    }
    
    func loadRates(tonInfo: TonInfo, tokens: [TokenInfo], currencies: [Currency]) async throws -> Rates {
        let requestTokens: [String] = [tonInfo.symbol.lowercased()] + tokens.map { $0.address.toRaw() }
        let requestCurrencies = currencies.map { $0.code }
        
        let request = RatesRequest(tokens: requestTokens, currencies: requestCurrencies)
        let response = try await api.send(request: request)
        
        let responseRates = response.entity.tokensRates
        
        var tonRates = [Rates.Rate]()
        var tokensRates = [Rates.TokenRate]()
        for responseRate in responseRates {
            if responseRate.key.lowercased() == tonInfo.symbol.lowercased() {
                tonRates = responseRate.rates.compactMap {
                    guard let currrency = Currency(rawValue: $0.code) else { return nil }
                    return Rates.Rate(currency: currrency, rate: $0.rate)
                }
                continue
            }
            guard let tokenInfo = tokens.first(where: { $0.address.toString() == responseRate.key }) else { continue }
            let rates: [Rates.Rate] = responseRate.rates.compactMap {
                guard let currrency = Currency(rawValue: $0.code) else { return nil }
                return Rates.Rate(currency: currrency, rate: $0.rate)
            }
            tokensRates.append(.init(tokenInfo: tokenInfo, rates: rates))
        }
        
        let rates = Rates(ton: tonRates, tokens: tokensRates)
        updateCache(with: rates)
        return rates
    }
}

private extension RatesServiceImplementation {
    func updateCache(with rates: Rates) {
        guard var cachedRates = try? getRates() else {
            try? localRepository.save(item: rates)
            return
        }
        
        cachedRates.ton = rates.ton
        
        for tokenRate in rates.tokens {
            guard let cachedTokenRatesIndex = cachedRates.tokens.firstIndex(where: { $0.tokenInfo == tokenRate.tokenInfo }) else {
                continue
            }
            
            cachedRates.tokens[cachedTokenRatesIndex].rates = tokenRate.rates
        }
        
        try? localRepository.save(item: cachedRates)
    }
}
