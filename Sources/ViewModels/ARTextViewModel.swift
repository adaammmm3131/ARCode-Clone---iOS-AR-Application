//
//  ARTextViewModel.swift
//  ARCodeClone
//
//  ViewModel pour AR Text Generator
//

import Foundation
import SwiftUI
import Combine
import ARKit
import SceneKit
import UIKit

final class ARTextViewModel: BaseViewModel, ObservableObject {
    @Published var text: String = "Hello AR"
    @Published var selectedFont: FontInfo = FontInfo(name: "Helvetica", displayName: "Helvetica", category: .sansSerif, isSystemFont: true, isLoaded: true)
    @Published var fontSize: CGFloat = 0.1
    @Published var depth: CGFloat = 0.02
    @Published var color: UIColor = .white
    @Published var red: Double = 1.0
    @Published var green: Double = 1.0
    @Published var blue: Double = 1.0
    @Published var materialType: TextMaterialType = .matte
    @Published var textNode: SCNNode?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let arService: ARServiceProtocol
    private let text3DService: ARText3DServiceProtocol
    private let fontService: ARTextFontServiceProtocol
    private let colorService: ARTextColorServiceProtocol
    private let gestureService: ARTextGestureServiceProtocol
    
    private var textNodeId: UUID?
    
    init(
        arService: ARServiceProtocol,
        text3DService: ARText3DServiceProtocol,
        fontService: ARTextFontServiceProtocol,
        colorService: ARTextColorServiceProtocol,
        gestureService: ARTextGestureServiceProtocol
    ) {
        self.arService = arService
        self.text3DService = text3DService
        self.fontService = fontService
        self.colorService = colorService
        self.gestureService = gestureService
        
        // Initialiser avec première police disponible
        let availableFonts = fontService.getAvailableFonts()
        if let firstFont = availableFonts.first {
            self.selectedFont = firstFont
        }
        
        super.init()
        
        // Observer changements
        setupObservers()
    }
    
    // MARK: - Text Creation
    
    func createText3D(in scene: SCNScene, at position: SIMD3<Float>) {
        isLoading = true
        errorMessage = nil
        
        // Charger police
        guard let font = fontService.loadFont(name: selectedFont.name, size: fontSize) else {
            errorMessage = "Échec chargement police"
            isLoading = false
            return
        }
        
        // Créer couleur depuis RGB
        let textColor = colorService.colorFromRGB(r: red, g: green, b: blue)
        
        // Créer texte 3D
        let node = text3DService.createText3D(text: text, font: font, depth: depth, color: textColor)
        
        // Appliquer matériau
        text3DService.applyMaterial(to: node, materialType: materialType, color: textColor, texture: nil)
        
        // Placer dans scène
        node.simdPosition = position
        scene.rootNode.addChildNode(node)
        
        textNode = node
        
        // Enregistrer
        if let service = text3DService as? ARText3DService {
            let id = service.registerTextNode(node)
            textNodeId = id
        }
        
        isLoading = false
    }
    
    // MARK: - Text Updates
    
    func updateText() {
        guard let node = textNode,
              let font = fontService.loadFont(name: selectedFont.name, size: fontSize) else { return }
        
        text3DService.updateText(node, newText: text, font: font)
    }
    
    func updateDepth() {
        guard let node = textNode else { return }
        text3DService.updateDepth(node, newDepth: depth)
    }
    
    func updateColor() {
        guard let node = textNode else { return }
        let textColor = colorService.colorFromRGB(r: red, g: green, b: blue)
        color = textColor
        text3DService.applyMaterial(to: node, materialType: materialType, color: textColor, texture: nil)
    }
    
    func updateMaterial() {
        guard let node = textNode else { return }
        let textColor = colorService.colorFromRGB(r: red, g: green, b: blue)
        text3DService.applyMaterial(to: node, materialType: materialType, color: textColor, texture: nil)
    }
    
    // MARK: - Gesture Setup
    
    func setupGestures(on view: UIView, scene: SCNScene) {
        guard let textNode = textNode else { return }
        gestureService.setupGestures(on: view, scene: scene, textNode: textNode)
    }
    
    func removeGestures(from view: UIView) {
        gestureService.removeGestures(from: view)
    }
    
    // MARK: - Preview
    
    func generatePreview() -> UIImage? {
        guard let textNode = textNode else { return nil }
        return text3DService.createPreview(textNode: textNode, size: CGSize(width: 512, height: 512))
    }
    
    // MARK: - Helper Methods
    
    private func setupObservers() {
        // Observer changements RGB pour mettre à jour couleur
        $red.sink { [weak self] _ in
            self?.updateColor()
        }.store(in: &cancellables)
        
        $green.sink { [weak self] _ in
            self?.updateColor()
        }.store(in: &cancellables)
        
        $blue.sink { [weak self] _ in
            self?.updateColor()
        }.store(in: &cancellables)
    }
    
    func getAvailableFonts() -> [FontInfo] {
        return fontService.getAvailableFonts()
    }
    
    func cleanup() {
        if let nodeId = textNodeId,
           let service = text3DService as? ARText3DService {
            service.removeTextNode(nodeId)
        }
        textNode = nil
    }
}

