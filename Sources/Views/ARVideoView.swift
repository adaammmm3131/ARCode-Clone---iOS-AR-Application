//
//  ARVideoView.swift
//  ARCodeClone
//
//  Interface utilisateur pour AR Video Player
//

import SwiftUI
import ARKit
import SceneKit
import PhotosUI

struct ARVideoView: View {
    @StateObject var viewModel: ARVideoViewModel
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var showVideoPicker: Bool = false
    @State private var arView: ARSCNView?
    @State private var showControls: Bool = true
    @State private var controlsOpacity: Double = 1.0
    
    var body: some View {
        ZStack {
            // AR View
            ARVideoViewContainer(
                viewModel: viewModel,
                arView: $arView
            )
            .ignoresSafeArea()
            
            // Controls Overlay
            if showControls && viewModel.videoNode != nil {
                VStack {
                    Spacer()
                    
                    ARVideoControlsOverlay(viewModel: viewModel)
                        .opacity(controlsOpacity)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(12)
                        .padding()
                }
            }
            
            // Top Controls
            VStack {
                HStack {
                    Button(action: {
                        showVideoPicker = true
                    }) {
                        Image(systemName: "video.badge.plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showControls.toggle()
                            controlsOpacity = showControls ? 1.0 : 0.0
                        }
                    }) {
                        Image(systemName: showControls ? "eye.slash" : "eye")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
            }
        }
        .photosPicker(
            isPresented: $showVideoPicker,
            selection: $selectedVideoItem,
            matching: .videos
        )
        .onChange(of: selectedVideoItem) { newItem in
            if let newItem = newItem {
                // Charger vidéo depuis PhotosPicker
                Task {
                    // Utiliser Movie.self pour PhotosPicker
                    if let result = try? await newItem.loadTransferable(type: Movie.self),
                       let videoURL = result.url {
                        // Obtenir scène AR
                        if let arView = arView,
                           let scene = arView.scene.rootNode.scene {
                            // Placement flottant par défaut
                            let position = SIMD3<Float>(0, 0, -1) // 1m devant la caméra
                            viewModel.loadVideo(
                                url: videoURL,
                                in: scene,
                                placement: .floating(position: position)
                            )
                            
                            // Setup gestes
                            viewModel.setupGestures(on: arView, scene: scene)
                        }
                    }
                }
            }
        }
        .onDisappear {
            if let arView = arView {
                viewModel.removeGestures(from: arView)
            }
            viewModel.cleanup()
        }
    }
}

// MARK: - AR View Container

struct ARVideoViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARVideoViewModel
    @Binding var arView: ARSCNView?
    
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
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        @ObservedObject var viewModel: ARVideoViewModel
        
        init(viewModel: ARVideoViewModel) {
            self.viewModel = viewModel
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            // Notifier détection plans si nécessaire
            if let planeAnchor = anchors.first as? ARPlaneAnchor,
               viewModel.videoNode == nil {
                // Optionnel: placer vidéo sur premier plan détecté
            }
        }
    }
}

// MARK: - Video Controls Overlay

struct ARVideoControlsOverlay: View {
    @ObservedObject var viewModel: ARVideoViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress Bar
            ProgressView(value: viewModel.progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .padding(.horizontal)
            
            // Time Labels
            HStack {
                Text(formatTime(viewModel.currentTime))
                    .foregroundColor(.white)
                    .font(.caption)
                
                Spacer()
                
                Text(formatTime(viewModel.duration))
                    .foregroundColor(.white)
                    .font(.caption)
            }
            .padding(.horizontal)
            
            // Controls
            HStack(spacing: 24) {
                // Play/Pause
                Button(action: {
                    viewModel.togglePlayback()
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                
                // Volume
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.white)
                    
                    Slider(value: Binding(
                        get: { viewModel.volume },
                        set: { viewModel.setVolume($0) }
                    ), in: 0...1)
                    .frame(width: 100)
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - Movie Transferable

struct Movie: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            // Copier fichier vers temp directory
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return Movie(url: tempURL)
        }
    }
}

// MARK: - Extension pour Placement sur Plane

extension ARVideoViewModel {
    func placeVideoOnPlane(_ planeAnchor: ARPlaneAnchor, in scene: SCNScene) {
        guard let videoURL = selectedVideoURL else { return }
        
        loadVideo(url: videoURL, in: scene, placement: .onPlane(planeAnchor: planeAnchor))
    }
}

