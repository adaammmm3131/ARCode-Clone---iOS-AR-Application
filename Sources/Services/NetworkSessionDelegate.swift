//
//  NetworkSessionDelegate.swift
//  ARCodeClone
//
//  Delegate URLSession pour certificate pinning
//

import Foundation

final class NetworkSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Certificate pinning simplifié
        // En production, implémenter pinning complet avec comparaison de certificats
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Pour l'instant, accepter toutes les chaînes de certificats valides
        // TODO: Implémenter certificate pinning complet avec certificats épinglés
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    }
}













