//
//  VideoUploadService.swift
//  ARCodeClone
//
//  Service pour l'upload de vidéos pour photogrammétrie
//

import Foundation
import AVFoundation
import UIKit

protocol VideoUploadServiceProtocol {
    func uploadVideo(
        _ videoURL: URL,
        endpoint: APIEndpoint,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> UploadResponse
    
    func validateVideo(_ videoURL: URL) throws -> VideoValidationResult
    func compressVideoIfNeeded(_ videoURL: URL, maxSizeMB: Int) async throws -> URL?
}

final class VideoUploadService: VideoUploadServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let maxDurationSeconds: TimeInterval = 90 // 1.5 minutes
    private let minDurationSeconds: TimeInterval = 60 // 1 minute
    private let maxSizeBytes: Int = 250 * 1024 * 1024 // 250MB
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    // MARK: - Video Validation
    
    func validateVideo(_ videoURL: URL) throws -> VideoValidationResult {
        // Vérifier que le fichier existe
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            throw VideoValidationError.fileNotFound
        }
        
        // Vérifier la taille
        let attributes = try FileManager.default.attributesOfItem(atPath: videoURL.path)
        guard let fileSize = attributes[.size] as? Int else {
            throw VideoValidationError.cannotReadFileSize
        }
        
        if fileSize > maxSizeBytes {
            throw VideoValidationError.fileTooLarge(maxSizeMB: maxSizeBytes / (1024 * 1024))
        }
        
        // Charger l'asset vidéo
        let asset = AVAsset(url: videoURL)
        
        // Vérifier la durée (synchrone)
        let duration = asset.duration
        let durationSeconds = CMTimeGetSeconds(duration)
        
        if durationSeconds < minDurationSeconds {
            throw VideoValidationError.tooShort(minDuration: Int(minDurationSeconds))
        }
        
        if durationSeconds > maxDurationSeconds {
            throw VideoValidationError.tooLong(maxDuration: Int(maxDurationSeconds))
        }
        
        // Vérifier le format (synchrone)
        let tracks = asset.tracks(withMediaType: .video)
        guard let track = tracks.first else {
            throw VideoValidationError.invalidFormat
        }
        
        let formatDescriptions = track.formatDescriptions
        guard let formatDescription = formatDescriptions.first as? CMFormatDescription else {
            throw VideoValidationError.invalidFormat
        }
        
        // Vérifier que c'est MP4 ou MOV compatible
        let codec = CMFormatDescriptionGetMediaSubType(formatDescription)
        let isValidFormat = codec == kCMVideoCodecType_H264 || 
                           codec == kCMVideoCodecType_HEVC ||
                           codec == kCMVideoCodecType_MPEG4Video
        
        guard isValidFormat else {
            throw VideoValidationError.invalidFormat
        }
        
        // Obtenir la résolution
        let naturalSize = track.naturalSize
        
