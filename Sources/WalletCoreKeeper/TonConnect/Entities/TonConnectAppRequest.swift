//
//  TonConnectAppRequest.swift
//  
//
//  Created by Grigory Serebryanyy on 27.10.2023.
//

import Foundation
import TonSwift

public extension TonConnect {
    struct AppRequest: Decodable {
        public enum Method: String, Decodable {
            case sendTransaction
        }
        
        public struct Param: Decodable {
            public let messages: [Message]
            public let validUntil: TimeInterval
            public let from: Address?
            
            enum CodingKeys: String, CodingKey {
                case messages
                case validUntil = "valid_until"
                case from
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                messages = try container.decode([Message].self, forKey: .messages)
                validUntil = try container.decode(TimeInterval.self, forKey: .validUntil)
                from = try Address.parse(try container.decode(String.self, forKey: .from))
            }
        }
        
        public struct Message: Decodable {
            public let address: Address
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
                address = try Address.parse(try container.decode(String.self, forKey: .address))
                amount = Int64(try container.decode(String.self, forKey: .amount)) ?? 0
                stateInit = try container.decodeIfPresent(String.self, forKey: .stateInit)
                payload = try container.decodeIfPresent(String.self, forKey: .payload)
            }
        }
        
        public let method: Method
        public let params: [Param]
        public let id: String
        
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
            params = paramsArray.compactMap {
                guard let data = $0.data(using: .utf8) else { return nil }
                return try? jsonDecoder.decode(Param.self, from: data)
            }
        }
    }
}
