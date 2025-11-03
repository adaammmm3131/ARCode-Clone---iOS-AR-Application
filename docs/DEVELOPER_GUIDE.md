# Guide Développeur - ARCode Clone

Documentation technique complète pour les développeurs.

## 📚 Table des Matières

1. [Architecture](#architecture)
2. [Installation & Setup](#installation--setup)
3. [Structure du Code](#structure-du-code)
4. [Services](#services)
5. [API Integration](#api-integration)
6. [Tests](#tests)
7. [Déploiement](#déploiement)
8. [Contributions](#contributions)

## 🏗️ Architecture

### Pattern MVVM
L'application utilise le pattern Model-View-ViewModel:

```
View (SwiftUI) → ViewModel → Service → Network/AR
```

### Dependency Injection
Utilisation de **Swinject** pour l'injection de dépendances:
- Toutes les dépendances sont enregistrées dans `DependencyContainer`
- Résolution automatique des dépendances
- Facilite les tests unitaires

### Protocol-Oriented Programming
Tous les services utilisent des protocols:
- `NetworkServiceProtocol`
- `ARRenderingPipelineProtocol`
- `AnalyticsServiceProtocol`
- etc.

## 🔧 Installation & Setup

### Prérequis
- Xcode 15.0+
- Swift 5.9+
- macOS 13.0+
- CocoaPods (optionnel)

### Setup Initial

```bash
# 1. Cloner le repository
git clone https://github.com/arcode-clone/arcode-clone-ios.git
cd arcode-clone-ios

# 2. Installer les dépendances Swift Package Manager
# Dans Xcode: File > Add Packages
# Ou via CLI:
swift package resolve

# 3. Ouvrir le projet
open ARCodeClone.xcodeproj
# ou
open Package.swift

# 4. Configurer les certificats de signature
# Xcode > Signing & Capabilities
```

### Configuration Backend

```bash
cd backend

# Installer les dépendances Python
pip install -r requirements.txt

# Configurer les variables d'environnement
cp .env.example .env
# Éditer .env avec vos clés API

# Lancer le serveur local
python api/app.py
```

## 📁 Structure du Code

```
Sources/
├── ARCodeCloneApp.swift      # Point d'entrée
├── Views/                    # Interfaces SwiftUI
│   ├── DashboardHomeView.swift
│   ├── ARExperienceView.swift
│   └── ...
├── ViewModels/              # Logique métier
│   ├── DashboardViewModel.swift
│   ├── ARExperienceViewModel.swift
│   └── ...
├── Models/                  # Modèles de données
│   ├── ARCode.swift
│   ├── User.swift
│   └── ...
├── Services/                # Services métier
│   ├── NetworkService.swift
│   ├── ARRenderingPipeline.swift
│   ├── AnalyticsService.swift
│   └── ...
├── Utils/                   # Utilitaires
│   ├── DependencyContainer.swift
│   └── ARConfigurationFactory.swift
└── DesignSystem/           # Composants UI
    ├── ARColors.swift
    ├── ARTypography.swift
    └── Components/
```

## 🔌 Services

### NetworkService
Service principal pour les appels API.

```swift
let networkService = DependencyContainer.shared.resolve(NetworkServiceProtocol.self)

// Exemple: Get AR Code
let arCode: ARCode = try await networkService.request(
    .getARCode,
    method: .get,
    parameters: nil,
    headers: nil,
    pathParameters: ["id": arCodeId]
)
```

### ARRenderingPipeline
Pipeline de rendu AR.

```swift
let pipeline = DependencyContainer.shared.resolve(ARRenderingPipelineProtocol.self)
pipeline.setupARView(arView)
pipeline.loadModel(url: modelURL)
```

### AnalyticsService
Service d'analytics.

```swift
let analytics = DependencyContainer.shared.resolve(AnalyticsServiceProtocol.self)
analytics.trackEvent(.qrScan, metadata: ["ar_code_id": id])
```

## 🌐 API Integration

### Authentification
L'application utilise Supabase Auth avec OAuth 2.0:

```swift
let authService = DependencyContainer.shared.resolve(AuthenticationServiceProtocol.self)
try await authService.login(email: email, password: password)
```

### Endpoints Principaux

#### AR Codes
- `GET /api/v1/ar-codes/{id}` - Récupérer un AR Code
- `POST /api/v1/ar-codes/create` - Créer un AR Code
- `PUT /api/v1/ar-codes/{id}` - Mettre à jour
- `DELETE /api/v1/ar-codes/{id}` - Supprimer

#### Upload 3D
- `POST /api/v1/3d/upload` - Upload modèle 3D
- `POST /api/v1/3d/photogrammetry` - Démarrer photogrammétrie

#### Analytics
- `POST /api/v1/analytics/track` - Tracker événement
- `GET /api/v1/analytics/stats` - Statistiques

Voir [Documentation API](API_DOCUMENTATION.md) pour plus de détails.

## 🧪 Tests

### Tests Unitaires

```swift
import XCTest
@testable import ARCodeClone

final class ARCodeTests: XCTestCase {
    func testARCodeEncoding() throws {
        let arCode = ARCode(...)
        let encoder = JSONEncoder()
        let data = try encoder.encode(arCode)
        // Assertions
    }
}
```

### Tests d'Intégration

```swift
func testNetworkService() async throws {
    let service = NetworkService()
    let arCode: ARCode = try await service.request(
        .getARCode,
        method: .get,
        parameters: nil,
        headers: nil,
        pathParameters: ["id": "test-id"]
    )
    XCTAssertNotNil(arCode)
}
```

### Exécuter les Tests

```bash
# Dans Xcode: Cmd+U
# Ou via CLI:
xcodebuild test -scheme ARCodeClone -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Coverage Target
- Minimum: 80%
- Utiliser Codecov pour tracking

## 🚀 Déploiement

### Build Production

```bash
# Archive
xcodebuild archive \
  -scheme ARCodeClone \
  -configuration Release \
  -archivePath build/ARCodeClone.xcarchive

# Export IPA
xcodebuild -exportArchive \
  -archivePath build/ARCodeClone.xcarchive \
  -exportPath build \
  -exportOptionsPlist exportOptions.plist
```

### TestFlight

1. Upload l'archive vers App Store Connect
2. Configurez les métadonnées
3. Invitez les testeurs
4. Surveillez les feedbacks

Voir [Guide Launch](LAUNCH.md) pour plus de détails.

## 🔄 CI/CD

### GitHub Actions
Le projet utilise GitHub Actions pour:
- Tests automatiques
- Builds
- Déploiement TestFlight
- Code coverage

Workflow: `.github/workflows/ios-build.yml`

### Configuration
- Secrets requis dans GitHub:
  - `APP_STORE_CONNECT_API_KEY`
  - `CERTIFICATE_PASSWORD`
  - `PROVISIONING_PROFILE`

## 📝 Contributions

### Workflow Git
1. Créer une branche depuis `develop`
2. Développer la feature
3. Écrire les tests
4. Créer une Pull Request
5. Code review
6. Merge dans `develop`

### Standards de Code
- SwiftLint pour linting
- Format: SwiftFormat (optionnel)
- Documentation: Swift DocC

### Commit Messages
Format: `[TYPE] Description`

Types:
- `[FEAT]` - Nouvelle fonctionnalité
- `[FIX]` - Correction de bug
- `[DOC]` - Documentation
- `[REFACTOR]` - Refactoring
- `[TEST]` - Tests

## 🔍 Debugging

### ARKit Debug
```swift
// Activer visualisation des plans
arView.debugOptions = [.showFeaturePoints, .showWorldOrigin]

// Performance monitoring
let monitor = ARPerformanceMonitor(arView: arView)
monitor.startMonitoring()
```

### Network Debugging
```swift
// Logs réseau
NetworkService.enableDebugLogging = true
```

### Sentry
Erreurs automatiquement trackées via Sentry.

## 📚 Ressources

- [Documentation ARKit](https://developer.apple.com/documentation/arkit)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [API Documentation](API_DOCUMENTATION.md)
- [Architecture Diagrams](ARCHITECTURE.md)

## 🐛 Troubleshooting

### Problèmes Courants

**Build fails:**
- Vérifier les certificats de signature
- Nettoyer le build folder (Cmd+Shift+K)
- Réinstaller les dépendances

**Tests fail:**
- Vérifier les mocks
- S'assurer que les services sont correctement injectés

**AR ne fonctionne pas:**
- Vérifier les permissions caméra
- Tester sur un device réel (pas simulateur)
- Vérifier ARKit support

## 📞 Support Développeur

- Issues: https://github.com/arcode-clone/issues
- Discussions: https://github.com/arcode-clone/discussions
- Email: dev@ar-code.com






