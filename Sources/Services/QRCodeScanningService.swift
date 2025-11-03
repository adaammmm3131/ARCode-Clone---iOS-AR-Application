//
//  QRCodeScanningService.swift
//  ARCodeClone
//
//  Service pour scanning QR codes natif iOS
//

import Foundation
import AVFoundation
import UIKit

protocol QRCodeScanningServiceProtocol {
    func requestCameraPermission(completion: @escaping (Bool) -> Void)
    func startScanning(completion: @escaping (Result<String, Error>) -> Void)
    func stopScanning()
    func isScanning() -> Bool
}

enum QRCodeScanningError: LocalizedError {
    case cameraNotAvailable
    case permissionDenied
    case sessionConfigurationFailed
    case scanningFailed
    
    var errorDescription: String? {
        switch self {
        case .cameraNotAvailable:
            return "Caméra non disponible"
        case .permissionDenied:
            return "Permission caméra refusée"
        case .sessionConfigurationFailed:
            return "Échec configuration session"
        case .scanningFailed:
            return "Échec scanning QR code"
        }
    }
}

final class QRCodeScanningService: NSObject, QRCodeScanningServiceProtocol {
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var metadataOutput: AVCaptureMetadataOutput?
    private var completionHandler: ((Result<String, Error>) -> Void)?
    private var isScanningActive = false
    
    // MARK: - Camera Permission
    
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    // MARK: - Scanning
    
    func startScanning(completion: @escaping (Result<String, Error>) -> Void) {
        guard !isScanningActive else {
            return
        }
        
        completionHandler = completion
        
        // Vérifier permission
        requestCameraPermission { [weak self] granted in
            guard let self = self else { return }
            
            guard granted else {
                completion(.failure(QRCodeScanningError.permissionDenied))
                return
            }
            
            self.setupCaptureSession()
        }
    }
    
    func stopScanning() {
        guard isScanningActive else { return }
        
        captureSession?.stopRunning()
        captureSession = nil
        videoPreviewLayer = nil
        metadataOutput = nil
        completionHandler = nil
        isScanningActive = false
    }
    
    func isScanning() -> Bool {
        return isScanningActive
    }
    
    // MARK: - Capture Session Setup
    
    private func setupCaptureSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            completionHandler?(.failure(QRCodeScanningError.cameraNotAvailable))
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            } else {
                completionHandler?(.failure(QRCodeScanningError.sessionConfigurationFailed))
                return
            }
            
            // Configurer metadata output pour QR codes
            let metadataOutput = AVCaptureMetadataOutput()
            
            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
                
                self.metadataOutput = metadataOutput
            } else {
                completionHandler?(.failure(QRCodeScanningError.sessionConfigurationFailed))
                return
            }
            
            self.captureSession = session
            
            // Démarrer session sur queue background
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
                DispatchQueue.main.async {
                    self?.isScanningActive = true
                }
            }
            
        } catch {
            completionHandler?(.failure(QRCodeScanningError.sessionConfigurationFailed))
        }
    }
    
    // MARK: - Preview Layer Setup
    
    func setupPreviewLayer(in view: UIView) -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else {
            return nil
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        videoPreviewLayer = previewLayer
        return previewLayer
    }
    
    func getCaptureSession() -> AVCaptureSession? {
        return captureSession
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRCodeScanningService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else {
            return
        }
        
        // QR code détecté
        stopScanning()
        completionHandler?(.success(stringValue))
    }
}