        return VideoValidationResult(
            isValid: true,
            duration: durationSeconds,
            fileSize: fileSize,
            resolution: naturalSize,
            codec: codec
        )
    }
    
    // MARK: - Video Compression
    
    func compressVideoIfNeeded(_ videoURL: URL, maxSizeMB: Int = 250) async throws -> URL? {
        let attributes = try FileManager.default.attributesOfItem(atPath: videoURL.path)
        guard let fileSize = attributes[.size] as? Int else {
            return nil
        }
        
        let maxSizeBytes = maxSizeMB * 1024 * 1024
        
        // Si la taille est acceptable, pas besoin de compression
        if fileSize <= maxSizeBytes {
            return nil
        }
        
        // Compression nécessaire
        return try await compressVideo(videoURL, targetSizeMB: maxSizeMB)
    }
    
    private func compressVideo(_ videoURL: URL, targetSizeMB: Int) async throws -> URL {
        let asset = AVAsset(url: videoURL)
        
        // Créer un preset de compression
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetMediumQuality
        ) else {
            throw VideoCompressionError.cannotCreateExportSession
        }
        
        // URL de sortie
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        // Supprimer si existe déjà
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        // Ajuster le bitrate pour atteindre la taille cible
        let duration = asset.duration
        let durationSeconds = CMTimeGetSeconds(duration)
        let targetBitrate = (targetSizeMB * 8 * 1024 * 1024) / Int(durationSeconds) // bits per second
        
        if let videoTrack = asset.tracks(withMediaType: .video).first {
            let videoCompressionProperties: [String: Any] = [
                AVVideoAverageBitRateKey: targetBitrate,
                AVVideoMaxKeyFrameIntervalKey: 30
            ]
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoCompressionPropertiesKey: videoCompressionProperties
            ]
            
            exportSession.videoComposition = createVideoComposition(
                for: asset,
                videoSettings: videoSettings
            )
        }
        
        // Exporter
        await exportSession.export()
        
        guard exportSession.status == .completed else {
            if let error = exportSession.error {
                throw error
            }
            throw VideoCompressionError.exportFailed
        }
        
        return outputURL
    }
    
    private func createVideoComposition(
        for asset: AVAsset,
        videoSettings: [String: Any]
    ) -> AVVideoComposition? {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return nil
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoTrack.naturalSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        instruction.layerInstructions = [layerInstruction]
        
        videoComposition.instructions = [instruction]
        
        return videoComposition
    }
    
    // MARK: - Video Upload
    
    func uploadVideo(
        _ videoURL: URL,
        endpoint: APIEndpoint,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> UploadResponse {
        // Valider la vidéo
        let validation = try validateVideo(videoURL)
        guard validation.isValid else {
            throw VideoUploadError.validationFailed
        }
        
        // Compresser si nécessaire
        let finalVideoURL = try await compressVideoIfNeeded(videoURL) ?? videoURL
        
        // Créer la requête multipart
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "https://api.ar-code.com\(endpoint.path)")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Lire les données vidéo
        let videoData = try Data(contentsOf: finalVideoURL)
        
        // Créer le body multipart
        var body = Data()
        
        // Boundary de début
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"video\"; filename=\"\(finalVideoURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(videoData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Upload avec suivi de progression
        let (data, response) = try await uploadWithProgress(
            request: request,
            progressHandler: progressHandler
        )
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw VideoUploadError.uploadFailed
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(UploadResponse.self, from: data)
    }
    
    private func uploadWithProgress(
        request: URLRequest,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> (Data, URLResponse) {
        // TODO: Implémenter upload avec progression réelle
        // Pour l'instant, upload simple
        let (data, response) = try await URLSession.shared.data(for: request)
        progressHandler(1.0)
        return (data, response)
    }
}

// MARK: - Supporting Types

struct VideoValidationResult {
    let isValid: Bool
    let duration: TimeInterval
    let fileSize: Int
    let resolution: CGSize
    let codec: FourCharCode
}

enum VideoValidationError: LocalizedError {
    case fileNotFound
    case cannotReadFileSize
    case fileTooLarge(maxSizeMB: Int)
    case tooShort(minDuration: Int)
    case tooLong(maxDuration: Int)
    case invalidFormat
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Le fichier vidéo est introuvable"
        case .cannotReadFileSize:
            return "Impossible de lire la taille du fichier"
        case .fileTooLarge(let maxMB):
            return "Le fichier est trop volumineux (maximum \(maxMB) MB)"
        case .tooShort(let min):
            return "La vidéo est trop courte (minimum \(min) secondes)"
        case .tooLong(let max):
            return "La vidéo est trop longue (maximum \(max) secondes)"
        case .invalidFormat:
            return "Format vidéo non supporté (MP4 ou MOV requis)"
        }
    }
}

enum VideoCompressionError: LocalizedError {
    case cannotCreateExportSession
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .cannotCreateExportSession:
            return "Impossible de créer la session d'export"
        case .exportFailed:
            return "L'export de la vidéo a échoué"
        }
    }
}

enum VideoUploadError: LocalizedError {
    case validationFailed
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .validationFailed:
            return "La validation de la vidéo a échoué"
        case .uploadFailed:
            return "L'upload de la vidéo a échoué"
        }
    }
}

