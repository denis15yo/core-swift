//
//  TonConnectEvent.swift
//  
//
//  Created by Grigory Serebryanyy on 27.10.2023.
//

import Foundation

public struct TonConnectEvent: Decodable {
    public let from: String
    public let message: String
}
