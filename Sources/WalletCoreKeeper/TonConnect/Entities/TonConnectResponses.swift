//
//  TonConnectResponses.swift
//  
//
//  Created by Grigory Serebryanyy on 30.10.2023.
//

import Foundation
import TonSwift
import WalletCoreCore

public enum TonConnect {}

extension TonConnect {
    enum ConnectEvent: Encodable {
        case success(ConnectEventSuccess)
        case error(ConnectEventError)
    }
    public struct ConnectEventSuccess: Encodable {
        public struct Payload: Encodable {
            let items: [ConnectItemReply]
            let device: DeviceInfo
            
            public init(items: [ConnectItemReply], device: DeviceInfo) {
                self.items = items
                self.device = device
            }
        }
        let event = "connect"
        let id = Int(Date().timeIntervalSince1970)
        let payload: Payload
        
        public init(payload: Payload) {
            self.payload = payload
        }
        
        public struct DeviceInfo: Encodable {
            let platform = "iphone"
            let appName = "nicegramWallet"
            let appVersion = "1.6.3"
            let maxProtocolVersion = 2
            let features = [Feature()]
            
            public init() {}
            
            struct Feature: Encodable {
                let name = "SendTransaction"
                let maxMessages = 4
            }
        }
    }
    public struct ConnectEventError: Encodable {
        struct Payload: Encodable {
            let code: Error
            let message: String
        }
        public enum Error: Int, Encodable {
            case unknownError = 0
            case badRequest = 1
            case appManifestNotFound = 2
            case appManifestContentError = 3
            case unknownApp = 100
            case userDeclinedTheConnection = 300
        }
        let event = "connect_error"
        let id = Int(Date().timeIntervalSince1970)
        let payload: Payload
    }
    
    public enum ConnectItemReply: Encodable {
        case tonAddress(TonAddressItemReply)
        case tonProof(TonProofItemReply)
    }
    public struct TonAddressItemReply: Encodable {
        let name = "ton_addr"
        let address: TonSwift.Address
        let network: Network
        let publicKey: TonSwift.PublicKey
        let walletStateInit: TonSwift.StateInit
        
        public init(address: TonSwift.Address, network: Network, publicKey: TonSwift.PublicKey, walletStateInit: TonSwift.StateInit) {
            self.address = address
            self.network = network
            self.publicKey = publicKey
            self.walletStateInit = walletStateInit
        }
    }
    public enum TonProofItemReply: Encodable {
        case success(TonProofItemReplySuccess)
        case error(TonProofItemReplyError)
    }
    public struct TonProofItemReplySuccess: Encodable {
        public struct Proof: Encodable {
            public let timestamp: UInt64
            public let domain: Domain
            public let signature: Signature
            public let payload: String
            public let privateKey: PrivateKey
        }
        
        public struct Signature: Encodable {
            public let address: TonSwift.Address
            public let domain: Domain
            public let timestamp: UInt64
            public let payload: String
        }
        
        public struct Domain: Encodable {
            public let lengthBytes: UInt32
            public let value: String
        }
        
        public let name = "ton_proof"
        public let proof: Proof
    }
    
    public struct TonProofItemReplyError: Encodable {
        struct Error: Encodable {
            let message: String?
            let code: ErrorCode
        }
        enum ErrorCode: Int, Encodable {
            case unknownError = 0
            case methodNotSupported = 400
        }
        
        let name = "ton_proof"
        let error: Error
    }
}

public extension TonConnect.TonProofItemReplySuccess {
    init(address: TonSwift.Address,
         domain: String,
         payload: String,
         privateKey: PrivateKey) {
        let timestamp = UInt64(Date().timeIntervalSince1970)
        let domain = Domain(domain: domain)
        let signature = Signature(
            address: address,
            domain: domain,
            timestamp: timestamp,
            payload: payload)
        let proof = Proof(
            timestamp: timestamp,
            domain: domain,
            signature: signature,
            payload: payload,
            privateKey: privateKey)
        
        self.init(proof: proof)
    }
}

extension TonConnect.TonProofItemReplySuccess.Domain {
    init(domain: String) {
        let domainLength = UInt32(domain.utf8.count)
        self.value = domain
        self.lengthBytes = domainLength
    }
}

extension TonConnect {
    enum SendTransactionResponse {
        case success(SendTransactionResponseSuccess)
        case error(SendTransactionResponseError)
    }
    public struct SendTransactionResponseSuccess: Encodable {
        let result: String
        let id: String
        
        public init(result: String, id: String) {
            self.result = result
            self.id = id
        }
    }
    public struct SendTransactionResponseError: Encodable {
        struct Error: Encodable {
            let code: ErrorCode
            let message: String
        }
        
        public enum ErrorCode: Int, Encodable {
            case unknownError = 0
            case badRequest = 1
            case unknownApp = 10
            case userDeclinedTransaction = 300
            case methodNotSupported = 400
        }
        
        let id: String
        let error: Error
    }
}
