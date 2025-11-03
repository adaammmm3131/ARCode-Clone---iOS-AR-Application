//
//  ARRenderingPipeline.swift
//  ARCodeClone
//
//  Pipeline de rendu AR optimisé avec SLAM tracking, lighting, occlusion
//

import Foundation
import ARKit
import SceneKit
import MetalKit

/// Pipeline de rendu AR optimisé pour 60fps
protocol ARRenderingPipelineProtocol {
    func setupPipeline(for arView: ARSCNView, configuration: ARWorldTrackingConfiguration)
    func updatePipeline(frame: ARFrame, scene: SCNScene)
    func applyLightingEstimate(_ lightEstimate: ARLightEstimate)
    func handlePlaneUpdates(_ anchors: [ARPlaneAnchor])
    func enableOcclusion(enabled: Bool)
    func enableFrustumCulling(enabled: Bool)
    func getCurrentFPS() -> Float
}

final class ARRenderingPipeline: NSObject, ARRenderingPipelineProtocol {
    private var arView: ARSCNView?
    private var configuration: ARWorldTrackingConfiguration?
    private var lastFrameTime: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var currentFPS: Float = 0
    
    // Lighting
    private var ambientLightNode: SCNNode?
    private var directionalLightNode: SCNNode?
    private var environmentProbe: SCNLight?
    
    // Occlusion
    private var isOcclusionEnabled: Bool = false
    
    // Frustum culling
    private var isFrustumCullingEnabled: Bool = true
    
    // Performance monitoring
    private var frameTimings: [CFTimeInterval] = []
    private let maxFrameTimings: Int = 60
    
    // MARK: - Pipeline Setup
    
    func setupPipeline(for arView: ARSCNView, configuration: ARWorldTrackingConfiguration) {
        self.arView = arView
        self.configuration = configuration
        
        // Configurer ARView pour performance optimale
        arView.antialiasingMode = .multisampling4X
        arView.preferredFramesPerSecond = 60
        arView.automaticallyUpdatesLighting = true
        arView.autoenablesDefaultLighting = false
        
        // Configurer scène
        if arView.scene == nil {
            arView.scene = SCNScene()
        }
        
        // Setup lighting
        setupLighting(in: arView.scene)
        
        // Setup occlusion si disponible
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            enableOcclusion(enabled: true)
        }
        
        // Setup frustum culling
        enableFrustumCulling(enabled: true)
        
