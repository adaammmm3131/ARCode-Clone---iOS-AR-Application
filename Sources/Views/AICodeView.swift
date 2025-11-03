//
//  AICodeView.swift
//  ARCodeClone
//
//  Interface utilisateur pour AI Code feature
//

import SwiftUI
import PhotosUI

struct AICodeView: View {
    @StateObject var viewModel: AICodeViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showImagePicker: Bool = false
    @State private var showPromptEditor: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Image Selection
                        if let image = viewModel.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            
                            // Actions
                            HStack(spacing: 16) {
                                Button(action: {
                                    viewModel.processOCR(image)
                                }) {
                                    Label("OCR", systemImage: "text.viewfinder")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .disabled(viewModel.isProcessingOCR)
                                
                                Button(action: {
                                    viewModel.processSegmentation(image)
                                }) {
                                    Label("Segment", systemImage: "person.crop.square")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .disabled(viewModel.isProcessingSegmentation)
                                
                                Button(action: {
                                    viewModel.analyzeImage(image)
                                }) {
                                    Label("Analyze", systemImage: "brain.head.profile")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.purple)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .disabled(viewModel.isAnalyzing)
                            }
                            .padding(.horizontal)
                        } else {
                            // Placeholder
                            VStack(spacing: 16) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                
                                Text("Sélectionner une image")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                Button(action: {
                                    showImagePicker = true
                                }) {
                                    Text("Choisir une photo")
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // OCR Results
                        if !viewModel.extractedText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Texte détecté")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.extractedText.indices, id: \.self) { index in
                                    let region = viewModel.extractedText[index]
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(region.text)
                                            .font(.body)
                                        if let language = region.language {
                                            Text("Langue: \(language)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Segmentation Results
                        if let segmentedImage = viewModel.segmentedPerson {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Personne segmentée")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                Image(uiImage: segmentedImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                        }
                        
                        // Analysis Results
                        if let result = viewModel.analysisResult {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Analyse IA")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(result.responseText)
                                        .font(.body)
                                    
                                    if !result.detectedObjects.isEmpty {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Objets détectés:")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            ForEach(result.detectedObjects, id: \.self) { object in
                                                Text("• \(object)")
                                                    .font(.caption)
                                            }
                                        }
                                        .padding(.top, 8)
                                    }
                                    
                                    HStack {
                                        Text("Modèle: \(result.model)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("Temps: \(String(format: "%.2f", result.processingTime))s")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.top, 8)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                        
                        // Error Display
                        if let error = viewModel.analysisError {
                            Text("Erreur: \(error)")
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        
                        // Loading Indicators
                        if viewModel.isAnalyzing || viewModel.isProcessingOCR || viewModel.isProcessingSegmentation {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("AI Code")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Image(systemName: "photo.badge.plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showPromptEditor = true
                    }) {
                        Image(systemName: "pencil.circle")
                    }
                }
            }
            .photosPicker(
                isPresented: $showImagePicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
            .sheet(isPresented: $showPromptEditor) {
                PromptEditorView(viewModel: viewModel)
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let newItem = newItem,
                       let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.selectedImage = image
                    }
                }
            }
        }
    }
}

struct PromptEditorView: View {
    @ObservedObject var viewModel: AICodeViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Prompt personnalisé")) {
                    TextEditor(text: $viewModel.customPrompt)
                        .frame(height: 100)
                }
                
                Section(header: Text("Contexte (optionnel)")) {
                    TextEditor(text: $viewModel.context)
                        .frame(height: 100)
                }
                
                Section {
                    Toggle("Synthèse vocale", isOn: $viewModel.isVoiceEnabled)
                }
            }
            .navigationTitle("Paramètres")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}










