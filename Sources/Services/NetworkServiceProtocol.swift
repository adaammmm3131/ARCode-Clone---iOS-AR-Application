//
//  NetworkServiceProtocol.swift
//  ARCodeClone
//
//  Protocol pour le service réseau
//

import Foundation

/// Protocol définissant les opérations réseau
protocol NetworkServiceProtocol {
    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        method: HTTPMethod,
        parameters: [String: Any]?,
        headers: [String: String]?,
        pathParameters: [String: String]? = nil
    ) async throws -> T
    
    func upload(
        _ endpoint: APIEndpoint,
        data: Data,
        fileName: String,
        progressHandler: @escaping (Double) -> Void,
        pathParameters: [String: String]? = nil
    ) async throws -> UploadResponse
    
    func uploadVideo(
        _ videoURL: URL,
        endpoint: APIEndpoint,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> UploadResponse
}

/// Méthodes HTTP supportées
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// Endpoints de l'API
enum APIEndpoint: String {
    case createARCode = "/api/v1/ar-codes/create"
    case getARCode = "/api/v1/ar-codes/{id}"
    case updateARCode = "/api/v1/ar-codes/{id}"
    case deleteARCode = "/api/v1/ar-codes/{id}"
    case upload3D = "/api/v1/3d/upload"
    case photogrammetry = "/api/v1/3d/photogrammetry"
    case aiAnalyze = "/api/v1/ai/vision/analyze"
    case faceFilter = "/api/v1/face-filter/create"
    case aiTxt2Img = "/api/v1/ai/generation/txt2img"
    case aiImg2Img = "/api/v1/ai/generation/img2img"
    case aiInpainting = "/api/v1/ai/generation/inpainting"
    case gaussianSplatting = "/api/v1/gaussian/splatting"
    case gaussianStatus = "/api/v1/gaussian/status/{id}"
    case analyticsTrack = "/api/v1/analytics/track"
    case analyticsEvents = "/api/v1/analytics/events"
    case analyticsStats = "/api/v1/analytics/stats"
    case getCTALinks = "/api/v1/cta-links/{ar_code_id}"
    case createCTALink = "/api/v1/cta-links"
    case updateCTALink = "/api/v1/cta-links/{id}"
    case deleteCTALink = "/api/v1/cta-links/{id}"
    case trackCTAClick = "/api/v1/analytics/cta-click"
    case getABTest = "/api/v1/ab-tests/{ar_code_id}"
    case createABTest = "/api/v1/ab-tests"
    case getABTestResults = "/api/v1/ab-tests/{test_id}/results"
    case trackABTestConversion = "/api/v1/analytics/ab-test-conversion"
    case concludeABTest = "/api/v1/ab-tests/{test_id}/conclude"
    case getWorkspaces = "/api/v1/workspaces"
    case createWorkspace = "/api/v1/workspaces"
    case getWorkspace = "/api/v1/workspaces/{id}"
    case updateWorkspace = "/api/v1/workspaces/{id}"
    case deleteWorkspace = "/api/v1/workspaces/{id}"
    case getWorkspaceMembers = "/api/v1/workspaces/{workspace_id}/members"
    case inviteWorkspaceMember = "/api/v1/workspaces/{workspace_id}/members/invite"
    case updateWorkspaceMember = "/api/v1/workspaces/{workspace_id}/members/{user_id}"
    case removeWorkspaceMember = "/api/v1/workspaces/{workspace_id}/members/{user_id}"
    case getWorkspaceComments = "/api/v1/workspaces/{workspace_id}/comments"
    case createWorkspaceComment = "/api/v1/workspaces/comments"
    case updateWorkspaceComment = "/api/v1/workspaces/comments/{id}"
    case deleteWorkspaceComment = "/api/v1/workspaces/comments/{id}"
    case resolveWorkspaceComment = "/api/v1/workspaces/comments/{id}/resolve"
    case getARCodeVersions = "/api/v1/ar-codes/{ar_code_id}/versions"
    case createARCodeVersion = "/api/v1/ar-codes/versions"
    case restoreARCodeVersion = "/api/v1/ar-codes/{ar_code_id}/versions/{version_id}/restore"
    case getWhiteLabelConfig = "/api/v1/white-label/config"
    case updateWhiteLabelConfig = "/api/v1/white-label/config/{id}"
    case validateCustomDomain = "/api/v1/white-label/validate-domain"
    
    func path(replacing parameters: [String: String] = [:]) -> String {
        var path = self.rawValue
        for (key, value) in parameters {
            path = path.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return path
    }
}

/// Réponse d'upload
struct UploadResponse: Codable {
    let id: String
    let url: String
    let status: String
}
