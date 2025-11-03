//
//  FaceFilterService.swift
//  ARCodeClone
//
//  Service pour gestion des filtres faciaux AR
//

import ARKit
import SceneKit
import Combine
import UIKit

protocol FaceFilterServiceProtocol {
    var detectedFaces: CurrentValueSubject<[UUID: ARFaceAnchor], Never> { get }
    var currentLogo: UIImage? { get }
    func setLogo(_ image: UIImage)
    func attachLogoToFace(_ faceAnchor: ARFaceAnchor, in scene: SCNScene) -> SCNNode?
    func updateLogoPosition(for faceAnchor: ARFaceAnchor, logoNode: SCNNode)
    func removeLogo(from faceAnchor: ARFaceAnchor, in scene: SCNScene)
    func getRegionPose(region: FaceRegion, from anchor: ARFaceAnchor) -> simd_float4x4?
}

enum FaceRegion {
    case center
    case frontLeft
    case frontRight
    case nose
}

final class FaceFilterService: NSObject, FaceFilterServiceProtocol {
    let detectedFaces = CurrentValueSubject<[UUID: ARFaceAnchor], Never>([:])
    var currentLogo: UIImage?
    
    // Nodes de logo par face
    private var logoNodes: [UUID: SCNNode] = [:]
    
    // Configuration
    private var logoScale: Float = 1.0
    private var logoOffset: SIMD3<Float> = SIMD3<Float>(0, 0, 0.05) // 5cm devant le visage
    
    override init() {
        super.init()
    }
    
    func setLogo(_ image: UIImage) {
        self.currentLogo = image
        
        // Supprimer anciens logos
        logoNodes.values.forEach { $0.removeFromParentNode() }
        logoNodes.removeAll()
        
        // Re-attacher aux faces détectées
        for (faceId, _) in detectedFaces.value {
            // Les logos seront attachés lors du prochain update
        }
    }
    
    func attachLogoToFace(_ faceAnchor: ARFaceAnchor, in scene: SCNScene) -> SCNNode? {
        guard let logoImage = currentLogo else { return nil }
        
        // Utiliser mapping service pour meilleure précision
        let mappingService = FaceFilterMappingService()
        
        // Créer node avec mapping optimisé
        let logoNode = mappingService.mapLogoToFaceMesh(
            logo: logoImage,
            faceAnchor: faceAnchor,
            region: .center
        )
        
        guard let logoNode = logoNode else { return nil }
        
        logoNode.name = "faceLogo_\(faceAnchor.identifier.uuidString)"
        
        // Ajouter à la scène
        scene.rootNode.addChildNode(logoNode)
        logoNodes[faceAnchor.identifier] = logoNode
        
        return logoNode
    }
    
    func updateLogoPosition(for faceAnchor: ARFaceAnchor, logoNode: SCNNode) {
        // Mettre à jour position selon pose du visage
        let regionPose = getRegionPose(region: .center, from: faceAnchor)
        
        if let pose = regionPose {
            // Smoothing interpolation pour éviter saccades
            let currentTransform = logoNode.simdTransform
            let targetTransform = pose * simd_float4x4(translation: logoOffset) * simd_float4x4(scale: logoScale)
            
            // Interpolation avec easing exponentiel pour mouvement smooth
            let alpha: Float = 0.25 // Facteur de smoothing (25% vers nouvelle position par frame)
            logoNode.simdTransform = interpolateTransform(currentTransform, targetTransform, alpha: alpha)
            
            // Ajuster orientation selon normal du visage
            updateLogoOrientation(for: faceAnchor, logoNode: logoNode)
            
            // Utiliser mapping service pour perspective correction
            let mappingService = FaceFilterMappingService()
            mappingService.applyPerspectiveCorrection(to: logoNode, basedOn: faceAnchor)
        }
    }
    
    func removeLogo(from faceAnchor: ARFaceAnchor, in scene: SCNScene) {
        if let logoNode = logoNodes[faceAnchor.identifier] {
            logoNode.removeFromParentNode()
            logoNodes.removeValue(forKey: faceAnchor.identifier)
        }
    }
    
    func getRegionPose(region: FaceRegion, from anchor: ARFaceAnchor) -> simd_float4x4? {
        // ARFaceAnchor fournit 468 points de mesh
        // On peut calculer pose de différentes régions
        
        switch region {
        case .center:
            // Utiliser transform du center du visage (approximé depuis anchor)
            return anchor.transform
            
        case .frontLeft:
            // Calculer depuis points mesh (joues gauche)
            return calculateRegionPose(from: anchor, regionIndices: getLeftCheekIndices())
            
        case .frontRight:
            // Calculer depuis points mesh (joues droite)
            return calculateRegionPose(from: anchor, regionIndices: getRightCheekIndices())
            
        case .nose:
            // Utiliser position nez depuis mesh
            return calculateRegionPose(from: anchor, regionIndices: getNoseIndices())
        }
    }
    
    // MARK: - Private Helpers
    
