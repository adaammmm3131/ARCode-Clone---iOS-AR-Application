# 📤 Guide: Pousser le Projet sur GitHub

## 🎯 Votre GitHub: `adaammmm3131`

## 📋 Étapes pour Pousser le Projet

### Étape 1: Créer le Dépôt sur GitHub

1. **Aller sur GitHub:**
   - Ouvrez https://github.com/adaammmm3131
   - Cliquez sur le bouton **"+"** en haut à droite
   - Sélectionnez **"New repository"**

2. **Configurer le dépôt:**
   - **Repository name:** `prompt-inchalah` (ou un autre nom)
   - **Description:** "ARCode Clone - iOS AR Application"
   - **Visibility:** Public ou Private (votre choix)
   - **⚠️ NE PAS** cocher "Add a README file"
   - **⚠️ NE PAS** cocher "Add .gitignore"
   - **⚠️ NE PAS** cocher "Choose a license"
   - Cliquez sur **"Create repository"**

### Étape 2: Pousser le Code

Une fois le dépôt créé, exécutez ces commandes:

```powershell
# Si le remote existe déjà (mauvais nom), le supprimer
git remote remove origin

# Ajouter le bon remote (remplacez NOM_REPO par le nom exact)
git remote add origin https://github.com/adaammmm3131/NOM_REPO.git

# Vérifier
git remote -v

# Pousser le code
git push -u origin main
```

**OU** si vous avez déjà créé le dépôt avec le nom `prompt-inchalah`:

```powershell
git remote set-url origin https://github.com/adaammmm3131/prompt-inchalah.git
git push -u origin main
```

---

## 🔐 Authentification GitHub

### Option 1: Personal Access Token (Recommandé)

1. **Créer un token:**
   - GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Cliquez sur **"Generate new token"**
   - Nom: "ARCode Clone"
   - Permissions: **repo** (toutes les cases)
   - Cliquez sur **"Generate token"**
   - **⚠️ Copiez le token** (il ne sera plus affiché)

2. **Utiliser le token:**
   ```powershell
   # Quand git demande le mot de passe, utilisez le token
   git push -u origin main
   # Username: adaammmm3131
   # Password: [collez votre token ici]
   ```

### Option 2: GitHub CLI

```powershell
# Installer GitHub CLI
winget install GitHub.cli

# S'authentifier
gh auth login

# Pousser le code
git push -u origin main
```

### Option 3: SSH (Avancé)

1. **Générer une clé SSH:**
   ```powershell
   ssh-keygen -t ed25519 -C "adaammmm3131@github"
   ```

2. **Ajouter la clé à GitHub:**
   - GitHub → Settings → SSH and GPG keys → New SSH key
   - Copiez le contenu de `~/.ssh/id_ed25519.pub`

3. **Changer le remote:**
   ```powershell
   git remote set-url origin git@github.com:adaammmm3131/NOM_REPO.git
   git push -u origin main
   ```

---

## ✅ Vérification

Après avoir poussé:

1. **Aller sur GitHub:**
   - https://github.com/adaammmm3131/NOM_REPO

2. **Vérifier:**
   - ✅ Les fichiers sont présents
   - ✅ Les workflows GitHub Actions sont dans `.github/workflows/`
   - ✅ Le README est présent

3. **Vérifier les Actions:**
   - Onglet **"Actions"** sur GitHub
   - Les workflows devraient s'exécuter automatiquement

---

## 🚀 Prochaines Étapes

Une fois le code poussé:

1. **Vérifier les Actions:**
   - GitHub → Actions
   - Les tests iOS devraient s'exécuter automatiquement

2. **Builder l'IPA:**
   - Créer un tag: `git tag v1.0.0`
   - Pousser le tag: `git push origin v1.0.0`
   - Le workflow buildera automatiquement l'IPA

3. **Télécharger l'IPA:**
   - Actions → Build iOS IPA
   - Télécharger l'artifact "ARCodeClone-IPA"

4. **Installer sur iPhone:**
   - Voir `INSTALL_IPA.md`

---

## 🐛 Problèmes Courants

### "Repository not found"
- Vérifiez que le dépôt existe sur GitHub
- Vérifiez le nom exact du dépôt
- Vérifiez que vous avez les permissions

### "Authentication failed"
- Utilisez un Personal Access Token au lieu du mot de passe
- Vérifiez que le token a les permissions "repo"

### "Permission denied"
- Vérifiez votre authentification GitHub
- Vérifiez que vous êtes connecté à GitHub

---

## 💡 Astuce

Si vous voulez créer le dépôt directement depuis la ligne de commande:

```powershell
# Installer GitHub CLI
winget install GitHub.cli

# S'authentifier
gh auth login

# Créer le dépôt
gh repo create prompt-inchalah --public --source=. --remote=origin --push
```

---

**Bon push! 🚀**

