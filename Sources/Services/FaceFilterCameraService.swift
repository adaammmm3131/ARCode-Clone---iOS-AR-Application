//
//  FaceFilterCameraService.swift
//  ARCodeClone
//
//  Service pour gestion caméra front/rear et switching
//

import AVFoundation
import ARKit

protocol FaceFilterCameraServiceProtocol {
    func switchCamera(for configuration: inout ARFaceTrackingConfiguration, to position: AVCaptureDevice.Position) -> Bool
    func getAvailableCameraPositions() -> [AVCaptureDevice.Position]
    func isCameraAvailable(at position: AVCaptureDevice.Position) -> Bool
}

final class FaceFilterCameraService: FaceFilterCameraServiceProtocol {
    
    func switchCamera(for configuration: inout ARFaceTrackingConfiguration, to position: AVCaptureDevice.Position) -> Bool {
        // Note: ARFaceTrackingConfiguration utilise uniquement caméra frontale par défaut
        // Le switching front/rear nécessite utiliser ARWorldTrackingConfiguration avec face tracking enabled
        
        guard isCameraAvailable(at: position) else {
            return false
        }
        
        // ARFaceTrackingConfiguration ne supporte que front camera directement
        // Pour rear camera, on doit utiliser une approche différente
        // (ARWorldTrackingConfiguration avec face detection via Vision framework)
        
        if position == .front {
            // Front camera - utiliser ARFaceTrackingConfiguration standard
            configuration.isWorldTrackingEnabled = true
            return true
        } else {
            // Rear camera - ARFaceTrackingConfiguration ne supporte pas directement
            // Nécessiterait fallback vers Vision framework + ARWorldTrackingConfiguration
            // Pour l'instant, retourner false
            return false
        }
    }
    
    func getAvailableCameraPositions() -> [AVCaptureDevice.Position] {
        var positions: [AVCaptureDevice.Position] = []
        
        // Vérifier front camera
        if let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            positions.append(.front)
        }
        
        // Vérifier rear camera
        if let rearDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            positions.append(.back)
        }
        
        return positions
    }
    
    func isCameraAvailable(at position: AVCaptureDevice.Position) -> Bool {
        let available = getAvailableCameraPositions()
        return available.contains(position)
    }
}

// MARK: - Multi-User Support

extension FaceFilterService {
    /// Support multi-user: attacher logo à toutes les faces détectées
    func attachLogoToAllFaces(in scene: SCNScene, faces: [ARFaceAnchor]) {
        for faceAnchor in faces {
            // Vérifier si logo déjà attaché à cette face
            if logoNodes[faceAnchor.identifier] == nil {
                _ = attachLogoToFace(faceAnchor, in: scene)
            }
        }
    }
    
    /// Mettre à jour toutes les positions de logo
    func updateAllLogoPositions(faces: [ARFaceAnchor], in scene: SCNScene) {
        for faceAnchor in faces {
            let logoNodeName = "faceLogo_\(faceAnchor.identifier.uuidString)"
            if let logoNode = scene.rootNode.childNode(withName: logoNodeName, recursively: true) {
                updateLogoPosition(for: faceAnchor, logoNode: logoNode)
            }
        }
    }
}










