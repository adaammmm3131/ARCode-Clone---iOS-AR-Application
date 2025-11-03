//
//  ARPortalControlsService.swift
//  ARCodeClone
//
//  Service pour contrôles look-around AR Portal (gyroscope, touch)
//

import Foundation
import CoreMotion
import SceneKit
import UIKit

protocol ARPortalControlsServiceProtocol {
    func startGyroscopeTracking(callback: @escaping (CMRotationMatrix) -> Void)
    func stopGyroscopeTracking()
    func setupTouchControls(on view: UIView, cameraNode: SCNNode)
    func removeTouchControls(from view: UIView)
}

final class ARPortalControlsService: NSObject, ARPortalControlsServiceProtocol {
    private let motionManager = CMMotionManager()
    private var gyroscopeUpdateTimer: Timer?
    private var panStartLocation: CGPoint = .zero
    private var lastPanRotation: Float = 0
    private var gestureRecognizers: [UIGestureRecognizer] = []
    private weak var cameraNode: SCNNode?
    
    // MARK: - Gyroscope Controls
    
    func startGyroscopeTracking(callback: @escaping (CMRotationMatrix) -> Void) {
        guard motionManager.isDeviceMotionAvailable else {
            print("⚠️ Device motion non disponible")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)
        
        gyroscopeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self = self,
                  let motion = self.motionManager.deviceMotion else {
                return
            }
            
            // Rotation matrix depuis attitude
            let attitude = motion.attitude
            let rotationMatrix = attitude.rotationMatrix
            
            DispatchQueue.main.async {
                callback(rotationMatrix)
            }
        }
    }
    
    func stopGyroscopeTracking() {
        motionManager.stopDeviceMotionUpdates()
        gyroscopeUpdateTimer?.invalidate()
        gyroscopeUpdateTimer = nil
    }
    
    // MARK: - Touch Controls
    
    func setupTouchControls(on view: UIView, cameraNode: SCNNode) {
        self.cameraNode = cameraNode
        
        // Pan gesture pour look-around
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)
        gestureRecognizers.append(panGesture)
    }
    
    func removeTouchControls(from view: UIView) {
        gestureRecognizers.forEach { view.removeGestureRecognizer($0) }
        gestureRecognizers.removeAll()
        cameraNode = nil
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let cameraNode = cameraNode else { return }
        
        switch gesture.state {
        case .began:
            panStartLocation = gesture.location(in: gesture.view)
            // Obtenir rotation actuelle
            if let eulerAngles = cameraNode.eulerAngles as SCNVector3? {
                lastPanRotation = eulerAngles.y
            }
            
        case .changed:
            let translation = gesture.translation(in: gesture.view)
            let sensitivity: Float = 0.005 // Ajuster sensibilité
            
            // Rotation horizontale (Y-axis) pour look-around horizontal
            let rotationY = lastPanRotation + Float(translation.x) * sensitivity
            
            // Rotation verticale (X-axis) pour look-around vertical
            let rotationX = Float(-translation.y) * sensitivity
            let clampedRotationX = max(-Float.pi / 2, min(Float.pi / 2, rotationX)) // Limiter à ±90°
            
            // Appliquer rotation à la caméra
            cameraNode.eulerAngles = SCNVector3(clampedRotationX, rotationY, 0)
            
        case .ended, .cancelled:
            break
            
        default:
            break
        }
    }
    
    // MARK: - Rotation Conversion
    
    func rotationMatrixToEulerAngles(_ matrix: CMRotationMatrix) -> SCNVector3 {
        // Convertir CMRotationMatrix en Euler angles
        // Utilisé pour synchroniser gyroscope avec rotation caméra
        let sy = sqrt(matrix.m11 * matrix.m11 + matrix.m12 * matrix.m12)
        let singular = sy < 1e-6
        
        var x: Float = 0
        var y: Float = 0
        var z: Float = 0
        
        if !singular {
            x = Float(atan2(-matrix.m23, matrix.m33))
            y = Float(atan2(matrix.m13, sy))
            z = Float(atan2(-matrix.m12, matrix.m11))
        } else {
            x = Float(atan2(-matrix.m23, matrix.m33))
            y = Float(atan2(-matrix.m31, matrix.m11))
            z = 0
        }
        
        return SCNVector3(x, y, z)
    }
}