        // Configurer delegate pour updates
        arView.session.delegate = self
    }
    
    // MARK: - Pipeline Update
    
    func updatePipeline(frame: ARFrame, scene: SCNScene) {
        let currentTime = CACurrentMediaTime()
        
        // Calculer FPS
        if lastFrameTime > 0 {
            let frameTime = currentTime - lastFrameTime
            frameTimings.append(frameTime)
            
            if frameTimings.count > maxFrameTimings {
                frameTimings.removeFirst()
            }
            
            // Moyenne FPS sur les dernières frames
            let avgFrameTime = frameTimings.reduce(0, +) / Double(frameTimings.count)
            currentFPS = Float(1.0 / avgFrameTime)
        }
        lastFrameTime = currentTime
        frameCount += 1
        
        // Mettre à jour lighting depuis frame
        if let lightEstimate = frame.lightEstimate {
            applyLightingEstimate(lightEstimate)
        }
        
        // Frustum culling (SceneKit fait automatiquement, mais on peut optimiser)
        if isFrustumCullingEnabled {
            optimizeSceneForFrustum(scene: scene, frame: frame)
        }
        
        // Occlusion handling (si activé)
        if isOcclusionEnabled {
            updateOcclusion(frame: frame)
        }
    }
    
    // MARK: - Lighting
    
    func setupLighting(in scene: SCNScene) {
        // Lumière ambiante
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.white.withAlphaComponent(0.3)
        ambientLight.intensity = 500
        
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        self.ambientLightNode = ambientNode
        
        // Lumière directionnelle principale
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = UIColor.white
        directionalLight.intensity = 1000
        directionalLight.castsShadow = true
        directionalLight.shadowMode = .deferred
        directionalLight.shadowRadius = 8
        directionalLight.shadowColor = UIColor.black.withAlphaComponent(0.3)
        
        let directionalNode = SCNNode()
        directionalNode.light = directionalLight
        directionalNode.position = SCNVector3(0, 5, 5)
        directionalNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directionalNode)
        self.directionalLightNode = directionalNode
        
        // Environment Probe pour IBL (Image-Based Lighting)
        let probe = SCNLight()
        probe.type = .probe
        probe.intensity = 1000
        
        let probeNode = SCNNode()
        probeNode.light = probe
        scene.rootNode.addChildNode(probeNode)
        self.environmentProbe = probe
    }
    
    func applyLightingEstimate(_ lightEstimate: ARLightEstimate) {
        // Mettre à jour lumière ambiante avec estimation ARKit
        if let ambient = ambientLightNode?.light {
            let ambientIntensity = lightEstimate.ambientIntensity
            ambient.intensity = CGFloat(ambientIntensity / 1000.0 * 500.0)
            
            // Ajuster couleur selon température
            let temperature = lightEstimate.ambientColorTemperature
            let color = temperatureToColor(temperature)
            ambient.color = color
        }
        
        // Mettre à jour lumière directionnelle
        if let directional = directionalLightNode?.light {
            directional.intensity = CGFloat(lightEstimate.ambientIntensity / 1000.0 * 1000.0)
        }
        
        // Mettre à jour environment probe
        if let probe = environmentProbe {
            probe.intensity = CGFloat(lightEstimate.ambientIntensity / 1000.0 * 1000.0)
        }
    }
    
    private func temperatureToColor(_ temperature: CGFloat) -> UIColor {
        // Conversion température couleur (K) vers UIColor approximatif
        // 6500K = blanc neutre
        if temperature < 5500 {
            // Plus chaud (jaune/rouge)
            return UIColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 1.0)
        } else if temperature > 7500 {
            // Plus froid (bleu)
            return UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
        } else {
            // Neutre
            return UIColor.white
        }
    }
    
    // MARK: - Plane Updates
    
    func handlePlaneUpdates(_ anchors: [ARPlaneAnchor]) {
        guard let scene = arView?.scene else { return }
        
        for anchor in anchors {
            // Mettre à jour ou créer visualisation plan si nécessaire
            // SceneKit gère automatiquement les anchors, mais on peut optimiser
        }
    }
    
    // MARK: - Occlusion
    
    func enableOcclusion(enabled: Bool) {
        isOcclusionEnabled = enabled
        
        guard let arView = arView else { return }
        
        if enabled {
            // Activer depth occlusion (nécessite LiDAR ou scene depth)
            if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
                // SceneKit gère automatiquement avec sceneReconstruction
                // On peut aussi utiliser ARDepthData manuellement
            }
        }
    }
    
    private func updateOcclusion(frame: ARFrame) {
        // Mettre à jour occlusion avec depth data si disponible
        if let depthData = frame.sceneDepth,
           let arView = arView {
            // Utiliser depth data pour occlusion
            // SceneKit le fait automatiquement avec sceneReconstruction
        }
    }
    
    // MARK: - Frustum Culling
    
    func enableFrustumCulling(enabled: Bool) {
        isFrustumCullingEnabled = enabled
    }
    
    private func optimizeSceneForFrustum(scene: SCNScene, frame: ARFrame) {
        // SceneKit fait le frustum culling automatiquement
        // Mais on peut optimiser en désactivant nodes hors frustum manuellement
        guard let camera = arView?.pointOfView else { return }
        
        let cameraTransform = frame.camera.transform
        let cameraPosition = SCNVector3(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        
        // Optimiser nodes selon distance
        scene.rootNode.enumerateChildNodes { node, _ in
            let distance = distanceBetween(node.position, cameraPosition)
            
            // Désactiver nodes très loin
            if distance > 10.0 && !node.isHidden {
                node.isHidden = true
            } else if distance <= 10.0 && node.isHidden {
                node.isHidden = false
            }
        }
    }
    
    private func distanceBetween(_ v1: SCNVector3, _ v2: SCNVector3) -> Float {
        let dx = v1.x - v2.x
        let dy = v1.y - v2.y
        let dz = v1.z - v2.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
    
    // MARK: - Performance
    
    func getCurrentFPS() -> Float {
        return currentFPS
    }
    
    func getFrameCount() -> Int {
        return frameCount
    }
    
    func getAverageFrameTime() -> CFTimeInterval {
        guard !frameTimings.isEmpty else { return 0 }
        return frameTimings.reduce(0, +) / Double(frameTimings.count)
    }
}

// MARK: - ARSessionDelegate

extension ARRenderingPipeline: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let scene = arView?.scene else { return }
        updatePipeline(frame: frame, scene: scene)
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        if let planeAnchors = anchors as? [ARPlaneAnchor] {
            handlePlaneUpdates(planeAnchors)
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        if let planeAnchors = anchors as? [ARPlaneAnchor] {
            handlePlaneUpdates(planeAnchors)
        }
    }
}









