//
//  CollectibleDetailsMapper.swift
//  
//
//  Created by Grigory on 24.8.23..
//

import Foundation
import TonSwift

struct CollectibleDetailsMapper {
    
    private let dateFormatter: DateFormatter
    
    init(dateFormatter: DateFormatter) {
        self.dateFormatter = dateFormatter
        dateFormatter.dateFormat = "dd MMM yyyy"
    }
    
    func map(collectible: Collectible,
             isOwner: Bool,
             linkedAddress: Address?,
             expirationDate: Date?,
             isInitial: Bool) -> CollectibleDetailsViewModel {
        
        let linkedAddressItem: ViewModelLoadableItem<String?>
        if let linkedAddress = linkedAddress {
            linkedAddressItem = .value(linkedAddress.toShortString(bounceable: false))
        } else if isInitial {
            linkedAddressItem = .loading
        } else {
            linkedAddressItem = .value(nil)
        }
        
        let expirationDateItem: ViewModelLoadableItem<String>?
        let daysExpiration: Int?
        if let expirationDate = expirationDate {
            let formattedDate = dateFormatter.string(from: expirationDate)
            expirationDateItem = .value(formattedDate)
            daysExpiration = calculateDaysNumberToExpire(expirationDate: expirationDate)
        } else {
            expirationDateItem = nil
            daysExpiration = nil
        }
        
        return CollectibleDetailsViewModel(
            title: collectible.name,
            collectibleDetails: mapCollectibleDetails(collectible: collectible),
            collectionDetails: mapCollectionDetails(collectible: collectible),
            properties: mapProperties(collectible: collectible),
            details: mapDetails(collectible: collectible),
            isTransferEnable: mapIsTransferEnable(collectible: collectible, isOwner: isOwner),
            isOnSale: collectible.sale != nil,
            linkedAddress: linkedAddressItem,
            expirationDateItem: expirationDateItem,
            daysExpiration: daysExpiration)
    }
    
    private func mapCollectibleDetails(collectible: Collectible) -> CollectibleDetailsViewModel.CollectibleDetails {
        var subtitle: String?
        if collectible.dns != nil {
            subtitle = "TON DNS"
        } else if let collection = collectible.collection, let collectionName = collection.name {
            subtitle = collectionName
        }
        
        let imageURL = collectible.preview.size1500 ?? collectible.preview.size500 ?? collectible.imageURL
        
        return CollectibleDetailsViewModel.CollectibleDetails(
            imageURL: imageURL,
            title: collectible.name,
            subtitle: subtitle,
            description: collectible.description
        )
    }
    
    private func mapCollectionDetails(collectible: Collectible) -> CollectibleDetailsViewModel.CollectionDetails {
        var title: String?
        var description: String?
        if let collectionName = collectible.collection?.name {
            title = "About \(collectionName)"
            description = collectible.collection?.description
        }
        return CollectibleDetailsViewModel.CollectionDetails(
            title: title,
            description: description
        )
    }
    
    private func mapProperties(collectible: Collectible) -> [CollectibleDetailsViewModel.Property] {
        collectible.attributes.map { CollectibleDetailsViewModel.Property(title: $0.key, value: $0.value) }
    }
    
    private func mapDetails(collectible: Collectible) -> CollectibleDetailsViewModel.Details {
        var items = [CollectibleDetailsViewModel.Details.Item]()
        if let owner = collectible.owner {
            items.append(.init(title: "Owner", value: owner.address.toShortString(bounceable: false)))
        }
        items.append(.init(title: "Contract address", value: collectible.address.toShortString(bounceable: false)))
        
        let url = URL.tonviewerURL.appendingPathComponent(collectible.address.toRaw())
        return CollectibleDetailsViewModel.Details(items: items, url: url)
    }
    
    private func mapIsTransferEnable(
        collectible: Collectible,
        isOwner: Bool) -> Bool {
            return collectible.sale == nil && isOwner
    }
    
    private func calculateDaysNumberToExpire(expirationDate: Date) -> Int {
        let calendar = Calendar.current
        let numberOfDays = calendar.dateComponents([.day], from: Date(), to: expirationDate)
        return (numberOfDays.day ?? 0)
    }
}

private extension URL {
    static let tonviewerURL = URL(string: "https://tonviewer.com/")!
}
