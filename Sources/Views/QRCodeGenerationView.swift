//
//  QRCodeGenerationView.swift
//  ARCodeClone
//
//  Interface utilisateur pour génération QR codes
//

import SwiftUI
import PhotosUI

struct QRCodeGenerationView: View {
    @StateObject var viewModel: QRCodeViewModel
    @State private var showLogoPicker: Bool = false
    @State private var showExportSheet: Bool = false
    @State private var exportedData: Data?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Configuration
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Configuration AR Code")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // AR Code ID
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AR Code ID")
                                .font(.headline)
                            TextField("ID unique du AR Code", text: $viewModel.arCodeId)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                        }
                        
                        // Content Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type de contenu")
                                .font(.headline)
                            Picker("Type", selection: $viewModel.contentType) {
                                Text("Object Capture").tag("object_capture")
                                Text("Face Filter").tag("face_filter")
                                Text("AI Code").tag("ai_code")
                                Text("Video").tag("video")
                                Text("Portal").tag("portal")
                                Text("Text").tag("text")
                                Text("Photo").tag("photo")
                                Text("Logo").tag("logo")
                                Text("Splat").tag("splat")
                                Text("Data").tag("data")
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Design Customization
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Personnalisation Design")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Logo
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Logo (optionnel)")
                                .font(.headline)
                            
                            if let logo = viewModel.logoImage {
                                HStack {
                                    Image(uiImage: logo)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(8)
                                    
                                    Button("Changer") {
                                        showLogoPicker = true
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button("Supprimer") {
                                        viewModel.setLogo(nil)
                                    }
                                    .buttonStyle(.bordered)
                                    .foregroundColor(.red)
                                }
                            } else {
                                Button("Ajouter Logo") {
                                    showLogoPicker = true
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                        }
                        
                        // Couleurs
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Couleurs")
                                .font(.headline)
                            
                            ColorPicker("Couleur QR Code", selection: $viewModel.foregroundColor)
                            ColorPicker("Couleur fond", selection: $viewModel.backgroundColor)
                        }
                        
                        // Corner Radius
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Coins arrondis: \(Int(viewModel.cornerRadius))px")
                                .font(.headline)
                            Slider(value: $viewModel.cornerRadius, in: 0...50, step: 1)
                        }
                        
                        // Taille
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Résolution: \(Int(viewModel.qrCodeSize.width))x\(Int(viewModel.qrCodeSize.height))px")
                                .font(.headline)
                            HStack {
                                Text("512px")
                                Slider(value: Binding(
                                    get: { viewModel.qrCodeSize.width },
                                    set: { viewModel.qrCodeSize = CGSize(width: $0, height: $0) }
                                ), in: 512...2048, step: 64)
                                Text("2048px")
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Generate Button
                    Button("Générer QR Code") {
                        viewModel.generateQRCode()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(viewModel.isLoading || viewModel.arCodeId.isEmpty)
                    
                    // Loading Indicator
                    if viewModel.isLoading {
                        ProgressView("Génération QR Code...")
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
                    
                    // QR Code Preview
                    if let qrImage = viewModel.qrCodeImage {
                        VStack(spacing: 16) {
                            Text("Preview QR Code")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Image(uiImage: qrImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 300, maxHeight: 300)
                                .cornerRadius(12)
                                .shadow(radius: 8)
                            
                            // Short URL
                            VStack(alignment: .leading, spacing: 8) {
                                Text("URL générée:")
                                    .font(.headline)
                                Text(viewModel.shortURL)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .textSelection(.enabled)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Export Format
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Format d'export")
                                    .font(.headline)
                                Picker("Format", selection: $viewModel.selectedFormat) {
                                    ForEach(QRCodeViewModel.ExportFormat.allCases, id: \.id) { format in
                                        Text(format.rawValue).tag(format)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            // Export Button
                            Button("Exporter QR Code") {
                                if let data = viewModel.exportQRCode() {
                                    exportedData = data
                                    showExportSheet = true
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Génération QR Code")
            .photosPicker(
                isPresented: $showLogoPicker,
                selection: Binding(
                    get: { nil },
                    set: { item in
                        Task {
                            if let item = item,
                               let data = try? await item.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                viewModel.setLogo(image)
                            }
                        }
                    }
                ),
                matching: .images
            )
            .sheet(isPresented: $showExportSheet) {
                if let data = exportedData {
                    ShareSheet(activityItems: [data])
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}









