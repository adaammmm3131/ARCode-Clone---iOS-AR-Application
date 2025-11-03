# Instructions pour Tester sur iPhone depuis Windows

## ✅ Étape 1: Backend Lancé

Le serveur backend est maintenant lancé sur votre PC Windows.

**Votre adresse IP:** `172.20.10.3`  
**Port:** `8080`  
**URL Backend:** `http://172.20.10.3:8080`

---

## 🔧 Étape 2: Configurer le Firewall Windows

**Option A: Script automatique (Recommandé)**

1. Ouvrez PowerShell **en tant qu'Administrateur** (clic droit → Exécuter en tant qu'administrateur)
2. Exécutez:
```powershell
cd "C:\Users\asus\OneDrive\Bureau\prompt inchalah\backend"
.\configure_network_access.ps1
```

**Option B: Manuel**

1. Ouvrez le **Pare-feu Windows Defender**
2. Cliquez sur **Paramètres avancés**
3. Cliquez sur **Règles de trafic entrant** → **Nouvelle règle**
4. Type: **Port** → Suivant
5. TCP, port spécifique: **8080** → Suivant
6. Autoriser la connexion → Suivant
7. Cochez tous les profils → Suivant
8. Nom: **ARCode Backend** → Terminer

---

## 📱 Étape 3: Tester depuis votre iPhone

1. **Assurez-vous que votre iPhone est sur le même WiFi** que votre PC Windows

2. **Ouvrez Safari sur iPhone**

3. **Testez la connexion:**
   - Allez à: `http://172.20.10.3:8080/health`
   - Vous devriez voir: `{"status":"ok","message":"ARCode API is running"}`

4. **Si ça ne fonctionne pas:**
   - Vérifiez que le serveur tourne sur Windows
   - Vérifiez que l'iPhone est sur le même WiFi
   - Vérifiez le firewall Windows

---

## 🍎 Étape 4: Tester l'Application iOS

### ⚠️ Problème: Xcode nécessite macOS

Pour tester votre application iOS native sur iPhone depuis Windows, vous avez **plusieurs options**:

### Option 1: Mac Cloud (Recommandé) ⭐

**Services:**
- **MacinCloud** - https://www.macincloud.com (à partir de $20/mois)
- **RentAMac.io** - https://rentamac.io (location flexible)
- **MacStadium** - https://www.macstadium.com (professionnel)

**Étapes:**
1. S'abonner à un service Mac cloud
2. Se connecter via RDP/VNC
3. Transférer votre projet iOS
4. Ouvrir dans Xcode
5. Connecter iPhone via USB
6. Compiler et installer

**Avantages:**
- Accès complet à Xcode
- Test sur iPhone réel
- Compilation App Store

---

### Option 2: TestFlight (Nécessite Mac une fois)

**Prérequis:**
- Compte développeur Apple ($99/an)
- Accès à un Mac (une seule fois)

**Étapes:**
1. Compiler l'app sur un Mac (ami, bibliothèque, Mac cloud)
2. Uploader sur App Store Connect
3. Distribuer via TestFlight
4. Installer sur iPhone via l'app TestFlight

---

### Option 3: Modifier le Code pour l'URL Backend

Une fois que vous avez accès à un Mac et compilez l'app, vous devez modifier l'URL de l'API dans votre code iOS.

**Cherchez dans votre code Swift:**
```swift
// Cherchez les fichiers qui contiennent des URLs API
// Exemples: Services/NetworkService.swift, Services/APIService.swift
```

**Modifiez l'URL:**
```swift
// Avant (localhost)
let baseURL = "http://localhost:8080"

// Après (IP Windows)
let baseURL = "http://172.20.10.3:8080"
```

**Fichiers à vérifier:**
- `Sources/Services/NetworkService.swift`
- `Sources/Services/APIService.swift`
- Tous les fichiers dans `Sources/Services/` qui gèrent les appels API

---

## 🔍 Rechercher les URLs dans le Code

Pour trouver où l'URL de l'API est définie:

```bash
# Dans le dossier Sources/
grep -r "localhost" Sources/
grep -r "http://" Sources/
grep -r "baseURL" Sources/
grep -r "API_URL" Sources/
```

---

## 📋 Checklist Complète

- [x] Backend lancé sur Windows (port 8080)
- [ ] Firewall Windows configuré
- [ ] Test depuis iPhone Safari réussi (`http://172.20.10.3:8080/health`)
- [ ] Accès à un Mac (cloud ou physique)
- [ ] Code iOS modifié avec la bonne URL IP
- [ ] App compilée et installée sur iPhone
- [ ] App iOS testée avec backend Windows

---

## 🚀 Prochaines Étapes

1. **Maintenant:** Testez le backend depuis iPhone Safari
2. **Ensuite:** Obtenez accès à un Mac (cloud recommandé)
3. **Puis:** Compilez et installez l'app sur iPhone
4. **Enfin:** Testez l'app complète avec le backend Windows

---

## 💡 Astuce

Pendant que vous configurez le Mac, vous pouvez:
- Continuer à développer le backend sur Windows
- Tester les endpoints API depuis iPhone Safari
- Préparer les modifications nécessaires dans le code iOS

---

## 📞 Besoin d'Aide?

Si vous avez besoin d'aide pour:
- Configurer le firewall
- Trouver les URLs dans le code
- Configurer un Mac cloud
- Modifier le code iOS

N'hésitez pas à demander!

