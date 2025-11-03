//
//  FaceFilterMappingService.swift
//  ARCodeClone
//
//  Service pour mapping logo sur face mesh avec perspective correction
//

import ARKit
import SceneKit
import UIKit

protocol FaceFilterMappingServiceProtocol {
    func mapLogoToFaceMesh(
        logo: UIImage,
        faceAnchor: ARFaceAnchor,
        region: FaceRegion
    ) -> SCNNode?
    
    func applyPerspectiveCorrection(
        to node: SCNNode,
        basedOn faceAnchor: ARFaceAnchor
    )
    
    func calculateFaceDimensions(from anchor: ARFaceAnchor) -> FaceDimensions
    func adjustLogoScale(
        logoSize: CGSize,
        faceDimensions: FaceDimensions,
        targetScale: Float
    ) -> Float
}

struct FaceDimensions {
    let width: Float
    let height: Float
    let depth: Float
}

final class FaceFilterMappingService: FaceFilterMappingServiceProtocol {
    
    func mapLogoToFaceMesh(
        logo: UIImage,
        faceAnchor: ARFaceAnchor,
        region: FaceRegion
    ) -> SCNNode? {
        // Créer plane pour logo
        let faceDims = calculateFaceDimensions(from: faceAnchor)
        let logoScale = adjustLogoScale(
            logoSize: logo.size,
            faceDimensions: faceDims,
            targetScale: 0.3 // 30% de largeur visage
        )
        
        let plane = SCNPlane(
            width: CGFloat(faceDims.width * logoScale),
            height: CGFloat(faceDims.height * logoScale * Float(logo.size.height / logo.size.width))
        )
        
        // Matériau avec image
        let material = SCNMaterial()
        material.diffuse.contents = logo
        material.isDoubleSided = true
        
        plane.materials = [material]
        let node = SCNNode(geometry: plane)
        
        // Positionner selon région
        positionNode(node, for: region, faceAnchor: faceAnchor)
        
        // Appliquer correction perspective
        applyPerspectiveCorrection(to: node, basedOn: faceAnchor)
        
        return node
    }
    
    func applyPerspectiveCorrection(
        to node: SCNNode,
        basedOn faceAnchor: ARFaceAnchor
    ) {
        // Calculer normal du visage
        let faceNormal = calculateFaceNormal(from: faceAnchor)
        
        // Orienter node perpendiculaire au visage
        // Utiliser transform du visage comme base
        node.simdTransform = faceAnchor.transform
        
        // Ajuster selon normal
        // TODO: Implémentation complète correction perspective 3D
    }
    
    func calculateFaceDimensions(from anchor: ARFaceAnchor) -> FaceDimensions {
        guard let geometry = anchor.geometry else {
            // Valeurs par défaut
            return FaceDimensions(width: 0.12, height: 0.15, depth: 0.08)
        }
        
        let vertices = geometry.vertices
        
        // Calculer bounding box
        var minX: Float = Float.greatestFiniteMagnitude
        var maxX: Float = -Float.greatestFiniteMagnitude
        var minY: Float = Float.greatestFiniteMagnitude
        var maxY: Float = -Float.greatestFiniteMagnitude
        var minZ: Float = Float.greatestFiniteMagnitude
        var maxZ: Float = -Float.greatestFiniteMagnitude
        
        for vertex in vertices {
            minX = min(minX, vertex.x)
            maxX = max(maxX, vertex.x)
            minY = min(minY, vertex.y)
            maxY = max(maxY, vertex.y)
            minZ = min(minZ, vertex.z)
            maxZ = max(maxZ, vertex.z)
        }
        
        return FaceDimensions(
            width: abs(maxX - minX),
            height: abs(maxY - minY),
            depth: abs(maxZ - minZ)
        )
    }
    
    func adjustLogoScale(
        logoSize: CGSize,
        faceDimensions: FaceDimensions,
        targetScale: Float
    ) -> Float {
        // Calculer scale pour que logo soit targetScale% de la largeur du visage
        let targetWidth = faceDimensions.width * targetScale
        let logoAspectRatio = Float(logoSize.width / logoSize.height)
        
        // S'assurer que logo ne dépasse pas dimensions visage
        let maxScale = min(
            targetWidth / Float(logoSize.width),
            faceDimensions.height * targetScale / Float(logoSize.height)
        )
        
        return maxScale
    }
    
    // MARK: - Private Helpers
    
    private func positionNode(
        _ node: SCNNode,
        for region: FaceRegion,
        faceAnchor: ARFaceAnchor
    ) {
        let faceDims = calculateFaceDimensions(from: faceAnchor)
        
        switch region {
        case .center:
            // Position au centre du visage
            let centerOffset = SIMD3<Float>(0, 0, faceDims.depth * 0.5)
            node.simdPosition = simd_mul(faceAnchor.transform, simd_float4(centerOffset, 1)).xyz
            
        case .frontLeft:
            let leftOffset = SIMD3<Float>(-faceDims.width * 0.2, 0, faceDims.depth * 0.5)
            node.simdPosition = simd_mul(faceAnchor.transform, simd_float4(leftOffset, 1)).xyz
            
        case .frontRight:
            let rightOffset = SIMD3<Float>(faceDims.width * 0.2, 0, faceDims.depth * 0.5)
            node.simdPosition = simd_mul(faceAnchor.transform, simd_float4(rightOffset, 1)).xyz
            
        case .nose:
            let noseOffset = SIMD3<Float>(0, faceDims.height * 0.1, faceDims.depth * 0.3)
            node.simdPosition = simd_mul(faceAnchor.transform, simd_float4(noseOffset, 1)).xyz
        }
    }
    
    private func calculateFaceNormal(from anchor: ARFaceAnchor) -> SIMD3<Float> {
        // Calculer normal depuis mesh (approximation)
        // Pour l'instant, utiliser direction -Z de transform (face regarde caméra)
        let transform = anchor.transform
        let normal = SIMD3<Float>(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z)
        return normalize(normal)
    }
}

// MARK: - SIMD Helpers

extension simd_float4x4 {
    func multiply(_ vector: simd_float4) -> simd_float4 {
        return self * vector
    }
}

func simd_mul(_ matrix: simd_float4x4, _ vector: simd_float4) -> simd_float4 {
    return matrix * vector
}

extension simd_float4 {
    var xyz: SIMD3<Float> {
        return SIMD3<Float>(x, y, z)
    }
}

func normalize(_ vector: SIMD3<Float>) -> SIMD3<Float> {
    let length = simd_length(vector)
    guard length > 0 else { return SIMD3<Float>(0, 0, 1) }
    return vector / length
}










