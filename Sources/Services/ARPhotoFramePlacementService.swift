//
//  ARPhotoFramePlacementService.swift
//  ARCodeClone
//
//  Service pour placement frames photo sur vertical planes et gallery mode
//

import Foundation
import ARKit
import SceneKit

protocol ARPhotoFramePlacementServiceProtocol {
    func placeFrame(_ frameNode: SCNNode, on plane: ARPlaneAnchor, in scene: SCNScene, at offset: SIMD3<Float>?)
    func createGallery(frames: [SCNNode], on plane: ARPlaneAnchor, in scene: SCNScene, layout: GalleryLayout)
    func navigateToNext(in gallery: SCNNode)
    func navigateToPrevious(in gallery: SCNNode)
}

enum GalleryLayout {
    case grid(columns: Int, spacing: Float)
    case horizontal(spacing: Float)
    case vertical(spacing: Float)
    case custom(positions: [SIMD3<Float>])
}

final class ARPhotoFramePlacementService: ARPhotoFramePlacementServiceProtocol {
    private var galleryNodes: [UUID: SCNNode] = [:]
    private var currentGalleryIndex: [UUID: Int] = [:]
    
    // MARK: - Frame Placement
    
    func placeFrame(_ frameNode: SCNNode, on plane: ARPlaneAnchor, in scene: SCNScene, at offset: SIMD3<Float>? = nil) {
        guard plane.alignment == .vertical else {
            print("⚠️ Plan doit être vertical pour placement mural")
            return
        }
        
        // Positionner sur plan vertical
        let position = offset ?? SIMD3<Float>(plane.center.x, plane.center.y, plane.center.z)
        frameNode.simdPosition = position
        
        // Orienter frame face à la caméra (perpendiculaire au plan)
        // Le plan vertical est perpendiculaire à Y, donc frame doit être face à la caméra
        frameNode.simdRotation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
        
        scene.rootNode.addChildNode(frameNode)
    }
    
    // MARK: - Gallery Creation
    
    func createGallery(frames: [SCNNode], on plane: ARPlaneAnchor, in scene: SCNScene, layout: GalleryLayout) {
        guard plane.alignment == .vertical else { return }
        
        // Créer container node pour gallery
        let galleryNode = SCNNode()
        galleryNode.name = "photoGallery_\(UUID().uuidString)"
        
        // Positionner gallery sur plan
        galleryNode.simdPosition = SIMD3<Float>(plane.center.x, plane.center.y, plane.center.z)
        galleryNode.simdRotation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
        
        // Disposer frames selon layout
        let positions = calculateLayoutPositions(count: frames.count, layout: layout, planeSize: plane.planeExtent)
        
        for (index, frame) in frames.enumerated() {
            if index < positions.count {
                // Positionner frame relativement à gallery
                frame.simdPosition = positions[index]
                galleryNode.addChildNode(frame)
            }
        }
        
        scene.rootNode.addChildNode(galleryNode)
        
        // Enregistrer gallery
        let galleryId = UUID()
        galleryNodes[galleryId] = galleryNode
        currentGalleryIndex[galleryId] = 0
        
        // Marquer frames comme gallery
        frames.forEach { $0.name = "galleryFrame_\(galleryId.uuidString)" }
    }
    
    // MARK: - Gallery Navigation
    
    func navigateToNext(in gallery: SCNNode) {
        guard let galleryId = getGalleryId(from: gallery) else { return }
        
        let currentIndex = currentGalleryIndex[galleryId] ?? 0
        let frames = gallery.childNodes.filter { $0.name?.contains("galleryFrame") ?? false }
        
        guard !frames.isEmpty else { return }
        
        let nextIndex = (currentIndex + 1) % frames.count
        
        // Cacher frame actuel
        if currentIndex < frames.count {
            frames[currentIndex].isHidden = true
        }
        
        // Afficher frame suivant
        frames[nextIndex].isHidden = false
        
        currentGalleryIndex[galleryId] = nextIndex
    }
    
    func navigateToPrevious(in gallery: SCNNode) {
        guard let galleryId = getGalleryId(from: gallery) else { return }
        
        let currentIndex = currentGalleryIndex[galleryId] ?? 0
        let frames = gallery.childNodes.filter { $0.name?.contains("galleryFrame") ?? false }
        
        guard !frames.isEmpty else { return }
        
        let previousIndex = (currentIndex - 1 + frames.count) % frames.count
        
        // Cacher frame actuel
        if currentIndex < frames.count {
            frames[currentIndex].isHidden = true
        }
        
        // Afficher frame précédent
        frames[previousIndex].isHidden = false
        
        currentGalleryIndex[galleryId] = previousIndex
    }
    
    // MARK: - Helper Methods
    
    private func calculateLayoutPositions(count: Int, layout: GalleryLayout, planeSize: simd_float3) -> [SIMD3<Float>] {
        var positions: [SIMD3<Float>] = []
        
        switch layout {
        case .grid(let columns, let spacing):
            let rows = (count + columns - 1) / columns
            let frameWidth: Float = 0.5 // Largeur approximative frame
            let frameHeight: Float = 0.6 // Hauteur approximative frame
            
            for row in 0..<rows {
                for col in 0..<columns {
                    let index = row * columns + col
                    if index >= count { break }
                    
                    let x = Float(col) * (frameWidth + spacing) - Float(columns - 1) * (frameWidth + spacing) / 2
                    let y = Float(row) * (frameHeight + spacing) - Float(rows - 1) * (frameHeight + spacing) / 2
                    
                    positions.append(SIMD3<Float>(x, y, 0))
                }
            }
            
        case .horizontal(let spacing):
            let frameWidth: Float = 0.5
            let totalWidth = Float(count - 1) * (frameWidth + spacing)
            
            for i in 0..<count {
                let x = Float(i) * (frameWidth + spacing) - totalWidth / 2
                positions.append(SIMD3<Float>(x, 0, 0))
            }
            
        case .vertical(let spacing):
            let frameHeight: Float = 0.6
            let totalHeight = Float(count - 1) * (frameHeight + spacing)
            
            for i in 0..<count {
                let y = Float(i) * (frameHeight + spacing) - totalHeight / 2
                positions.append(SIMD3<Float>(0, y, 0))
            }
            
        case .custom(let customPositions):
            positions = customPositions
        }
        
        return positions
    }
    
    private func getGalleryId(from gallery: SCNNode) -> UUID? {
        guard let name = gallery.name,
              name.contains("photoGallery_"),
              let idString = name.components(separatedBy: "_").last,
              let uuid = UUID(uuidString: idString) else {
            return nil
        }
        return uuid
    }
    
    func registerGallery(_ galleryNode: SCNNode) -> UUID {
        let id = UUID()
        galleryNodes[id] = galleryNode
        currentGalleryIndex[id] = 0
        return id
    }
    
    func removeGallery(_ galleryId: UUID) {
        galleryNodes[galleryId]?.removeFromParentNode()
        galleryNodes.removeValue(forKey: galleryId)
        currentGalleryIndex.removeValue(forKey: galleryId)
    }
}










