# ARCode Clone - Application iOS de Réalité Augmentée

Application iOS complète de réalité augmentée, répliquant toutes les fonctionnalités d'AR Code (https://ar-code.com), **sans système d'abonnement**.

## 🎯 Mission Globale

Créer une application iOS de réalité augmentée identique à AR Code avec toutes ses fonctionnalités, technologies, animations, designs et performances, à l'exception du système d'abonnement.

## 🚀 Fonctionnalités Principales

### Modules AR
- ✅ **AR Code Object Capture** - Capture d'objets 3D par photogrammétrie
- ✅ **AR Face Filter** - Filtres visage temps réel avec ARKit Face Tracking
- ✅ **AI Code** - Assistant IA avec vision et génération d'images
- ✅ **AR Video** - Lecteur vidéo flottant en AR
- ✅ **AR Portal** - Expériences 360° immersives
- ✅ **AR Text** - Texte 3D extrudé personnalisable
- ✅ **AR Photo/Frame** - Photos avec cadres 3D
- ✅ **AR Logo** - Logos SVG → 3D
- ✅ **AR Splat** - Gaussian Splatting photoréaliste
- ✅ **AR Data API** - Contenu dynamique temps réel

### Technologies Clés
- **SLAM WebAR** - Système propriétaire sans app nécessaire
- **Photogrammétrie** - COLMAP pour reconstruction 3D
- **Gaussian Splatting** - Rendu photoréaliste avancé
- **QR Codes AR** - Partage universel multiplateforme

## 🛠️ Stack Technique

### iOS
- **Swift 5.9+**
- **SwiftUI** - Interface utilisateur
- **ARKit** - Réalité augmentée native
- **RealityKit 2.0+** - Rendu 3D
- **SceneKit** - Rendu AR alternatif
- **Vision Framework** - OCR, segmentation

### Backend (100% Gratuit)
- **Oracle Cloud Free Tier** - Hébergement (4 CPUs, 24GB RAM)
- **Cloudflare R2** - Stockage (10GB gratuit, 0$ egress)
- **Cloudflare CDN** - Distribution (bandwidth illimité)
- **PostgreSQL** - Base de données (self-hosted)
- **Redis** - Cache (Redis Cloud Free 30MB)
- **Supabase Auth** - Authentification (50K MAU)

### Processing
- **COLMAP** - Photogrammétrie
- **Nerfstudio** - Gaussian Splatting
- **Blender** - Mesh optimization
- **Ollama** - Vision models IA
- **Stable Diffusion** - Génération d'images

## 📁 Structure du Projet

```
ARCodeClone/
├── Sources/
│   ├── Views/          # Interfaces SwiftUI
│   ├── ViewModels/     # Logique MVVM
│   ├── Models/         # Modèles de données
│   ├── Services/       # Services (Network, AR, etc.)
│   ├── Utils/          # Utilitaires
│   └── Resources/      # Assets, localizations
├── Tests/              # Tests unitaires et intégration
├── Package.swift       # Dépendances SwiftPM
└── .swiftlint.yml      # Configuration SwiftLint
```

## 🔧 Installation

### Prérequis
- Xcode 15.0+
- iOS 16.0+ (deployment target)
- Swift 5.9+
- macOS pour développement

### Setup

```bash
# Cloner le projet
git clone [repository-url]
cd ARCodeClone

# Installer les dépendances
swift package resolve

# Ouvrir dans Xcode
open Package.swift
```

### Configuration SwiftLint

```bash
# Installer SwiftLint (optionnel pour Xcode)
brew install swiftlint

# Linter le projet
swiftlint lint
```

## 📱 Développement

### Architecture
- **MVVM** - Model-View-ViewModel
- **Dependency Injection** - Swinject
- **Protocol-Oriented** - Swift best practices

### Tests
- Tests unitaires avec XCTest
- Coverage target: 80%+
- Tests d'intégration API
- Tests ARKit avec simulation

## 🎨 Design System

### Couleurs
- Primary: `#6C5CE7` (Violet)
- Secondary: `#00B894` (Vert)
- Accent: `#FF7675` (Rouge corail)
- Dark: `#2D3436`
- Light: `#DFE6E9`

### Typography
- Headings: Inter Bold (24-48pt)
- Body: Inter Regular (14-18pt)
- Code: JetBrains Mono

## 📊 Performance Targets

- **AR Rendering**: 60fps constant (iPhone 12+)
- **SLAM Latency**: <16ms
- **Memory**: <150MB par scène AR
- **Load Time**: <3s initial, <1s AR activation

## 🔒 Sécurité

- OAuth 2.0 + JWT
- Keychain iOS pour tokens
- HTTPS only (TLS 1.3)
- GDPR compliant
- Rate limiting (100 req/min)

## 📚 Documentation

Documentation complète disponible dans le dossier `docs/`:

- [Guide Utilisateur](docs/USER_GUIDE.md) - Guide complet pour les utilisateurs
- [Guide Développeur](docs/DEVELOPER_GUIDE.md) - Documentation technique
- [Documentation API](docs/API_DOCUMENTATION.md) - API REST complète
- [Architecture](docs/ARCHITECTURE.md) - Diagrammes et architecture
- [App Store Guide](docs/APP_STORE.md) - Préparation App Store
- [Guide Launch](docs/LAUNCH.md) - Guide de lancement

## 📝 Licence

MIT License - Voir [LICENSE](LICENSE) pour plus de détails.

## 👥 Contributeurs

Merci à tous les contributeurs! Voir [CONTRIBUTORS.md](CONTRIBUTORS.md).

## 📞 Support

- **Email**: support@ar-code.com
- **Documentation**: https://docs.ar-code.com
- **GitHub Issues**: https://github.com/arcode-clone/issues
- **Discussions**: https://github.com/arcode-clone/discussions

## 🔗 Liens Utiles

- [Site Web](https://ar-code.com)
- [API Documentation](https://api.ar-code.com/docs)
- [Privacy Policy](docs/PRIVACY_POLICY.md)
- [Terms of Service](docs/TERMS_OF_SERVICE.md)

---

**Note**: Ce projet est une implémentation éducative et ne doit pas être utilisé à des fins commerciales sans autorisation appropriée d'AR Code.









