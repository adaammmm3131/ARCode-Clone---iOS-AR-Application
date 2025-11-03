//
//  WorkspaceViewModel.swift
//  ARCodeClone
//
//  ViewModel pour gestion des workspaces
//

import Foundation
import SwiftUI
import Combine

final class WorkspaceViewModel: BaseViewModel, ObservableObject {
    @Published var workspaces: [Workspace] = []
    @Published var currentWorkspace: Workspace?
    @Published var members: [WorkspaceMember] = []
    @Published var comments: [WorkspaceComment] = []
    @Published var versions: [ARCodeVersion] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let workspaceService: WorkspaceServiceProtocol
    
    init(workspaceService: WorkspaceServiceProtocol) {
        self.workspaceService = workspaceService
        super.init()
        
        loadWorkspaces()
    }
    
    // MARK: - Workspaces
    
    func loadWorkspaces() {
        isLoading = true
        workspaceService.getWorkspaces { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let workspaces):
                    self?.workspaces = workspaces
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func selectWorkspace(_ workspace: Workspace) {
        currentWorkspace = workspace
        loadMembers()
        loadComments()
    }
    
    func createWorkspace(name: String, description: String?) {
        isLoading = true
        workspaceService.createWorkspace(name: name, description: description) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let workspace):
                    self?.workspaces.append(workspace)
                    self?.currentWorkspace = workspace
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Members
    
    func loadMembers() {
        guard let workspaceId = currentWorkspace?.id else { return }
        
        workspaceService.getWorkspaceMembers(workspaceId: workspaceId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let members):
                    self?.members = members
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func inviteMember(email: String, role: WorkspaceRole) {
        guard let workspaceId = currentWorkspace?.id else { return }
        
        isLoading = true
        workspaceService.inviteMember(workspaceId: workspaceId, email: email, role: role) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let member):
                    self?.members.append(member)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func updateMemberRole(userId: String, role: WorkspaceRole) {
        guard let workspaceId = currentWorkspace?.id else { return }
        
        isLoading = true
        workspaceService.updateMemberRole(workspaceId: workspaceId, userId: userId, role: role) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let updated):
                    if let index = self?.members.firstIndex(where: { $0.id == updated.id }) {
                        self?.members[index] = updated
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Comments
    
    func loadComments(arCodeId: String? = nil) {
        guard let workspaceId = currentWorkspace?.id else { return }
        
        workspaceService.getComments(workspaceId: workspaceId, arCodeId: arCodeId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let comments):
                    self?.comments = comments
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func createComment(content: String, arCodeId: String? = nil) {
        guard let workspaceId = currentWorkspace?.id else { return }
        
        isLoading = true
        workspaceService.createComment(workspaceId: workspaceId, arCodeId: arCodeId, content: content) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let comment):
                    self?.comments.append(comment)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Versions
    
    func loadVersions(arCodeId: String) {
        workspaceService.getARCodeVersions(arCodeId: arCodeId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let versions):
                    self?.versions = versions
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}







