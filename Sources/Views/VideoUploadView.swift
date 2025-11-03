//
//  VideoUploadView.swift
//  ARCodeClone
//
//  Vue pour l'upload de vidéo pour photogrammétrie
//

import SwiftUI
import PhotosUI

struct VideoUploadView: View {
    @StateObject private var viewModel: VideoUploadViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(uploadService: VideoUploadServiceProtocol) {
        _viewModel = StateObject(wrappedValue: VideoUploadViewModel(uploadService: uploadService))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Capture d'objet 3D")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Pour créer un modèle 3D, enregistrez une vidéo circulaire de l'objet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Durée : 1-1.5 minutes", systemImage: "clock")
                        Label("Taille max : 250 MB", systemImage: "doc")
                        Label("Format : MP4 ou MOV", systemImage: "film")
                        Label("Mouvement circulaire autour de l'objet", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Bouton sélection vidéo
                if viewModel.selectedVideoURL == nil {
                    PhotosPicker(
                        selection: $viewModel.selectedItem,
                        matching: .videos,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            Image(systemName: "video.badge.plus")
                            Text("Sélectionner une vidéo")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                // Aperçu et validation
                if let videoURL = viewModel.selectedVideoURL {
                    VStack(spacing: 16) {
                        // Aperçu vidéo
                        VideoPreviewView(videoURL: videoURL)
                            .frame(height: 200)
                            .cornerRadius(12)
                        
                        // Info vidéo
                        if let validation = viewModel.validationResult {
                            VideoInfoView(validation: validation)
                        }
                        
                        // Boutons actions
                        HStack(spacing: 12) {
                            Button("Annuler") {
                                viewModel.cancelSelection()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Upload") {
                                Task {
                                    await viewModel.uploadVideo()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!viewModel.canUpload)
                        }
                    }
                    .padding()
                }
                
                // Barre de progression
                if viewModel.isUploading {
                    VStack(spacing: 8) {
                        ProgressView(value: viewModel.uploadProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text("Upload en cours... \(Int(viewModel.uploadProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                // Messages d'erreur
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Object Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Video Preview

struct VideoPreviewView: UIViewRepresentable {
    let videoURL: URL
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let playerLayer = AVPlayerLayer()
        let player = AVPlayer(url: videoURL)
        
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(playerLayer)
        
        // Auto-play pour preview
        player.play()
        
        // Stopper après première lecture
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVPlayerLayer {
            layer.frame = uiView.bounds
        }
    }
}

// MARK: - Video Info View

struct VideoInfoView: View {
    let validation: VideoValidationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: validation.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(validation.isValid ? .green : .red)
                Text(validation.isValid ? "Vidéo valide" : "Vidéo invalide")
                    .fontWeight(.semibold)
            }
            
            Divider()
            
            InfoRow(label: "Durée", value: formatDuration(validation.duration))
            InfoRow(label: "Taille", value: formatFileSize(validation.fileSize))
            InfoRow(label: "Résolution", value: "\(Int(validation.resolution.width))×\(Int(validation.resolution.height))")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(minutes):\(String(format: "%02d", secs))"
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let mb = Double(bytes) / (1024 * 1024)
        return String(format: "%.2f MB", mb)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}













