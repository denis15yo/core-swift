import Foundation
import TonSwift
import BigInt

public final class SendConfirmationController {
  
  public enum Error: Swift.Error {
    case failedToCalculateFee
    case failedToSendTransaction
  }
  
  public var didUpdateModel: ((SendConfirmationModel) -> Void)?
  public var didGetError: ((Error) -> Void)?
  
  private var transactionEmulationExtra: Int64 = 0
  
  private let wallet: Wallet
  private let recipient: Recipient
  private let sendItem: SendItem
  private let comment: String?
  private let sendService: SendService
  private let balanceStore: BalanceStore
  private let ratesStore: RatesStore
  private let currencyStore: CurrencyStore
  private let mnemonicRepository: WalletMnemonicRepository
  private let amountFormatter: AmountFormatter
  
  init(wallet: Wallet,
       recipient: Recipient,
       sendItem: SendItem,
       comment: String?,
       sendService: SendService,
       balanceStore: BalanceStore,
       ratesStore: RatesStore,
       currencyStore: CurrencyStore,
       mnemonicRepository: WalletMnemonicRepository,
       amountFormatter: AmountFormatter) {
    self.wallet = wallet
    self.recipient = recipient
    self.sendItem = sendItem
    self.comment = comment
    self.sendService = sendService
    self.balanceStore = balanceStore
    self.ratesStore = ratesStore
    self.currencyStore = currencyStore
    self.mnemonicRepository = mnemonicRepository
    self.amountFormatter = amountFormatter
  }
  
  public func start() {
    didUpdateModel?(buildInitialModel())
    Task {
      await emulate()
    }
  }
  
  public func sendTransaction() async throws {
    do {
      let transactionBoc = try await createTransactionBoc()
      try await sendService.sendTransaction(boc: transactionBoc)
    } catch {
      Task { @MainActor in
        didGetError?(.failedToSendTransaction)
      }
      throw error
    }
  }
}

private extension SendConfirmationController {
  func buildInitialModel() -> SendConfirmationModel {
    return buildModel(fee: .loading, feeConverted: .value(nil))
  }
  
  func buildEmulatedModel(fee: Int64?) -> SendConfirmationModel {
    let feeItem: LoadableModelItem<String>
    let feeConverted: LoadableModelItem<String?>
    if let fee = fee {
      let feeFormatted = amountFormatter.formatAmount(
        BigUInt(UInt64(fee)),
        fractionDigits: TonInfo.fractionDigits,
        maximumFractionDigits: TonInfo.fractionDigits,
        symbol: TonInfo.symbol
      )
      feeItem = .value(feeFormatted)
      let rates = ratesStore.getRates(jettons: [])
      let currency = currencyStore.getActiveCurrency()
      if let rates = rates.ton.first(where: { $0.currency == currency }) {
        let rateConverter = RateConverter()
        let converted = rateConverter.convert(
          amount: fee,
          amountFractionLength: TonInfo.fractionDigits,
          rate: rates
        )
        let convertedFeeFormatted = amountFormatter.formatAmount(
          converted.amount,
          fractionDigits: converted.fractionLength,
          maximumFractionDigits: 2,
          currency: currency
        )
        feeConverted = .value(convertedFeeFormatted)
      } else {
        feeConverted = .value(nil)
      }
    } else {
      feeItem = .value("?")
      feeConverted = .value(nil)
    }
    
    return buildModel(fee: feeItem, feeConverted: feeConverted)
  }
  
