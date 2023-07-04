//
//  WalletBalanceController.swift
//
//
//  Created by Grigory on 1.7.23..
//

import Foundation

protocol WalletBalanceControllerWalletProvider {
    var wallet: Wallet { get throws }
}

public class WalletBalanceController {
    private let balanceService: WalletBalanceService
    private let ratesService: RatesService
    private let walletProvider: WalletBalanceControllerWalletProvider
    private let walletBalanceMapper: WalletBalanceMapper
    
    init(balanceService: WalletBalanceService,
         ratesService: RatesService,
         walletProvider: WalletBalanceControllerWalletProvider,
         walletBalanceMapper: WalletBalanceMapper) {
        self.balanceService = balanceService
        self.ratesService = ratesService
        self.walletProvider = walletProvider
        self.walletBalanceMapper = walletBalanceMapper
    }
    
    public func getWalletBalance() throws -> WalletBalanceModel {
        let wallet = try walletProvider.wallet
        let walletBalance = try balanceService.getWalletBalance(wallet: wallet)
        let rates = try ratesService.getRates()
        let walletState = walletBalanceMapper.mapWalletBalance(walletBalance, rates: rates)
        return walletState
    }
    
    public func reloadWalletBalance() async throws -> WalletBalanceModel {
        let wallet = try walletProvider.wallet
        let walletBalance = try await balanceService.loadWalletBalance(wallet: wallet)
        let rates = try await loadRates(walletBalance: walletBalance)
        let walletState = walletBalanceMapper.mapWalletBalance(walletBalance, rates: rates)
        return walletState
    }
}

private extension WalletBalanceController {
    func loadRates(walletBalance: WalletBalance) async throws -> Rates {
        let tokensInfo = walletBalance.tokensBalance.map { $0.amount.tokenInfo }
        let tonInfo = walletBalance.tonBalance.amount.tonInfo
        return try await ratesService.loadRates(tonInfo: tonInfo,
                                                tokens: tokensInfo,
                                                currencies: Currency.allCases)
    }
}