//
//  QRCodeScanningView.swift
//  ARCodeClone
//
//  Interface utilisateur pour scanning QR codes
//

import SwiftUI
import AVFoundation

struct QRCodeScanningView: View {
    @ObservedObject var viewModel: QRCodeScanningViewModel
    @State private var previewLayer: AVCaptureVideoPreviewLayer?
    @State private var showARView: Bool = false
    
    var body: some View {
        ZStack {
            // Camera Preview
            QRCodeCameraPreview(
                previewLayer: $previewLayer,
                scanningService: viewModel.scanningService
            )
            .ignoresSafeArea()
            
            // Overlay
            VStack {
                Spacer()
                
                // Scanning Frame
                VStack(spacing: 20) {
                    // Instructions
                    Text("Scannez le QR Code")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Frame guide
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 250, height: 250)
                        .overlay(
                            // Corner indicators
                            VStack {
                                HStack {
                                    CornerIndicator()
                                    Spacer()
                                    CornerIndicator()
                                }
                                Spacer()
                                HStack {
                                    CornerIndicator()
                                        .rotationEffect(.degrees(180))
                                    Spacer()
                                    CornerIndicator()
                                        .rotationEffect(.degrees(180))
                                }
                            }
                            .padding(8)
                        )
                    
                    // Loading Experience
                    if viewModel.isLoadingAR {
                        viewModel.loadingExperienceService.createProgressBar(
                            progress: $viewModel.loadingProgress,
                            message: $viewModel.loadingMessage
                        )
                        .padding()
                    }
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(20)
                
                Spacer()
                
                // Controls
                VStack(spacing: 16) {
                    // Permission Request
                    if !viewModel.hasCameraPermission {
                        VStack(spacing: 12) {
                            Text("Permission caméra requise")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Button("Autoriser caméra") {
                                viewModel.requestCameraPermission()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(12)
                    }
                    
                    // Error Display
                    if let error = viewModel.errorMessage {
                        Text("Erreur: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    // Stop Button
                    if viewModel.isScanning {
                        Button("Arrêter") {
                            viewModel.stopScanning()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            setupCameraPreview()
            if viewModel.hasCameraPermission {
                viewModel.startScanning()
            }
        }
        .onDisappear {
            viewModel.stopScanning()
        }
        .sheet(isPresented: $showARView) {
            // AR View avec contenu chargé
            // TODO: Naviguer vers AR view approprié selon contentType
        }
    }
    
    // MARK: - Camera Preview Setup
    
    private func setupCameraPreview() {
        // Setup preview layer sera fait par QRCodeCameraPreview
    }
}

// MARK: - Camera Preview

struct QRCodeCameraPreview: UIViewRepresentable {
    @Binding var previewLayer: AVCaptureVideoPreviewLayer?
    var scanningService: QRCodeScanningServiceProtocol
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        // Setup preview layer
        if let service = scanningService as? QRCodeScanningService,
           let session = service.getCaptureSession() {
            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill
            preview.frame = view.bounds
            view.layer.addSublayer(preview)
            previewLayer = preview
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Mettre à jour frame si nécessaire
        if let preview = previewLayer {
            preview.frame = uiView.bounds
        }
    }
}

// MARK: - Corner Indicator

struct CornerIndicator: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 30, height: 3)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 3, height: 30)
            }
        }
    }
}

