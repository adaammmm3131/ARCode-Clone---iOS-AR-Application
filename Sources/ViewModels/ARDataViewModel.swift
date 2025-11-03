//
//  ARDataViewModel.swift
//  ARCodeClone
//
//  ViewModel pour AR Data API
//

import Foundation
import SwiftUI
import Combine
import ARKit
import SceneKit

final class ARDataViewModel: BaseViewModel, ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var dataEndpoint: String = ""
    @Published var selectedTemplate: DataTemplate = .generic
    @Published var currentData: ARDataResponse?
    @Published var updateInterval: TimeInterval = 5.0
    @Published var isSubscribing: Bool = false
    @Published var currentDisplayNode: SCNNode?
    @Published var errorMessage: String?
    @Published var webhookURL: String = ""
    @Published var webhookEvents: [String] = []
    @Published var registeredWebhookId: String?
    
    private let authService: AuthenticationServiceProtocol
    private let dataService: ARDataAPIServiceProtocol
    private let templateService: ARDataTemplateServiceProtocol
    private var subscriptionCancellable: AnyCancellable?
    
    init(
        authService: AuthenticationServiceProtocol,
        dataService: ARDataAPIServiceProtocol,
        templateService: ARDataTemplateServiceProtocol
    ) {
        self.authService = authService
        self.dataService = dataService
        self.templateService = templateService
        super.init()
        
        // Vérifier authentification
        checkAuthentication()
    }
    
    // MARK: - Authentication
    
    func checkAuthentication() {
        isAuthenticated = authService.isAuthenticated()
    }
    
    func login() {
        authService.authenticate { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.isAuthenticated = true
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func logout() {
        authService.logout()
        isAuthenticated = false
        stopSubscription()
        cleanup()
    }
    
    // MARK: - Data Fetching
    
    func fetchData() {
        guard !dataEndpoint.isEmpty else {
            errorMessage = "Endpoint requis"
            return
        }
        
        dataService.fetchData(endpoint: dataEndpoint, parameters: nil) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.currentData = response
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Subscription
    
    func startSubscription() {
        guard !dataEndpoint.isEmpty, !isSubscribing else { return }
        
        isSubscribing = true
        
        subscriptionCancellable = dataService.subscribeToUpdates(
            endpoint: dataEndpoint,
            interval: updateInterval
        )
        .sink { [weak self] response in
            DispatchQueue.main.async {
                self?.currentData = response
            }
        }
    }
    
    func stopSubscription() {
        subscriptionCancellable?.cancel()
        subscriptionCancellable = nil
        isSubscribing = false
    }
    
    // MARK: - AR Display
    
    func createDisplay(in scene: SCNScene, at position: SIMD3<Float>) {
        guard let data = currentData else {
            errorMessage = "Aucune donnée disponible"
            return
        }
        
        // Supprimer ancien display
        if let oldNode = currentDisplayNode {
            oldNode.removeFromParentNode()
        }
        
        // Créer nouveau display selon template
        let node = templateService.createGenericDisplay(
            data: data,
            template: selectedTemplate,
            in: scene,
            at: position
        )
        
        currentDisplayNode = node
    }
    
    func updateDisplay() {
        guard let node = currentDisplayNode,
              let data = currentData,
              let scene = node.scene else {
            return
        }
        
        // Supprimer ancien
        node.removeFromParentNode()
        
        // Recréer avec nouvelles données
        let newNode = templateService.createGenericDisplay(
            data: data,
            template: selectedTemplate,
            in: scene,
            at: node.simdPosition
        )
        
        currentDisplayNode = newNode
    }
    
    // MARK: - Webhook Registration
    
    func registerWebhook() {
        guard !webhookURL.isEmpty, !webhookEvents.isEmpty else {
            errorMessage = "URL et événements requis"
            return
        }
        
        dataService.registerWebhook(url: webhookURL, events: webhookEvents) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let webhookId):
                    self?.registeredWebhookId = webhookId
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        stopSubscription()
        currentDisplayNode?.removeFromParentNode()
        currentDisplayNode = nil
        currentData = nil
    }
}









