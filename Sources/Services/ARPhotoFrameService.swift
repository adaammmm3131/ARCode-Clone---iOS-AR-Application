//
//  ARPhotoFrameService.swift
//  ARCodeClone
//
//  Service pour création frames photo 3D personnalisables
//

import Foundation
import ARKit
import SceneKit
import UIKit

protocol ARPhotoFrameServiceProtocol {
    func createFrame(style: FrameStyle, size: CGSize, image: UIImage) -> SCNNode
    func updateImage(in frameNode: SCNNode, newImage: UIImage)
    func resizeFrame(_ frameNode: SCNNode, newSize: CGSize)
    func getFrameStyles() -> [FrameStyle]
}

enum FrameStyle: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case modern = "Modern"
    case ornate = "Ornate"
    case minimal = "Minimal"
    case vintage = "Vintage"
    case wood = "Wood"
    case metal = "Metal"
    case gold = "Gold"
    
    var id: String { self.rawValue }
}

enum ARPhotoFrameError: LocalizedError {
    case invalidImage
    case frameCreationFailed
    case imageUpdateFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Image invalide"
        case .frameCreationFailed:
            return "Échec création frame"
        case .imageUpdateFailed:
            return "Échec mise à jour image"
        }
    }
}

final class ARPhotoFrameService: ARPhotoFrameServiceProtocol {
    private var frameNodes: [UUID: SCNNode] = [:]
    
    // MARK: - Frame Creation
    
    func createFrame(style: FrameStyle, size: CGSize, image: UIImage) -> SCNNode {
        // Créer container node pour frame + photo
        let containerNode = SCNNode()
        containerNode.name = "photoFrame_\(UUID().uuidString)"
        
        // Créer frame 3D selon style
        let frameNode = createFrameGeometry(style: style, size: size)
        containerNode.addChildNode(frameNode)
        
        // Créer photo plane
        let photoNode = createPhotoPlane(size: size, image: image)
        containerNode.addChildNode(photoNode)
        
        return containerNode
    }
    
    // MARK: - Frame Geometry Creation
    
    private func createFrameGeometry(style: FrameStyle, size: CGSize) -> SCNNode {
        let frameWidth: CGFloat = 0.05 // 5cm épaisseur frame
        let frameDepth: CGFloat = 0.01 // 1cm profondeur frame
        
        let frameNode = SCNNode()
        
        switch style {
        case .classic:
            // Frame classique avec bords arrondis
            return createClassicFrame(size: size, width: frameWidth, depth: frameDepth)
            
        case .modern:
            // Frame moderne mince et élégant
            return createModernFrame(size: size, width: frameWidth, depth: frameDepth)
            
        case .ornate:
            // Frame orné avec détails décoratifs
            return createOrnateFrame(size: size, width: frameWidth, depth: frameDepth)
            
        case .minimal:
            // Frame minimal sans bordure visible
            return createMinimalFrame(size: size, width: frameWidth, depth: frameDepth)
            
        case .vintage:
            // Frame vintage avec texture vieillie
            return createVintageFrame(size: size, width: frameWidth, depth: frameDepth)
            
        case .wood:
            // Frame en bois avec texture grain
            return createWoodFrame(size: size, width: frameWidth, depth: frameDepth)
            
        case .metal:
            // Frame métallique brillant
            return createMetalFrame(size: size, width: frameWidth, depth: frameDepth)
            
        case .gold:
            // Frame doré
            return createGoldFrame(size: size, width: frameWidth, depth: frameDepth)
        }
    }
    
    private func createClassicFrame(size: CGSize, width: CGFloat, depth: CGFloat) -> SCNNode {
        let frameNode = SCNNode()
        
        // Frame externe (bordure)
        let outerSize = CGSize(width: size.width + width * 2, height: size.height + width * 2)
        
        // Top border
        let topBox = SCNBox(width: outerSize.width, height: width, length: depth, chamferRadius: 0.005)
        topBox.chamferSegmentCount = 8
        let topMaterial = createFrameMaterial(color: UIColor.brown, style: .classic)
        topBox.materials = [topMaterial]
        
        let topNode = SCNNode(geometry: topBox)
        topNode.position = SCNVector3(0, size.height / 2 + width / 2, 0)
        frameNode.addChildNode(topNode)
        
        // Bottom border
        let bottomBox = SCNBox(width: outerSize.width, height: width, length: depth, chamferRadius: 0.005)
        bottomBox.materials = [topMaterial]
        let bottomNode = SCNNode(geometry: bottomBox)
        bottomNode.position = SCNVector3(0, -size.height / 2 - width / 2, 0)
        frameNode.addChildNode(bottomNode)
        
        // Left border
        let leftBox = SCNBox(width: width, height: size.height, length: depth, chamferRadius: 0.005)
        leftBox.materials = [topMaterial]
        let leftNode = SCNNode(geometry: leftBox)
        leftNode.position = SCNVector3(-size.width / 2 - width / 2, 0, 0)
        frameNode.addChildNode(leftNode)
        
        // Right border
        let rightBox = SCNBox(width: width, height: size.height, length: depth, chamferRadius: 0.005)
        rightBox.materials = [topMaterial]
        let rightNode = SCNNode(geometry: rightBox)
        rightNode.position = SCNVector3(size.width / 2 + width / 2, 0, 0)
        frameNode.addChildNode(rightNode)
        
        return frameNode
    }
    
