//
//  CTALinkViewModel.swift
//  ARCodeClone
//
//  ViewModel pour gestion des CTA links
//

import Foundation
import SwiftUI
import Combine

final class CTALinkViewModel: BaseViewModel, ObservableObject {
    @Published var ctaLinks: [ARCodeCTALink] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedLink: ARCodeCTALink?
    @Published var showEditSheet: Bool = false
    
    private let ctaLinkService: CTALinkServiceProtocol
    private let abTestingService: ABTestingServiceProtocol
    private let arCodeId: String
    
    init(
        arCodeId: String,
        ctaLinkService: CTALinkServiceProtocol,
        abTestingService: ABTestingServiceProtocol
    ) {
        self.arCodeId = arCodeId
        self.ctaLinkService = ctaLinkService
        self.abTestingService = abTestingService
        super.init()
        
        loadCTALinks()
    }
    
    // MARK: - Load CTA Links
    
    func loadCTALinks() {
        isLoading = true
        errorMessage = nil
        
        ctaLinkService.getCTALinks(for: arCodeId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let links):
                    self?.ctaLinks = links
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Create CTA Link
    
    func createCTALink(
        buttonText: String,
        buttonStyle: CTAButtonStyle,
        destinationURL: String,
        destinationType: CTADestinationType,
        position: CTAPosition
    ) {
        let newLink = ARCodeCTALink(
            id: UUID().uuidString,
            arCodeId: arCodeId,
            buttonText: buttonText,
            buttonStyle: buttonStyle,
            destinationURL: destinationURL,
            destinationType: destinationType,
            position: position,
            isEnabled: true,
            analyticsId: nil,
            variant: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        isLoading = true
        ctaLinkService.createCTALink(newLink) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let createdLink):
                    self?.ctaLinks.append(createdLink)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Update CTA Link
    
    func updateCTALink(_ link: ARCodeCTALink) {
        isLoading = true
        ctaLinkService.updateCTALink(link) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let updatedLink):
                    if let index = self?.ctaLinks.firstIndex(where: { $0.id == updatedLink.id }) {
                        self?.ctaLinks[index] = updatedLink
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Delete CTA Link
    
    func deleteCTALink(_ link: ARCodeCTALink) {
        isLoading = true
        ctaLinkService.deleteCTALink(id: link.id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.ctaLinks.removeAll { $0.id == link.id }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - A/B Testing
    
    func createABTest(name: String, variants: [ABTestVariant]) {
        let test = ABTest(
            id: UUID().uuidString,
            arCodeId: arCodeId,
            name: name,
            isActive: true,
            variants: variants,
            startDate: Date(),
            endDate: nil,
            winnerVariantId: nil
        )
        
        isLoading = true
        abTestingService.createABTest(test) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    // Reload CTA links to apply A/B test
                    self?.loadCTALinks()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func getABTestResults() {
        // Load A/B test results
        abTestingService.getABTest(for: arCodeId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let test):
                    if let test = test {
                        // Afficher résultats
                        print("AB Test Results: \(test)")
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}







