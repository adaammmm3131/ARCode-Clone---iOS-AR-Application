# 🚀 Comment Lancer le Serveur ARCode

## Méthode 1: PowerShell Script (Recommandé)

```powershell
cd backend
.\start_server.ps1
```

## Méthode 2: Commande Directe

```powershell
cd backend
python api/app_simple.py
```

## Méthode 3: Port Personnalisé

Si le port 8080 est occupé:

```powershell
cd backend
$env:PORT=8081
python api/app_simple.py
```

## Vérification

Une fois le serveur démarré, ouvrez votre navigateur:

- **Health Check**: http://localhost:8080/health
- **Test**: http://localhost:8080/api/v1/test

Ou avec PowerShell:

```powershell
Invoke-WebRequest -Uri http://localhost:8080/health
Invoke-WebRequest -Uri http://localhost:8080/api/v1/test
```

## Dépannage

### Port déjà utilisé
```powershell
# Voir quel processus utilise le port
Get-NetTCPConnection -LocalPort 8080 | Select-Object OwningProcess

# Arrêter le processus (remplacer PID par le numéro)
Stop-Process -Id PID

# Ou utiliser un autre port
$env:PORT=8081
python api/app_simple.py
```

### Erreur de permissions
```powershell
# Lancer PowerShell en tant qu'administrateur
# Ou utiliser un port > 1024 (8080, 8081, etc.)
```

## Statut

✅ **Serveur lancé sur**: http://localhost:8081

---

**Le serveur est maintenant opérationnel!** 🎉


