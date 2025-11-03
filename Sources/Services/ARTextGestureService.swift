//
//  ARTextGestureService.swift
//  ARCodeClone
//
//  Service pour gestes AR texte (placement, rotation, scale)
//

import Foundation
import ARKit
import SceneKit
import UIKit

protocol ARTextGestureServiceProtocol {
    func setupGestures(on view: UIView, scene: SCNScene, textNode: SCNNode)
    func removeGestures(from view: UIView)
}

final class ARTextGestureService: NSObject, ARTextGestureServiceProtocol {
    private var gestureRecognizers: [UIGestureRecognizer] = []
    private weak var currentTextNode: SCNNode?
    private weak var currentScene: SCNScene?
    
    // MARK: - Gesture Setup
    
    func setupGestures(on view: UIView, scene: SCNScene, textNode: SCNNode) {
        self.currentScene = scene
        self.currentTextNode = textNode
        
        // Pinch gesture (scale)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinchGesture)
        gestureRecognizers.append(pinchGesture)
        
        // Rotation gesture (two-finger rotate)
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        view.addGestureRecognizer(rotationGesture)
        gestureRecognizers.append(rotationGesture)
        
        // Pan gesture (movement)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)
        gestureRecognizers.append(panGesture)
        
        // Double-tap (reset)
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
        gestureRecognizers.append(doubleTapGesture)
    }
    
    func removeGestures(from view: UIView) {
        gestureRecognizers.forEach { view.removeGestureRecognizer($0) }
        gestureRecognizers.removeAll()
        currentTextNode = nil
        currentScene = nil
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let textNode = currentTextNode else { return }
        
        switch gesture.state {
        case .began:
            gesture.scale = CGFloat(textNode.scale.x)
        case .changed:
            // Limiter scale entre 0.1x et 10.0x
            let minScale: Float = 0.1
            let maxScale: Float = 10.0
            let newScale = Float(gesture.scale)
            let clampedScale = max(minScale, min(maxScale, newScale))
            
            textNode.scale = SCNVector3(clampedScale, clampedScale, clampedScale)
        default:
            break
        }
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let textNode = currentTextNode else { return }
        
        switch gesture.state {
        case .began:
            break
        case .changed:
            // Rotation autour de l'axe Y (vertical)
            let rotationDelta = Float(gesture.rotation)
            textNode.eulerAngles.y += rotationDelta
            gesture.rotation = 0 // Reset pour prochain changement
        default:
            break
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let textNode = currentTextNode,
              let arView = gesture.view as? ARSCNView,
              let frame = arView.session.currentFrame else { return }
        
        switch gesture.state {
        case .began:
            break
        case .changed:
            let translation = gesture.translation(in: arView)
            let location = gesture.location(in: arView)
            let sensitivity: Float = 0.001
            
            // Utiliser ARKit hit test pour déplacer sur plan détecté
            let hitTestResults = frame.hitTest(
                location,
                types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane, .estimatedVerticalPlane]
            )
            
            if let hitResult = hitTestResults.first {
                // Déplacer texte vers point de hit test sur plan
                let worldTransform = hitResult.worldTransform
                let worldPosition = SIMD3<Float>(
                    worldTransform.columns.3.x,
                    worldTransform.columns.3.y,
                    worldTransform.columns.3.z
                )
                textNode.simdPosition = worldPosition
            } else {
                // Fallback: déplacement approximatif
                let cameraTransform = frame.camera.transform
                let cameraRight = SIMD3<Float>(cameraTransform.columns.0.x, cameraTransform.columns.0.y, cameraTransform.columns.0.z)
                let cameraForward = SIMD3<Float>(cameraTransform.columns.2.x, cameraTransform.columns.2.y, cameraTransform.columns.2.z)
                
                let moveRight = cameraRight * Float(translation.x) * sensitivity
                let moveForward = cameraForward * Float(-translation.y) * sensitivity
                
                textNode.simdPosition += moveRight + moveForward
            }
            
            gesture.setTranslation(.zero, in: arView)
        default:
            break
        }
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let textNode = currentTextNode else { return }
        
        // Reset position/rotation/scale
        textNode.position = SCNVector3Zero
        textNode.rotation = SCNVector4Zero
        textNode.scale = SCNVector3(1, 1, 1)
    }
}










