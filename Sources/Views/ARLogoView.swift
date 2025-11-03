//
//  ARLogoView.swift
//  ARCodeClone
//
//  Interface utilisateur pour AR Logo
//

import SwiftUI
import ARKit
import SceneKit
import UniformTypeIdentifiers

struct ARLogoView: View {
    @StateObject var viewModel: ARLogoViewModel
    @State private var showFilePicker: Bool = false
    @State private var arView: ARSCNView?
    @State private var detectedPlane: ARPlaneAnchor?
    
    var body: some View {
        ZStack {
            // AR View
            ARLogoViewContainer(
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
                        // SVG Preview
                        if let preview = viewModel.svgPreview {
                            Image(uiImage: preview)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 120)
                                .cornerRadius(8)
                                .background(Color.gray.opacity(0.2))
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 120)
                                .cornerRadius(8)
                                .overlay(
                                    Text("Aucun SVG chargé")
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        // Dimensions
                        if let dims = viewModel.dimensions {
                            Text("Dimensions: \(Int(dims.width))×\(Int(dims.height))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        // Upload Button
                        Button(action: {
                            showFilePicker = true
                        }) {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                Text("Choisir SVG")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        // Depth Slider (0.1mm - 10cm = 0.001m - 0.1m)
                        VStack(alignment: .leading) {
                            Text("Profondeur: \(String(format: "%.1f", viewModel.depth * 100)) cm")
                                .font(.headline)
                            Slider(
                                value: Binding(
                                    get: { viewModel.depth },
                                    set: { viewModel.updateDepth($0) }
                                ),
                                in: 0.001...0.1,
                                step: 0.001
                            )
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        
                        // Material Controls
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Matériau")
                                .font(.headline)
                            
                            // Color Picker
                            ColorPicker("Couleur", selection: Binding(
                                get: { Color(viewModel.materialColor) },
                                set: { viewModel.updateMaterial(
                                    color: UIColor($0),
                                    metalness: viewModel.materialMetalness,
                                    roughness: viewModel.materialRoughness
                                )}
                            ))
                            
                            // Metalness Slider
                            VStack(alignment: .leading) {
                                Text("Metalness: \(String(format: "%.2f", viewModel.materialMetalness))")
                                Slider(
                                    value: Binding(
                                        get: { viewModel.materialMetalness },
                                        set: { viewModel.updateMaterial(
                                            color: viewModel.materialColor,
                                            metalness: $0,
                                            roughness: viewModel.materialRoughness
                                        )}
                                    ),
                                    in: 0...1
                                )
                            }
                            
                            // Roughness Slider
                            VStack(alignment: .leading) {
                                Text("Roughness: \(String(format: "%.2f", viewModel.materialRoughness))")
                                Slider(
                                    value: Binding(
                                        get: { viewModel.materialRoughness },
                                        set: { viewModel.updateMaterial(
                                            color: viewModel.materialColor,
                                            metalness: viewModel.materialMetalness,
                                            roughness: $0
                                        )}
                                    ),
                                    in: 0...1
                                )
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        
                        // Animation Controls
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Animation Rotation", isOn: Binding(
                                get: { viewModel.isAnimationEnabled },
                                set: { _ in viewModel.toggleAnimation() }
                            ))
                            
                            if viewModel.isAnimationEnabled {
                                // Speed Slider
                                VStack(alignment: .leading) {
                                    Text("Vitesse: \(String(format: "%.1f", viewModel.animationSpeed))x")
                                    Slider(
                                        value: Binding(
                                            get: { viewModel.animationSpeed },
                                            set: { viewModel.updateAnimationSpeed($0) }
                                        ),
                                        in: 0.1...5.0
                                    )
                                }
                                
                                // Easing Picker
                                Picker("Easing", selection: $viewModel.animationEasing) {
                                    ForEach(AnimationEasing.allCases, id: \.self) { easing in
                                        Text(easing.rawValue).tag(easing)
                                    }
                                }
                                .onChange(of: viewModel.animationEasing) { newEasing in
                                    viewModel.updateAnimationEasing(newEasing)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        
                        // Create Logo Button
                        Button(action: {
                            if let arView = arView,
                               let scene = arView.scene.rootNode.scene {
                                let position = detectedPlane?.center ?? SIMD3<Float>(0, 0, -1)
                                viewModel.createLogo3D(in: scene, at: position)
                            }
                        }) {
                            Text("Créer Logo AR")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.selectedSVGURL == nil ? Color.gray : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(viewModel.selectedSVGURL == nil)
                    }
                    .padding()
                }
                .frame(maxHeight: 400)
                .background(Color.white.opacity(0.95))
                .cornerRadius(16)
            }
            .padding()
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.svg, UTType.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.loadSVG(url: url)
                }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

// MARK: - AR Logo View Container

struct ARLogoViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARLogoViewModel
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
        @ObservedObject var viewModel: ARLogoViewModel
        @Binding var detectedPlane: ARPlaneAnchor?
        
        init(viewModel: ARLogoViewModel, detectedPlane: Binding<ARPlaneAnchor?>) {
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