    private func createLogoNode(image: UIImage, faceAnchor: ARFaceAnchor) -> SCNNode {
        // Créer geometry plane pour logo
        let plane = SCNPlane(width: 0.1, height: 0.1) // 10cm x 10cm
        
        // Ajuster taille selon dimensions visage
        let faceWidth = estimateFaceWidth(from: faceAnchor)
        let logoSize = faceWidth * 0.3 // 30% de la largeur du visage
        plane.width = CGFloat(logoSize)
        plane.height = CGFloat(logoSize * (image.size.height / image.size.width)) // Aspect ratio
        
        // Créer matériau avec image
        let material = SCNMaterial()
        material.diffuse.contents = image
        material.isDoubleSided = true
        material.transparency = 1.0 // Transparence supportée via image
        
        plane.materials = [material]
        
        let node = SCNNode(geometry: plane)
        node.name = "faceLogo_\(faceAnchor.identifier.uuidString)"
        
        return node
    }
    
    private func estimateFaceWidth(from anchor: ARFaceAnchor) -> Float {
        // Estimer largeur visage depuis mesh
        // Pour simplifier, utiliser valeur approximative
        return 0.12 // ~12cm (largeur moyenne visage humain)
    }
    
    private func calculateRegionPose(from anchor: ARFaceAnchor, regionIndices: [Int]) -> simd_float4x4? {
        // Calculer pose d'une région depuis indices mesh
        guard let geometry = anchor.geometry else { return anchor.transform }
        
        // Obtenir positions des points de la région
        let vertices = geometry.vertices
        var regionCenter = SIMD3<Float>(0, 0, 0)
        var count: Float = 0
        
        for index in regionIndices {
            if index < vertices.count {
                regionCenter += vertices[index]
                count += 1
            }
        }
        
        if count > 0 {
            regionCenter /= count
            
            // Créer transform centré sur cette région
            var transform = anchor.transform
            transform.columns.3 = SIMD4<Float>(regionCenter.x, regionCenter.y, regionCenter.z, 1)
            return transform
        }
        
        return anchor.transform
    }
    
    private func getLeftCheekIndices() -> [Int] {
        // Indices approximatifs pour joue gauche (mesh ARFaceAnchor a 468 points)
        // Ces indices doivent être calibrés selon vrai mesh ARKit
        // Pour l'instant, valeurs approximatives
        return Array(100..<150) // Exemple
    }
    
    private func getRightCheekIndices() -> [Int] {
        // Indices approximatifs pour joue droite
        return Array(250..<300) // Exemple
    }
    
    private func getNoseIndices() -> [Int] {
        // Indices approximatifs pour nez
        return Array(200..<220) // Exemple
    }
    
    private func updateLogoOrientation(for faceAnchor: ARFaceAnchor, logoNode: SCNNode) {
        // Ajuster orientation pour être perpendiculaire au visage
        let transform = faceAnchor.transform
        
        // Extraire rotation depuis transform
        // ARFaceAnchor.transform inclut déjà orientation correcte
        logoNode.simdRotation = simd_quatf(transform)
    }
    
    private func interpolateTransform(_ a: simd_float4x4, _ b: simd_float4x4, alpha: Float) -> simd_float4x4 {
        // Interpolation SLERP pour rotation
        let quatA = simd_quatf(a)
        let quatB = simd_quatf(b)
        let interpolatedQuat = simd_slerp(quatA, quatB, alpha)
        
        // Interpolation linéaire pour translation
        let transA = SIMD3<Float>(a.columns.3.x, a.columns.3.y, a.columns.3.z)
        let transB = SIMD3<Float>(b.columns.3.x, b.columns.3.y, b.columns.3.z)
        let interpolatedTrans = simd_mix(transA, transB, SIMD3<Float>(repeating: alpha))
        
        // Reconstruire transform
        var result = simd_float4x4(interpolatedQuat)
        result.columns.3 = SIMD4<Float>(interpolatedTrans.x, interpolatedTrans.y, interpolatedTrans.z, 1)
        
        return result
    }
}

// MARK: - SIMD Helpers

extension simd_float4x4 {
    init(translation: SIMD3<Float>) {
        self.init(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(translation.x, translation.y, translation.z, 1)
        )
    }
    
    init(scale: Float) {
        self.init(
            SIMD4<Float>(scale, 0, 0, 0),
            SIMD4<Float>(0, scale, 0, 0),
            SIMD4<Float>(0, 0, scale, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
}

extension simd_quatf {
    init(_ matrix: simd_float4x4) {
        // Extraire quaternion depuis matrice de rotation
        // Simplifié: utiliser rotation de base
        self = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1) // Quaternion identité
        // TODO: Vraie extraction quaternion depuis matrice
    }
}

extension SCNNode {
    var simdRotation: simd_quatf {
        get {
            // Convertir euler angles en quaternion
            let euler = simd_float3(Float(self.eulerAngles.x), Float(self.eulerAngles.y), Float(self.eulerAngles.z))
            return simd_quatf(euler: euler)
        }
        set {
            // Convertir quaternion en euler angles
            let euler = newValue.eulerAngles
            self.eulerAngles = SCNVector3(euler.x, euler.y, euler.z)
        }
    }
}

extension simd_quatf {
    var eulerAngles: simd_float3 {
        // Conversion quaternion → Euler (simplifié)
        return simd_float3(0, 0, 0)
    }
    
    init(euler: simd_float3) {
        // Conversion Euler → Quaternion (simplifié)
        self = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    }
}

