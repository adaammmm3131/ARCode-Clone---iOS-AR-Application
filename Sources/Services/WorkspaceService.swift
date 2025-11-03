//
//  WorkspaceService.swift
//  ARCodeClone
//
//  Service pour gestion des workspaces et collaboration
//

import Foundation
import Combine

protocol WorkspaceServiceProtocol {
    func getWorkspaces(completion: @escaping (Result<[Workspace], Error>) -> Void)
    func getWorkspace(id: String, completion: @escaping (Result<Workspace, Error>) -> Void)
    func createWorkspace(name: String, description: String?, completion: @escaping (Result<Workspace, Error>) -> Void)
    func updateWorkspace(_ workspace: Workspace, completion: @escaping (Result<Workspace, Error>) -> Void)
    func deleteWorkspace(id: String, completion: @escaping (Result<Void, Error>) -> Void)
    
    func getWorkspaceMembers(workspaceId: String, completion: @escaping (Result<[WorkspaceMember], Error>) -> Void)
    func inviteMember(workspaceId: String, email: String, role: WorkspaceRole, completion: @escaping (Result<WorkspaceMember, Error>) -> Void)
    func updateMemberRole(workspaceId: String, userId: String, role: WorkspaceRole, completion: @escaping (Result<WorkspaceMember, Error>) -> Void)
    func removeMember(workspaceId: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void)
    
    func getComments(workspaceId: String, arCodeId: String?, completion: @escaping (Result<[WorkspaceComment], Error>) -> Void)
    func createComment(workspaceId: String, arCodeId: String?, content: String, completion: @escaping (Result<WorkspaceComment, Error>) -> Void)
    func updateComment(commentId: String, content: String, completion: @escaping (Result<WorkspaceComment, Error>) -> Void)
    func deleteComment(commentId: String, completion: @escaping (Result<Void, Error>) -> Void)
    func resolveComment(commentId: String, completion: @escaping (Result<WorkspaceComment, Error>) -> Void)
    
    func getARCodeVersions(arCodeId: String, completion: @escaping (Result<[ARCodeVersion], Error>) -> Void)
    func createVersion(arCodeId: String, assetURL: String?, metadata: [String: Any], changelog: String?, completion: @escaping (Result<ARCodeVersion, Error>) -> Void)
    func restoreVersion(arCodeId: String, versionId: String, completion: @escaping (Result<ARCode, Error>) -> Void)
}

