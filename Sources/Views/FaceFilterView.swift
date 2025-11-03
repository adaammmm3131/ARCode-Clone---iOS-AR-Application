//
//  FaceFilterView.swift
//  ARCodeClone
//
//  Vue pour Face Filter AR
//

import SwiftUI
import ARKit
import SceneKit
import PhotosUI

struct FaceFilterView: View {
    @StateObject var viewModel: FaceFilterViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showImagePicker: Bool = false
    @State private var arView: ARSCNView?
    @State private var validationResult: ImageValidationResult?
    @State private var showValidationAlert: Bool = false
    @State private var validationMessage: String = ""
    
    var body: some View {
        ZStack {
            // AR View
            ARFaceViewContainer(
                viewModel: viewModel,
                arView: $arView
            )
            .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top controls
                HStack {
                    Button(action: { showImagePicker = true }) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: { viewModel.toggleCamera() }) {
                        Image(systemName: "camera.rotate")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        viewModel.takePhoto(arView: arView) { result in
                            switch result {
                            case .success(let image):
                                // Afficher preview ou sauvegarder
                                let recordingService = FaceFilterRecordingService()
                                
                                // Sauvegarder dans photo library
                                recordingService.saveToPhotoLibrary(image) { saveResult in
                                    switch saveResult {
                                    case .success:
                                        print("Photo sauvegardée")
                                    case .failure(let error):
                                        print("Erreur sauvegarde: \(error)")
                                    }
                                }
                                
                                // Optionnel: Partager
                                // if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                //    let rootVC = windowScene.windows.first?.rootViewController {
                                //     recordingService.shareMedia(image, from: rootVC)
                                // }
                                
                            case .failure(let error):
                                print("Erreur capture: \(error)")
                            }
                        }
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                // Bottom controls
                HStack {
                    // Recording button
                    Button(action: {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        } else {
                            viewModel.startRecording()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isRecording ? Color.red : Color.white)
                                .frame(width: 60, height: 60)
                            
                            if viewModel.isRecording {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white)
                                    .frame(width: 20, height: 20)
                            } else {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 50, height: 50)
                            }
                        }
                    }
                    .padding()
                    
                    // Face count indicator
                    if viewModel.detectedFacesCount > 0 {
                        HStack {
                            Image(systemName: "face.smiling")
                            Text("\(viewModel.detectedFacesCount)")
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
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
                    
                    // Valider image
                    let imageService = FaceFilterImageService()
                    let validation = imageService.validateImage(image)
                    validationResult = validation
                    
                    if validation.isValid {
                        // Préparer image pour AR
                        if let preparedImage = imageService.prepareImageForAR(image) {
                            viewModel.loadLogo(image: preparedImage)
                        } else {
                            // Fallback: utiliser image originale
                            viewModel.loadLogo(image: image)
                        }
                    } else {
                        // Afficher erreur validation
                        validationMessage = validation.errorMessage ?? "Image invalide"
                        showValidationAlert = true
                    }
                }
            }
        }
        .alert("Erreur validation", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessage)
        }
    }
}

struct ARFaceViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: FaceFilterViewModel
    @Binding var arView: ARSCNView?
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        
        // Configuration face tracking
        let configuration = ARFaceTrackingConfiguration()
        configuration.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
        configuration.isWorldTrackingEnabled = true
        
        // Configurer scène
        let scene = SCNScene()
        arView.scene = scene
        
        // Démarrer session
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
        Coordinator(viewModel: viewModel, arView: $arView)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        @ObservedObject var viewModel: FaceFilterViewModel
        @Binding var arView: ARSCNView?
        
        init(viewModel: FaceFilterViewModel, arView: Binding<ARSCNView?>) {
            self.viewModel = viewModel
            self._arView = arView
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            // Mises à jour faces pour multi-user support
            let faceAnchors = anchors.compactMap { $0 as? ARFaceAnchor }
            
            // Notifier ViewModel
            // viewModel.updateFaces(faceAnchors)
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            // Nouvelles faces détectées (multi-user)
            let faceAnchors = anchors.compactMap { $0 as? ARFaceAnchor }
            
            if let arView = arView {
                // Attacher logo à toutes les nouvelles faces
                // viewModel.attachLogoToFaces(faceAnchors, in: arView.scene)
            }
        }
    }
}

