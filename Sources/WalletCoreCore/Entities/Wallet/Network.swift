//
//  Network.swift
//  
//
//  Created by Grigory Serebryanyy on 17.11.2023.
//

import Foundation
import TonSwift

public enum Network: Int16 {
    case mainnet = -239
    case testnet = -3
}

extension Network: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        var intValue = try? container.decode(Int16.self)
        
        if intValue == nil,
           let stringValue = try? container.decode(String.self) {
            intValue = Int16(stringValue)
        }
        
        if let intValue,
           let network = Network(rawValue: intValue) {
            self = network
        } else {
            throw TonSwift.TonError.custom("Invalid network code")
        }
    }
}

extension Network: CellCodable {
    public func storeTo(builder: Builder) throws {
        try builder.store(int: rawValue, bits: .rawValueLength)
    }
    
    public static func loadFrom(slice: Slice) throws -> Network {
        return try slice.tryLoad { s in
            let rawValue = Int16(try s.loadInt(bits: .rawValueLength))
            guard let network = Network(rawValue: rawValue) else {
                throw TonSwift.TonError.custom("Invalid network code")
            }
            return network
        }
    }
}

private extension Int {
    static let rawValueLength = 16
}
