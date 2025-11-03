//
//  ARSplatUploadService.swift
//  ARCodeClone
//
//  Service pour upload vidéo walk-around pour Gaussian Splatting
//

import Foundation
import AVFoundation
import UIKit

protocol ARSplatUploadServiceProtocol {
    func validateVideo(url: URL) -> VideoValidationResult
    func extractPreviewFrames(from url: URL, count: Int, completion: @escaping (Result<[UIImage], Error>) -> Void)
    func estimateFrameCount(url: URL) -> Int?
}

struct VideoValidationResult {
    let isValid: Bool
    let duration: TimeInterval?
    let frameCount: Int?
    let resolution: CGSize?
    let fileSize: Int64?
    let errorMessage: String?
}

enum ARSplatUploadError: LocalizedError {
    case invalidDuration
    case insufficientFrames
    case invalidFormat
    case fileTooLarge
    case frameExtractionFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidDuration:
            return "Durée invalide (30s-2min requis)"
        case .insufficientFrames:
            return "Pas assez de frames (minimum 100 requis)"
        case .invalidFormat:
            return "Format non supporté (MP4/MOV requis)"
        case .fileTooLarge:
            return "Fichier trop volumineux (max 500MB)"
        case .frameExtractionFailed(let error):
            return "Échec extraction frames: \(error.localizedDescription)"
        }
    }
}

final class ARSplatUploadService: ARSplatUploadServiceProtocol {
    private let minDuration: TimeInterval = 30.0 // 30 secondes
    private let maxDuration: TimeInterval = 120.0 // 2 minutes
    private let minFrames: Int = 100
    private let maxFileSize: Int64 = 500 * 1024 * 1024 // 500MB
    
    // MARK: - Video Validation
    
    func validateVideo(url: URL) -> VideoValidationResult {
        // Vérifier extension
        let ext = url.pathExtension.lowercased()
        guard ext == "mp4" || ext == "mov" || ext == "MOV" || ext == "MP4" else {
            return VideoValidationResult(
                isValid: false,
                duration: nil,
                frameCount: nil,
                resolution: nil,
                fileSize: nil,
                errorMessage: "Format non supporté (MP4/MOV requis)"
            )
        }
        
        // Vérifier taille fichier
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return VideoValidationResult(
                isValid: false,
                duration: nil,
                frameCount: nil,
                resolution: nil,
                fileSize: nil,
                errorMessage: "Impossible de lire les attributs du fichier"
            )
        }
        
        if fileSize > maxFileSize {
            return VideoValidationResult(
                isValid: false,
                duration: nil,
                frameCount: nil,
                resolution: nil,
                fileSize: fileSize,
                errorMessage: "Fichier trop volumineux (max 500MB)"
            )
        }
        
        // Charger asset vidéo
        let asset = AVAsset(url: url)
        guard let duration = try? asset.duration.seconds else {
            return VideoValidationResult(
                isValid: false,
                duration: nil,
                frameCount: nil,
                resolution: nil,
                fileSize: fileSize,
                errorMessage: "Impossible de lire la durée de la vidéo"
            )
        }
        
        // Vérifier durée
        guard duration >= minDuration && duration <= maxDuration else {
            return VideoValidationResult(
                isValid: false,
                duration: duration,
                frameCount: nil,
                resolution: nil,
                fileSize: fileSize,
                errorMessage: "Durée invalide (30s-2min requis, actuel: \(Int(duration))s)"
            )
        }
        
        // Estimer frame count
        let frameCount = estimateFrameCount(url: url)
        
        // Vérifier nombre de frames
        if let frames = frameCount, frames < minFrames {
            return VideoValidationResult(
                isValid: false,
                duration: duration,
                frameCount: frames,
                resolution: nil,
                fileSize: fileSize,
                errorMessage: "Pas assez de frames (minimum 100 requis, actuel: \(frames))"
            )
        }
        
        // Obtenir résolution
        guard let track = asset.tracks(withMediaType: .video).first else {
            return VideoValidationResult(
                isValid: false,
                duration: duration,
                frameCount: frameCount,
                resolution: nil,
                fileSize: fileSize,
                errorMessage: "Aucune piste vidéo trouvée"
            )
        }
        
        let resolution = track.naturalSize
        
        return VideoValidationResult(
            isValid: true,
            duration: duration,
            frameCount: frameCount,
            resolution: resolution,
            fileSize: fileSize,
            errorMessage: nil
        )
    }
    
    // MARK: - Frame Count Estimation
    
    func estimateFrameCount(url: URL) -> Int? {
        let asset = AVAsset(url: url)
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return nil
        }
        
        // Obtenir frame rate
        let frameRate = videoTrack.nominalFrameRate
        guard frameRate > 0 else {
            return nil
        }
        
        // Estimer frames depuis durée
        guard let duration = try? asset.duration.seconds else {
            return nil
        }
        
        let estimatedFrames = Int(duration * Double(frameRate))
        return estimatedFrames
    }
    
    // MARK: - Preview Frames Extraction
    
    func extractPreviewFrames(from url: URL, count: Int, completion: @escaping (Result<[UIImage], Error>) -> Void) {
        let asset = AVAsset(url: url)
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(.failure(ARSplatUploadError.frameExtractionFailed(NSError(domain: "ARSplat", code: -1, userInfo: [NSLocalizedDescriptionKey: "Aucune piste vidéo"]))))
            return
        }
        
        guard let duration = try? asset.duration.seconds, duration > 0 else {
            completion(.failure(ARSplatUploadError.frameExtractionFailed(NSError(domain: "ARSplat", code: -1, userInfo: [NSLocalizedDescriptionKey: "Durée invalide"]))))
            return
        }
        
        // Créer image generator
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        
        // Calculer intervalles pour extraction
        let interval = duration / Double(count + 1)
        var times: [CMTime] = []
        
        for i in 1...count {
            let time = CMTime(seconds: interval * Double(i), preferredTimescale: 600)
            times.append(time)
        }
        
        // Extraire frames
        var images: [UIImage] = []
        var errors: [Error] = []
        let group = DispatchGroup()
        
        for time in times {
            group.enter()
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, error, _ in
                defer { group.leave() }
                
                if let error = error {
                    errors.append(error)
                } else if let cgImage = cgImage {
                    images.append(UIImage(cgImage: cgImage))
                }
            }
        }
        
        group.notify(queue: .main) {
            if !errors.isEmpty && images.isEmpty {
                completion(.failure(ARSplatUploadError.frameExtractionFailed(errors.first!)))
            } else {
                // Trier par temps si nécessaire
                completion(.success(images))
            }
        }
    }
}









