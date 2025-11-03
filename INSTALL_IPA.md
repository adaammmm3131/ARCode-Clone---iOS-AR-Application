# 📱 Guide: Installer l'IPA sur votre iPhone

Ce guide explique comment installer le fichier `.ipa` généré par GitHub Actions sur votre iPhone.

## 📋 Prérequis

1. **iPhone** avec iOS 16.0+
2. **Ordinateur** (Windows/Mac/Linux)
3. **Câble USB** pour connecter l'iPhone (selon méthode)
4. **Compte Apple ID** (gratuit)

---

## 🎯 Méthode 1: AltStore (Recommandé - Gratuit) ⭐

**Avantages:**
- ✅ Gratuit
- ✅ Pas besoin de Mac
- ✅ Fonctionne sur Windows
- ✅ Installation directe depuis Windows

**Limitations:**
- ⚠️ L'app expire après 7 jours (renouvelable via AltServer)
- ⚠️ Besoin de renouveler chaque semaine

### Étapes

#### 1. Installer AltServer sur Windows

1. **Télécharger AltServer:**
   - Allez sur: https://altstore.io
   - Téléchargez AltServer pour Windows
   - Installez-le

2. **Installer iTunes et iCloud:**
   - Téléchargez iTunes depuis le Microsoft Store
   - Téléchargez iCloud depuis le site Apple
   - **Important:** Les deux doivent être installés

#### 2. Configurer AltServer

1. **Lancer AltServer** (depuis la barre système)
2. **Connecter votre iPhone** via USB
3. **Autoriser l'ordinateur** sur l'iPhone (si demandé)

#### 3. Installer AltStore sur iPhone

1. **Ouvrir AltServer** → Cliquer sur votre iPhone
2. **Sélectionner "Install AltStore"**
3. **Entrer votre Apple ID** (email et mot de passe)
4. Attendre l'installation

#### 4. Installer l'IPA

1. **Télécharger l'IPA** depuis GitHub Actions:
   - Allez dans "Actions" → Sélectionnez le workflow
   - Téléchargez l'artifact "ARCodeClone-IPA"
   - Extrayez le fichier `.ipa`

2. **Sur iPhone:**
   - Ouvrez **AltStore**
   - Allez dans l'onglet **"My Apps"**
   - Appuyez sur **"+"** en haut à gauche
   - Sélectionnez le fichier `.ipa`
   - Attendez l'installation

3. **Faire confiance à l'app:**
   - Réglages → Général → Gestion des appareils
   - Sélectionnez votre Apple ID
   - Appuyez sur **"Faire confiance"**

#### 5. Renouveler l'app (tous les 7 jours)

1. **Connecter iPhone** à Windows
2. **Ouvrir AltServer**
3. **Cliquer sur iPhone** → **"Refresh Apps"**
4. Ou utiliser l'option dans AltStore sur iPhone

---

## 🎯 Méthode 2: Sideloadly (Gratuit - Windows)

**Avantages:**
- ✅ Gratuit
- ✅ Interface simple
- ✅ Fonctionne bien sur Windows

**Limitations:**
- ⚠️ L'app expire après 7 jours
- ⚠️ Besoin de renouveler chaque semaine

### Étapes

1. **Télécharger Sideloadly:**
   - Allez sur: https://sideloadly.io
   - Téléchargez pour Windows
   - Installez

2. **Installer iTunes** (si pas déjà installé)

3. **Connecter iPhone** via USB

4. **Ouvrir Sideloadly:**
   - Sélectionnez votre iPhone
   - Entrez votre **Apple ID** et **mot de passe**
   - Cliquez sur **"IPA File"** → Sélectionnez votre `.ipa`
   - Cliquez sur **"Start"**

5. **Autoriser sur iPhone:**
   - Sur iPhone, allez dans **Réglages → Général → Gestion des appareils**
   - Faites confiance à votre Apple ID

6. **Faire confiance à l'app:**
   - Réglages → Général → Gestion des appareils
   - Sélectionnez "ARCode Clone"
   - Appuyez sur **"Faire confiance"**

---

## 🎯 Méthode 3: Xcode (Mac uniquement)

