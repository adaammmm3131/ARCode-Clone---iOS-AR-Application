# Guide: Modifier les URLs API pour utiliser le Backend Windows

## 📍 Votre IP Windows: `172.20.10.3`
## 🔌 Port Backend: `8080`
## 🌐 URL Base: `http://172.20.10.3:8080`

---

## 📝 Fichiers à Modifier

### 1. `Sources/Services/NetworkService.swift` (Principal)

**Ligne 18:** Modifier l'URL par défaut

```swift
// AVANT:
init(
    baseURL: String = "https://api.ar-code.com",
    ...
)

// APRÈS:
init(
    baseURL: String = "http://172.20.10.3:8080",
    ...
)
```

---

### 2. `Sources/Services/ARDataAPIService.swift`

**Ligne 122:** Modifier l'URL par défaut

```swift
// AVANT:
init(
    networkService: NetworkServiceProtocol,
    authService: AuthenticationServiceProtocol,
    baseURL: String = "https://api.ar-code.com"
)

// APRÈS:
init(
    networkService: NetworkServiceProtocol,
    authService: AuthenticationServiceProtocol,
    baseURL: String = "http://172.20.10.3:8080"
)
```

---

### 3. `Sources/Services/AuthenticationService.swift`

**Ligne 76:** Modifier l'URL par défaut

```swift
// AVANT:
init(
    ...
    baseURL: String = "https://api.ar-code.com",
    ...
)

// APRÈS:
init(
    ...
    baseURL: String = "http://172.20.10.3:8080",
    ...
)
```

---

### 4. `Sources/Services/AnalyticsService.swift`

**Ligne 29:** Modifier l'URL par défaut

```swift
// AVANT:
self.apiBaseURL = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String ?? "https://api.ar-code.com"

// APRÈS:
self.apiBaseURL = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String ?? "http://172.20.10.3:8080"
```

---

### 5. `Sources/Utils/DependencyContainer.swift`

**Ligne 255:** Services avec localhost

```swift
// Chercher les services qui utilisent "http://localhost:5000"
// et les remplacer par "http://172.20.10.3:8080"
```

---

### 6. Services avec localhost spécifiques

#### `Sources/Services/ARSplatProcessingService.swift` (Ligne 74)
```swift
// AVANT:
init(networkService: NetworkServiceProtocol, baseURL: String = "http://localhost:5000")

// APRÈS:
init(networkService: NetworkServiceProtocol, baseURL: String = "http://172.20.10.3:8080")
```

#### `Sources/Services/AIAnalysisService.swift` (Ligne 50)
```swift
// AVANT:
init(networkService: NetworkServiceProtocol, baseURL: String = "http://localhost:5001")

// APRÈS:
init(networkService: NetworkServiceProtocol, baseURL: String = "http://172.20.10.3:8080")
```

#### `Sources/Services/VirtualTryOnService.swift` (Ligne 62)
```swift
// AVANT:
baseURL: String = "http://localhost:5002"

// APRÈS:
baseURL: String = "http://172.20.10.3:8080"
```

---

## 🔧 Alternative: Utiliser Info.plist (Recommandé)

Au lieu de modifier le code directement, vous pouvez utiliser un fichier `Info.plist` pour configurer l'URL:

1. **Créer/modifier `Info.plist`** dans votre projet Xcode:
```xml
<key>APIBaseURL</key>
<string>http://172.20.10.3:8080</string>
```

2. **Le code lira automatiquement cette valeur:**
```swift
// Déjà implémenté dans AnalyticsService.swift ligne 29
self.apiBaseURL = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String ?? "https://api.ar-code.com"
```

---

## ⚠️ Important: HTTPS vs HTTP

**Note:** Votre backend Windows utilise HTTP (pas HTTPS). iOS par défaut bloque les connexions HTTP non sécurisées.

### Solution: Autoriser HTTP dans Info.plist

Ajoutez dans `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <!-- OU pour un domaine spécifique: -->
    <key>NSExceptionDomains</key>
    <dict>
        <key>172.20.10.3</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

---

## 📋 Checklist de Modification

- [ ] Modifier `NetworkService.swift` (ligne 18)
- [ ] Modifier `ARDataAPIService.swift` (ligne 122)
- [ ] Modifier `AuthenticationService.swift` (ligne 76)
- [ ] Modifier `AnalyticsService.swift` (ligne 29)
- [ ] Modifier `ARSplatProcessingService.swift` (ligne 74)
- [ ] Modifier `AIAnalysisService.swift` (ligne 50)
- [ ] Modifier `VirtualTryOnService.swift` (ligne 62)
- [ ] Modifier `DependencyContainer.swift` (ligne 255)
- [ ] Ajouter `NSAppTransportSecurity` dans Info.plist
- [ ] Tester la connexion depuis l'app

---

## 🧪 Test Rapide

Après modification, testez dans l'app:
1. Lancer l'app sur iPhone
2. Vérifier les logs réseau dans Xcode
3. Vérifier que les requêtes vont vers `172.20.10.3:8080`
4. Vérifier les réponses du backend

---

## 💡 Astuce

Si votre IP Windows change (connexion WiFi différente), vous devrez:
1. Relancer `ipconfig` pour trouver la nouvelle IP
2. Mettre à jour toutes les URLs dans le code
3. Ou utiliser un service DNS local (comme ngrok pour exposer le backend)

---

## 🔗 Alternative: Utiliser ngrok (Tunnel)

Si vous voulez une URL publique stable:

1. **Installer ngrok:** https://ngrok.com
2. **Créer un tunnel:**
```bash
ngrok http 8080
```
3. **Utiliser l'URL ngrok** (ex: `https://abc123.ngrok.io`) dans le code iOS

**Avantage:** URL stable, HTTPS automatique, pas besoin de configurer firewall

