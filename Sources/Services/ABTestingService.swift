//
//  ABTestingService.swift
//  ARCodeClone
//
//  Service pour A/B testing des CTA links
//

import Foundation

protocol ABTestingServiceProtocol {
    func getABTest(for arCodeId: String, completion: @escaping (Result<ABTest?, Error>) -> Void)
    func createABTest(_ test: ABTest, completion: @escaping (Result<ABTest, Error>) -> Void)
    func selectVariant(for testId: String, userId: String?) -> ABTestVariant?
    func trackConversion(variantId: String, completion: @escaping (Result<Void, Error>) -> Void)
    func getTestResults(testId: String, completion: @escaping (Result<ABTest, Error>) -> Void)
    func concludeTest(testId: String, winnerVariantId: String, completion: @escaping (Result<Void, Error>) -> Void)
}

final class ABTestingService: ABTestingServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private var cachedTests: [String: ABTest] = [:]
    private var userVariantAssignments: [String: String] = [:] // userId -> variantId
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    // MARK: - AB Test Management
    
    func getABTest(for arCodeId: String, completion: @escaping (Result<ABTest?, Error>) -> Void) {
        // Vérifier cache d'abord
        if let cached = cachedTests[arCodeId] {
            completion(.success(cached))
            return
        }
        
        Task {
            do {
                let test: ABTest? = try await networkService.request(
                    .getABTest,
                    method: .get,
                    parameters: nil,
                    headers: nil,
                    pathParameters: ["ar_code_id": arCodeId]
                )
                
                if let test = test {
                    cachedTests[arCodeId] = test
                }
                
                DispatchQueue.main.async {
                    completion(.success(test))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func createABTest(_ test: ABTest, completion: @escaping (Result<ABTest, Error>) -> Void) {
        let parameters: [String: Any] = [
            "ar_code_id": test.arCodeId,
            "name": test.name,
            "is_active": test.isActive,
            "variants": try! JSONEncoder().encode(test.variants).base64EncodedString(),
            "start_date": ISO8601DateFormatter().string(from: test.startDate)
        ]
        
        Task {
            do {
                let createdTest: ABTest = try await networkService.request(
                    .createABTest,
                    method: .post,
                    parameters: parameters,
                    headers: nil
                )
                
                cachedTests[createdTest.arCodeId] = createdTest
                
                DispatchQueue.main.async {
                    completion(.success(createdTest))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Variant Selection
    
    func selectVariant(for testId: String, userId: String?) -> ABTestVariant? {
        // Si utilisateur déjà assigné, retourner variant existant
        if let userId = userId,
           let assignedVariantId = userVariantAssignments[userId],
           let test = cachedTests.values.first(where: { $0.id == testId }),
           let variant = test.variants.first(where: { $0.variantId == assignedVariantId }) {
            return variant
        }
        
        // Sinon, sélectionner variant selon poids
        guard let test = cachedTests.values.first(where: { $0.id == testId }),
              test.isActive else {
            return nil
        }
        
        let selectedVariant = selectVariantByWeight(test.variants)
        
        // Assigner à utilisateur si disponible
        if let userId = userId {
            userVariantAssignments[userId] = selectedVariant.variantId
        }
        
        return selectedVariant
    }
    
    private func selectVariantByWeight(_ variants: [ABTestVariant]) -> ABTestVariant {
        let totalWeight = variants.reduce(0) { $0 + $1.weight }
        let random = Int.random(in: 0..<totalWeight)
        
        var currentWeight = 0
        for variant in variants {
            currentWeight += variant.weight
            if random < currentWeight {
                return variant
            }
        }
        
        // Fallback: premier variant
        return variants.first!
    }
    
    // MARK: - Analytics
    
    func trackConversion(variantId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let parameters: [String: Any] = [
            "variant_id": variantId,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        Task {
            do {
                let _: EmptyResponse = try await networkService.request(
                    .trackABTestConversion,
                    method: .post,
                    parameters: parameters,
                    headers: nil
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
    
    func getTestResults(testId: String, completion: @escaping (Result<ABTest, Error>) -> Void) {
        Task {
            do {
                let test: ABTest = try await networkService.request(
                    .getABTestResults,
                    method: .get,
                    parameters: nil,
                    headers: nil,
                    pathParameters: ["test_id": testId]
                )
                
                // Mettre à jour cache
                cachedTests[test.arCodeId] = test
                
                DispatchQueue.main.async {
                    completion(.success(test))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func concludeTest(testId: String, winnerVariantId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let parameters: [String: Any] = [
            "test_id": testId,
            "winner_variant_id": winnerVariantId
        ]
        
        Task {
            do {
                let _: EmptyResponse = try await networkService.request(
                    .concludeABTest,
                    method: .post,
                    parameters: parameters,
                    headers: nil,
                    pathParameters: ["test_id": testId]
                )
                
                // Mettre à jour cache
                if let test = cachedTests.values.first(where: { $0.id == testId }) {
                    var updatedTest = test
                    updatedTest.winnerVariantId = winnerVariantId
                    updatedTest.isActive = false
                    cachedTests[updatedTest.arCodeId] = updatedTest
                }
                
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
}

