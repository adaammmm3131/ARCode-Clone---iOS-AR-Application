//
//  AssetLoadingService.swift
//  ARCodeClone
//
//  Service pour loading assets avec progress tracking, preloading, lazy loading
//

import Foundation
import Combine
import SceneKit

protocol AssetLoadingServiceProtocol {
    func loadARAsset(
        url: URL,
        contentType: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> ARAsset
    func preloadAsset(url: URL, contentType: String) async throws
    func loadModelWithLOD(url: URL, lodLevel: LODLevel, progressHandler: @escaping (Double) -> Void) async throws -> SCNNode
    func getCachedAsset(for url: URL) -> ARAsset?
}

enum LODLevel: Int, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
    
    var suffix: String {
        switch self {
        case .low: return "_low"
        case .medium: return "_medium"
        case .high: return "_high"
        }
    }
}

struct ARAsset {
    let url: URL
    let contentType: String
    let node: SCNNode?
    let modelEntity: ModelEntity? // Pour RealityKit
    let thumbnail: UIImage?
    let metadata: [String: Any]
}

enum AssetLoadingError: LocalizedError {
    case invalidURL
    case unsupportedFormat
    case loadingFailed(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .unsupportedFormat:
            return "Format non supporté"
        case .loadingFailed(let error):
            return "Échec chargement: \(error.localizedDescription)"
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        }
    }
}

final class AssetLoadingService: AssetLoadingServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private var assetCache: [URL: ARAsset] = [:]
    private var preloadTasks: [URL: Task<Void, Error>] = [:]
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    // MARK: - Asset Loading
    
    func loadARAsset(
        url: URL,
        contentType: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> ARAsset {
        // Vérifier cache d'abord
        if let cached = getCachedAsset(for: url) {
            progressHandler(1.0)
            return cached
        }
        
        // Charger selon type
        switch contentType {
        case "object_capture", "splat":
            let node = try await loadModelWithLOD(url: url, lodLevel: .medium, progressHandler: progressHandler)
            let asset = ARAsset(
                url: url,
                contentType: contentType,
                node: node,
                modelEntity: nil,
                thumbnail: nil,
                metadata: [:]
            )
            
            // Mettre en cache
            assetCache[url] = asset
            return asset
            
        case "video":
            // Charger vidéo
            progressHandler(0.5)
            let node = try await loadVideoNode(url: url)
            progressHandler(1.0)
            
            let asset = ARAsset(
                url: url,
                contentType: contentType,
                node: node,
                modelEntity: nil,
                thumbnail: nil,
                metadata: [:]
            )
            
            assetCache[url] = asset
            return asset
            
        default:
            throw AssetLoadingError.unsupportedFormat
        }
    }
    
    // MARK: - Preloading
    
    func preloadAsset(url: URL, contentType: String) async throws {
        // Si déjà en cache, retourner
        if getCachedAsset(for: url) != nil {
            return
        }
        
        // Si déjà en cours de preload, attendre
        if let existingTask = preloadTasks[url] {
            try await existingTask.value
            return
        }
        
        // Créer task de preload
        let task = Task {
            _ = try await loadARAsset(url: url, contentType: contentType) { _ in }
        }
        
        preloadTasks[url] = task
        
        do {
            try await task.value
        } catch {
            preloadTasks.removeValue(forKey: url)
            throw error
        }
    }
    
    // MARK: - LOD Loading
    
    func loadModelWithLOD(
        url: URL,
        lodLevel: LODLevel,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> SCNNode {
        // Construire URL avec LOD suffix
        let lodURL = url.deletingLastPathComponent()
            .appendingPathComponent(url.deletingPathExtension().lastPathComponent + lodLevel.suffix)
            .appendingPathExtension(url.pathExtension)
        
        // Essayer charger LOD spécifique, fallback sur original
        let finalURL: URL
        if lodLevel != .high {
            // Vérifier si fichier LOD existe (tenter de charger)
            // En production, vérifier existence fichier avant
            finalURL = lodURL
        } else {
            finalURL = url
        }
        
        progressHandler(0.2)
        
        // Télécharger fichier d'abord
        let (data, _) = try await URLSession.shared.data(from: finalURL)
        
        progressHandler(0.5)
        
        // Sauvegarder temporairement pour charger dans SceneKit
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(finalURL.pathExtension)
        
        try data.write(to: tempURL)
        
        progressHandler(0.7)
        
        // Charger modèle 3D depuis fichier local
        // Note: Implémentation basique - pour production, utiliser Model I/O ou RealityKit
        let scene = try SCNScene(url: tempURL, options: nil)
        
        progressHandler(0.9)
        
        guard let node = scene.rootNode.childNodes.first else {
            throw AssetLoadingError.loadingFailed(NSError(domain: "AssetLoading", code: -1, userInfo: [NSLocalizedDescriptionKey: "No nodes found"]))
        }
        
        // Nettoyer fichier temporaire
        try? FileManager.default.removeItem(at: tempURL)
        
        progressHandler(1.0)
        
        return node
    }
    
    // MARK: - Cache
    
    func getCachedAsset(for url: URL) -> ARAsset? {
        return assetCache[url]
    }
    
    // MARK: - Helper Methods
    
    private func loadVideoNode(url: URL) async throws -> SCNNode {
        // Créer node vidéo (similaire à ARVideoPlayerService)
        // Note: Implémentation simplifiée
        let plane = SCNPlane(width: 1.0, height: 1.0)
        let node = SCNNode(geometry: plane)
        return node
    }
}

