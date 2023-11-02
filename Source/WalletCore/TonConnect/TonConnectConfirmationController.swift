//
//  TonConnectConfirmationController.swift
//  
//
//  Created by Grigory Serebryanyy on 27.10.2023.
//

import Foundation
import BigInt
import TonConnectAPI
import TonAPI
import TonSwift

public protocol TonConnectConfirmationControllerOutput: AnyObject {
    func tonConnectConfirmationControllerDidStartEmulation(_ controller: TonConnectConfirmationController)
    func tonConnectConfirmationControllerDidFinishEmulation(_ controller: TonConnectConfirmationController,
                                                            result: Result<TonConnectConfirmationModel, Swift.Error>)
}

public final class TonConnectConfirmationController {
    enum State {
        case idle
        case confirmation(TonConnect.AppRequest, app: TonConnectApp)
        case confirmed
    }
    
    public weak var output: TonConnectConfirmationControllerOutput?
    
    private let sendMessageBuilder: SendMessageBuilder
    private let sendService: SendService
    private let apiClient: TonConnectAPI.Client
    private let rateService: RatesService
    private let collectiblesService: CollectiblesService
    private let walletProvider: WalletProvider
    private let tonConnectConfirmationMapper: TonConnectConfirmationMapper
    
    private let state: ThreadSafeProperty<State> = .init(property: .idle)
    
    init(sendMessageBuilder: SendMessageBuilder,
         sendService: SendService,
         apiClient: TonConnectAPI.Client,
         rateService: RatesService,
         collectiblesService: CollectiblesService,
         walletProvider: WalletProvider,
         tonConnectConfirmationMapper: TonConnectConfirmationMapper) {
        self.sendMessageBuilder = sendMessageBuilder
        self.sendService = sendService
        self.apiClient = apiClient
        self.rateService = rateService
        self.collectiblesService = collectiblesService
        self.walletProvider = walletProvider
        self.tonConnectConfirmationMapper = tonConnectConfirmationMapper
    }
    
    public func handleAppRequest(_ appRequest: TonConnect.AppRequest,
                                 app: TonConnectApp) {
        Task {
            guard case .idle = await state.property else { return }
            await state.setValue(.confirmation(appRequest, app: app))
            emulateAppRequest(appRequest)
        }
    }

    public func didFinish() {
        Task {
            guard case .confirmation = await state.property else {
                await state.setValue(.idle)
                return
            }
            await cancelAppRequest()
            await state.setValue(.idle)
        }
    }
    
    public func confirmTransaction() async throws {
        guard case .confirmation(let message, let app) = await state.property else { return }
        guard let params = message.params.first else { return }
        
        let boc = try await transactionBoc(forParams: params)

        try await sendService.sendTransaction(boc: boc)
        await self.state.setValue(.confirmed)
        
        let sessionCrypto = try TonConnectSessionCrypto(privateKey: app.keyPair.privateKey)
        let body = try TonConnectResponseBuilder
            .buildSendTransactionResponseSuccess(sessionCrypto: sessionCrypto,
                                                 boc: boc,
                                                 id: message.id,
                                                 clientId: app.clientId)
        
        _ = try await apiClient.message(
            query: .init(client_id: sessionCrypto.sessionId,
                         to: app.clientId,
                         ttl: 300),
            body: .plainText(.init(stringLiteral: body))
        )
    }
}

private extension TonConnectConfirmationController {
    func emulateAppRequest(_ appRequest: TonConnect.AppRequest) {
        Task { @MainActor in
            output?.tonConnectConfirmationControllerDidStartEmulation(self)
        }
        Task {
            guard let param = appRequest.params.first else { return }
            do {
                let emulationResult = try await emulate(appRequestParam: param)
                await MainActor.run {
                    output?.tonConnectConfirmationControllerDidFinishEmulation(
                        self,
                        result: .success(emulationResult)
                    )
                }
            } catch {
                await cancelAppRequest()
                await MainActor.run {
                    output?.tonConnectConfirmationControllerDidFinishEmulation(
                        self,
                        result: .failure(error)
                    )
                }
            }
        }
    }
    
