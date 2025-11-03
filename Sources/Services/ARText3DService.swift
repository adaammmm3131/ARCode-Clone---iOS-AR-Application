//
//  ARText3DService.swift
//  ARCodeClone
//
//  Service pour création texte 3D avec SCNText, extrusion, matériaux
//

import Foundation
import ARKit
import SceneKit
import UIKit

protocol ARText3DServiceProtocol {
    func createText3D(text: String, font: UIFont, depth: CGFloat, color: UIColor) -> SCNNode
    func applyMaterial(to node: SCNNode, materialType: TextMaterialType, color: UIColor, texture: UIImage?)
    func updateText(_ node: SCNNode, newText: String, font: UIFont)
    func updateDepth(_ node: SCNNode, newDepth: CGFloat)
    func createPreview(textNode: SCNNode, size: CGSize) -> UIImage?
}

enum TextMaterialType {
    case matte
    case glossy
    case metallic
    case custom(texture: UIImage?)
}

enum ARText3DError: LocalizedError {
    case invalidText
    case fontLoadFailed
    case nodeUpdateFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidText:
            return "Texte invalide"
        case .fontLoadFailed:
            return "Échec chargement police"
        case .nodeUpdateFailed:
            return "Échec mise à jour nœud"
        }
    }
}

final class ARText3DService: ARText3DServiceProtocol {
    private var textNodes: [UUID: SCNNode] = [:]
    
    // MARK: - Text Creation
    
    func createText3D(text: String, font: UIFont, depth: CGFloat, color: UIColor) -> SCNNode {
        // Créer géométrie texte 3D avec SCNText
        let textGeometry = SCNText(string: text, extrusionDepth: depth)
        
        // Configuration police
        textGeometry.font = font
        textGeometry.flatness = 0.6 // Qualité courbes (plus bas = meilleure qualité)
        
        // Configuration extrusion
        textGeometry.chamferRadius = 0.01 // Arrondi bords (optionnel)
        textGeometry.chamferProfile = nil // Profil arrondi par défaut
        
        // Créer matériau par défaut (sera remplacé par applyMaterial)
        let material = SCNMaterial()
        material.diffuse.contents = color
        textGeometry.materials = [material]
        
        // Créer node
        let textNode = SCNNode(geometry: textGeometry)
        
        // Centrer le texte (SCNText place l'origine en bas à gauche)
        let (min, max) = textGeometry.boundingBox
        let dx = (max.x - min.x) / 2 + min.x
        let dy = (max.y - min.y) / 2 + min.y
        let dz = (max.z - min.z) / 2 + min.z
        textNode.pivot = SCNMatrix4MakeTranslation(-dx, -dy, -dz)
        
        textNode.name = "text3D_\(UUID().uuidString)"
        
        return textNode
    }
    
    // MARK: - Material Application
    
    func applyMaterial(to node: SCNNode, materialType: TextMaterialType, color: UIColor, texture: UIImage?) {
        guard let geometry = node.geometry as? SCNText else { return }
        
        let material = SCNMaterial()
        
        switch materialType {
        case .matte:
            // Matériau mat (pas de réflexion)
            material.diffuse.contents = color
            material.lightingModel = .lambert
            material.metalness.contents = 0.0
            material.roughness.contents = 1.0
            
        case .glossy:
            // Matériau brillant (réflexions)
            material.diffuse.contents = color
            material.lightingModel = .physicallyBased
            material.metalness.contents = 0.0
            material.roughness.contents = 0.1 // Très lisse
            
        case .metallic:
            // Matériau métallique
            material.diffuse.contents = color
            material.lightingModel = .physicallyBased
            material.metalness.contents = 1.0
            material.roughness.contents = 0.2
            
        case .custom(let customTexture):
            // Matériau personnalisé avec texture
            if let texture = customTexture {
                material.diffuse.contents = texture
            } else {
                material.diffuse.contents = color
            }
            material.lightingModel = .physicallyBased
            material.metalness.contents = 0.5
            material.roughness.contents = 0.5
        }
        
        // Appliquer matériau aux faces (front, back, sides, chamfer)
        geometry.materials = [material, material, material, material, material]
        // Indices: 0=front, 1=back, 2=sides, 3=chamfer front, 4=chamfer back
    }
    
    // MARK: - Text Update
    
    func updateText(_ node: SCNNode, newText: String, font: UIFont) {
        guard let geometry = node.geometry as? SCNText else { return }
        
        // Mettre à jour texte
        geometry.string = newText
        geometry.font = font
        
        // Recalculer pivot pour centrer
        let (min, max) = geometry.boundingBox
        let dx = (max.x - min.x) / 2 + min.x
        let dy = (max.y - min.y) / 2 + min.y
        let dz = (max.z - min.z) / 2 + min.z
        node.pivot = SCNMatrix4MakeTranslation(-dx, -dy, -dz)
    }
    
    func updateDepth(_ node: SCNNode, newDepth: CGFloat) {
        guard let geometry = node.geometry as? SCNText else { return }
        geometry.extrusionDepth = newDepth
    }
    
    // MARK: - Preview Generation
    
    func createPreview(textNode: SCNNode, size: CGSize) -> UIImage? {
        // Créer scène temporaire pour preview
        let scene = SCNScene()
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 5)
        scene.rootNode.addChildNode(cameraNode)
        
        // Ajouter texte à scène
        let previewTextNode = textNode.clone()
        previewTextNode.position = SCNVector3Zero
        scene.rootNode.addChildNode(previewTextNode)
        
        // Créer vue SceneKit pour snapshot
        #if canImport(Metal)
        if let device = MTLCreateSystemDefaultDevice() {
            let renderer = SCNRenderer(device: device, options: nil)
            renderer.scene = scene
            renderer.pointOfView = cameraNode
            
            // Renderer image
            let image = renderer.snapshot(atTime: 0, with: size, antialiasingMode: .multisampling4X)
            return image
        }
        #endif
        
        // Fallback: créer image simple
        return nil
    }
    
    // MARK: - Helper Methods
    
    func registerTextNode(_ node: SCNNode) -> UUID {
        let id = UUID()
        textNodes[id] = node
        return id
    }
    
    func removeTextNode(_ nodeId: UUID) {
        textNodes[nodeId]?.removeFromParentNode()
        textNodes.removeValue(forKey: nodeId)
    }
}

#if canImport(Metal)
import Metal
#endif

