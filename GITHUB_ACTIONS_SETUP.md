# 🚀 Configuration GitHub Actions pour iOS

Guide complet pour configurer et utiliser GitHub Actions pour tester et builder votre app iOS.

## 📋 Ce qui a été créé

### 1. Workflow de Tests (`ios-test.yml`)
- ✅ Tests automatiques sur simulateur iOS
- ✅ Tests sur plusieurs versions iOS (16.0, 17.0)
- ✅ Tests sur plusieurs appareils (iPhone 14, iPhone 15 Pro)
- ✅ Build et test du Swift Package

### 2. Workflow de Build IPA (`ios-build-ipa.yml`)
- ✅ Build automatique du .ipa
- ✅ Génération d'artifact téléchargeable
- ✅ Création de release GitHub automatique

### 3. Guides d'installation
- ✅ `INSTALL_IPA.md` - Guide complet pour installer l'IPA sur iPhone

---

## 🔧 Configuration Initiale

### Étape 1: Pousser le code sur GitHub

```bash
# Initialiser git (si pas déjà fait)
git init

# Ajouter tous les fichiers
git add .

# Commit
git commit -m "Initial commit with GitHub Actions"

# Créer un repo sur GitHub, puis:
git remote add origin https://github.com/VOTRE_USERNAME/VOTRE_REPO.git
git push -u origin main
```

### Étape 2: Vérifier les workflows

1. Allez sur votre repo GitHub
2. Cliquez sur l'onglet **"Actions"**
3. Les workflows devraient apparaître automatiquement

---

## 🧪 Exécuter les Tests

### Automatique
- Les tests s'exécutent automatiquement à chaque push sur `main`/`master`/`develop`
- Ou à chaque Pull Request

### Manuel
1. Allez dans **Actions**
2. Sélectionnez **"iOS Tests with Simulator"**
3. Cliquez sur **"Run workflow"**
4. Sélectionnez la branche
5. Cliquez sur **"Run workflow"**

### Résultats
- Vous verrez les résultats dans l'onglet Actions
- Les tests passent sur simulateur iOS 16 et 17
- Les tests passent sur iPhone 14 et iPhone 15 Pro

---

## 📦 Build et Générer l'IPA

### Option 1: Build Automatique (Tag)

```bash
# Créer un tag
git tag v1.0.0
git push origin v1.0.0
```

Le workflow va automatiquement:
1. Builder l'app
2. Créer un .ipa
3. Uploader comme artifact
4. Créer une release GitHub

### Option 2: Build Manuel

1. Allez dans **Actions**
2. Sélectionnez **"Build iOS IPA"**
3. Cliquez sur **"Run workflow"**
4. Optionnel: Sélectionnez `build_for_device: true`
5. Cliquez sur **"Run workflow"**

### Télécharger l'IPA

1. Attendez que le workflow se termine
2. Cliquez sur le workflow terminé
3. Scroll down vers **"Artifacts"**
4. Cliquez sur **"ARCodeClone-IPA"**
5. Téléchargez et extrayez le fichier `.ipa`

---

## 🔐 Configuration Avancée (Optionnel)

### Pour Signer avec Certificat Développeur

Si vous avez un compte développeur Apple ($99/an):

1. **Exporter votre certificat:**
   - Ouvrez Keychain Access sur Mac
   - Exportez le certificat en .p12
   - Notez le mot de passe

2. **Ajouter les secrets GitHub:**
   - Repo → Settings → Secrets and variables → Actions
   - Ajoutez:
     - `IOS_CERTIFICATE_P12` - Base64 du fichier .p12
     - `IOS_CERTIFICATE_PASSWORD` - Mot de passe du certificat
     - `IOS_TEAM_ID` - Team ID Apple
     - `IOS_BUNDLE_ID` - `com.arcode.clone`
     - `IOS_ISSUER_ID` - App Store Connect API Key
     - `IOS_API_KEY_ID` - App Store Connect API Key ID
     - `IOS_API_KEY` - App Store Connect API Key (base64)

3. **Convertir .p12 en base64:**
   ```bash
   # Sur Mac
   base64 -i certificate.p12 -o certificate.txt
   ```

### Pour Upload automatique sur TestFlight

Le workflow `ios-build-ipa.yml` inclut déjà la logique pour uploader sur TestFlight si les secrets sont configurés.

---

## 📱 Installer l'IPA sur iPhone

Voir le guide complet: **`INSTALL_IPA.md`**

### Méthodes disponibles:
1. **AltStore** (Recommandé - Gratuit, Windows)
2. **Sideloadly** (Gratuit, Windows)
3. **Xcode** (Mac uniquement)
4. **TestFlight** (Nécessite compte développeur)
5. **3uTools** (Alternative Windows)

---

## 🔍 Troubleshooting

### Workflow échoue: "Package.swift not found"
- Vérifiez que `Package.swift` est à la racine du repo
- Vérifiez que le workflow checkout le code

### Build échoue: "No such module"
- Vérifiez que toutes les dépendances sont dans `Package.swift`
- Le workflow résout automatiquement les dépendances

### IPA non généré
- Vérifiez les logs du workflow
- Le workflow essaie plusieurs méthodes de build
- Vérifiez que le projet Swift Package est valide

### Simulateur ne démarre pas
- GitHub Actions utilise macOS avec simulateurs pré-installés
- Vérifiez que la version iOS est disponible

---

## 📊 Monitoring

### Voir les logs
1. Allez dans **Actions**
2. Sélectionnez un workflow
3. Cliquez sur un job
4. Cliquez sur une étape pour voir les logs

### Notifications
- GitHub vous enverra un email si un workflow échoue
- Configurez les notifications dans GitHub Settings

---

## 🎯 Prochaines Étapes

1. ✅ **Pousser le code** sur GitHub
2. ✅ **Exécuter les tests** pour vérifier que tout fonctionne
3. ✅ **Builder l'IPA** pour tester
4. ✅ **Installer sur iPhone** via AltStore ou autre méthode
5. ✅ **Tester l'app** avec le backend Windows

---

## 💡 Astuces

### Automatiser les builds
- Créez un tag à chaque release
- Le workflow buildera automatiquement

### Tests multiples
- Le workflow teste sur plusieurs versions iOS
- Vous pouvez ajouter d'autres versions dans la matrix

### CI/CD Complet
- Les tests s'exécutent automatiquement
- Les builds sont créés sur demande ou sur tag
- Les releases sont créées automatiquement

---

## 📞 Besoin d'Aide?

Si vous avez des problèmes:
1. Vérifiez les logs du workflow
2. Vérifiez que tous les fichiers sont présents
3. Vérifiez la syntaxe YAML
4. Consultez la documentation GitHub Actions

**Bon développement! 🚀**