final class WorkspaceService: WorkspaceServiceProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    // MARK: - Workspace CRUD
    
    func getWorkspaces(completion: @escaping (Result<[Workspace], Error>) -> Void) {
        Task {
            do {
                let workspaces: [Workspace] = try await networkService.request(
                    .getWorkspaces,
                    method: .get,
                    parameters: nil,
                    headers: nil
                )
                DispatchQueue.main.async {
                    completion(.success(workspaces))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func getWorkspace(id: String, completion: @escaping (Result<Workspace, Error>) -> Void) {
        Task {
            do {
                let workspace: Workspace = try await networkService.request(
                    .getWorkspace,
                    method: .get,
                    parameters: nil,
                    headers: nil,
                    pathParameters: ["id": id]
                )
                DispatchQueue.main.async {
                    completion(.success(workspace))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func createWorkspace(name: String, description: String?, completion: @escaping (Result<Workspace, Error>) -> Void) {
        let parameters: [String: Any] = [
            "name": name,
            "description": description as Any
        ]
        
        Task {
            do {
                let workspace: Workspace = try await networkService.request(
                    .createWorkspace,
                    method: .post,
                    parameters: parameters,
                    headers: nil
                )
                DispatchQueue.main.async {
                    completion(.success(workspace))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func updateWorkspace(_ workspace: Workspace, completion: @escaping (Result<Workspace, Error>) -> Void) {
        let parameters: [String: Any] = [
            "name": workspace.name,
            "description": workspace.description as Any,
            "settings": try! JSONEncoder().encode(workspace.settings)
        ]
        
        Task {
            do {
                let updated: Workspace = try await networkService.request(
                    .updateWorkspace,
                    method: .put,
                    parameters: parameters,
                    headers: nil,
                    pathParameters: ["id": workspace.id]
                )
                DispatchQueue.main.async {
                    completion(.success(updated))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func deleteWorkspace(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                let _: EmptyResponse = try await networkService.request(
                    .deleteWorkspace,
                    method: .delete,
                    parameters: nil,
                    headers: nil,
                    pathParameters: ["id": id]
                )
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Members Management
    
    func getWorkspaceMembers(workspaceId: String, completion: @escaping (Result<[WorkspaceMember], Error>) -> Void) {
        Task {
            do {
                let members: [WorkspaceMember] = try await networkService.request(
                    .getWorkspaceMembers,
                    method: .get,
                    parameters: nil,
                    headers: nil,
                    pathParameters: ["workspace_id": workspaceId]
                )
                DispatchQueue.main.async {
                    completion(.success(members))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func inviteMember(workspaceId: String, email: String, role: WorkspaceRole, completion: @escaping (Result<WorkspaceMember, Error>) -> Void) {
        let parameters: [String: Any] = [
            "workspace_id": workspaceId,
            "email": email,
            "role": role.rawValue
        ]
        
        Task {
            do {
                let member: WorkspaceMember = try await networkService.request(
                    .inviteWorkspaceMember,
                    method: .post,
                    parameters: parameters,
                    headers: nil,
                    pathParameters: ["workspace_id": workspaceId]
                )
                DispatchQueue.main.async {
                    completion(.success(member))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func updateMemberRole(workspaceId: String, userId: String, role: WorkspaceRole, completion: @escaping (Result<WorkspaceMember, Error>) -> Void) {
        let parameters: [String: Any] = [
            "role": role.rawValue
        ]
        
        Task {
            do {
                let member: WorkspaceMember = try await networkService.request(
                    .updateWorkspaceMember,
                    method: .put,
                    parameters: parameters,
                    headers: nil,
                    pathParameters: ["workspace_id": workspaceId, "user_id": userId]
                )
                DispatchQueue.main.async {
                    completion(.success(member))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func removeMember(workspaceId: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                let _: EmptyResponse = try await networkService.request(
                    .removeWorkspaceMember,
                    method: .delete,
                    parameters: nil,
                    headers: nil,
                    pathParameters: ["workspace_id": workspaceId, "user_id": userId]
                )
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Comments
    
    func getComments(workspaceId: String, arCodeId: String?, completion: @escaping (Result<[WorkspaceComment], Error>) -> Void) {
        Task {
            do {
                let comments: [WorkspaceComment] = try await networkService.request(
                    .getWorkspaceComments,
                    method: .get,
                    parameters: arCodeId != nil ? ["ar_code_id": arCodeId!] : nil,
                    headers: nil,
                    pathParameters: ["workspace_id": workspaceId]
                )
                DispatchQueue.main.async {
                    completion(.success(comments))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func createComment(workspaceId: String, arCodeId: String?, content: String, completion: @escaping (Result<WorkspaceComment, Error>) -> Void) {
        var parameters: [String: Any] = [
            "workspace_id": workspaceId,
            "content": content
        ]
        if let arCodeId = arCodeId {
            parameters["ar_code_id"] = arCodeId
        }
        
        Task {
            do {
                let comment: WorkspaceComment = try await networkService.request(
                    .createWorkspaceComment,
                    method: .post,
                    parameters: parameters,
                    headers: nil
                )
                DispatchQueue.main.async {
                    completion(.success(comment))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func updateComment(commentId: String, content: String, completion: @escaping (Result<WorkspaceComment, Error>) -> Void) {
        let parameters: [String: Any] = [
            "content": content
        ]
        
        Task {
            do {
                let comment: WorkspaceComment = try await networkService.request(
                    .updateWorkspaceComment,
                    method: .put,
                    parameters: parameters,
                    headers: nil,
                    pathParameters: ["id": commentId]
                )
                DispatchQueue.main.async {
                    completion(.success(comment))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func deleteComment(commentId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                let _: EmptyResponse = try await networkService.request(
                    .deleteWorkspaceComment,
                    method: .delete,
                    parameters: nil,
                    headers: nil,
                    pathParameters: ["id": commentId]
                )
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func resolveComment(commentId: String, completion: @escaping (Result<WorkspaceComment, Error>) -> Void) {
        let parameters: [String: Any] = [
            "is_resolved": true
        ]
        
        Task {
            do {
                let comment: WorkspaceComment = try await networkService.request(
                    .resolveWorkspaceComment,
                    method: .put,
                    parameters: parameters,
                    headers: nil,
                    pathParameters: ["id": commentId]
                )
                DispatchQueue.main.async {
                    completion(.success(comment))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Version History
    
    func getARCodeVersions(arCodeId: String, completion: @escaping (Result<[ARCodeVersion], Error>) -> Void) {
        Task {
            do {
                let versions: [ARCodeVersion] = try await networkService.request(
                    .getARCodeVersions,
                    method: .get,
                    parameters: nil,
                    headers: nil,
                    pathParameters: ["ar_code_id": arCodeId]
                )
                DispatchQueue.main.async {
                    completion(.success(versions))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func createVersion(arCodeId: String, assetURL: String?, metadata: [String: Any], changelog: String?, completion: @escaping (Result<ARCodeVersion, Error>) -> Void) {
        let parameters: [String: Any] = [
            "ar_code_id": arCodeId,
            "asset_url": assetURL as Any,
            "metadata": metadata,
            "changelog": changelog as Any
        ]
        
        Task {
            do {
                let version: ARCodeVersion = try await networkService.request(
                    .createARCodeVersion,
                    method: .post,
                    parameters: parameters,
                    headers: nil
                )
                DispatchQueue.main.async {
                    completion(.success(version))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func restoreVersion(arCodeId: String, versionId: String, completion: @escaping (Result<ARCode, Error>) -> Void) {
        Task {
            do {
                let arCode: ARCode = try await networkService.request(
                    .restoreARCodeVersion,
                    method: .post,
                    parameters: nil,
                    headers: nil,
                    pathParameters: ["ar_code_id": arCodeId, "version_id": versionId]
                )
                DispatchQueue.main.async {
                    completion(.success(arCode))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

