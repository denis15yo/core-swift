//
//  Address+Short.swift
//
//
//  Created by Grigory on 7.7.23..
//

import Foundation
import TonSwift

public extension Address {
    func toShortString(bounceable: Bool) -> String {
        let string = self.toString(bounceable: bounceable)
        let leftPart = string.prefix(4)
        let rightPart = string.suffix(4)
        return "\(leftPart)...\(rightPart)"
    }
}