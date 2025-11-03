# 🚀 Démarrage Rapide - ARCode Backend (Windows)

## ✅ Étape 1: Installation des Dépendances

```powershell
# Installer les dépendances principales (sans PostgreSQL/Redis pour le moment)
pip install Flask Flask-CORS Flask-Limiter requests python-dotenv PyJWT python-dateutil
```

## ✅ Étape 2: Démarrer le Serveur Simple

```powershell
# Depuis le dossier backend/
python api/app_simple.py
```

Le serveur démarre sur **http://localhost:8080**

## ✅ Étape 3: Tester l'API

### Avec PowerShell
```powershell
# Health check
Invoke-WebRequest -Uri http://localhost:8080/health | Select-Object -Expand Content

# Test endpoint
Invoke-WebRequest -Uri http://localhost:8080/api/v1/test | Select-Object -Expand Content
```

### Avec curl (si installé)
```bash
curl http://localhost:8080/health
curl http://localhost:8080/api/v1/test
```

### Dans un navigateur
- Ouvrir: http://localhost:8080/health
- Ouvrir: http://localhost:8080/api/v1/test

## 📋 Endpoints Disponibles

### Version Simple (sans DB)
- `GET /health` - Health check
- `GET /health/live` - Liveness probe
- `GET /health/ready` - Readiness probe
- `GET /api/v1/test` - Test endpoint
- `GET /` - Root endpoint avec info

## 🔧 Configuration Avancée

### Pour installer PostgreSQL/Redis (optionnel)

#### PostgreSQL
1. Télécharger: https://www.postgresql.org/download/windows/
2. Ou utiliser Docker: `docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:15`

#### Redis
1. Télécharger: https://github.com/microsoftarchive/redis/releases
2. Ou utiliser Docker: `docker run -d -p 6379:6379 redis:7`

### Pour psycopg2-binary (si PostgreSQL installé)
```powershell
# Installer Visual C++ Build Tools d'abord
# Télécharger: https://visualstudio.microsoft.com/visual-cpp-build-tools/

# Puis installer psycopg2
pip install psycopg2-binary
```

### Pour utiliser l'API complète
```powershell
# Une fois PostgreSQL/Redis installés et configurés
python api/app.py
```

## 📝 Variables d'Environnement

Créer un fichier `.env` dans `backend/`:

```env
FLASK_SECRET_KEY=dev-secret-key
FLASK_DEBUG=True
PORT=8080
```

## 🐛 Dépannage

### Port déjà utilisé
```powershell
# Changer le port
$env:PORT=8081
python api/app_simple.py
```

### Erreur de module
```powershell
# Réinstaller les dépendances
pip install Flask Flask-CORS Flask-Limiter requests python-dotenv PyJWT python-dateutil
```

### Serveur ne démarre pas
- Vérifier que Python est installé: `python --version`
- Vérifier que vous êtes dans le dossier `backend/`
- Vérifier les logs d'erreur dans la console

## 📚 Documentation Complète

Voir [START_WINDOWS.md](START_WINDOWS.md) pour le guide complet.

## ✅ Statut

✅ **Serveur Simple**: Fonctionnel sans DB
⏳ **Serveur Complet**: Nécessite PostgreSQL/Redis

---

**Le serveur simple est maintenant opérationnel!** 🎉


