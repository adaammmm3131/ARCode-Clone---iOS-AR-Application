//
//  AR3DEditorView.swift
//  ARCodeClone
//
//  3D Editor avec SceneKit viewport, orbit controls, lighting, materials
//

import SwiftUI
import SceneKit

struct AR3DEditorView: View {
    @State private var scene: SCNScene?
    @State private var selectedNode: SCNNode?
    @State private var showLightingPanel: Bool = false
    @State private var showMaterialPanel: Bool = false
    @State private var showTransformPanel: Bool = false
    
    var body: some View {
        ZStack {
            // 3D Viewport
            SceneKitViewport(
                scene: $scene,
                selectedNode: $selectedNode
            )
            
            // Toolbar
            VStack {
                HStack {
                    Spacer()
                    
                    // Tools
                    HStack(spacing: 12) {
                        Button(action: { showLightingPanel.toggle() }) {
                            Image(systemName: "lightbulb.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Button(action: { showMaterialPanel.toggle() }) {
                            Image(systemName: "paintpalette.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Button(action: { showTransformPanel.toggle() }) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                // Bottom Panels
                VStack(spacing: 0) {
                    if showLightingPanel {
                        LightingControlsPanel()
                            .transition(.move(edge: .bottom))
                    }
                    
                    if showMaterialPanel {
                        MaterialEditorPanel(selectedNode: $selectedNode)
                            .transition(.move(edge: .bottom))
                    }
                    
                    if showTransformPanel {
                        TransformToolsPanel(selectedNode: $selectedNode)
                            .transition(.move(edge: .bottom))
                    }
                }
            }
        }
        .navigationTitle("3D Editor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupScene()
        }
    }
    
    private func setupScene() {
        let newScene = SCNScene()
        
        // Ajouter lumière ambiante
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.white.withAlphaComponent(0.3)
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        newScene.rootNode.addChildNode(ambientNode)
        
        // Ajouter lumière directionnelle
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = UIColor.white
        let directionalNode = SCNNode()
        directionalNode.light = directionalLight
        directionalNode.position = SCNVector3(0, 5, 5)
        directionalNode.look(at: SCNVector3(0, 0, 0))
        newScene.rootNode.addChildNode(directionalNode)
        
        scene = newScene
    }
}

// MARK: - SceneKit Viewport

struct SceneKitViewport: UIViewRepresentable {
    @Binding var scene: SCNScene?
    @Binding var selectedNode: SCNNode?
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.allowsCameraControl = true // Orbit controls natifs
        scnView.showsStatistics = false
        scnView.backgroundColor = UIColor.systemBackground
        scnView.autoenablesDefaultLighting = false
        
        // Ajouter gesture recognizers pour zoom/pan custom si nécessaire
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        scnView.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        scnView.addGestureRecognizer(panGesture)
        
        context.coordinator.view = scnView
        
        return scnView
    }
    
    func updateUIView(_ scnView: SCNView, context: Context) {
        scnView.scene = scene
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: SceneKitViewport
        var view: SCNView?
        
        init(_ parent: SceneKitViewport) {
            self.parent = parent
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let view = view else { return }
            
            // Zoom avec pinch
            let scale = Float(gesture.scale)
            if let camera = view.pointOfView {
                let currentZ = camera.position.z
                camera.position.z = currentZ * scale
                gesture.scale = 1.0
            }
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = view else { return }
            
            // Pan camera
            let translation = gesture.translation(in: view)
            let panSpeed: Float = 0.01
            
            if let camera = view.pointOfView {
                camera.position.x -= Float(translation.x) * panSpeed
                camera.position.y += Float(translation.y) * panSpeed
            }
            
            gesture.setTranslation(.zero, in: view)
        }
    }
}

// MARK: - Lighting Controls Panel

struct LightingControlsPanel: View {
    @State private var ambientIntensity: Double = 0.3
    @State private var directionalIntensity: Double = 1.0
    
    var body: some View {
        ARCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Éclairage")
                    .font(ARTypography.titleMedium)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Lumière ambiante: \(Int(ambientIntensity * 100))%")
                        .font(ARTypography.labelMedium)
                    
                    Slider(value: $ambientIntensity, in: 0...1)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Lumière directionnelle: \(Int(directionalIntensity * 100))%")
                        .font(ARTypography.labelMedium)
                    
                    Slider(value: $directionalIntensity, in: 0...2)
                }
            }
        }
        .padding()
    }
}

// MARK: - Material Editor Panel

struct MaterialEditorPanel: View {
    @Binding var selectedNode: SCNNode?
    @State private var selectedMaterial: SCNMaterial?
    
