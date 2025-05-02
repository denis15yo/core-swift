//
//  TonConnectAppRequest.swift
//  
//
//  Created by Grigory Serebryanyy on 27.10.2023.
//

import Foundation
import TonSwift
import WalletCoreCore

public extension TonConnect {
    struct AppRequest: Decodable {
        public enum Method: String, Decodable {
            case disconnect
            case sendTransaction
        }
        
        public struct Param: Decodable {
            public let messages: [Message]
            public var validUntil: UInt64?
            public let from: String
            public let network: Network?
            
            enum CodingKeys: String, CodingKey {
                case messages
                case validUntil = "valid_until"
                case from
                case network
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                messages = try container.decode([Message].self, forKey: .messages)
                validUntil = try container.decodeIfPresentAndFailForNil(UInt64.self, forKey: .validUntil)
                
                from = try container.decode(String.self, forKey: .from)
                try from.validateTonAddress()
                
                network = try container.decodeIfPresent(Network.self, forKey: .network)
            }
        }
        
        public struct Message: Decodable {
            public let address: String
            public let amount: Int64
            public let stateInit: String?
            public let payload: String?
            
            enum CodingKeys: String, CodingKey {
                case address
                case amount
                case stateInit
                case payload
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                address = try container.decode(String.self, forKey: .address)
                try address.validateFriendlyAddress()
                
                let amountString = try container.decode(String.self, forKey: .amount)
                if let amount = Int64(amountString) {
                    self.amount = amount
                } else {
                    throw TonSwift.TonError.custom("Amount is invalid")
                }
                
                stateInit = try container.decodeIfPresent(String.self, forKey: .stateInit)
                payload = try container.decodeIfPresent(String.self, forKey: .payload)
            }
        }
        
        public let method: Method
        public var params: [Param]
        public var id: String
        
        public init(method: Method, params: [Param], id: String) {
            self.method = method
            self.params = params
            self.id = id
        }
        
        enum CodingKeys: String, CodingKey {
            case method
            case params
            case id
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            method = try container.decode(Method.self, forKey: .method)
            id = try container.decode(String.self, forKey: .id)
            let paramsArray = try container.decode([String].self, forKey: .params)
            let jsonDecoder = JSONDecoder()
            params = try paramsArray.compactMap {
                guard let data = $0.data(using: .utf8) else { return nil }
                return try jsonDecoder.decode(Param.self, from: data)
            }
        }
    }
}

private extension String {
    func validateFriendlyAddress() throws {
        if self.contains(":") {
            throw TonError.custom("Unexpected raw address")
        }
        _ = try FriendlyAddress(string: self)
    }
    
    func validateTonAddress() throws {
        _ = try Address.parse(self)
    }
}

private extension KeyedDecodingContainer {
    func decodeIfPresentAndFailForNil<T>(
        _ type: T.Type,
        forKey key: KeyedDecodingContainer<K>.Key
    ) throws -> T? where T: Decodable {
        let result = try self.decodeIfPresent(type, forKey: key)
        
        if result == nil, self.contains(key) {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Unexpected null value for key \(key.stringValue)"
            )
        }
        
        return result
    }
}
