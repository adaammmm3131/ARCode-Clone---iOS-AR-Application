//
//  WhiteLabelSettingsView.swift
//  ARCodeClone
//
//  Interface pour configuration white label
//

import SwiftUI

struct WhiteLabelSettingsView: View {
    @StateObject var viewModel: WhiteLabelViewModel
    @State private var showColorPicker: Bool = false
    
    var body: some View {
        Form {
            Section("Domaine Personnalisé") {
                TextField("Domaine (ex: ar.votresite.com)", text: Binding(
                    get: { viewModel.config?.settings.customDomain ?? "" },
                    set: { viewModel.updateCustomDomain($0) }
                ))
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                
                if let domain = viewModel.config?.settings.customDomain, !domain.isEmpty {
                    Button("Valider le domaine") {
                        viewModel.validateDomain(domain)
                    }
                    .buttonStyle(.bordered)
                    
                    if let validationMessage = viewModel.domainValidationMessage {
                        Text(validationMessage)
                            .font(.caption)
                            .foregroundColor(validationMessage.contains("valid") ? .green : .red)
                    }
                }
            }
            
            Section("Logo") {
                if let logoURL = viewModel.config?.settings.logoURL {
                    AsyncImage(url: URL(string: logoURL)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                    } placeholder: {
                        ProgressView()
                    }
                    
                    Button("Changer le logo") {
                        // TODO: Image picker
                    }
                } else {
                    Button("Ajouter un logo") {
                        // TODO: Image picker
                    }
                }
            }
            
            Section("Couleurs") {
                ColorPicker("Couleur Principale", selection: Binding(
                    get: { Color(hex: viewModel.config?.settings.primaryColor ?? "#6C5CE7") ?? .purple },
                    set: { viewModel.updatePrimaryColor($0.toHex()) }
                ))
                
                ColorPicker("Couleur Secondaire", selection: Binding(
                    get: { Color(hex: viewModel.config?.settings.secondaryColor ?? "#00B894") ?? .green },
                    set: { viewModel.updateSecondaryColor($0.toHex()) }
                ))
                
                ColorPicker("Couleur Accent", selection: Binding(
                    get: { Color(hex: viewModel.config?.settings.accentColor ?? "#FF7675") ?? .red },
                    set: { viewModel.updateAccentColor($0.toHex()) }
                ))
            }
            
            Section("Informations Entreprise") {
                TextField("Nom de l'entreprise", text: Binding(
                    get: { viewModel.config?.settings.companyName ?? "" },
                    set: { viewModel.updateCompanyName($0) }
                ))
                
                TextField("Email de support", text: Binding(
                    get: { viewModel.config?.settings.supportEmail ?? "" },
                    set: { viewModel.updateSupportEmail($0) }
                ))
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            }
            
            Section("Écran de Chargement") {
                TextField("URL écran de chargement personnalisé", text: Binding(
                    get: { viewModel.config?.settings.customLoadingScreenURL ?? "" },
                    set: { viewModel.updateLoadingScreenURL($0) }
                ))
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
            }
            
            Section {
                Toggle("Templates email personnalisés", isOn: Binding(
                    get: { viewModel.config?.settings.emailTemplatesCustom ?? false },
                    set: { viewModel.updateEmailTemplatesCustom($0) }
                ))
            }
            
            Section {
                Button("Enregistrer") {
                    viewModel.save()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("White Label")
        .onAppear {
            viewModel.loadConfig()
        }
    }
}

// MARK: - ViewModel

final class WhiteLabelViewModel: ObservableObject {
    @Published var config: WhiteLabelConfig?
    @Published var domainValidationMessage: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let whiteLabelService: WhiteLabelServiceProtocol
    
    init(whiteLabelService: WhiteLabelServiceProtocol) {
        self.whiteLabelService = whiteLabelService
    }
    
    func loadConfig() {
        isLoading = true
        whiteLabelService.getWhiteLabelConfig { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let config):
                    self?.config = config
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func updateCustomDomain(_ domain: String) {
        config?.settings.customDomain = domain.isEmpty ? nil : domain
    }
    
    func validateDomain(_ domain: String) {
        whiteLabelService.validateCustomDomain(domain) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let isValid):
                    self?.domainValidationMessage = isValid ? "Domaine valide" : "Domaine invalide"
                case .failure(let error):
                    self?.domainValidationMessage = "Erreur: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func updatePrimaryColor(_ color: String) {
        config?.settings.primaryColor = color
    }
    
    func updateSecondaryColor(_ color: String) {
        config?.settings.secondaryColor = color
    }
    
    func updateAccentColor(_ color: String) {
        config?.settings.accentColor = color
    }
    
    func updateCompanyName(_ name: String) {
        config?.settings.companyName = name.isEmpty ? nil : name
    }
    
    func updateSupportEmail(_ email: String) {
        config?.settings.supportEmail = email.isEmpty ? nil : email
    }
    
    func updateLoadingScreenURL(_ url: String) {
        config?.settings.customLoadingScreenURL = url.isEmpty ? nil : url
    }
    
    func updateEmailTemplatesCustom(_ enabled: Bool) {
        config?.settings.emailTemplatesCustom = enabled
    }
    
    func save() {
        guard var config = config else { return }
        
        isLoading = true
        whiteLabelService.updateWhiteLabelConfig(config) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let updated):
                    self?.config = updated
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Color Extensions

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        let components = UIColor(self).cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0
        
        return String(format: "#%02X%02X%02X",
                     Int(r * 255),
                     Int(g * 255),
                     Int(b * 255))
    }
}







