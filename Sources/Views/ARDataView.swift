//
//  ARDataView.swift
//  ARCodeClone
//
//  Interface utilisateur pour AR Data API
//

import SwiftUI
import ARKit
import SceneKit

struct ARDataView: View {
    @StateObject var viewModel: ARDataViewModel
    @State private var arView: ARSCNView?
    @State private var detectedPlane: ARPlaneAnchor?
    @State private var showWebhookSettings: Bool = false
    
    var body: some View {
        ZStack {
            // AR View
            ARDataViewContainer(
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
                        // Authentication Status
                        if !viewModel.isAuthenticated {
                            VStack(spacing: 12) {
                                Text("Authentification requise")
                                    .font(.headline)
                                
                                Button("Se connecter") {
                                    viewModel.login()
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                        } else {
                            // Endpoint Configuration
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Endpoint API")
                                    .font(.headline)
                                
                                TextField("Ex: /api/v1/iot/data", text: $viewModel.dataEndpoint)
                                    .textFieldStyle(.roundedBorder)
                                
                                Button("Charger données") {
                                    viewModel.fetchData()
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            
                            // Template Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Template d'affichage")
                                    .font(.headline)
                                
                                Picker("Template", selection: $viewModel.selectedTemplate) {
                                    ForEach(DataTemplate.allCases, id: \.id) { template in
                                        Text(template.rawValue).tag(template)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            
                            // Subscription Controls
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Mise à jour automatique")
                                    .font(.headline)
                                
                                Toggle("Activer subscription", isOn: Binding(
                                    get: { viewModel.isSubscribing },
                                    set: { enabled in
                                        if enabled {
                                            viewModel.startSubscription()
                                        } else {
                                            viewModel.stopSubscription()
                                        }
                                    }
                                ))
                                
                                if viewModel.isSubscribing {
                                    VStack(alignment: .leading) {
                                        Text("Intervalle: \(Int(viewModel.updateInterval))s")
                                        Slider(
                                            value: $viewModel.updateInterval,
                                            in: 1...60,
                                            step: 1
                                        )
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            
                            // Current Data Display
                            if let data = viewModel.currentData {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Données actuelles")
                                        .font(.headline)
                                    
                                    ForEach(Array(data.data.keys.sorted()), id: \.self) { key in
                                        HStack {
                                            Text(key)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Text("\(data.data[key] ?? "N/A")")
                                                .font(.caption)
                                                .bold()
                                        }
                                    }
                                    
                                    Text("Updated: \(formatDate(data.timestamp))")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                            
                            // Create Display Button
                            if viewModel.currentData != nil {
                                Button("Créer affichage AR") {
                                    if let arView = arView,
                                       let scene = arView.scene.rootNode.scene {
                                        let position = detectedPlane?.center ?? SIMD3<Float>(0, 0, -1)
                                        viewModel.createDisplay(in: scene, at: position)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            
                            // Webhook Settings
                            Button("Configurer Webhook") {
                                showWebhookSettings = true
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            
                            // Logout
                            Button("Déconnexion") {
                                viewModel.logout()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.7))
                            .foregroundColor(.white)
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
                .frame(maxHeight: 600)
                .background(Color.white.opacity(0.95))
                .cornerRadius(16)
            }
            .padding()
        }
        .sheet(isPresented: $showWebhookSettings) {
            WebhookSettingsView(viewModel: viewModel)
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - AR Data View Container

struct ARDataViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARDataViewModel
    @Binding var arView: ARSCNView?
    @Binding var detectedPlane: ARPlaneAnchor?
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        let scene = SCNScene()
        arView.scene = scene
        
        arView.antialiasingMode = .multisampling4X
        arView.preferredFramesPerSecond = 60
        
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        arView.session.delegate = context.coordinator
        
        self.arView = arView
        
        // Observer data updates pour mettre à jour display
        context.coordinator.observeDataUpdates()
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Mises à jour si nécessaire
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, detectedPlane: $detectedPlane)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        @ObservedObject var viewModel: ARDataViewModel
        @Binding var detectedPlane: ARPlaneAnchor?
        private var dataUpdateObserver: AnyCancellable?
        
        init(viewModel: ARDataViewModel, detectedPlane: Binding<ARPlaneAnchor?>) {
            self.viewModel = viewModel
            self._detectedPlane = detectedPlane
        }
        
        func observeDataUpdates() {
            // Observer changements de currentData pour mettre à jour display
            dataUpdateObserver = viewModel.$currentData
                .sink { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.viewModel.updateDisplay()
                    }
                }
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            if detectedPlane == nil {
                if let planeAnchor = anchors.first(where: { $0 is ARPlaneAnchor }) as? ARPlaneAnchor {
                    detectedPlane = planeAnchor
                }
            }
        }
    }
}

// MARK: - Webhook Settings View

struct WebhookSettingsView: View {
    @ObservedObject var viewModel: ARDataViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedEvent: String = ""
    
    let availableEvents = ["data.updated", "data.created", "data.deleted", "error.occurred"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Webhook URL") {
                    TextField("https://votreserveur.com/webhook", text: $viewModel.webhookURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section("Événements") {
                    ForEach(availableEvents, id: \.self) { event in
                        Toggle(event, isOn: Binding(
                            get: { viewModel.webhookEvents.contains(event) },
                            set: { enabled in
                                if enabled {
                                    viewModel.webhookEvents.append(event)
                                } else {
                                    viewModel.webhookEvents.removeAll { $0 == event }
                                }
                            }
                        ))
                    }
                }
                
                if let webhookId = viewModel.registeredWebhookId {
                    Section("Webhook enregistré") {
                        Text("ID: \(webhookId)")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Webhook Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        viewModel.registerWebhook()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}









