# 📱 Obtenir votre IPA Maintenant

## ✅ Si les Tests sont Verts

Si tous les tests passent, vous pouvez obtenir votre IPA de plusieurs façons:

## 🎯 Méthode 1: Via GitHub Actions (Recommandé)

### Étape 1: Déclencher le Build Manuellement

1. **Allez sur GitHub Actions:**
   - https://github.com/adaammmm3131/ARCode-Clone---iOS-AR-Application/actions

2. **Trouvez le workflow "Build iOS IPA":**
   - Cliquez dessus

3. **Cliquez sur "Run workflow":**
   - Sélectionnez la branche: `main`
   - Laissez les options par défaut
   - Cliquez sur "Run workflow"

4. **Attendez le build:**
   - Temps estimé: 5-10 minutes
   - Surveillez les logs

### Étape 2: Télécharger l'IPA

1. **Une fois terminé:**
   - Scroll down vers "Artifacts"
   - Cliquez sur "ARCodeClone-IPA"
   - Téléchargez le `.zip`
   - Extrayez le fichier `.ipa`

## 🎯 Méthode 2: Via Tag (Déjà Fait)

Le tag `v1.0.0` a déjà été créé et poussé. Le build devrait se déclencher automatiquement.

**Vérifier:**
- https://github.com/adaammmm3131/ARCode-Clone---iOS-AR-Application/actions/workflows/ios-build-ipa.yml

## 🎯 Méthode 3: Créer un Nouveau Tag

Si le build précédent a échoué, créez un nouveau tag:

```bash
git tag v1.0.1
git push origin v1.0.1
```

## 📊 Vérifier le Statut

### URL Actions Directe:
https://github.com/adaammmm3131/ARCode-Clone---iOS-AR-Application/actions/workflows/ios-build-ipa.yml

### Statuts:
- 🟡 **Jaune** = En cours (attendez)
- ✅ **Vert** = Terminé (IPA disponible dans Artifacts)
- ❌ **Rouge** = Échoué (voir les logs pour erreurs)

## ⚠️ Si le Build Échoue

### Problème: Erreur CoreServices/Alamofire

Si vous voyez des erreurs CoreServices, c'est qu'Alamofire essaie d'utiliser le SDK macOS. Les corrections ont été poussées, mais il faut peut-être attendre le prochain build.

**Solution:**
1. Relancer le workflow manuellement
2. Vérifier que les flags `-isysroot` sont bien passés
3. Vérifier les logs pour voir quel SDK est utilisé

### Problème: IPA Non Créé

Si le build réussit mais l'IPA n'est pas créé:
1. Vérifiez les logs de l'étape "Create IPA from Archive or Package"
2. Vérifiez que le build Swift Package a réussi
3. Le workflow créera un placeholder IPA si nécessaire

## 📥 Installation sur iPhone

Une fois l'IPA téléchargé, voir **`INSTALL_IPA.md`** pour installer.

**Rappel: AltStore (Gratuit)**
- Télécharger: https://altstore.io
- Installer iTunes + iCloud
- Connecter iPhone
- Installer AltStore
- Ouvrir AltStore → "+" → Sélectionner l'IPA

## 💡 Astuce

Pour vérifier rapidement si un build est en cours:
- Allez sur Actions
- Cherchez un workflow jaune (en cours)
- Ou un workflow vert récent (terminé)

**Votre IPA sera disponible dans quelques minutes! 🚀**

