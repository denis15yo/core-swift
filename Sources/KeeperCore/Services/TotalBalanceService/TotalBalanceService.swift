import Foundation
import BigInt
import TonSwift

protocol TotalBalanceService {
  func getTotalBalance(address: Address, currency: Currency) throws -> TotalBalance
  func saveTotalBalance(totalBalance: TotalBalance, address: Address, currency: Currency) throws
  func calculateTotalBalance(balance: Balance, currency: Currency, rates: Rates) -> TotalBalance
}

final class TotalBalanceServiceImplementation: TotalBalanceService {
  let totalBalanceRepository: TotalBalanceRepository
  let rateConverter: RateConverter
  
  init(totalBalanceRepository: TotalBalanceRepository,
       rateConverter: RateConverter) {
    self.totalBalanceRepository = totalBalanceRepository
    self.rateConverter = rateConverter
  }
  
  func getTotalBalance(address: Address, currency: Currency) throws -> TotalBalance {
    try totalBalanceRepository.getTotalBalance(
      address: address,
      currency: currency
    )
  }
  
  func saveTotalBalance(totalBalance: TotalBalance, address: Address, currency: Currency) throws {
    try totalBalanceRepository.saveTotalBalance(
      totalBalance: totalBalance,
      address: address,
      currency: currency
    )
  }
  
  func calculateTotalBalance(balance: Balance, currency: Currency, rates: Rates) -> TotalBalance {
    struct Item {
      let amount: BigUInt
      let fractionDigits: Int
    }
    var items = [Item]()
    var maximumFractionDigits = 0
    
    // TON
    if let tonRate = rates.ton.first(where: { $0.currency == currency }) {
      let converted = rateConverter.convert(
        amount: balance.tonBalance.amount,
        amountFractionLength: TonInfo.fractionDigits,
        rate: tonRate
      )
      items.append(Item(amount: converted.amount, fractionDigits: converted.fractionLength))
      maximumFractionDigits = converted.fractionLength
    }
    
    // Jettons
    for jettonBalance in balance.jettonsBalance {
      guard let jettonRates = rates.jettonsRates
        .first(where: { $0.jettonInfo == jettonBalance.amount.jettonInfo })?
        .rates
        .first(where: { $0.currency == currency })
         else {
        continue
      }
      
      let converted = rateConverter.convert(
        amount: jettonBalance.amount.quantity,
        amountFractionLength: jettonBalance.amount.jettonInfo.fractionDigits,
        rate: jettonRates
      )
      items.append(Item(amount: converted.amount, fractionDigits: converted.fractionLength))
      maximumFractionDigits = max(converted.fractionLength, maximumFractionDigits)
    }
    
    var totalSum = BigUInt("0")
    for item in items {
      if item.fractionDigits < maximumFractionDigits {
        let countToExtend = maximumFractionDigits - item.fractionDigits
        let amountToMultiply = BigUInt(stringLiteral: "1" + String(repeating: "0", count: countToExtend))
        let extendedAmount = item.amount * amountToMultiply
        totalSum += extendedAmount
      } else {
        totalSum += item.amount
      }
    }
    
    return TotalBalance(amount: totalSum, fractionalDigits: maximumFractionDigits)
  }
}
