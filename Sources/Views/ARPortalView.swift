//
//  ARPortalView.swift
//  ARCodeClone
//
//  Interface utilisateur pour AR Portal
//

import SwiftUI
import ARKit
import SceneKit
import PhotosUI

struct ARPortalView: View {
    @StateObject var viewModel: ARPortalViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showMediaPicker: Bool = false
    @State private var arView: ARSCNView?
    @State private var showControls: Bool = true
    
    var body: some View {
        ZStack {
            // AR View
            ARPortalViewContainer(
                viewModel: viewModel,
                arView: $arView
            )
            .ignoresSafeArea()
            
            // Controls Overlay
            if showControls {
                VStack {
                    HStack {
                        Button(action: {
                            showMediaPicker = true
                        }) {
                            Image(systemName: "photo.badge.plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Toggle Immersive
                        Button(action: {
                            if viewModel.isImmersive {
                                viewModel.exitImmersiveMode()
                            } else {
                                viewModel.enterImmersiveMode()
                            }
                        }) {
                            Image(systemName: viewModel.isImmersive ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(viewModel.isImmersive ? Color.red.opacity(0.6) : Color.blue.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.portalNode == nil)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Portal Info
                    if let portalNode = viewModel.portalNode {
                        VStack(spacing: 8) {
                            Text("Portal actif")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Toggle("Gyroscope", isOn: $viewModel.useGyroscope)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .padding()
                    }
                }
            }
            
            // Loading Indicator
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
            
            // Error Message
            if let error = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text("Erreur: \(error)")
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .padding()
                }
            }
        }
        .photosPicker(
            isPresented: $showMediaPicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let newItem = newItem {
                    // Charger image depuis PhotosPicker
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        // Sauvegarder temporairement
                        let tempURL = FileManager.default.temporaryDirectory
                            .appendingPathComponent(UUID().uuidString)
                            .appendingPathExtension("jpg")
                        
                        if let imageData = image.jpegData(compressionQuality: 0.9) {
                            try? imageData.write(to: tempURL)
                            
                            // Obtenir scène AR et charger portal
                            if let arView = arView,
                               let scene = arView.scene.rootNode.scene {
                                let position = SIMD3<Float>(0, 0, -2) // 2m devant la caméra
                                viewModel.loadPortal(url: tempURL, in: scene, at: position)
                                
                                // Setup contrôles
                                if let cameraNode = arView.pointOfView {
                                    viewModel.setupControls(on: arView, cameraNode: cameraNode)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onDisappear {
            if let arView = arView {
                viewModel.removeControls(from: arView)
            }
            viewModel.cleanup()
        }
    }
}

// MARK: - AR Portal View Container

struct ARPortalViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARPortalViewModel
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
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        @ObservedObject var viewModel: ARPortalViewModel
        
        init(viewModel: ARPortalViewModel) {
            self.viewModel = viewModel
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            // Notifier détection plans si nécessaire
            // Le portal peut être placé sur plan détecté
        }
    }
}










