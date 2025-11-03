//
//  StorageServiceProtocol.swift
//  ARCodeClone
//
//  Protocol pour le service de stockage local
//

import Foundation

/// Protocol pour les opérations de stockage
protocol StorageServiceProtocol {
    func save<T: Codable>(_ object: T, forKey key: String) throws
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T?
    func delete(forKey key: String) throws
    func clearAll() throws
}