    private func createModernFrame(size: CGSize, width: CGFloat, depth: CGFloat) -> SCNNode {
        let frameNode = SCNNode()
        let thinWidth = width * 0.5 // Frame plus mince
        
        // Créer frame mince moderne
        let frameMaterial = createFrameMaterial(color: UIColor.black, style: .modern)
        
        // Top
        let topBox = SCNBox(width: size.width + thinWidth * 2, height: thinWidth, length: depth, chamferRadius: 0.001)
        topBox.materials = [frameMaterial]
        let topNode = SCNNode(geometry: topBox)
        topNode.position = SCNVector3(0, size.height / 2 + thinWidth / 2, 0)
        frameNode.addChildNode(topNode)
        
        // Bottom, Left, Right (similaire)
        let bottomBox = SCNBox(width: size.width + thinWidth * 2, height: thinWidth, length: depth, chamferRadius: 0.001)
        bottomBox.materials = [frameMaterial]
        let bottomNode = SCNNode(geometry: bottomBox)
        bottomNode.position = SCNVector3(0, -size.height / 2 - thinWidth / 2, 0)
        frameNode.addChildNode(bottomNode)
        
        let leftBox = SCNBox(width: thinWidth, height: size.height, length: depth, chamferRadius: 0.001)
        leftBox.materials = [frameMaterial]
        let leftNode = SCNNode(geometry: leftBox)
        leftNode.position = SCNVector3(-size.width / 2 - thinWidth / 2, 0, 0)
        frameNode.addChildNode(leftNode)
        
        let rightBox = SCNBox(width: thinWidth, height: size.height, length: depth, chamferRadius: 0.001)
        rightBox.materials = [frameMaterial]
        let rightNode = SCNNode(geometry: rightBox)
        rightNode.position = SCNVector3(size.width / 2 + thinWidth / 2, 0, 0)
        frameNode.addChildNode(rightNode)
        
        return frameNode
    }
    
    private func createOrnateFrame(size: CGSize, width: CGFloat, depth: CGFloat) -> SCNNode {
        // Frame orné avec détails décoratifs
        let frameNode = createClassicFrame(size: size, width: width * 1.5, depth: depth * 1.2)
        
        // Ajouter décorations (corners)
        let decorationMaterial = createFrameMaterial(color: UIColor.gold, style: .ornate)
        
        // Corner decorations (simplifiées)
        for corner in [(1, 1), (1, -1), (-1, 1), (-1, -1)] {
            let cornerBox = SCNBox(width: width * 0.3, height: width * 0.3, length: depth * 0.5, chamferRadius: 0.01)
            cornerBox.materials = [decorationMaterial]
            let cornerNode = SCNNode(geometry: cornerBox)
            cornerNode.position = SCNVector3(
                Float(corner.0) * Float(size.width / 2 + width),
                Float(corner.1) * Float(size.height / 2 + width),
                0
            )
            frameNode.addChildNode(cornerNode)
        }
        
        return frameNode
    }
    
    private func createMinimalFrame(size: CGSize, width: CGFloat, depth: CGFloat) -> SCNNode {
        // Frame minimal (presque invisible)
        let frameNode = SCNNode()
        let minimalWidth = width * 0.1
        
        let frameMaterial = createFrameMaterial(color: UIColor.white.withAlphaComponent(0.3), style: .minimal)
        
        // Simple border
        let borderBox = SCNBox(width: size.width + minimalWidth * 2, height: size.height + minimalWidth * 2, length: depth, chamferRadius: 0)
        borderBox.materials = [frameMaterial]
        let borderNode = SCNNode(geometry: borderBox)
        frameNode.addChildNode(borderNode)
        
        return frameNode
    }
    
    private func createVintageFrame(size: CGSize, width: CGFloat, depth: CGFloat) -> SCNNode {
        let frameNode = createClassicFrame(size: size, width: width, depth: depth)
        
        // Appliquer texture vintage sur matériaux
        if let geometry = frameNode.geometry {
            let vintageMaterial = createFrameMaterial(color: UIColor(red: 0.6, green: 0.5, blue: 0.4, alpha: 1.0), style: .vintage)
            geometry.materials = [vintageMaterial]
        }
        
        return frameNode
    }
    
