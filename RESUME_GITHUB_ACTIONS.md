# 🚀 Résumé: GitHub Actions pour iOS

## ✅ Ce qui a été créé

### 1. Workflow de Tests (`ios-test.yml`)
- ✅ Tests automatiques sur simulateur iOS
- ✅ Build et test du Swift Package
- ✅ Exécution sur plusieurs versions iOS
- ✅ Cache des dépendances Swift

### 2. Workflow de Build IPA (`ios-build-ipa.yml`)
- ✅ Build automatique du .ipa
- ✅ Génération d'artifact téléchargeable
- ✅ Création de release GitHub automatique (sur tag)
- ✅ Support pour build ad-hoc (pour installation directe)

### 3. Guides complets
- ✅ `INSTALL_IPA.md` - Guide détaillé pour installer l'IPA sur iPhone
- ✅ `GITHUB_ACTIONS_SETUP.md` - Guide de configuration
- ✅ `create-xcode-project.sh` - Script pour créer projet Xcode

---

## 🎯 Utilisation Rapide

### 1. Pousser sur GitHub

```bash
# Si pas encore fait
git init
git add .
git commit -m "Add GitHub Actions workflows"
git remote add origin https://github.com/VOTRE_USERNAME/VOTRE_REPO.git
git push -u origin main
```

### 2. Exécuter les Tests

**Automatique:**
- Les tests s'exécutent automatiquement à chaque push

**Manuel:**
1. GitHub → Actions → "iOS Tests with Simulator"
2. Cliquez sur "Run workflow"
3. Sélectionnez la branche
4. Cliquez sur "Run workflow"

### 3. Builder l'IPA

**Option A: Via Tag (Recommandé)**
```bash
git tag v1.0.0
git push origin v1.0.0
```
→ Le workflow buildera automatiquement et créera une release

**Option B: Manuel**
1. GitHub → Actions → "Build iOS IPA"
2. Cliquez sur "Run workflow"
3. Optionnel: `build_for_device: true`
4. Cliquez sur "Run workflow"

### 4. Télécharger l'IPA

1. Attendez que le workflow se termine
2. Dans le workflow terminé, scroll down vers "Artifacts"
3. Cliquez sur "ARCodeClone-IPA"
4. Téléchargez et extrayez le `.ipa`

### 5. Installer sur iPhone

Voir le guide complet: **`INSTALL_IPA.md`**

**Méthodes recommandées:**
- **AltStore** (Gratuit, Windows) ⭐
- **Sideloadly** (Gratuit, Windows)
- **Xcode** (Mac uniquement)

---

## 📋 Workflows Disponibles

### `ios-test.yml`
- **Quand:** Push/PR sur main/master/develop
- **Quoi:** Build et tests du Swift Package
- **Où:** Simulateur iOS sur GitHub Actions

### `ios-build-ipa.yml`
- **Quand:** Tag `v*` ou push sur main/master, ou manuel
- **Quoi:** Build du .ipa
- **Résultat:** Artifact téléchargeable + Release GitHub

---

## 🔧 Configuration Avancée

### Secrets GitHub (Optionnel)

Pour signer avec certificat développeur:

1. **Repo → Settings → Secrets and variables → Actions**
2. **Ajouter:**
   - `IOS_CERTIFICATE_P12` - Certificat en base64
   - `IOS_CERTIFICATE_PASSWORD` - Mot de passe
   - `IOS_TEAM_ID` - Team ID Apple
   - `IOS_BUNDLE_ID` - `com.arcode.clone`
   - `IOS_ISSUER_ID` - App Store Connect API
   - `IOS_API_KEY_ID` - App Store Connect API Key ID
   - `IOS_API_KEY` - App Store Connect API Key

### Bundle ID

Le bundle ID par défaut est: `com.arcode.clone`

Pour changer, modifiez:
- `exportOptions.plist`
- `ios-build-ipa.yml` (ligne BUNDLE_ID)

---

## 📱 Installation sur iPhone

### Méthode 1: AltStore (Recommandé)

1. **Installer AltServer sur Windows:**
   - https://altstore.io
   - Installer iTunes + iCloud

2. **Installer AltStore sur iPhone:**
   - Connecter iPhone via USB
   - AltServer → Install AltStore
   - Entrer Apple ID

3. **Installer l'IPA:**
   - Télécharger l'IPA depuis GitHub
   - Ouvrir AltStore sur iPhone
   - Appuyer sur "+" → Sélectionner l'IPA

4. **Faire confiance:**
   - Réglages → Général → Gestion des appareils
   - Faire confiance à votre Apple ID

**Note:** L'app expire après 7 jours (renouvelable)

### Méthode 2: Sideloadly

1. **Télécharger Sideloadly:**
   - https://sideloadly.io

2. **Connecter iPhone** via USB

3. **Ouvrir Sideloadly:**
   - Sélectionner iPhone
   - Entrer Apple ID
   - Sélectionner l'IPA
   - Cliquer sur "Start"

### Méthode 3: Xcode (Mac)

1. **Ouvrir Xcode**
2. **Window → Devices and Simulators**
3. **Sélectionner iPhone**
4. **Installer l'IPA**

---

## 🔍 Troubleshooting

### Tests échouent
- Vérifiez que `Package.swift` est valide
- Vérifiez que les dépendances sont correctes
- Consultez les logs du workflow

### IPA non généré
- Vérifiez les logs du workflow
- Le workflow essaie plusieurs méthodes
- Vérifiez que le Swift Package est valide

### Installation échoue
- Vérifiez que l'iPhone est compatible (iOS 16+)
- Vérifiez que l'app n'est pas expirée (7 jours)
- Faire confiance à l'app dans Réglages

---

## 📊 Monitoring

### Voir les résultats
1. GitHub → Actions
2. Sélectionner un workflow
3. Voir les logs et résultats

### Notifications
- GitHub envoie un email si un workflow échoue
- Configurez dans GitHub Settings

---

## 🎯 Prochaines Étapes

1. ✅ **Pousser le code** sur GitHub
2. ✅ **Exécuter les tests** pour vérifier
3. ✅ **Builder l'IPA** pour tester
4. ✅ **Installer sur iPhone** via AltStore
5. ✅ **Tester l'app** avec le backend Windows

---

## 💡 Astuces

### Automatisation
- Créez un tag à chaque release
- Le workflow buildera automatiquement

### Tests multiples
- Les tests s'exécutent sur plusieurs versions iOS
- Vous pouvez ajouter d'autres versions

### CI/CD Complet
- Tests automatiques à chaque push
- Builds sur demande ou sur tag
- Releases automatiques

---

## 📞 Besoin d'Aide?

Consultez:
- `GITHUB_ACTIONS_SETUP.md` - Guide complet
- `INSTALL_IPA.md` - Guide d'installation
- Logs GitHub Actions pour erreurs

**Bon développement! 🚀**

