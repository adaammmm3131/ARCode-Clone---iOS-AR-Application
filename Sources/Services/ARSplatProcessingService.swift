//
//  ARSplatProcessingService.swift
//  ARCodeClone
//
//  Service pour monitoring training Gaussian Splatting
//

import Foundation
import Combine

protocol ARSplatProcessingServiceProtocol {
    func submitVideo(_ videoURL: URL, completion: @escaping (Result<String, Error>) -> Void) -> String // jobId
    func getProcessingStatus(jobId: String, completion: @escaping (Result<ProcessingStatus, Error>) -> Void)
    func subscribeToProgress(jobId: String) -> AnyPublisher<ProcessingProgress, Never>
    func cancelProcessing(jobId: String, completion: @escaping (Result<Void, Error>) -> Void)
}

struct ProcessingStatus: Codable {
    let jobId: String
    let status: ProcessingStatusType
    let progress: Float // 0.0 - 1.0
    let message: String?
    let resultURL: String? // URL du fichier .PLY/.SPLAT final
    let error: String?
    let startedAt: Date?
    let completedAt: Date?
    let estimatedTimeRemaining: TimeInterval?
}

enum ProcessingStatusType: String, Codable {
    case queued = "queued"
    case preprocessing = "preprocessing"
    case training = "training"
    case exporting = "exporting"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
}

struct ProcessingProgress: Codable {
    let jobId: String
    let stage: String
    let progress: Float
    let message: String
    let timestamp: Date
}

enum ARSplatProcessingError: LocalizedError {
    case invalidJobId
    case networkError(Error)
    case apiError(String)
    case processingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidJobId:
            return "ID de job invalide"
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        case .apiError(let message):
            return "Erreur API: \(message)"
        case .processingFailed(let message):
            return "Échec traitement: \(message)"
        }
    }
}

final class ARSplatProcessingService: ARSplatProcessingServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let baseURL: String
    private var progressPublishers: [String: PassthroughSubject<ProcessingProgress, Never>] = [:]
    private var pollingTimers: [String: Timer] = [:]
    
    init(networkService: NetworkServiceProtocol, baseURL: String = "http://localhost:5000") {
        self.networkService = networkService
        self.baseURL = baseURL
    }
    
    // MARK: - Video Submission
    
    func submitVideo(_ videoURL: URL, completion: @escaping (Result<String, Error>) -> Void) -> String {
        // Générer job ID
        let jobId = UUID().uuidString
        
        // Upload vidéo et créer job
        Task {
            do {
                // Upload vidéo
                let uploadResponse: UploadResponse = try await networkService.uploadVideo(
                    videoURL,
                    endpoint: .photogrammetry, // Utiliser endpoint photogrammetry pour l'instant
                    progressHandler: { progress in
                        // Progress upload
                    }
                )
                
                // Créer job de training Gaussian Splatting
                let body: [String: Any] = [
                    "job_type": "gaussian_splatting",
                    "video_url": uploadResponse.url,
                    "job_id": jobId
                ]
                
                // Note: Nécessite endpoint API dédié pour Gaussian Splatting
                // Pour l'instant, simuler création job
                
                DispatchQueue.main.async {
                    completion(.success(jobId))
                    
                    // Démarrer polling pour ce job
                    self.startPolling(jobId: jobId)
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(ARSplatProcessingError.networkError(error)))
                }
            }
        }
        
        return jobId
    }
    
    // MARK: - Status Checking
    
    func getProcessingStatus(jobId: String, completion: @escaping (Result<ProcessingStatus, Error>) -> Void) {
        Task {
            do {
                // Appel API pour status
                // Note: Nécessite endpoint API /api/v1/gaussian/status/{jobId}
                let response: [String: Any] = try await networkService.request(
                    .photogrammetry, // Utiliser endpoint existant temporairement
                    method: .get,
                    parameters: ["job_id": jobId],
                    headers: nil
                )
                
                // Parser response
                guard let statusString = response["status"] as? String,
                      let statusType = ProcessingStatusType(rawValue: statusString) else {
                    completion(.failure(ARSplatProcessingError.apiError("Format réponse invalide")))
                    return
                }
                
                let status = ProcessingStatus(
                    jobId: jobId,
                    status: statusType,
                    progress: response["progress"] as? Float ?? 0.0,
                    message: response["message"] as? String,
                    resultURL: response["result_url"] as? String,
                    error: response["error"] as? String,
                    startedAt: nil,
                    completedAt: nil,
                    estimatedTimeRemaining: response["estimated_time_remaining"] as? TimeInterval
                )
                
                DispatchQueue.main.async {
                    completion(.success(status))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(ARSplatProcessingError.networkError(error)))
                }
            }
        }
    }
    
    // MARK: - Progress Subscription
    
    func subscribeToProgress(jobId: String) -> AnyPublisher<ProcessingProgress, Never> {
        // Créer publisher si inexistant
        if progressPublishers[jobId] == nil {
            progressPublishers[jobId] = PassthroughSubject<ProcessingProgress, Never>()
            
            // Démarrer polling
            startPolling(jobId: jobId)
        }
        
        return progressPublishers[jobId]!.eraseToAnyPublisher()
    }
    
    // MARK: - Cancellation
    
    func cancelProcessing(jobId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Arrêter polling
        stopPolling(jobId: jobId)
        
        // Appel API pour cancellation
        Task {
            do {
                // Note: Nécessite endpoint API pour cancellation
                let _: [String: Any] = try await networkService.request(
                    .photogrammetry,
                    method: .delete,
                    parameters: ["job_id": jobId],
                    headers: nil
                )
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(ARSplatProcessingError.networkError(error)))
                }
            }
        }
    }
    
    // MARK: - Polling
    
    private func startPolling(jobId: String) {
        // Arrêter timer existant si présent
        stopPolling(jobId: jobId)
        
        let timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkProgress(jobId: jobId)
        }
        
        pollingTimers[jobId] = timer
        RunLoop.current.add(timer, forMode: .common)
        
        // Vérifier immédiatement
        checkProgress(jobId: jobId)
    }
    
    private func stopPolling(jobId: String) {
        pollingTimers[jobId]?.invalidate()
        pollingTimers.removeValue(forKey: jobId)
    }
    
    private func checkProgress(jobId: String) {
        getProcessingStatus(jobId: jobId) { [weak self] result in
            guard let self = self,
                  let publisher = self.progressPublishers[jobId] else {
                return
            }
            
            switch result {
            case .success(let status):
                let progress = ProcessingProgress(
                    jobId: jobId,
                    stage: status.status.rawValue,
                    progress: status.progress,
                    message: status.message ?? status.status.rawValue,
                    timestamp: Date()
                )
                
                publisher.send(progress)
                
                // Arrêter polling si terminé
                if status.status == .completed || status.status == .failed || status.status == .cancelled {
                    self.stopPolling(jobId: jobId)
                    publisher.send(completion: .finished)
                    self.progressPublishers.removeValue(forKey: jobId)
                }
                
            case .failure:
                // Continuer polling même en cas d'erreur temporaire
                break
            }
        }
    }
}









