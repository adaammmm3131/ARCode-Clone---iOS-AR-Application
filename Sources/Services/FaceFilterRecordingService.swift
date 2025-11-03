//
//  FaceFilterRecordingService.swift
//  ARCodeClone
//
//  Service pour enregistrement photo/vidéo avec filtre facial
//

import AVFoundation
import ARKit
import UIKit
import Photos

protocol FaceFilterRecordingServiceProtocol {
    func capturePhoto(from arView: ARSCNView, completion: @escaping (Result<UIImage, Error>) -> Void)
    func startVideoRecording(from arView: ARSCNView, outputURL: URL, progressHandler: @escaping (Double) -> Void) throws
    func stopVideoRecording(completion: @escaping (Result<URL, Error>) -> Void)
    func saveToPhotoLibrary(_ image: UIImage, completion: @escaping (Result<Void, Error>) -> Void)
    func shareMedia(_ image: UIImage, from viewController: UIViewController)
}

final class FaceFilterRecordingService: NSObject, FaceFilterRecordingServiceProtocol {
    private var videoWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var isRecording: Bool = false
    private var recordingStartTime: CMTime?
    
    func capturePhoto(from arView: ARSCNView, completion: @escaping (Result<UIImage, Error>) -> Void) {
        // Méthode 1: Snapshot depuis ARSCNView (inclut filtre AR)
        let snapshot = arView.snapshot()
        
        // Méthode 2 alternative: Capturer depuis ARFrame (sans overlay UI)
        // Utiliser snapshot si on veut inclure les filtres AR renderés
        
        // Vérifier si snapshot est valide
        guard let cgImage = snapshot.cgImage else {
            // Fallback: ARFrame
            guard let frame = arView.session.currentFrame else {
                completion(.failure(RecordingError.noFrame))
                return
            }
            
            let pixelBuffer = frame.capturedImage
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                completion(.failure(RecordingError.imageCreationFailed))
                return
            }
            
            let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
            completion(.success(image))
            return
        }
        
        let image = UIImage(cgImage: cgImage, scale: snapshot.scale, orientation: snapshot.imageOrientation)
        completion(.success(image))
    }
    
    func startVideoRecording(from arView: ARSCNView, outputURL: URL, progressHandler: @escaping (Double) -> Void) throws {
        guard !isRecording else {
            throw RecordingError.alreadyRecording
        }
        
        // Configuration vidéo
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: arView.frame.width,
            AVVideoHeightKey: arView.frame.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6_000_000
            ]
        ]
        
        // Créer AVAssetWriter
        do {
            let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
            
            let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoInput.expectsMediaDataInRealTime = true
            
            if writer.canAdd(videoInput) {
                writer.add(videoInput)
                self.videoInput = videoInput
            }
            
            self.videoWriter = writer
            self.isRecording = true
            self.recordingStartTime = nil
            
            // Démarrer recording (sera alimenté frame par frame)
            // Note: Nécessite implémentation complète avec ARFrame capture loop
            
        } catch {
            throw RecordingError.setupFailed(error)
        }
    }
    
    func stopVideoRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        guard let writer = videoWriter, isRecording else {
            completion(.failure(RecordingError.notRecording))
            return
        }
        
        videoInput?.markAsFinished()
        
        writer.finishWriting { [weak self] in
            guard let self = self else { return }
            
            self.isRecording = false
            self.videoWriter = nil
            self.videoInput = nil
            self.audioInput = nil
            
            if writer.status == .completed {
                completion(.success(writer.outputURL))
            } else {
                completion(.failure(RecordingError.recordingFailed(writer.error)))
            }
        }
    }
    
    func saveToPhotoLibrary(_ image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                completion(.failure(RecordingError.photoLibraryAccessDenied))
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(.success(()))
                    } else {
                        completion(.failure(error ?? RecordingError.saveFailed))
                    }
                }
            }
        }
    }
    
    func shareMedia(_ image: UIImage, from viewController: UIViewController) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityVC, animated: true)
    }
}

enum RecordingError: LocalizedError {
    case noFrame
    case imageCreationFailed
    case alreadyRecording
    case notRecording
    case setupFailed(Error?)
    case recordingFailed(Error?)
    case photoLibraryAccessDenied
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .noFrame:
            return "Aucune frame AR disponible"
        case .imageCreationFailed:
            return "Échec création image"
        case .alreadyRecording:
            return "Enregistrement déjà en cours"
        case .notRecording:
            return "Aucun enregistrement en cours"
        case .setupFailed(let error):
            return "Échec setup enregistrement: \(error?.localizedDescription ?? "erreur inconnue")"
        case .recordingFailed(let error):
            return "Échec enregistrement: \(error?.localizedDescription ?? "erreur inconnue")"
        case .photoLibraryAccessDenied:
            return "Accès photo library refusé"
        case .saveFailed:
            return "Échec sauvegarde"
        }
    }
}

