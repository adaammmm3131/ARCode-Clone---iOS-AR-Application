//
//  ARPhotoFrameView.swift
//  ARCodeClone
//
//  Interface utilisateur pour AR Photo Frame
//

import SwiftUI
import ARKit
import SceneKit
import PhotosUI

struct ARPhotoFrameView: View {
    @StateObject var viewModel: ARPhotoFrameViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showImagePicker: Bool = false
    @State private var showFrameStylePicker: Bool = false
    @State private var showAspectRatioPicker: Bool = false
    @State private var arView: ARSCNView?
    @State private var detectedPlane: ARPlaneAnchor?
    
    var body: some View {
        ZStack {
            // AR View
            ARPhotoFrameViewContainer(
                viewModel: viewModel,
                arView: $arView,
                detectedPlane: $detectedPlane
            )
            .ignoresSafeArea()
            
            // Controls Panel
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    // Image Preview
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 100)
                            .cornerRadius(8)
                            .overlay(
                                Text("Sélectionner une photo")
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    // Upload Button
                    Button(action: {
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                            Text("Sélectionner Photo")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    // Frame Style Picker
                    Button(action: {
                        showFrameStylePicker = true
                    }) {
                        HStack {
                            Text("Style: \(viewModel.selectedFrameStyle.rawValue)")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                    
                    // Aspect Ratio Picker
                    Button(action: {
                        showAspectRatioPicker = true
                    }) {
                        HStack {
                            Text("Ratio: \(viewModel.selectedAspectRatio.rawValue)")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                    
                    // Create Frame Button
                    Button(action: {
                        if let arView = arView,
                           let scene = arView.scene.rootNode.scene {
                            viewModel.createFrame(in: scene, on: detectedPlane)
                            
                            // Setup gestes
                            viewModel.setupGestures(on: arView, scene: scene)
                        }
                    }) {
                        Text("Créer Frame AR")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.selectedImage == nil ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.selectedImage == nil)
                    
                    // Gallery Mode Controls
                    if viewModel.isGalleryMode {
                        HStack {
                            Button(action: {
                                viewModel.navigateToPrevious()
                            }) {
                                Image(systemName: "chevron.left")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                            
                            Text("\(viewModel.currentGalleryIndex + 1) / \(viewModel.galleryFrames.count)")
                                .frame(maxWidth: .infinity)
                            
                            Button(action: {
                                viewModel.navigateToNext()
                            }) {
                                Image(systemName: "chevron.right")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(16)
            }
            .padding()
        }
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let newItem = newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.loadImage(image)
                }
            }
        }
        .sheet(isPresented: $showFrameStylePicker) {
            FrameStylePickerView(
                styles: viewModel.getFrameStyles(),
                selectedStyle: $viewModel.selectedFrameStyle
            )
        }
        .sheet(isPresented: $showAspectRatioPicker) {
            AspectRatioPickerView(
                aspectRatios: AspectRatio.allCases,
                selectedRatio: $viewModel.selectedAspectRatio
            )
        }
        .onDisappear {
            if let arView = arView {
                viewModel.removeGestures(from: arView)
            }
            viewModel.cleanup()
        }
    }
}

// MARK: - AR Photo Frame View Container

struct ARPhotoFrameViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARPhotoFrameViewModel
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
        @ObservedObject var viewModel: ARPhotoFrameViewModel
        @Binding var detectedPlane: ARPlaneAnchor?
        
        init(viewModel: ARPhotoFrameViewModel, detectedPlane: Binding<ARPlaneAnchor?>) {
            self.viewModel = viewModel
            self._detectedPlane = detectedPlane
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            // Détecter premier plan vertical
            if detectedPlane == nil {
                if let planeAnchor = anchors.first(where: { $0 is ARPlaneAnchor }) as? ARPlaneAnchor,
                   planeAnchor.alignment == .vertical {
                    detectedPlane = planeAnchor
                }
            }
        }
    }
}

// MARK: - Frame Style Picker View

struct FrameStylePickerView: View {
    let styles: [FrameStyle]
    @Binding var selectedStyle: FrameStyle
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(styles, id: \.id) { style in
                Button(action: {
                    selectedStyle = style
                    dismiss()
                }) {
                    HStack {
                        Text(style.rawValue)
                        Spacer()
                        if style.id == selectedStyle.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Style de Frame")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Aspect Ratio Picker View

struct AspectRatioPickerView: View {
    let aspectRatios: [AspectRatio]
    @Binding var selectedRatio: AspectRatio
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(aspectRatios, id: \.id) { ratio in
                Button(action: {
                    selectedRatio = ratio
                    dismiss()
                }) {
                    HStack {
                        Text(ratio.rawValue)
                        Spacer()
                        if ratio.id == selectedRatio.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Ratio d'Aspect")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}









