//
//  ARPortalService.swift
//  ARCodeClone
//
//  Service pour création et gestion AR Portal avec projection sphere 360°
//

import Foundation
import ARKit
import SceneKit
import UIKit
import AVFoundation

protocol ARPortalServiceProtocol {
    func createPortalSphere(radius: Float) -> SCNNode
    func loadEquirectangularTexture(url: URL, completion: @escaping (Result<UIImage, Error>) -> Void)
    func applyTextureToSphere(_ texture: UIImage, sphere: SCNNode)
    func placePortal(_ portalNode: SCNNode, at position: SIMD3<Float>, in scene: SCNScene)
    func createPortalPreview(_ portalNode: SCNNode) -> UIImage?
}

enum ARPortalError: LocalizedError {
    case invalidTextureURL
    case textureLoadFailed(Error)
    case invalidFormat
    case sphereCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidTextureURL:
            return "URL texture invalide"
        case .textureLoadFailed(let error):
            return "Échec chargement texture: \(error.localizedDescription)"
        case .invalidFormat:
            return "Format texture non supporté"
        case .sphereCreationFailed:
            return "Échec création sphère portal"
        }
    }
}

final class ARPortalService: ARPortalServiceProtocol {
    private var portalNodes: [UUID: SCNNode] = [:]
    
    // MARK: - Portal Sphere Creation
    
    func createPortalSphere(radius: Float = 10.0) -> SCNNode {
        // Créer géométrie sphère pour projection 360°
        // Utiliser SCNSphere avec segmentation élevée pour qualité
        let sphere = SCNSphere(radius: CGFloat(radius))
        
        // Segmentation pour qualité (plus de segments = meilleure qualité mais plus lourd)
        sphere.segmentCount = 48 // Bon équilibre qualité/performance
        
        // Matériau pour texture equirectangular
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.clear // Sera remplacé par texture
        material.isDoubleSided = false // Intérieur visible uniquement
        material.lightingModel = .constant // Pas d'éclairage pour panorama
        
        // Configurer mapping texture equirectangular
        // Inverser la sphère pour voir depuis l'intérieur
        sphere.materials = [material]
        
        // Créer node
        let sphereNode = SCNNode(geometry: sphere)
        
        // Inverser normales pour voir depuis l'intérieur
        sphereNode.scale = SCNVector3(-1, 1, 1) // Inverser X pour voir de l'intérieur
        
        sphereNode.name = "portalSphere_\(UUID().uuidString)"
        
        return sphereNode
    }
    
    // MARK: - Texture Loading
    
    func loadEquirectangularTexture(url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        // Charger texture depuis URL (locale ou réseau)
        if url.isFileURL {
            // Chargement local
            guard let image = UIImage(contentsOfFile: url.path) else {
                completion(.failure(ARPortalError.textureLoadFailed(NSError(domain: "ARPortal", code: -1))))
                return
            }
            completion(.success(image))
        } else {
            // Chargement réseau
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    guard let image = UIImage(data: data) else {
                        completion(.failure(ARPortalError.invalidFormat))
                        return
                    }
                    DispatchQueue.main.async {
                        completion(.success(image))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(ARPortalError.textureLoadFailed(error)))
                    }
                }
            }
        }
    }
    
    // MARK: - Texture Application
    
    func applyTextureToSphere(_ texture: UIImage, sphere: SCNNode) {
        guard let geometry = sphere.geometry as? SCNSphere,
              let material = geometry.materials.first else {
            return
        }
        
        // Appliquer texture equirectangular sur matériau
        material.diffuse.contents = texture
        material.diffuse.wrapS = .repeat // Pas de répétition pour panorama
        material.diffuse.wrapT = .repeat
        
        // Désactiver filtrage pour éviter artefacts aux pôles
        material.diffuse.minificationFilter = .linear
        material.diffuse.magnificationFilter = .linear
    }
    
    // MARK: - Portal Placement
    
    func placePortal(_ portalNode: SCNNode, at position: SIMD3<Float>, in scene: SCNScene) {
        // Positionner portal dans scène AR
        portalNode.simdPosition = position
        
        // Orientation par défaut (peut être ajustée)
        portalNode.simdRotation = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
        
        scene.rootNode.addChildNode(portalNode)
        
        // Enregistrer pour cleanup
        let id = UUID()
        portalNodes[id] = portalNode
    }
    
    // MARK: - Preview Generation
    
    func createPortalPreview(_ portalNode: SCNNode) -> UIImage? {
        // Générer preview du portal (snapshot)
        // Cette méthode sera utilisée pour afficher thumbnail
        guard let geometry = portalNode.geometry as? SCNSphere,
              let material = geometry.materials.first,
              let texture = material.diffuse.contents as? UIImage else {
            return nil
        }
        
        // Pour preview, retourner texture directement ou version réduite
        return texture
    }
    
    // MARK: - Helper Methods
    
    func registerPortal(_ portalNode: SCNNode) -> UUID {
        let id = UUID()
        portalNodes[id] = portalNode
        return id
    }
    
    func removePortal(_ portalId: UUID) {
        portalNodes[portalId]?.removeFromParentNode()
        portalNodes.removeValue(forKey: portalId)
    }
}










