//
//  WalletIdentityCellCodableTests.swift
//  
//
//  Created by Grigory on 26.6.23..
//

import XCTest
import TonSwift
@testable import WalletCore

final class WalletIdentityCellCodableTests: XCTestCase {
    func testWalletIdentittyCoding() throws {
        // GIVEN
        let publicKey = TonSwift.PublicKey(data: Data(hex: "5754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522")!)
        let walletKind = WalletKind.Regular(publicKey)
        let walletIdentity = WalletIdentity(network: .testnet, kind: walletKind)
        let builder = Builder()
        
        // WHEN
        try walletIdentity.storeTo(builder: builder)
        let slice = Slice(bits: builder.bitstring())
        let decodedWalletIdentity: WalletIdentity = try slice.loadType()
        
        // THEN
        XCTAssertEqual(decodedWalletIdentity.network, .testnet)
        guard case let .Regular(decodedPublicKey) = decodedWalletIdentity.kind,
              decodedPublicKey.data == publicKey.data else {
            XCTFail()
            return
        }
    }
}

// WalletKind

extension WalletIdentityCellCodableTests {
    func testWalletKindRegularCoding() throws {
        // GIVEN
        let publicKey = TonSwift.PublicKey(data: Data(hex: "5754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522")!)
        let walletKind = WalletKind.Regular(publicKey)
        let builder = Builder()
        
        // WHEN
        try walletKind.storeTo(builder: builder)
        let slice = Slice(bits: builder.bitstring())
        let decodedWalletKind: WalletKind = try slice.loadType()
        
        // THEN
        guard case let .Regular(decodedPublicKey) = decodedWalletKind,
              decodedPublicKey.data ==  publicKey.data else {
            XCTFail()
            return
        }
    }
    
    func testWalletKindLockupCoding() throws {
        // GIVEN
        let lockupConfig = LockupConfig()
        let publicKey = TonSwift.PublicKey(data: Data(hex: "5754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522")!)
        let walletKind = WalletKind.Lockup(publicKey, lockupConfig)
        let builder = Builder()
        
        // WHEN
        try walletKind.storeTo(builder: builder)
        let slice = Slice(bits: builder.bitstring())
        let decodedWalletKind: WalletKind = try slice.loadType()
        
        // THEN
        guard case let .Lockup(decodedPublicKey, decodedLockupConfig) = decodedWalletKind,
              decodedPublicKey.data ==  publicKey.data,
              decodedLockupConfig == lockupConfig else {
            XCTFail()
            return
        }
    }
    
    func testWalletKindWatchonlyCoding() throws {
        // GIVEN
        let address = Address.mock(workchain: 0, seed: "testResolvableAddressResolvedCoding")
        let resolvableAddress = ResolvableAddress.Resolved(address)
        let walletKind = WalletKind.Watchonly(resolvableAddress)
        let builder = Builder()
        
        // WHEN
        try walletKind.storeTo(builder: builder)
        let slice = Slice(bits: builder.bitstring())
        let decodedWalletKind: WalletKind = try slice.loadType()
        
        // THEN
        guard case let .Watchonly(decodedResolvableAddress) = decodedWalletKind,
              case let .Resolved(decodedAddress) = decodedResolvableAddress,
              decodedAddress == address else {
            XCTFail()
            return
        }
    }
}

// ResolvableAddress

extension WalletIdentityCellCodableTests {
    func testResolvableAddressResolvedCoding() throws {
        // GIVEN
        let address = Address.mock(workchain: 0, seed: "testResolvableAddressResolvedCoding")
        let resolvedAddress = ResolvableAddress.Resolved(address)
        let builder = Builder()
        
        // WHEN
        try resolvedAddress.storeTo(builder: builder)
        let slice = Slice(bits: builder.bitstring())
        let decodedResolvedAddress: ResolvableAddress = try slice.loadType()
        
        // THEN
        XCTAssertEqual(decodedResolvedAddress, resolvedAddress)
    }
    
    func testResolvableAddressDomainCoding() throws {
        // GIVEN
        let domain = "it's test domain even with emoji🚘👯‍♂️. let's try to encode and decode it"
        let resolvedAddress = ResolvableAddress.Domain(domain)
        let builder = Builder()
        
        // WHEN
        try resolvedAddress.storeTo(builder: builder)
        let slice = Slice(bits: builder.bitstring())
        let decodedResolvedAddress: ResolvableAddress = try slice.loadType()
        
        // THEN
        XCTAssertEqual(decodedResolvedAddress, resolvedAddress)
    }
}

// Network

extension WalletIdentityCellCodableTests {
    func testNetworkMainnetCoding() throws {
        // GIVEN
        let network = Network.mainnet
        let builder = Builder()
        
        // WHEN
        try network.storeTo(builder: builder)
        let slice = Slice(bits: builder.bitstring())
        let decodedNetwork: Network = try slice.loadType()
        
        // THEN
        XCTAssertEqual(decodedNetwork, network)
    }
    
    func testNetworkTestnetCoding() throws {
        // GIVEN
        let network = Network.testnet
        let builder = Builder()
        
        // WHEN
        try network.storeTo(builder: builder)
        let slice = Slice(bits: builder.bitstring())
        let decodedNetwork: Network = try slice.loadType()
        
        // THEN
        XCTAssertEqual(decodedNetwork, network)
    }
}
