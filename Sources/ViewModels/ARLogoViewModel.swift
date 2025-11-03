//
//  ARLogoViewModel.swift
//  ARCodeClone
//
//  ViewModel pour AR Logo
//

import Foundation
import SwiftUI
import Combine
import ARKit
import SceneKit
import UIKit

final class ARLogoViewModel: BaseViewModel, ObservableObject {
    @Published var selectedSVGURL: URL?
    @Published var svgPreview: UIImage?
    @Published var dimensions: CGSize?
    @Published var depth: Float = 0.1 // 1mm par défaut
    @Published var isAnimationEnabled: Bool = false
    @Published var animationSpeed: Float = 1.0
    @Published var animationEasing: AnimationEasing = .easeInOut
    @Published var materialColor: UIColor = .white
    @Published var materialMetalness: Float = 0.5
    @Published var materialRoughness: Float = 0.5
    @Published var currentLogoNode: SCNNode?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let uploadService: ARLogoUploadServiceProtocol
    private let extrusionService: ARLogo3DExtrusionServiceProtocol
    private let animationService: ARLogoAnimationServiceProtocol
    private let arService: ARServiceProtocol
    
    init(
        uploadService: ARLogoUploadServiceProtocol,
        extrusionService: ARLogo3DExtrusionServiceProtocol,
        animationService: ARLogoAnimationServiceProtocol,
        arService: ARServiceProtocol
    ) {
        self.uploadService = uploadService
        self.extrusionService = extrusionService
        self.animationService = animationService
        self.arService = arService
        super.init()
    }
    
    // MARK: - SVG Loading
    
    func loadSVG(url: URL) {
        isLoading = true
        errorMessage = nil
        selectedSVGURL = url
        
        // Valider SVG
        let validation = uploadService.validateSVG(url: url)
        guard validation.isValid else {
            errorMessage = validation.errorMessage ?? "SVG invalide"
            isLoading = false
            return
        }
        
        dimensions = validation.dimensions
        
        // Charger preview
        uploadService.loadSVGPreview(url: url) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let image):
                    self?.svgPreview = image
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Logo 3D Creation
    
    func createLogo3D(in scene: SCNScene, at position: SIMD3<Float>) {
        guard let url = selectedSVGURL,
              let svgData = try? Data(contentsOf: url) else {
            errorMessage = "Aucun SVG chargé"
            return
        }
        
        // Créer matériau PBR
        let material = extrusionService.createPBRMaterial(
            color: materialColor,
            metalness: materialMetalness,
            roughness: materialRoughness
        )
        
        // Créer logo 3D
        guard let logoNode = extrusionService.createLogo3D(
            from: svgData,
            depth: depth,
            material: material
        ) else {
            errorMessage = "Échec création logo 3D"
            return
        }
        
        // Placer dans scène
        logoNode.simdPosition = position
        scene.rootNode.addChildNode(logoNode)
        
        currentLogoNode = logoNode
        
        // Appliquer animation si activée
        if isAnimationEnabled {
            animationService.startRotationAnimation(
                node: logoNode,
                speed: animationSpeed,
                easing: animationEasing
            )
        }
    }
    
    // MARK: - Depth Update
    
    func updateDepth(_ newDepth: Float) {
        depth = newDepth
        
        // Mettre à jour logo existant si présent
        if let node = currentLogoNode {
            extrusionService.updateDepth(node, newDepth: newDepth)
        }
    }
    
    // MARK: - Animation Control
    
    func toggleAnimation() {
        guard let node = currentLogoNode else { return }
        
        isAnimationEnabled.toggle()
        
        if isAnimationEnabled {
            animationService.startRotationAnimation(
                node: node,
                speed: animationSpeed,
                easing: animationEasing
            )
        } else {
            animationService.stopRotationAnimation(node: node)
        }
    }
    
    func updateAnimationSpeed(_ speed: Float) {
        animationSpeed = speed
        
        if isAnimationEnabled, let node = currentLogoNode {
            animationService.setRotationSpeed(node: node, speed: speed)
        }
    }
    
    func updateAnimationEasing(_ easing: AnimationEasing) {
        animationEasing = easing
        
        if isAnimationEnabled, let node = currentLogoNode {
            animationService.stopRotationAnimation(node: node)
            animationService.startRotationAnimation(node: node, speed: animationSpeed, easing: easing)
        }
    }
    
    // MARK: - Material Update
    
    func updateMaterial(color: UIColor, metalness: Float, roughness: Float) {
        materialColor = color
        materialMetalness = metalness
        materialRoughness = roughness
        
        // Mettre à jour matériau logo existant
        if let node = currentLogoNode {
            let material = extrusionService.createPBRMaterial(
                color: color,
                metalness: metalness,
                roughness: roughness
            )
            extrusionService.applyMaterial(node, material: material)
        }
    }
    
    // MARK: - Export
    
    func exportLogo(includeAnimation: Bool) -> SCNNode? {
        guard let node = currentLogoNode else { return nil }
        return animationService.exportWithAnimation(node, includeAnimation: includeAnimation)
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        if let node = currentLogoNode {
            animationService.stopRotationAnimation(node: node)
            node.removeFromParentNode()
        }
        currentLogoNode = nil
        selectedSVGURL = nil
        svgPreview = nil
    }
}









