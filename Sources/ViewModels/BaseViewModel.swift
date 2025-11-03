//
//  BaseViewModel.swift
//  ARCodeClone
//
//  ViewModel de base pour le pattern MVVM
//

import Foundation
import Combine

/// ViewModel de base avec gestion d'état
class BaseViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isError: Bool = false
    
    var cancellables = Set<AnyCancellable>()
    
    /// Affiche une erreur
    func showError(_ message: String) {
        errorMessage = message
        isError = true
        isLoading = false
    }
    
    /// Efface l'erreur
    func clearError() {
        errorMessage = nil
        isError = false
    }
    
    deinit {
        cancellables.removeAll()
    }
}












