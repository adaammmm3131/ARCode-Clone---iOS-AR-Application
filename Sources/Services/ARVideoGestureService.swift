//
//  ARVideoGestureService.swift
//  ARCodeClone
//
//  Service pour gestion gestes AR vidéo (pinch, rotate, pan)
//

import Foundation
import ARKit
import SceneKit
import UIKit

protocol ARVideoGestureServiceProtocol {
    func setupGestures(on view: UIView, scene: SCNScene, videoNode: SCNNode)
    func removeGestures(from view: UIView)
}

final class ARVideoGestureService: NSObject, ARVideoGestureServiceProtocol {
    private var gestureRecognizers: [UIGestureRecognizer] = []
    private weak var currentVideoNode: SCNNode?
    private weak var currentScene: SCNScene?
    
    // MARK: - Gesture Setup
    
    func setupGestures(on view: UIView, scene: SCNScene, videoNode: SCNNode) {
        self.currentScene = scene
        self.currentVideoNode = videoNode
        
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
        
        // Tap gesture (toggle playback)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
        gestureRecognizers.append(tapGesture)
        
        // Double tap (reset)
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        tapGesture.require(toFail: doubleTapGesture)
        view.addGestureRecognizer(doubleTapGesture)
        gestureRecognizers.append(doubleTapGesture)
    }
    
    func removeGestures(from view: UIView) {
        gestureRecognizers.forEach { view.removeGestureRecognizer($0) }
        gestureRecognizers.removeAll()
        currentVideoNode = nil
        currentScene = nil
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let videoNode = currentVideoNode else { return }
        
        switch gesture.state {
        case .began:
            gesture.scale = CGFloat(videoNode.scale.x)
        case .changed:
            // Limiter scale entre 0.1x et 5.0x
            let minScale: Float = 0.1
            let maxScale: Float = 5.0
            let newScale = Float(gesture.scale)
            let clampedScale = max(minScale, min(maxScale, newScale))
            
            videoNode.scale = SCNVector3(clampedScale, clampedScale, clampedScale)
        default:
            break
        }
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let videoNode = currentVideoNode else { return }
        
        switch gesture.state {
        case .began:
            // Rotation initiale
            break
        case .changed:
            // Rotation autour de l'axe Y (vertical)
            let rotationDelta = Float(gesture.rotation)
            videoNode.eulerAngles.y += rotationDelta
            gesture.rotation = 0 // Reset pour prochain changement
        default:
            break
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let videoNode = currentVideoNode,
              let arView = gesture.view as? ARSCNView,
              let frame = arView.session.currentFrame else { return }
        
        switch gesture.state {
        case .began:
            break
        case .changed:
            // Projeter mouvement 2D en 3D
            let translation = gesture.translation(in: arView)
            let location = gesture.location(in: arView)
            let sensitivity: Float = 0.001 // Ajuster sensibilité
            
            // Utiliser ARKit hit test via ARFrame pour déplacer sur plan détecté
            let hitTestResults = frame.hitTest(
                location,
                types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane, .estimatedVerticalPlane]
            )
            
            if let hitResult = hitTestResults.first {
                // Déplacer vidéo vers point de hit test sur plan
                let worldTransform = hitResult.worldTransform
                let worldPosition = SIMD3<Float>(
                    worldTransform.columns.3.x,
                    worldTransform.columns.3.y,
                    worldTransform.columns.3.z
                )
                videoNode.simdPosition = worldPosition
            } else {
                // Fallback: déplacement approximatif basé sur translation
                // Calculer mouvement 3D depuis translation 2D
                // Utiliser camera orientation pour projeter correctement
                let cameraTransform = frame.camera.transform
                let cameraForward = SIMD3<Float>(cameraTransform.columns.2.x, cameraTransform.columns.2.y, cameraTransform.columns.2.z)
                let cameraRight = SIMD3<Float>(cameraTransform.columns.0.x, cameraTransform.columns.0.y, cameraTransform.columns.0.z)
                
                let moveRight = cameraRight * Float(translation.x) * sensitivity
                let moveForward = cameraForward * Float(-translation.y) * sensitivity
                
                videoNode.simdPosition += moveRight + moveForward
            }
            
            gesture.setTranslation(.zero, in: arView)
        default:
            break
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let videoNode = currentVideoNode else { return }
        
        // Toggle playback via notification ou callback
        NotificationCenter.default.post(
            name: .arVideoTogglePlayback,
            object: videoNode
        )
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let videoNode = currentVideoNode else { return }
        
        // Reset position/rotation/scale
        videoNode.position = SCNVector3Zero
        videoNode.rotation = SCNVector4Zero
        videoNode.scale = SCNVector3(1, 1, 1)
        
        NotificationCenter.default.post(
            name: .arVideoReset,
            object: videoNode
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let arVideoTogglePlayback = Notification.Name("arVideoTogglePlayback")
    static let arVideoReset = Notification.Name("arVideoReset")
}

