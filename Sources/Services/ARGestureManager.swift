//
//  ARGestureManager.swift
//  ARCodeClone
//
//  Gestionnaire de gestes AR: rotate, scale, pan, tap
//

import Foundation
import UIKit
import ARKit
import SceneKit

protocol ARGestureManagerProtocol {
    func setupGestures(for arView: ARSCNView, scene: SCNScene)
    func attachToNode(_ node: SCNNode)
    func detachFromNode()
    func enableGesture(_ gesture: ARGestureType, enabled: Bool)
    var onNodeSelected: ((SCNNode?) -> Void)? { get set }
    var onNodeTransformed: ((SCNNode) -> Void)? { get set }
}

enum ARGestureType {
    case rotate
    case scale
    case pan
    case tap
    case doubleTap
}

final class ARGestureManager: NSObject, ARGestureManagerProtocol {
    private var arView: ARSCNView?
    private var scene: SCNScene?
    private var selectedNode: SCNNode?
    
    // Gestures
    private var panGesture: UIPanGestureRecognizer?
    private var pinchGesture: UIPinchGestureRecognizer?
    private var rotationGesture: UIRotationGestureRecognizer?
    private var tapGesture: UITapGestureRecognizer?
    private var doubleTapGesture: UITapGestureRecognizer?
    
    // State
    private var initialNodeTransform: SCNMatrix4?
    private var initialPanLocation: CGPoint?
    private var initialNodePosition: SCNVector3?
    private var initialNodeScale: Float = 1.0
    private var initialNodeRotation: Float = 0.0
    
    // Enabled gestures
    private var enabledGestures: Set<ARGestureType> = [.rotate, .scale, .pan, .tap, .doubleTap]
    
    // Callbacks
    var onNodeSelected: ((SCNNode?) -> Void)?
    var onNodeTransformed: ((SCNNode) -> Void)?
    
    // MARK: - Setup
    
    func setupGestures(for arView: ARSCNView, scene: SCNScene) {
        self.arView = arView
        self.scene = scene
        
        // Remove existing gestures
        removeAllGestures()
        
        // Setup gestures
        setupTapGesture()
        setupDoubleTapGesture()
        setupPanGesture()
        setupPinchGesture()
        setupRotationGesture()
    }
    
    // MARK: - Node Management
    
    func attachToNode(_ node: SCNNode) {
        selectedNode = node
        initialNodeTransform = node.transform
        initialNodePosition = node.position
        initialNodeScale = node.scale.x // Assume uniform scale
    }
    
    func detachFromNode() {
        selectedNode = nil
        initialNodeTransform = nil
        initialNodePosition = nil
    }
    
    func enableGesture(_ gesture: ARGestureType, enabled: Bool) {
        if enabled {
            enabledGestures.insert(gesture)
        } else {
            enabledGestures.remove(gesture)
        }
    }
    
    // MARK: - Tap Gesture
    
    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        arView?.addGestureRecognizer(tap)
        tapGesture = tap
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard enabledGestures.contains(.tap),
              let arView = arView,
              let scene = scene else { return }
        
        let location = gesture.location(in: arView)
        let hitResults = arView.hitTest(location, options: nil)
        
        if let firstResult = hitResults.first {
            let node = firstResult.node
            attachToNode(node)
            onNodeSelected?(node)
            
            // Feedback haptique
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        } else {
            // Tap sur rien - désélectionner
            detachFromNode()
            onNodeSelected?(nil)
        }
    }
    
    // MARK: - Double Tap Gesture
    
    private func setupDoubleTapGesture() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        arView?.addGestureRecognizer(doubleTap)
        
        // Require tap gesture to fail
        if let tap = tapGesture {
            tap.require(toFail: doubleTap)
        }
        
        doubleTapGesture = doubleTap
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard enabledGestures.contains(.doubleTap) else { return }
        
        // Reset node transform
        if let node = selectedNode,
           let initialTransform = initialNodeTransform {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            node.transform = initialTransform
            node.position = initialNodePosition ?? SCNVector3(0, 0, 0)
            node.scale = SCNVector3(initialNodeScale, initialNodeScale, initialNodeScale)
            SCNTransaction.commit()
            
            onNodeTransformed?(node)
            
            // Feedback haptique
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
    }
    
    // MARK: - Pan Gesture (One finger rotate Y-axis or Pan)
    
    private func setupPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        arView?.addGestureRecognizer(pan)
        panGesture = pan
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard enabledGestures.contains(.pan),
              let node = selectedNode,
              let arView = arView else { return }
        
        let location = gesture.location(in: arView)
        let translation = gesture.translation(in: arView)
        
        switch gesture.state {
        case .began:
            initialPanLocation = location
            initialNodePosition = node.position
            
        case .changed:
            // Pan on XZ plane (horizontal)
            guard let initial = initialPanLocation else { return }
            
            let deltaX = Float(translation.x) * 0.001 // Scale factor
            let deltaZ = Float(-translation.y) * 0.001 // Invert Y
            
            // Rotate Y-axis if panning horizontally
            if abs(translation.x) > abs(translation.y) {
                // Rotation Y-axis
                let rotationY = Float(translation.x) * 0.01
                node.eulerAngles.y += rotationY
            } else {
                // Pan on XZ plane
                if let initialPos = initialNodePosition {
                    node.position = SCNVector3(
                        initialPos.x + deltaX,
                        initialPos.y,
                        initialPos.z + deltaZ
                    )
                }
            }
            
            onNodeTransformed?(node)
            
        case .ended, .cancelled:
            initialPanLocation = nil
            
        default:
            break
        }
    }
    
    // MARK: - Pinch Gesture (Scale)
    
    private func setupPinchGesture() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        arView?.addGestureRecognizer(pinch)
        pinchGesture = pinch
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard enabledGestures.contains(.scale),
              let node = selectedNode else { return }
        
        switch gesture.state {
        case .began:
            initialNodeScale = node.scale.x
            
        case .changed:
            let scale = Float(gesture.scale) * initialNodeScale
            let clampedScale = max(0.1, min(5.0, scale)) // Limiter entre 0.1x et 5.0x
            node.scale = SCNVector3(clampedScale, clampedScale, clampedScale)
            onNodeTransformed?(node)
            
        default:
            break
        }
    }
    
    // MARK: - Rotation Gesture (Two finger rotate Z-axis)
    
    private func setupRotationGesture() {
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        arView?.addGestureRecognizer(rotation)
        rotationGesture = rotation
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard enabledGestures.contains(.rotate),
              let node = selectedNode else { return }
        
        switch gesture.state {
        case .began:
            initialNodeRotation = node.eulerAngles.z
            
        case .changed:
            node.eulerAngles.z = initialNodeRotation + Float(gesture.rotation)
            onNodeTransformed?(node)
            
        default:
            break
        }
    }
    
    // MARK: - Cleanup
    
    private func removeAllGestures() {
        guard let arView = arView else { return }
        
        if let pan = panGesture {
            arView.removeGestureRecognizer(pan)
        }
        if let pinch = pinchGesture {
            arView.removeGestureRecognizer(pinch)
        }
        if let rotation = rotationGesture {
            arView.removeGestureRecognizer(rotation)
        }
        if let tap = tapGesture {
            arView.removeGestureRecognizer(tap)
        }
        if let doubleTap = doubleTapGesture {
            arView.removeGestureRecognizer(doubleTap)
        }
    }
}









