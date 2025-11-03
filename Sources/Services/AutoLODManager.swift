//
//  AutoLODManager.swift
//  ARCodeClone
//
//  Automatic LOD switching based on distance
//

import Foundation
import SceneKit
import ARKit
import Combine
import SwiftUI

protocol AutoLODManagerProtocol {
    func updateLOD(for node: SCNNode, cameraPosition: SIMD3<Float>)
    func loadModelWithAutoLOD(
        baseURL: URL,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> SCNNode
}

final class AutoLODManager: AutoLODManagerProtocol {
    private let lodService: LODServiceProtocol
    private let assetLoadingService: AssetLoadingServiceProtocol
    private var loadedNodes: [SCNNode: URL] = [:]
    private var currentLODLevels: [SCNNode: LODLevel] = [:]
    
    init(
        lodService: LODServiceProtocol,
        assetLoadingService: AssetLoadingServiceProtocol
    ) {
        self.lodService = lodService
        self.assetLoadingService = assetLoadingService
    }
    
    func updateLOD(for node: SCNNode, cameraPosition: SIMD3<Float>) {
        guard let baseURL = loadedNodes[node] else { return }
        
        // Calculate distance
        let nodePosition = SIMD3<Float>(
            node.position.x,
            node.position.y,
            node.position.z
        )
        let distance = simd_distance(cameraPosition, nodePosition)
        
        // Get appropriate LOD level
        let newLODLevel = lodService.getLODLevel(for: distance)
        let currentLODLevel = currentLODLevels[node]
        
        // Switch LOD if changed
        if newLODLevel != currentLODLevel {
            Task {
                await switchToLOD(node: node, level: newLODLevel, baseURL: baseURL)
            }
        }
    }
    
    private func switchToLOD(node: SCNNode, level: LODLevel, baseURL: URL) async {
        do {
            // Get LOD URL
            let lodURL = lodService.getAssetURL(for: baseURL, lodLevel: level)
            
            // Load new LOD model
            let lodNode = try await assetLoadingService.loadARAsset(
                url: lodURL,
                contentType: "object_capture"
            ) { _ in }
            
            // Replace geometry (preserve position/rotation)
            if let newGeometry = lodNode.node?.geometry {
                node.geometry = newGeometry
                node.geometry?.materials = lodNode.node?.geometry?.materials ?? []
                
                // Update current LOD level
                currentLODLevels[node] = level
            }
        } catch {
            print("Error switching LOD: \(error)")
        }
    }
    
    func loadModelWithAutoLOD(
        baseURL: URL,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> SCNNode {
        // Load high detail first (default)
        let node = try await assetLoadingService.loadARAsset(
            url: baseURL,
            contentType: "object_capture"
        ) { progress in
            progressHandler(progress * 0.8) // 80% for loading
        }
        
        guard let loadedNode = node.node else {
            throw NSError(domain: "AutoLOD", code: -1)
        }
        
        // Store base URL for LOD switching
        loadedNodes[loadedNode] = baseURL
        currentLODLevels[loadedNode] = .high
        
        progressHandler(1.0)
        
        return loadedNode
    }
    
    func startAutoLODUpdates(
        for node: SCNNode,
        cameraPosition: @escaping () -> SIMD3<Float>,
        updateInterval: TimeInterval = 0.5
    ) -> Timer? {
        let timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let camPos = cameraPosition()
            self.updateLOD(for: node, cameraPosition: camPos)
        }
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }
}

