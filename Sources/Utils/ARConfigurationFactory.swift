//
//  ARConfigurationFactory.swift
//  ARCodeClone
//
//  Factory pour créer des configurations AR
//

import ARKit

struct ARConfigurationFactory {
    
    /// Crée une configuration World Tracking optimale
    static func createWorldTracking() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        
        // Plane detection
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Scene reconstruction (mesh) si disponible
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        // People occlusion si LiDAR disponible
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            configuration.frameSemantics.insert(.personSegmentationWithDepth)
        }
        
        // Maximum tracked images
        configuration.maximumNumberOfTrackedImages = 10
        
        // Environment texturing pour reflections réalistes (IBL)
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        
        // People occlusion si disponible (ARKit 3+)
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            configuration.frameSemantics.insert(.personSegmentationWithDepth)
        }
        
        // Activer l'estimation de lumière (activée par défaut)
        // Pas besoin de configuration supplémentaire, ARKit le fait automatiquement
        
        return configuration
    }
    
    /// Crée une configuration Face Tracking
    static func createFaceTracking() -> ARFaceTrackingConfiguration {
        let configuration = ARFaceTrackingConfiguration()
        
        // Maximum tracked faces
        configuration.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
        
        // World tracking avec face tracking (iOS 13+)
        configuration.isWorldTrackingEnabled = true
        
        return configuration
    }
    
    /// Crée une configuration Image Tracking avec des images de référence
    static func createImageTracking(referenceImages: Set<ARReferenceImage>) -> ARImageTrackingConfiguration {
        let configuration = ARImageTrackingConfiguration()
        
        // Images de référence pour le tracking
        configuration.trackingImages = referenceImages
        
        // Maximum tracked images
        configuration.maximumNumberOfTrackedImages = referenceImages.count
        
        return configuration
    }
    
    /// Crée une configuration Image Tracking depuis des URLs
    static func createImageTracking(from imageURLs: [URL]) -> ARImageTrackingConfiguration {
        let configuration = ARImageTrackingConfiguration()
        
        // TODO: Charger les images depuis les URLs et créer ARReferenceImage
        // Pour l'instant, configuration vide
        
        configuration.maximumNumberOfTrackedImages = 10
        
        return configuration
    }
    
    /// Vérifie si ARKit est supporté
    static func isARKitSupported() -> Bool {
        return ARWorldTrackingConfiguration.isSupported
    }
    
    /// Vérifie si Face Tracking est supporté
    static func isFaceTrackingSupported() -> Bool {
        return ARFaceTrackingConfiguration.isSupported
    }
    
    /// Vérifie si LiDAR est disponible
    static func isLiDARAvailable() -> Bool {
        return ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }
}

