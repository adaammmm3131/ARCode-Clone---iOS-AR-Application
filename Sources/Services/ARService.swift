//
//  ARService.swift
//  ARCodeClone
//
//  Implémentation du service AR avec ARKit
//

import Foundation
import ARKit
import RealityKit
import SceneKit

final class ARService: NSObject, ARServiceProtocol {
    private var arSession: ARSession?
    private var currentConfiguration: ARConfiguration?
    private var arView: ARSCNView?
    private var anchors: [UUID: ARAnchor] = [:]
    
    // Face Filter Service
    var faceFilterService: FaceFilterServiceProtocol?
    private var faceScene: SCNScene?
    
    // Callbacks
    var onPlaneDetected: ((ARPlaneAnchor) -> Void)?
    var onFaceDetected: ((ARFaceAnchor) -> Void)?
    var onImageDetected: ((ARImageAnchor) -> Void)?
    var onError: ((Error) -> Void)?
    
    override init() {
        super.init()
        self.faceFilterService = FaceFilterService()
    }
    
    // MARK: - AR Session Management
    
    func startARSession(configuration: ARConfiguration) throws {
        guard ARWorldTrackingConfiguration.isSupported else {
            throw ARError.deviceNotSupported
        }
        
        let session = ARSession()
        session.delegate = self
        
        // Configurer selon le type
        if let worldConfig = configuration as? ARWorldTrackingConfiguration {
            configureWorldTracking(worldConfig)
        } else if let faceConfig = configuration as? ARFaceTrackingConfiguration {
            configureFaceTracking(faceConfig)
            // Créer scène pour face filter si nécessaire
            if faceScene == nil {
                faceScene = SCNScene()
            }
        } else if let imageConfig = configuration as? ARImageTrackingConfiguration {
            configureImageTracking(imageConfig)
        }
        
        self.arSession = session
        self.currentConfiguration = configuration
        
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func setFaceScene(_ scene: SCNScene) {
        self.faceScene = scene
    }
    
    func stopARSession() {
        arSession?.pause()
        anchors.removeAll()
        currentConfiguration = nil
    }
    
    // MARK: - Configuration Methods
    
    private func configureWorldTracking(_ config: ARWorldTrackingConfiguration) {
        // Activer plane detection
        config.planeDetection = [.horizontal, .vertical]
        
        // Activer environment texturing si disponible
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        // Activer people occlusion si LiDAR disponible
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            config.frameSemantics.insert(.personSegmentationWithDepth)
        }
        
        // Maximum number of tracked images
        config.maximumNumberOfTrackedImages = 10
    }
    
    private func configureFaceTracking(_ config: ARFaceTrackingConfiguration) {
        // Maximum number of tracked faces
        config.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
        
        // Activer world tracking avec face tracking (iOS 13+)
        config.isWorldTrackingEnabled = true
    }
    
    private func configureImageTracking(_ config: ARImageTrackingConfiguration) {
        // Maximum number of tracked images
        config.maximumNumberOfTrackedImages = 10
        
        // Tracking images seront configurés dynamiquement
    }
    
    // MARK: - Model Loading & Placement
    
    func loadModel(at url: URL) async throws -> ModelEntity {
        // TODO: Implémenter le chargement de modèles 3D
        // Pour l'instant, retourner un modèle vide
        throw ARError.notImplemented
    }
    
    func placeModel(_ model: ModelEntity, at position: SIMD3<Float>) {
        // TODO: Implémenter le placement de modèles dans la scène AR
    }
    
    // MARK: - Plane Detection
    
    func detectPlanes() -> [ARPlaneAnchor] {
        return anchors.values.compactMap { $0 as? ARPlaneAnchor }
    }
    
    // MARK: - Lighting Estimation
    
    func estimateLighting() -> ARLightEstimate? {
        guard let frame = arSession?.currentFrame else {
            return nil
        }
        return frame.lightEstimate
    }
    
    /// Obtient le frame AR actuel
    func getCurrentFrame() -> ARFrame? {
        return arSession?.currentFrame
    }
}

// MARK: - ARSessionDelegate

extension ARService: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Mise à jour de la frame AR
        // Utilisé pour le tracking et l'estimation de lumière
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            self.anchors[anchor.identifier] = anchor
            
            if let planeAnchor = anchor as? ARPlaneAnchor {
                onPlaneDetected?(planeAnchor)
            } else if let faceAnchor = anchor as? ARFaceAnchor {
                // Mettre à jour faceFilterService
                var currentFaces = faceFilterService?.detectedFaces.value ?? [:]
                currentFaces[faceAnchor.identifier] = faceAnchor
                faceFilterService?.detectedFaces.send(currentFaces)
                
                // Attacher logo si disponible
                if let scene = faceScene {
                    _ = faceFilterService?.attachLogoToFace(faceAnchor, in: scene)
                }
                
                onFaceDetected?(faceAnchor)
            } else if let imageAnchor = anchor as? ARImageAnchor {
                onImageDetected?(imageAnchor)
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            self.anchors[anchor.identifier] = anchor
            
            // Notifier les mises à jour
            if let planeAnchor = anchor as? ARPlaneAnchor {
                onPlaneDetected?(planeAnchor)
            } else if let faceAnchor = anchor as? ARFaceAnchor {
                // Mettre à jour faceFilterService
                var currentFaces = faceFilterService?.detectedFaces.value ?? [:]
                currentFaces[faceAnchor.identifier] = faceAnchor
                faceFilterService?.detectedFaces.send(currentFaces)
                
                // Mettre à jour position logo
                if let scene = faceScene,
                   let faceFilterService = faceFilterService {
                    // Chercher node logo existant
                    let logoNodeName = "faceLogo_\(faceAnchor.identifier.uuidString)"
                    if let logoNode = scene.rootNode.childNode(withName: logoNodeName, recursively: true) {
                        faceFilterService.updateLogoPosition(for: faceAnchor, logoNode: logoNode)
                    }
                }
            }
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            self.anchors.removeValue(forKey: anchor.identifier)
            
            // Supprimer logo si face supprimée
            if let faceAnchor = anchor as? ARFaceAnchor,
               let scene = faceScene {
                faceFilterService?.removeLogo(from: faceAnchor, in: scene)
                
                var currentFaces = faceFilterService?.detectedFaces.value ?? [:]
                currentFaces.removeValue(forKey: faceAnchor.identifier)
                faceFilterService?.detectedFaces.send(currentFaces)
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        onError?(error)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Session interrompue (ex: appel téléphonique)
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Session reprend
        // Relancer avec la dernière configuration
        if let config = currentConfiguration {
            session.run(config, options: [.resetTracking])
        }
    }
}

// MARK: - AR Errors

enum ARError: LocalizedError {
    case deviceNotSupported
    case sessionNotInitialized
    case configurationInvalid
    case modelLoadingFailed
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .deviceNotSupported:
            return "ARKit n'est pas supporté sur cet appareil"
        case .sessionNotInitialized:
            return "La session AR n'est pas initialisée"
        case .configurationInvalid:
            return "La configuration AR est invalide"
        case .modelLoadingFailed:
            return "Échec du chargement du modèle 3D"
        case .notImplemented:
            return "Fonctionnalité non implémentée"
        }
    }
}