    var body: some View {
        ARCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Matériaux")
                    .font(ARTypography.titleMedium)
                
                if let material = selectedMaterial {
                    VStack(alignment: .leading, spacing: 12) {
                        // Material properties
                        ColorPicker("Couleur diffuse", selection: .constant(.blue))
                        
                        Picker("Type", selection: .constant("Matte")) {
                            Text("Matte").tag("Matte")
                            Text("Glossy").tag("Glossy")
                            Text("Metallic").tag("Metallic")
                        }
                        .pickerStyle(.menu)
                    }
                } else {
                    Text("Sélectionnez un objet pour éditer ses matériaux")
                        .font(ARTypography.bodySmall)
                        .foregroundColor(ARColors.textSecondary)
                }
            }
        }
        .padding()
        .onChange(of: selectedNode) { node in
            selectedMaterial = node?.geometry?.firstMaterial
        }
    }
}

// MARK: - Transform Tools Panel

struct TransformToolsPanel: View {
    @Binding var selectedNode: SCNNode?
    @State private var position: SIMD3<Float> = SIMD3(0, 0, 0)
    @State private var rotation: SIMD3<Float> = SIMD3(0, 0, 0)
    @State private var scale: SIMD3<Float> = SIMD3(1, 1, 1)
    
    var body: some View {
        ARCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Transformation")
                    .font(ARTypography.titleMedium)
                
                if selectedNode != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        // Position
                        Text("Position")
                            .font(ARTypography.labelMedium)
                        HStack {
                            Text("X: \(String(format: "%.2f", position.x))")
                            Text("Y: \(String(format: "%.2f", position.y))")
                            Text("Z: \(String(format: "%.2f", position.z))")
                        }
                        .font(ARTypography.bodySmall)
                        
                        // Rotation
                        Text("Rotation")
                            .font(ARTypography.labelMedium)
                        HStack {
                            Text("X: \(String(format: "%.1f", rotation.x))°")
                            Text("Y: \(String(format: "%.1f", rotation.y))°")
                            Text("Z: \(String(format: "%.1f", rotation.z))°")
                        }
                        .font(ARTypography.bodySmall)
                        
                        // Scale
                        Text("Échelle")
                            .font(ARTypography.labelMedium)
                        HStack {
                            Text("X: \(String(format: "%.2f", scale.x))")
                            Text("Y: \(String(format: "%.2f", scale.y))")
                            Text("Z: \(String(format: "%.2f", scale.z))")
                        }
                        .font(ARTypography.bodySmall)
                        
                        // Reset button
                        ARButton("Reset", style: .outlined, size: .small) {
                            resetTransform()
                        }
                    }
                } else {
                    Text("Sélectionnez un objet pour le transformer")
                        .font(ARTypography.bodySmall)
                        .foregroundColor(ARColors.textSecondary)
                }
            }
        }
        .padding()
        .onChange(of: selectedNode) { node in
            if let node = node {
                position = node.simdPosition
                rotation = node.simdEulerAngles
                scale = node.simdScale
            }
        }
    }
    
    private func resetTransform() {
        selectedNode?.simdPosition = SIMD3(0, 0, 0)
        selectedNode?.simdEulerAngles = SIMD3(0, 0, 0)
        selectedNode?.simdScale = SIMD3(1, 1, 1)
    }
}









