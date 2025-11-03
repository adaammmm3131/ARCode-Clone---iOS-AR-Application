//
//  ARPhotoFrameGestureService.swift
//  ARCodeClone
//
//  Service pour gestes AR photo frame (placement, rotation, scale)
//

import Foundation
import ARKit
import SceneKit
import UIKit

protocol ARPhotoFrameGestureServiceProtocol {
    func setupGestures(on view: UIView, scene: SCNScene, frameNode: SCNNode)
    func removeGestures(from view: UIView)
}

final class ARPhotoFrameGestureService: NSObject, ARPhotoFrameGestureServiceProtocol {
    private var gestureRecognizers: [UIGestureRecognizer] = []
    private weak var currentFrameNode: SCNNode?
    private weak var currentScene: SCNScene?
    
    // MARK: - Gesture Setup
    
    func setupGestures(on view: UIView, scene: SCNScene, frameNode: SCNNode) {
        self.currentScene = scene
        self.currentFrameNode = frameNode
        
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
        
        // Tap gesture (select)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
        gestureRecognizers.append(tapGesture)
    }
    
    func removeGestures(from view: UIView) {
        gestureRecognizers.forEach { view.removeGestureRecognizer($0) }
        gestureRecognizers.removeAll()
        currentFrameNode = nil
        currentScene = nil
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let frameNode = currentFrameNode else { return }
        
        switch gesture.state {
        case .began:
            gesture.scale = CGFloat(frameNode.scale.x)
        case .changed:
            // Limiter scale entre 0.2x et 5.0x
            let minScale: Float = 0.2
            let maxScale: Float = 5.0
            let newScale = Float(gesture.scale)
            let clampedScale = max(minScale, min(maxScale, newScale))
            
            frameNode.scale = SCNVector3(clampedScale, clampedScale, clampedScale)
        default:
            break
        }
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let frameNode = currentFrameNode else { return }
        
        switch gesture.state {
        case .began:
            break
        case .changed:
            // Rotation autour de l'axe Y (vertical pour frame mural)
            let rotationDelta = Float(gesture.rotation)
            frameNode.eulerAngles.y += rotationDelta
            gesture.rotation = 0
        default:
            break
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let frameNode = currentFrameNode,
              let arView = gesture.view as? ARSCNView,
              let frame = arView.session.currentFrame else { return }
        
        switch gesture.state {
        case .began:
            break
        case .changed:
            let location = gesture.location(in: arView)
            let sensitivity: Float = 0.001
            
            // Utiliser ARKit hit test pour déplacer sur plan vertical
            let hitTestResults = frame.hitTest(
                location,
                types: [.existingPlaneUsingExtent, .estimatedVerticalPlane]
            )
            
            if let hitResult = hitTestResults.first {
                let worldTransform = hitResult.worldTransform
                let worldPosition = SIMD3<Float>(
                    worldTransform.columns.3.x,
                    worldTransform.columns.3.y,
                    worldTransform.columns.3.z
                )
                frameNode.simdPosition = worldPosition
            } else {
                // Fallback: déplacement approximatif
                let translation = gesture.translation(in: arView)
                let cameraTransform = frame.camera.transform
                let cameraRight = SIMD3<Float>(cameraTransform.columns.0.x, cameraTransform.columns.0.y, cameraTransform.columns.0.z)
                let cameraUp = SIMD3<Float>(cameraTransform.columns.1.x, cameraTransform.columns.1.y, cameraTransform.columns.1.z)
                
                let moveRight = cameraRight * Float(translation.x) * sensitivity
                let moveUp = cameraUp * Float(-translation.y) * sensitivity
                
                frameNode.simdPosition += moveRight + moveUp
            }
            
            gesture.setTranslation(.zero, in: arView)
        default:
            break
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let frameNode = currentFrameNode else { return }
        
        // Notifier sélection frame
        NotificationCenter.default.post(
            name: .arPhotoFrameSelected,
            object: frameNode
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let arPhotoFrameSelected = Notification.Name("arPhotoFrameSelected")
}