    func cancelAppRequest() async {
        guard case .confirmation(let appRequest, let app) = await state.property else { return }
        await state.setValue(.idle)
        Task {
            let sessionCrypto = try TonConnectSessionCrypto(privateKey: app.keyPair.privateKey)
            let body = try TonConnectResponseBuilder.buildSendTransactionResponseError(
                sessionCrypto: sessionCrypto,
                errorCode: .userDeclinedTransaction,
                id: appRequest.id,
                clientId: app.clientId)
            
            _ = try await apiClient.message(
                query: .init(client_id: sessionCrypto.sessionId,
                             to: app.clientId,
                             ttl: 300),
                body: .plainText(.init(stringLiteral: body))
            )
        }
    }
    
    func emulate(appRequestParam: TonConnect.AppRequest.Param) async throws -> TonConnectConfirmationModel {
        async let bocTask = transactionBoc(forParams: appRequestParam)
        async let ratesTask = loadRates()
        
        let loadedRates = await ratesTask
        let boc = try await bocTask
        
        let transactionInfo = try await sendService.loadTransactionInfo(boc: boc)
        let currency = try walletProvider.activeWallet.currency
        let rates = loadedRates?.first(where: { $0.currency == currency })
        
        let event = try AccountEvent(accountEvent: transactionInfo.event)
        let nfts = try await loadEventNFTs(event: event)
        
        return try tonConnectConfirmationMapper.mapTransactionInfo(
            transactionInfo,
            tonRates: rates,
            currency: currency,
            collectibles: nfts)
    }
    
    func loadRates() async -> [Rates.Rate]? {
        if let rates = try? await rateService.loadRates(tonInfo: TonInfo(), tokens: [], currencies: Currency.allCases) {
            return rates.ton
        } else if let rates = try? rateService.getRates() {
            return rates.ton
        } else {
            return nil
        }
    }
    
    func loadEventNFTs(event: AccountEvent) async throws -> Collectibles {
        var nftAddressesToLoad = Set<Address>()
        var nfts = [Address: Collectible]()
        for action in event.actions {
            switch action.type {
            case .nftItemTransfer(let nftItemTransfer):
                nftAddressesToLoad.insert(nftItemTransfer.nftAddress)
            case .nftPurchase(let nftPurchase):
                nfts[nftPurchase.collectible.address] = nftPurchase.collectible
                try? collectiblesService.saveCollectible(collectible: nftPurchase.collectible)
            default: continue
            }
        }
        
        if let loadedNFTs = try? await collectiblesService.loadCollectibles(addresses: Array(nftAddressesToLoad)) {
            nfts.merge(loadedNFTs.collectibles, uniquingKeysWith: { $1 })
        }
        
        return Collectibles(collectibles: nfts)
    }
    
    func transactionBoc(forParams params: TonConnect.AppRequest.Param) async throws -> String {
        let payloads: [SendMessageBuilder.TonConnectSendPayload] = params.messages.map {
            .init(
                value: BigInt(integerLiteral: $0.amount),
                recipientAddress: $0.address,
                stateInit: $0.stateInit,
                payload: $0.payload)
        }
        
        return try await sendMessageBuilder.sendTonConnectTransactionBoc(
            payloads,
            sender: params.from
        )
    }
}

actor ThreadSafeProperty<PropertyType> {
    var property: PropertyType
    
    init(property: PropertyType) {
        self.property = property
    }
    
    func setValue(_ value: PropertyType) {
        self.property = value
    }
    
    func getValue() -> PropertyType {
        return property
    }
}

public struct TonConnectConfirmationModel {
    public let event: ActivityEventViewModel
    public let fee: String
}
