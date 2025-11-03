//
//  ARTextView.swift
//  ARCodeClone
//
//  Interface utilisateur pour AR Text Generator
//

import SwiftUI
import ARKit
import SceneKit

struct ARTextView: View {
    @StateObject var viewModel: ARTextViewModel
    @State private var arView: ARSCNView?
    @State private var showFontPicker: Bool = false
    @State private var showMaterialPicker: Bool = false
    
    var body: some View {
        ZStack {
            // AR View
            ARTextViewContainer(
                viewModel: viewModel,
                arView: $arView
            )
            .ignoresSafeArea()
            
            // Controls Panel
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    // Text Input
                    TextField("Entrez votre texte", text: $viewModel.text)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: viewModel.text) { _ in
                            viewModel.updateText()
                        }
                    
                    // Font Selection
                    Button(action: {
                        showFontPicker = true
                    }) {
                        HStack {
                            Text("Police: \(viewModel.selectedFont.displayName)")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                    
                    // Size & Depth Sliders
                    VStack(alignment: .leading) {
                        Text("Taille: \(String(format: "%.2f", viewModel.fontSize))")
                        Slider(value: $viewModel.fontSize, in: 0.05...0.5)
                            .onChange(of: viewModel.fontSize) { _ in
                                viewModel.updateText()
                            }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Profondeur: \(String(format: "%.2f", viewModel.depth))")
                        Slider(value: $viewModel.depth, in: 0.01...0.1)
                            .onChange(of: viewModel.depth) { _ in
                                viewModel.updateDepth()
                            }
                    }
                    
                    // RGB Color Pickers
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Couleur RGB")
                            .font(.headline)
                        
                        HStack {
                            Text("R")
                            Slider(value: $viewModel.red, in: 0...1)
                            Text("\(Int(viewModel.red * 255))")
                                .frame(width: 40)
                        }
                        
                        HStack {
                            Text("G")
                            Slider(value: $viewModel.green, in: 0...1)
                            Text("\(Int(viewModel.green * 255))")
                                .frame(width: 40)
                        }
                        
                        HStack {
                            Text("B")
                            Slider(value: $viewModel.blue, in: 0...1)
                            Text("\(Int(viewModel.blue * 255))")
                                .frame(width: 40)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Material Type
                    Picker("Matériau", selection: $viewModel.materialType) {
                        Text("Matte").tag(TextMaterialType.matte)
                        Text("Glossy").tag(TextMaterialType.glossy)
                        Text("Metallic").tag(TextMaterialType.metallic)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.materialType) { _ in
                        viewModel.updateMaterial()
                    }
                    
                    // Create Button
                    Button(action: {
                        if let arView = arView,
                           let scene = arView.scene.rootNode.scene {
                            let position = SIMD3<Float>(0, 0, -1) // 1m devant caméra
                            viewModel.createText3D(in: scene, at: position)
                            
                            // Setup gestes
                            viewModel.setupGestures(on: arView, scene: scene)
                        }
                    }) {
                        Text("Créer Texte 3D")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.textNode == nil ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.textNode != nil)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(16)
            }
            .padding()
        }
        .sheet(isPresented: $showFontPicker) {
            FontPickerView(
                fonts: viewModel.getAvailableFonts(),
                selectedFont: $viewModel.selectedFont,
                onFontChange: {
                    viewModel.updateText()
                }
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

// MARK: - AR Text View Container

struct ARTextViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARTextViewModel
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
        
        self.arView = arView
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Mises à jour si nécessaire
    }
}

// MARK: - Font Picker View

struct FontPickerView: View {
    let fonts: [FontInfo]
    @Binding var selectedFont: FontInfo
    let onFontChange: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(fonts, id: \.name) { font in
                Button(action: {
                    selectedFont = font
                    onFontChange()
                    dismiss()
                }) {
                    HStack {
                        Text(font.displayName)
                            .font(.custom(font.name, size: 18))
                        Spacer()
                        if font.name == selectedFont.name {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Choisir Police")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