**Avantages:**
- ✅ Pas de limite de 7 jours
- ✅ Installation permanente
- ✅ Debug possible

**Limitations:**
- ⚠️ Nécessite un Mac
- ⚠️ Nécessite Xcode installé

### Étapes

1. **Ouvrir Xcode** sur Mac

2. **Connecter iPhone** via USB

3. **Faire confiance à l'ordinateur** sur iPhone

4. **Dans Xcode:**
   - Window → Devices and Simulators
   - Sélectionnez votre iPhone
   - Cliquez sur **"+"** → Installez l'IPA

5. **Sur iPhone:**
   - Réglages → Général → Gestion des appareils
   - Faites confiance à l'app

---

## 🎯 Méthode 4: TestFlight (Nécessite compte développeur)

**Avantages:**
- ✅ Installation facile
- ✅ Pas de limite de 7 jours
- ✅ Distribution aux testeurs

**Limitations:**
- ⚠️ Nécessite compte développeur Apple ($99/an)
- ⚠️ Nécessite upload sur App Store Connect

### Étapes

1. **Compiler l'app** avec certificat développeur
2. **Uploader sur App Store Connect** via Xcode ou Transporter
3. **Ajouter à TestFlight**
4. **Installer TestFlight** sur iPhone
5. **Accepter l'invitation** de test
6. **Installer l'app** depuis TestFlight

---

## 🎯 Méthode 5: 3uTools (Windows - Alternative)

**Avantages:**
- ✅ Gratuit
- ✅ Interface en chinois/anglais
- ✅ Outils supplémentaires

### Étapes

1. **Télécharger 3uTools:**
   - Allez sur: https://www.3u.com
   - Téléchargez et installez

2. **Connecter iPhone** via USB

3. **Installer IPA:**
   - Onglet "Apps" → "Install"
   - Sélectionnez votre `.ipa`
   - Cliquez sur "Install"

---

## ⚠️ Problèmes Courants

### Erreur: "Untrusted Developer"

**Solution:**
1. Réglages → Général → Gestion des appareils
2. Sélectionnez votre Apple ID / Développeur
3. Appuyez sur "Faire confiance"

### Erreur: "App Expired"

**Solution:**
- L'app expire après 7 jours (méthode gratuite)
- Renouvelez via AltStore ou Sideloadly
- Ou installez à nouveau

### Erreur: "Could not connect to AltServer"

**Solution:**
- Vérifiez que AltServer est lancé
- Vérifiez que iTunes et iCloud sont installés
- Vérifiez la connexion USB
- Redémarrez AltServer

### Erreur: "Provisioning profile not found"

**Solution:**
- L'IPA doit être signé correctement
- Utilisez un compte développeur ou méthode ad-hoc
- Vérifiez que le bundle ID correspond

---

## 📱 Tester l'App

Une fois installée:

1. **Ouvrir l'app** sur iPhone
2. **Autoriser les permissions** (caméra, photos, etc.)
3. **Tester les fonctionnalités AR**
4. **Vérifier la connexion** au backend:
   - Ouvrir l'app
   - Vérifier que les appels API fonctionnent
   - Vérifier les logs dans Xcode (si connecté)

---

## 🔄 Mettre à Jour l'App

### Via AltStore/Sideloadly:
1. Télécharger la nouvelle version IPA
2. Installer par-dessus l'ancienne version
3. Ou supprimer l'ancienne et réinstaller

### Via GitHub Actions:
1. Télécharger le nouvel artifact IPA
2. Installer via votre méthode préférée

---

## 💡 Astuces

### Installation Automatique
- Configurez AltStore pour renouveler automatiquement
- Utilisez un script pour automatiser l'installation

### Backup
- Sauvegardez votre IPA avant installation
- Gardez une copie des anciennes versions

### Debug
- Connectez iPhone à Xcode pour voir les logs
- Utilisez Instruments pour profiling

---

## 📞 Besoin d'Aide?

Si vous rencontrez des problèmes:
1. Vérifiez les prérequis
2. Consultez les logs d'erreur
3. Essayez une autre méthode
4. Vérifiez que l'iPhone est compatible (iOS 16+)

**Bon test! 🚀**

