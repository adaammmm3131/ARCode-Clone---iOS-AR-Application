//
//  FaceFilterViewModel.swift
//  ARCodeClone
//
//  ViewModel pour Face Filter
//

import Foundation
import ARKit
import SwiftUI
import Combine
import PhotosUI

final class FaceFilterViewModel: BaseViewModel, ObservableObject {
    @Published var isFilterActive: Bool = false
    @Published var logoImage: UIImage?
    @Published var detectedFacesCount: Int = 0
    @Published var cameraPosition: AVCaptureDevice.Position = .front
    @Published var isRecording: Bool = false
    @Published var recordingProgress: Double = 0.0
    
    private let faceFilterService: FaceFilterServiceProtocol
    private let arService: ARServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(faceFilterService: FaceFilterServiceProtocol, arService: ARServiceProtocol) {
        self.faceFilterService = faceFilterService
        self.arService = arService
        super.init()
        
        setupBindings()
    }
    
    private func setupBindings() {
        // Écouter faces détectées
        faceFilterService.detectedFaces
            .map { $0.count }
            .assign(to: &$detectedFacesCount)
    }
    
    func loadLogo(image: UIImage) {
        logoImage = image
        faceFilterService.setLogo(image)
        isFilterActive = true
    }
    
    func toggleCamera() {
        let newPosition: AVCaptureDevice.Position = cameraPosition == .front ? .back : .front
        
        // Note: ARFaceTrackingConfiguration supporte uniquement front camera
        // Le switching nécessiterait changer vers ARWorldTrackingConfiguration
        // Pour l'instant, seulement front camera supportée pour face tracking
        
        cameraPosition = newPosition
        
        // TODO: Implémenter vrai switch avec ARService
        // Nécessiterait changer configuration ARSession
    }
    
    func startRecording() {
        isRecording = true
        recordingProgress = 0.0
        // TODO: Implémenter recording
    }
    
    func stopRecording() {
        isRecording = false
        // TODO: Finaliser enregistrement
    }
    
    func takePhoto(arView: ARSCNView?, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let arView = arView else {
            completion(.failure(RecordingError.noFrame))
            return
        }
        
        let recordingService = FaceFilterRecordingService()
        recordingService.capturePhoto(from: arView) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}

