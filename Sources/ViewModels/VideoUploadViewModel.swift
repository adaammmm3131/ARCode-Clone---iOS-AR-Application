//
//  VideoUploadViewModel.swift
//  ARCodeClone
//
//  ViewModel pour l'upload de vidéo
//

import Foundation
import PhotosUI
import AVFoundation

@MainActor
final class VideoUploadViewModel: BaseViewModel {
    private let uploadService: VideoUploadServiceProtocol
    
    @Published var selectedItem: PhotosPickerItem?
    @Published var selectedVideoURL: URL?
    @Published var validationResult: VideoValidationResult?
    @Published var isUploading: Bool = false
    @Published var uploadProgress: Double = 0.0
    @Published var canUpload: Bool = false
    
    init(uploadService: VideoUploadServiceProtocol) {
        self.uploadService = uploadService
        super.init()
        
        setupPhotoPickerObserver()
    }
    
    private func setupPhotoPickerObserver() {
        $selectedItem
            .compactMap { $0 }
            .task { item in
                await loadVideo(from: item)
            }
            .store(in: &cancellables)
    }
    
    private func loadVideo(from item: PhotosPickerItem) async {
        isLoading = true
        clearError()
        
        do {
            // Charger la vidéo
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw VideoUploadError.validationFailed
            }
            
            // Sauvegarder temporairement
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            
            try data.write(to: tempURL)
            selectedVideoURL = tempURL
            
            // Valider la vidéo
            validationResult = try uploadService.validateVideo(tempURL)
            canUpload = validationResult?.isValid ?? false
            
        } catch {
            showError(error.localizedDescription)
            selectedVideoURL = nil
            validationResult = nil
            canUpload = false
        }
        
        isLoading = false
    }
    
    func cancelSelection() {
        selectedItem = nil
        selectedVideoURL = nil
        validationResult = nil
        canUpload = false
        clearError()
    }
    
    func uploadVideo() async {
        guard let videoURL = selectedVideoURL else { return }
        
        isUploading = true
        uploadProgress = 0.0
        clearError()
        
        do {
            let response = try await uploadService.uploadVideo(
                videoURL,
                endpoint: .photogrammetry,
                progressHandler: { progress in
                    self.uploadProgress = progress
                }
            )
            
            // Upload réussi
            isUploading = false
            uploadProgress = 1.0
            
            // TODO: Naviguer vers l'écran de suivi de traitement
            
        } catch {
            showError(error.localizedDescription)
            isUploading = false
            uploadProgress = 0.0
        }
    }
}












