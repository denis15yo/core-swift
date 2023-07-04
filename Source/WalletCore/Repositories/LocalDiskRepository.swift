//
//  LocalDiskRepository.swift
//  
//
//  Created by Grigory on 27.6.23..
//

import Foundation

struct LocalDiskRepository<T: Codable & LocalStorable>: LocalRepository {
    enum Error: Swift.Error {
        case noItemInRepository
        case corruptedData(DecodingError)
    }
    
    private let fileManager: FileManager
    private let directory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    init(fileManager: FileManager,
         directory: URL,
         encoder: JSONEncoder,
         decoder: JSONDecoder) {
        self.fileManager = fileManager
        self.directory = directory
        self.encoder = encoder
        self.decoder = decoder
    }
    
    func save(item: T) throws {
        let path = folderPath().appendingPathComponent(item.fileName)
        try createFolderIfNeeded(url: path)
        if fileManager.fileExists(atPath: path.path) {
            try fileManager.removeItem(at: path)
        }
        
        let data = try encoder.encode(item)
        try data.write(to: path, options: .atomic)
    }
    
    func load(fileName: String) throws -> T {
        let path = folderPath().appendingPathComponent(fileName)
        do {
            let data = try Data(contentsOf: path)
            let item = try decoder.decode(T.self, from: data)
            return item
        } catch CocoaError.fileReadNoSuchFile {
            throw Error.noItemInRepository
        } catch let decodingError as DecodingError {
            throw Error.corruptedData(decodingError)
        } catch {
            throw error
        }
    }
}

private extension LocalDiskRepository {
    func folderPath() -> URL {
        let typeFolder = String(describing: T.self)
        let folderURL = directory.appendingPathComponent(typeFolder, isDirectory: true)
        return folderURL
    }
    
    func itemPath(itemType: T.Type) -> URL {
        return folderPath().appendingPathComponent(itemType.fileName)
    }
    
    func createFolderIfNeeded(url: URL) throws {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
}