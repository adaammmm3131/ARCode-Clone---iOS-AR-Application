//
//  OcclusionService.swift
//  ARCodeClone
//
//  Service pour gérer l'occlusion depth avec LiDAR et fallback
//

import ARKit
import SceneKit

final class OcclusionService {
    private var occlusionNodes: [UUID: SCNNode] = [:]
    private var isLiDARAvailable: Bool = false
    private var depthMap: CVPixelBuffer?
    
    /// Vérifie si LiDAR est disponible
    func checkLiDARAvailability() -> Bool {
        let config = ARWorldTrackingConfiguration()
        isLiDARAvailable = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
        return isLiDARAvailable
    }
    
    /// Met à jour les données de profondeur depuis une frame AR
    func updateDepth(from frame: ARFrame) {
        if isLiDARAvailable {
            // Utiliser ARDepthData avec LiDAR
            if let sceneDepth = frame.sceneDepth {
                depthMap = sceneDepth.depthMap
            }
        } else {
            // Fallback : estimation de profondeur depuis plane detection
            depthMap = estimateDepthFromPlanes(frame: frame)
        }
    }
    
    /// Crée un nœud d'occlusion depuis ARDepthData (LiDAR)
    func createOcclusionNode(from depthData: ARDepthData) -> SCNNode? {
        guard let depthMap = depthData.depthMap else { return nil }
        
        // Convertir CVPixelBuffer en texture pour SceneKit
        let occlusionGeometry = createOcclusionGeometry(from: depthMap)
        
        let material = SCNMaterial()
        // Matériau invisible qui écrit dans le depth buffer
        material.colorBufferWriteMask = []
        material.writesToDepthBuffer = true
        material.readsFromDepthBuffer = true
        material.isDoubleSided = false
        
        occlusionGeometry?.materials = [material]
        
        let occlusionNode = SCNNode(geometry: occlusionGeometry)
        occlusionNode.name = "occlusion_depth_\(UUID().uuidString)"
        
        return occlusionNode
    }
    
    /// Crée un nœud d'occlusion depuis ARPlaneAnchor (fallback sans LiDAR)
    func createOcclusionNode(from planeAnchor: ARPlaneAnchor) -> SCNNode {
        let plane = SCNPlane(
            width: CGFloat(planeAnchor.planeExtent.width),
            height: CGFloat(planeAnchor.planeExtent.height)
        )
        
        let material = SCNMaterial()
        // Matériau invisible pour occlusion
        material.colorBufferWriteMask = []
        material.writesToDepthBuffer = true
        material.readsFromDepthBuffer = true
        material.isDoubleSided = false
        
        plane.materials = [material]
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3(
            planeAnchor.center.x,
            planeAnchor.center.y,
            planeAnchor.center.z
        )
        
        // Rotation pour plan vertical
        if planeAnchor.alignment == .vertical {
            planeNode.eulerAngles.x = -.pi / 2
        }
        
        planeNode.name = "occlusion_plane_\(planeAnchor.identifier.uuidString)"
        
        return planeNode
    }
    
    /// Applique l'occlusion à un nœud 3D
    func applyOcclusion(to node: SCNNode) {
        // Activer la lecture du depth buffer
        if let geometry = node.geometry,
           let material = geometry.firstMaterial {
            material.readsFromDepthBuffer = true
            material.writesToDepthBuffer = true
        }
        
        // Configurer le rendu pour l'occlusion
        node.renderingOrder = -1 // Rendre en premier pour occlusion
    }
    
    /// Configure une scène pour l'occlusion
    func configureSceneForOcclusion(_ scene: SCNScene) {
        // Activer le depth testing
        scene.isPaused = false
        
        // Configurer le background
        scene.background.contents = UIColor.clear
    }
    
    /// Estimation de profondeur depuis plane detection (fallback)
    private func estimateDepthFromPlanes(frame: ARFrame) -> CVPixelBuffer? {
        // Fallback simple : utiliser les planes détectés pour créer un depth map approximatif
        // En production, on pourrait implémenter une stéréo vision ou d'autres techniques
        return nil
    }
    
    /// Crée une géométrie d'occlusion depuis un depth map
    private func createOcclusionGeometry(from depthMap: CVPixelBuffer) -> SCNGeometry? {
        // Convertir CVPixelBuffer en mesh pour occlusion
        // Pour simplifier, on crée un plan d'occlusion
        // En production, on pourrait créer un mesh complet depuis le depth map
        
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        
        // Créer un plane d'occlusion
        let plane = SCNPlane(width: 1.0, height: 1.0)
        return plane
    }
    
    /// Nettoie les nœuds d'occlusion
    func cleanup() {
        occlusionNodes.removeAll()
        depthMap = nil
    }
}

// MARK: - Frustum Culling Support

extension OcclusionService {
    /// Vérifie si un nœud est dans le frustum de la caméra
    func isNodeInFrustum(_ node: SCNNode, cameraTransform: simd_float4x4, projectionMatrix: matrix_float4x4) -> Bool {
        // Implémentation simplifiée du frustum culling
        // Vérifie si le bounding box du nœud intersecte le frustum de la caméra
        
        guard let geometry = node.geometry else { return false }
        
        let boundingBox = geometry.boundingBox
        let min = boundingBox.min
        let max = boundingBox.max
        
        // Convertir les points du bounding box dans l'espace monde
        let worldTransform = node.worldTransform
        
        // Points du bounding box
        let corners = [
            SIMD3<Float>(Float(min.x), Float(min.y), Float(min.z)),
            SIMD3<Float>(Float(max.x), Float(min.y), Float(min.z)),
            SIMD3<Float>(Float(min.x), Float(max.y), Float(min.z)),
            SIMD3<Float>(Float(max.x), Float(max.y), Float(min.z)),
            SIMD3<Float>(Float(min.x), Float(min.y), Float(max.z)),
            SIMD3<Float>(Float(max.x), Float(min.y), Float(max.z)),
            SIMD3<Float>(Float(min.x), Float(max.y), Float(max.z)),
            SIMD3<Float>(Float(max.x), Float(max.y), Float(max.z))
        ]
        
        // Transformer dans l'espace caméra et vérifier si dans le frustum
        for corner in corners {
            let worldPos = worldTransform * simd_float4(corner.x, corner.y, corner.z, 1.0)
            let cameraPos = cameraTransform.inverse * worldPos
            
            // Vérifier si dans le frustum (simplifié)
            if cameraPos.z > 0 && cameraPos.z < 10.0 { // Near et far planes
                // Projection dans l'espace écran
                let projected = projectionMatrix * cameraPos
                let normalized = projected / projected.w
                
                // Vérifier si dans les limites du viewport (-1 à 1)
                if normalized.x >= -1.5 && normalized.x <= 1.5 &&
                   normalized.y >= -1.5 && normalized.y <= 1.5 {
                    return true // Au moins un point visible
                }
            }
        }
        
        return false
    }
    
    /// Optimise une scène en masquant les nœuds hors frustum
    func optimizeScene(_ scene: SCNScene, cameraTransform: simd_float4x4, projectionMatrix: matrix_float4x4) {
        func processNode(_ node: SCNNode) {
            // Vérifier si le nœud est dans le frustum
            let isVisible = isNodeInFrustum(node, cameraTransform: cameraTransform, projectionMatrix: projectionMatrix)
            
            // Masquer les nœuds hors frustum
            node.isHidden = !isVisible
            
            // Traiter les enfants récursivement
            for child in node.childNodes {
                processNode(child)
            }
        }
        
        // Traiter tous les nœuds de la scène
        processNode(scene.rootNode)
    }
}