  func buildModel(fee: LoadableModelItem<String>,
                  feeConverted: LoadableModelItem<String?>) -> SendConfirmationModel {
    let image: SendConfirmationModel.Image
    let titleType: SendConfirmationModel.TitleType
    let descriptionType: SendConfirmationModel.DescriptionType
    let formattedAmount: String?
    var formattedConvertedAmount: String?
    switch sendItem {
    case .token(let token, let amount):
      switch token {
      case .ton:
        image = .ton
        titleType = .ton
        descriptionType = .ton
        formattedAmount = amountFormatter.formatAmount(
          amount,
          fractionDigits: TonInfo.fractionDigits,
          maximumFractionDigits: TonInfo.fractionDigits,
          symbol: TonInfo.symbol
        )
        let rates = ratesStore.getRates(jettons: [])
        let currency = currencyStore.getActiveCurrency()
        if let rates = rates.ton.first(where: { $0.currency == currency }) {
          let rateConverter = RateConverter()
          let converted = rateConverter.convert(
            amount: amount,
            amountFractionLength: TonInfo.fractionDigits,
            rate: rates
          )
          formattedConvertedAmount = amountFormatter.formatAmount(
            converted.amount,
            fractionDigits: converted.fractionLength,
            maximumFractionDigits: 2,
            currency: currency
          )
        }
      case .jetton(let jettonItem):
        image = .jetton(jettonItem.jettonInfo.imageURL)
        titleType = .jetton(jettonItem.jettonInfo.symbol ?? jettonItem.jettonInfo.name)
        descriptionType = .jetton
        formattedAmount = amountFormatter.formatAmount(
          amount,
          fractionDigits: jettonItem.jettonInfo.fractionDigits,
          maximumFractionDigits: jettonItem.jettonInfo.fractionDigits,
          symbol: jettonItem.jettonInfo.symbol
        )
        let rates = ratesStore.getRates(jettons: [jettonItem.jettonInfo])
        let currency = currencyStore.getActiveCurrency()
        if let rates = rates.jettonsRates.first(where: { $0.jettonInfo == jettonItem.jettonInfo })?.rates.first(where: { $0.currency == currency }) {
          let rateConverter = RateConverter()
          let converted = rateConverter.convert(
            amount: amount,
            amountFractionLength: TonInfo.fractionDigits,
            rate: rates
          )
          formattedConvertedAmount = amountFormatter.formatAmount(
            converted.amount,
            fractionDigits: converted.fractionLength,
            maximumFractionDigits: 2,
            currency: currency
          )
        }
      }
    case .nft(let nft):
      let description = [nft.name, nft.collection?.name].compactMap { $0 }.joined(separator: " · ")
      image = .nft(nft.imageURL)
      titleType = .nft
      descriptionType = .nft(description)
      formattedAmount = nil
      formattedConvertedAmount = nil
    }
    
    return SendConfirmationModel(
      image: image,
      titleType: titleType,
      descriptionType: descriptionType,
      wallet: wallet.model.emojiLabel,
      recipientAddress: recipient.recipientAddress.shortAddressString,
      recipientName: recipient.recipientAddress.name,
      amount: formattedAmount,
      amountConverted: .value(formattedConvertedAmount),
      fee: fee,
      feeConverted: feeConverted,
      comment: comment
    )
  }
  
  func emulate() async {
    async let createTransactionBocTask = createEmulateTransactionBoc()
    
    do {
      let transactionBoc = try await createTransactionBocTask
      let transactionInfo = try await sendService.loadTransactionInfo(boc: transactionBoc)
      let sendTransactionModel = SendTransactionModel(
        accountEvent: transactionInfo.event,
        risk: transactionInfo.risk,
        transaction: transactionInfo.trace.transaction
      )
      transactionEmulationExtra = sendTransactionModel.extra
      let model = buildEmulatedModel(fee: sendTransactionModel.fee)
      Task { @MainActor in
        didUpdateModel?(model)
      }
    } catch {
      let model = buildEmulatedModel(fee: nil)
      Task { @MainActor in
        didUpdateModel?(model)
        didGetError?(.failedToCalculateFee)
      }
    }
  }
  
