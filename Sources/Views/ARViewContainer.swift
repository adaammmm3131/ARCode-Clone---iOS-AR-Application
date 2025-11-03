//
//  ARViewContainer.swift
//  ARCodeClone
//
//  Container SwiftUI pour ARView
//

import SwiftUI
import ARKit
import RealityKit
import SceneKit

struct ARViewContainer: UIViewRepresentable {
    let configuration: ARConfiguration
    @Binding var isSessionRunning: Bool
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        
        // Configuration de la scène
        let scene = SCNScene()
        arView.scene = scene
        
        // Options de rendu
        arView.antialiasingMode = .multisampling4X
        arView.automaticallyUpdatesLighting = true
        arView.autoenablesDefaultLighting = false
        
        // Session AR
        let session = ARSession()
        arView.session = session
        
        // Démarrer la session
        if isSessionRunning {
            session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
        
        // Debug options (à désactiver en production)
        #if DEBUG
        arView.showsStatistics = true
        arView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        #endif
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        if isSessionRunning {
            uiView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        } else {
            uiView.session.pause()
        }
    }
}

// MARK: - ARView avec RealityKit

struct RealityKitARViewContainer: UIViewRepresentable {
    let configuration: ARConfiguration
    @Binding var isSessionRunning: Bool
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Démarrer la session
        if isSessionRunning {
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if isSessionRunning {
            uiView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        } else {
            uiView.session.pause()
        }
    }
}













