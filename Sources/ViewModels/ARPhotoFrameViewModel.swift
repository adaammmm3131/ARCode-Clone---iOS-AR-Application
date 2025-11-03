//
//  ARPhotoFrameViewModel.swift
//  ARCodeClone
//
//  ViewModel pour AR Photo Frame
//

import Foundation
import SwiftUI
import Combine
import ARKit
import SceneKit
import UIKit

final class ARPhotoFrameViewModel: BaseViewModel, ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedFrameStyle: FrameStyle = .classic
    @Published var selectedAspectRatio: AspectRatio = .original
    @Published var frameSize: CGSize = CGSize(width: 0.5, height: 0.6)
    @Published var currentFrameNode: SCNNode?
    @Published var galleryFrames: [SCNNode] = []
    @Published var isGalleryMode: Bool = false
    @Published var currentGalleryIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let arService: ARServiceProtocol
    private let frameService: ARPhotoFrameServiceProtocol
    private let imageService: ARPhotoFrameImageServiceProtocol
    private let placementService: ARPhotoFramePlacementServiceProtocol
    private let gestureService: ARPhotoFrameGestureServiceProtocol
    
    private var frameNodeId: UUID?
    private var galleryNodeId: UUID?
    
    init(
        arService: ARServiceProtocol,
        frameService: ARPhotoFrameServiceProtocol,
        imageService: ARPhotoFrameImageServiceProtocol,
        placementService: ARPhotoFramePlacementServiceProtocol,
        gestureService: ARPhotoFrameGestureServiceProtocol
    ) {
        self.arService = arService
        self.frameService = frameService
        self.imageService = imageService
        self.placementService = placementService
        self.gestureService = gestureService
        super.init()
    }
    
    // MARK: - Image Selection
    
    func loadImage(_ image: UIImage) {
        isLoading = true
        errorMessage = nil
        
        // Valider image
        let validation = imageService.validateImage(image)
        guard validation.isValid else {
            errorMessage = validation.errorMessage ?? "Image invalide"
            isLoading = false
            return
        }
        
        // Ajuster aspect ratio si nécessaire
        var processedImage = image
        if selectedAspectRatio != .original {
            if let cropped = imageService.cropImage(image, to: selectedAspectRatio) {
                processedImage = cropped
            }
        }
        
        selectedImage = processedImage
        
        // Calculer taille frame basée sur image
        let imageSize = processedImage.size
        let aspectRatio = Float(imageSize.width / imageSize.height)
        
        // Définir taille frame (en mètres AR)
        frameSize = CGSize(
            width: CGFloat(min(1.0, aspectRatio * 0.6)),
            height: CGFloat(min(1.0, 0.6))
        )
        
        isLoading = false
    }
    
    // MARK: - Frame Creation
    
    func createFrame(in scene: SCNScene, on plane: ARPlaneAnchor?) {
        guard let image = selectedImage else {
            errorMessage = "Aucune image sélectionnée"
            return
        }
        
        // Créer frame
        let frameNode = frameService.createFrame(style: selectedFrameStyle, size: frameSize, image: image)
        
        // Placer frame
        if let plane = plane {
            placementService.placeFrame(frameNode, on: plane, in: scene, at: nil)
        } else {
            // Placement flottant par défaut
            frameNode.simdPosition = SIMD3<Float>(0, 0, -1)
            scene.rootNode.addChildNode(frameNode)
        }
        
        currentFrameNode = frameNode
        
        // Enregistrer
        if let service = frameService as? ARPhotoFrameService {
            let id = service.registerFrame(frameNode)
            frameNodeId = id
        }
    }
    
    // MARK: - Gallery Mode
    
    func createGallery(images: [UIImage], in scene: SCNScene, on plane: ARPlaneAnchor, layout: GalleryLayout) {
        guard !images.isEmpty else { return }
        
        isLoading = true
        
        // Créer frames pour chaque image
        var frames: [SCNNode] = []
        
        for (index, image) in images.enumerated() {
            // Ajuster aspect ratio
            var processedImage = image
            if selectedAspectRatio != .original {
                if let cropped = imageService.cropImage(image, to: selectedAspectRatio) {
                    processedImage = cropped
                }
            }
            
            let frame = frameService.createFrame(style: selectedFrameStyle, size: frameSize, image: processedImage)
            
            // Cacher tous sauf le premier
            frame.isHidden = index > 0
            
            frames.append(frame)
        }
        
        // Créer gallery
        placementService.createGallery(frames: frames, on: plane, in: scene, layout: layout)
        
        galleryFrames = frames
        isGalleryMode = true
        currentGalleryIndex = 0
        
        isLoading = false
    }
    
    func navigateToNext() {
        guard isGalleryMode, let galleryNode = findGalleryNode() else { return }
        placementService.navigateToNext(in: galleryNode)
        currentGalleryIndex = (currentGalleryIndex + 1) % galleryFrames.count
    }
    
    func navigateToPrevious() {
        guard isGalleryMode, let galleryNode = findGalleryNode() else { return }
        placementService.navigateToPrevious(in: galleryNode)
        currentGalleryIndex = (currentGalleryIndex - 1 + galleryFrames.count) % galleryFrames.count
    }
    
    // MARK: - Gesture Setup
    
    func setupGestures(on view: UIView, scene: SCNScene) {
        guard let frameNode = currentFrameNode else { return }
        gestureService.setupGestures(on: view, scene: scene, frameNode: frameNode)
    }
    
    func removeGestures(from view: UIView) {
        gestureService.removeGestures(from: view)
    }
    
    // MARK: - Helper Methods
    
    private func findGalleryNode() -> SCNNode? {
        // Trouver gallery node dans scène
        // Simplifié: rechercher dans currentFrameNode parent
        return currentFrameNode?.parent
    }
    
    func getFrameStyles() -> [FrameStyle] {
        return frameService.getFrameStyles()
    }
    
    func cleanup() {
        if let nodeId = frameNodeId,
           let service = frameService as? ARPhotoFrameService {
            service.removeFrame(nodeId)
        }
        currentFrameNode = nil
        galleryFrames.removeAll()
        isGalleryMode = false
    }
}









