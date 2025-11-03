//
//  SentryService.swift
//  ARCodeClone
//
//  Sentry integration for error tracking and performance monitoring
//

import Foundation
import Sentry

protocol SentryServiceProtocol {
    func initialize()
    func captureError(_ error: Error, context: [String: Any]?)
    func captureMessage(_ message: String, level: SentryLevel)
    func setUser(userId: String?, email: String?, username: String?)
    func addBreadcrumb(message: String, category: String, level: SentryLevel)
    func startTransaction(name: String, operation: String) -> SentryTransaction?
}

enum SentryLevel {
    case debug
    case info
    case warning
    case error
    case fatal
    
    var sentryLevel: Sentry.SentryLevel {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .fatal: return .fatal
        }
    }
}

final class SentryService: SentryServiceProtocol {
    static let shared = SentryService()
    
    private var isInitialized = false
    
    private init() {}
    
    func initialize() {
        guard !isInitialized else { return }
        
        SentrySDK.start { options in
            // DSN from environment or Info.plist
            options.dsn = Bundle.main.object(forInfoDictionaryKey: "SentryDSN") as? String ?? ProcessInfo.processInfo.environment["SENTRY_DSN"]
            
            options.debug = false // Set to true for development
            options.environment = ProcessInfo.processInfo.environment["SENTRY_ENV"] ?? "production"
            
            // Performance monitoring
            options.tracesSampleRate = 0.1 // 10% of transactions
            options.enableAutoSessionTracking = true
            
            // Release tracking
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                options.releaseName = "ar-code@\(version)"
            }
            
            // Capture uncaught exceptions
            options.enableCaptureFailedRequests = true
            
            // Additional context
            options.beforeSend = { event in
                // Filter sensitive data
                return self.filterSensitiveData(event)
            }
        }
        
        isInitialized = true
    }
    
    func captureError(_ error: Error, context: [String: Any]? = nil) {
        SentrySDK.capture(error: error) { scope in
            if let context = context {
                scope.setContext(value: context, key: "Additional Context")
            }
        }
    }
    
    func captureMessage(_ message: String, level: SentryLevel) {
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(level.sentryLevel)
        }
    }
    
    func setUser(userId: String?, email: String?, username: String?) {
        SentrySDK.setUser(User(
            userId: userId,
            email: email,
            username: username
        ))
    }
    
    func addBreadcrumb(message: String, category: String, level: SentryLevel) {
        let breadcrumb = Breadcrumb()
        breadcrumb.message = message
        breadcrumb.category = category
        breadcrumb.level = level.sentryLevel
        SentrySDK.addBreadcrumb(breadcrumb)
    }
    
    func startTransaction(name: String, operation: String) -> SentryTransaction? {
        let transaction = SentrySDK.startTransaction(name: name, operation: operation)
        return transaction
    }
    
    private func filterSensitiveData(_ event: Event) -> Event? {
        // Remove sensitive data from event
        // Example: passwords, tokens, etc.
        
        if let request = event.request {
            // Filter sensitive headers
            var filteredHeaders = request.headers ?? [:]
            filteredHeaders.removeValue(forKey: "Authorization")
            filteredHeaders.removeValue(forKey: "X-API-Key")
            
            event.request?.headers = filteredHeaders
        }
        
        return event
    }
}

// MARK: - Convenience Extensions

extension SentryService {
    func trackARError(_ error: Error, arCodeId: String? = nil) {
        var context: [String: Any] = [:]
        if let arCodeId = arCodeId {
            context["ar_code_id"] = arCodeId
        }
        captureError(error, context: context)
    }
    
    func trackPerformance(operation: String, duration: TimeInterval) {
        addBreadcrumb(
            message: "\(operation) took \(duration)s",
            category: "performance",
            level: .info
        )
    }
}







