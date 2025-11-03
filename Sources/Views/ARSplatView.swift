//
//  ARSplatView.swift
//  ARCodeClone
//
//  Interface utilisateur pour AR Splat
//

import SwiftUI
import ARKit
import SceneKit
import PhotosUI

struct ARSplatView: View {
    @StateObject var viewModel: ARSplatViewModel
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var arView: ARSCNView?
    @State private var detectedPlane: ARPlaneAnchor?
    
    var body: some View {
        ZStack {
            // AR View
            ARSplatViewContainer(
                viewModel: viewModel,
                arView: $arView,
                detectedPlane: $detectedPlane
            )
            .ignoresSafeArea()
            
            // Controls Panel
            VStack {
                Spacer()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Instructions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gaussian Splatting")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Enregistrez une vidéo walk-around de l'objet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Durée : 30s - 2min", systemImage: "clock")
                                Label("Minimum : 100 frames", systemImage: "video")
                                Label("Format : MP4/MOV", systemImage: "film")
                                Label("Taille max : 500MB", systemImage: "doc")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        
                        // Video Preview Frames
                        if !viewModel.previewFrames.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Preview Frames")
                                    .font(.headline)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Array(viewModel.previewFrames.enumerated()), id: \.offset) { index, frame in
                                            Image(uiImage: frame)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(8)
                                                .clipped()
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        // Upload Button
                        PhotosPicker(
                            selection: $selectedVideoItem,
                            matching: .videos,
                            photoLibrary: .shared()
                        ) {
                            HStack {
                                Image(systemName: "video.badge.plus")
                                Text("Choisir Vidéo Walk-Around")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .onChange(of: selectedVideoItem) { newItem in
                            Task {
                                if let newItem = newItem,
                                   let data = try? await newItem.loadTransferable(type: Data.self),
                                   let tempURL = createTempFile(data: data) {
                                    viewModel.loadVideo(url: tempURL)
                                }
                            }
                        }
                        
                        // Submit Button (manuel)
                        if viewModel.selectedVideoURL != nil && !viewModel.isProcessing && viewModel.resultSplatURL == nil {
                            Button("Lancer Training") {
                                viewModel.submitForProcessing()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        // Processing Status
                        if viewModel.isProcessing {
                            VStack(spacing: 12) {
                                Text(viewModel.processingMessage)
                                    .font(.headline)
                                
                                ProgressView(value: viewModel.processingProgress)
                                    .progressViewStyle(LinearProgressViewStyle())
                                
                                Text("\(Int(viewModel.processingProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                if let status = viewModel.processingStatus {
                                    Text("Stage: \(status.status.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Button("Annuler") {
                                    if let jobId = viewModel.processingJobId {
                                        viewModel.exposedProcessingService.cancelProcessing(jobId: jobId) { _ in }
                                    }
                                }
                                .buttonStyle(.bordered)
                                .padding(.top, 4)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        // Result Splat
                        if let splatURL = viewModel.resultSplatURL {
                            VStack(spacing: 12) {
                                Text("Gaussian Splat prêt!")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                Button("Charger en AR") {
                                    if let arView = arView,
                                       let scene = arView.scene.rootNode.scene {
                                        let position = detectedPlane?.center ?? SIMD3<Float>(0, 0, -1)
                                        viewModel.loadSplatFile(url: splatURL, in: scene, at: position)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        // Error Display
                        if let error = viewModel.errorMessage {
                            Text("Erreur: \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 500)
                .background(Color.white.opacity(0.95))
                .cornerRadius(16)
            }
            .padding()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
    // MARK: - Helper
    
    private func createTempFile(data: Data) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }
}

// MARK: - AR Splat View Container

struct ARSplatViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARSplatViewModel
    @Binding var arView: ARSCNView?
    @Binding var detectedPlane: ARPlaneAnchor?
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        
        // Configuration AR
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        // Créer scène
        let scene = SCNScene()
        arView.scene = scene
        
        // Configuration rendering
        arView.antialiasingMode = .multisampling4X
        arView.preferredFramesPerSecond = 60
        
        // Démarrage session
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // Définir delegate
        arView.session.delegate = context.coordinator
        
        self.arView = arView
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Mises à jour si nécessaire
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, detectedPlane: $detectedPlane)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        @ObservedObject var viewModel: ARSplatViewModel
        @Binding var detectedPlane: ARPlaneAnchor?
        
        init(viewModel: ARSplatViewModel, detectedPlane: Binding<ARPlaneAnchor?>) {
            self.viewModel = viewModel
            self._detectedPlane = detectedPlane
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            // Détecter premier plan
            if detectedPlane == nil {
                if let planeAnchor = anchors.first(where: { $0 is ARPlaneAnchor }) as? ARPlaneAnchor {
                    detectedPlane = planeAnchor
                }
            }
        }
    }
}