    private func createWoodFrame(size: CGSize, width: CGFloat, depth: CGFloat) -> SCNNode {
        let frameNode = createClassicFrame(size: size, width: width, depth: depth)
        let woodMaterial = createFrameMaterial(color: UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0), style: .wood)
        
        // Mettre à jour matériaux enfants
        frameNode.enumerateChildNodes { node, _ in
            if let geometry = node.geometry {
                geometry.materials = [woodMaterial]
            }
        }
        
        return frameNode
    }
    
    private func createMetalFrame(size: CGSize, width: CGFloat, depth: CGFloat) -> SCNNode {
        let frameNode = createModernFrame(size: size, width: width, depth: depth)
        let metalMaterial = createFrameMaterial(color: UIColor.gray, style: .metal)
        
        frameNode.enumerateChildNodes { node, _ in
            if let geometry = node.geometry {
                geometry.materials = [metalMaterial]
            }
        }
        
        return frameNode
    }
    
    private func createGoldFrame(size: CGSize, width: CGFloat, depth: CGFloat) -> SCNNode {
        let frameNode = createClassicFrame(size: size, width: width * 1.2, depth: depth)
        let goldMaterial = createFrameMaterial(color: UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0), style: .gold)
        
        frameNode.enumerateChildNodes { node, _ in
            if let geometry = node.geometry {
                geometry.materials = [goldMaterial]
            }
        }
        
        return frameNode
    }
    
    // MARK: - Photo Plane Creation
    
    private func createPhotoPlane(size: CGSize, image: UIImage) -> SCNNode {
        let photoPlane = SCNPlane(width: size.width, height: size.height)
        
        // Appliquer image comme texture
        let material = SCNMaterial()
        material.diffuse.contents = image
        material.isDoubleSided = false
        photoPlane.materials = [material]
        
        let photoNode = SCNNode(geometry: photoPlane)
        photoNode.name = "photoPlane"
        photoNode.position = SCNVector3(0, 0, 0.001) // Légèrement devant le frame
        
        return photoNode
    }
    
    // MARK: - Material Creation
    
    private func createFrameMaterial(color: UIColor, style: FrameStyle) -> SCNMaterial {
        let material = SCNMaterial()
        
        switch style {
        case .classic, .ornate, .vintage:
            material.diffuse.contents = color
            material.lightingModel = .lambert
            material.roughness.contents = 0.6
            
        case .modern, .minimal:
            material.diffuse.contents = color
            material.lightingModel = .constant
            material.roughness.contents = 0.3
            
        case .wood:
            material.diffuse.contents = color
            material.lightingModel = .physicallyBased
            material.roughness.contents = 0.8
            material.metalness.contents = 0.0
            
        case .metal:
            material.diffuse.contents = color
            material.lightingModel = .physicallyBased
            material.roughness.contents = 0.2
            material.metalness.contents = 1.0
            
        case .gold:
            material.diffuse.contents = color
            material.lightingModel = .physicallyBased
            material.roughness.contents = 0.1
            material.metalness.contents = 0.9
            material.emission.contents = UIColor.yellow.withAlphaComponent(0.1)
        }
        
        return material
    }
    
    // MARK: - Frame Updates
    
    func updateImage(in frameNode: SCNNode, newImage: UIImage) {
        frameNode.enumerateChildNodes { node, _ in
            if node.name == "photoPlane",
               let geometry = node.geometry as? SCNPlane,
               let material = geometry.materials.first {
                material.diffuse.contents = newImage
            }
        }
    }
    
    func resizeFrame(_ frameNode: SCNNode, newSize: CGSize) {
        // Mettre à jour taille frame et photo
        frameNode.enumerateChildNodes { node, _ in
            if let frameGeometry = node.geometry as? SCNBox {
                // Ajuster frame selon nouvelle taille
                // Note: Simplifié, nécessiterait recalcul complet
            } else if let photoGeometry = node.geometry as? SCNPlane {
                photoGeometry.width = newSize.width
                photoGeometry.height = newSize.height
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func getFrameStyles() -> [FrameStyle] {
        return FrameStyle.allCases
    }
    
    func registerFrame(_ frameNode: SCNNode) -> UUID {
        let id = UUID()
        frameNodes[id] = frameNode
        return id
    }
    
    func removeFrame(_ frameId: UUID) {
        frameNodes[frameId]?.removeFromParentNode()
        frameNodes.removeValue(forKey: frameId)
    }
}