  func createEmulateTransactionBoc() async throws -> String {
    let boc: String
    switch sendItem {
    case .nft(let nft):
      boc = try await createNFTEmulateTransactionBoc(nft: nft)
    case .token(let token, let amount):
      boc = try await createTokenTransactionBoc(token: token, amount: amount) { transfer in
        try transfer.signMessage(signer: WalletTransferEmptyKeySigner())
      }
    }
    return boc
  }
  
  func createTransactionBoc() async throws -> String {
    let boc: String
    switch sendItem {
    case .nft(let nft):
      boc = try await createNFTTransactionBoc(nft: nft)
    case .token(let token, let amount):
      let mnemonic = try mnemonicRepository.getMnemonic(forWallet: wallet)
      let keyPair = try TonSwift.Mnemonic.mnemonicToPrivateKey(mnemonicArray: mnemonic.mnemonicWords)
      let privateKey = keyPair.privateKey
      boc = try await createTokenTransactionBoc(token: token, amount: amount) { transfer in
        return try transfer.signMessage(signer: WalletTransferSecretKeySigner(secretKey: privateKey.data))
      }
    }
    return boc
  }
  
  func createTokenTransactionBoc(token: Token, amount: BigUInt, signClosure: (WalletTransfer) async throws -> Cell) async throws -> String {
    let seqno = try await sendService.loadSeqno(address: wallet.address)
    switch token {
    case .ton:
      let isMax: Bool
      if let balance = try? balanceStore.getBalance(wallet: wallet) {
        isMax = BigUInt(balance.balance.tonBalance.amount) == amount
      } else {
        isMax = false
      }
      return try await TonTransferMessageBuilder.sendTonTransfer(
        wallet: wallet,
        seqno: seqno,
        value: amount,
        isMax: isMax,
        recipientAddress: recipient.recipientAddress.address,
        isBounceable: recipient.recipientAddress.isBouncable,
        comment: comment,
        signClosure: signClosure
      )
    case .jetton(let jettonItem):
      return try await TokenTransferMessageBuilder.sendTokenTransfer(
        wallet: wallet,
        seqno: seqno,
        tokenAddress: jettonItem.walletAddress,
        value: amount,
        recipientAddress: recipient.recipientAddress.address,
        isBounceable: recipient.recipientAddress.isBouncable,
        comment: comment,
        signClosure: signClosure
      )
    }
  }
  
  func createNFTEmulateTransactionBoc(nft: NFT) async throws -> String {
    let transferAmount = BigUInt(stringLiteral: "10000000000")
    let seqno = try await sendService.loadSeqno(address: wallet.address)
    return try await NFTTransferMessageBuilder.sendNFTTransfer(
        wallet: wallet,
        seqno: seqno,
        nftAddress: nft.address,
        recipientAddress: recipient.recipientAddress.address,
        transferAmount: transferAmount) { transfer in
            try transfer.signMessage(signer: WalletTransferEmptyKeySigner())
        }
  }
  
  func createNFTTransactionBoc(nft: NFT) async throws -> String {
    let emulationExtra = BigInt(integerLiteral: transactionEmulationExtra)
    let minimumTransferAmount = BigInt(stringLiteral: "50000000")
    var transferAmount = emulationExtra + minimumTransferAmount
    transferAmount = transferAmount < minimumTransferAmount
    ? minimumTransferAmount
    : transferAmount
    let seqno = try await sendService.loadSeqno(address: wallet.address)
    let mnemonic = try mnemonicRepository.getMnemonic(forWallet: wallet)
    let keyPair = try TonSwift.Mnemonic.mnemonicToPrivateKey(mnemonicArray: mnemonic.mnemonicWords)
    let privateKey = keyPair.privateKey
    
    return try await NFTTransferMessageBuilder.sendNFTTransfer(
        wallet: wallet,
        seqno: seqno,
        nftAddress: nft.address,
        recipientAddress: recipient.recipientAddress.address,
        transferAmount: transferAmount.magnitude) { transfer in
          return try transfer.signMessage(signer: WalletTransferSecretKeySigner(secretKey: privateKey.data))
        }
  }
}
