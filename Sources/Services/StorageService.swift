//
//  StorageService.swift
//  ARCodeClone
//
//  Implémentation du service de stockage local avec UserDefaults
//

import Foundation

final class StorageService: StorageServiceProtocol {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func save<T: Codable>(_ object: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(object)
        userDefaults.set(data, forKey: key)
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }
    
    func delete(forKey key: String) throws {
        userDefaults.removeObject(forKey: key)
    }
    
    func clearAll() throws {
        if let bundleID = Bundle.main.bundleIdentifier {
            userDefaults.removePersistentDomain(forName: bundleID)
        }
    }
}

// Keys pour le stockage
extension StorageService {
    enum Keys {
        static let currentUser = "current_user"
        static let arcodes = "arcodes"
        static let analyticsEvents = "analytics_events"
        static let cachedAssets = "cached_assets"
    }
}













