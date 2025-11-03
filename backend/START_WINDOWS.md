# Guide de Démarrage - ARCode Backend (Windows)

Guide complet pour lancer le backend ARCode sur Windows.

## 📋 Prérequis

### 1. Python 3.9+
```powershell
# Vérifier Python installé
python --version
# ou
python3 --version

# Si non installé, télécharger depuis: https://www.python.org/downloads/
```

### 2. PostgreSQL (optionnel pour développement local)
- Télécharger: https://www.postgresql.org/download/windows/
- Ou utiliser Docker: `docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:15`

### 3. Redis (optionnel pour développement local)
- Télécharger: https://github.com/microsoftarchive/redis/releases
- Ou utiliser Docker: `docker run -d -p 6379:6379 redis:7`

## 🚀 Installation Rapide

### Étape 1: Cloner/Naviguer vers le projet
```powershell
cd "C:\Users\asus\OneDrive\Bureau\prompt inchalah"
cd backend
```

### Étape 2: Créer environnement virtuel Python
```powershell
# Créer environnement virtuel
python -m venv venv

# Activer l'environnement virtuel
.\venv\Scripts\Activate.ps1

# Si erreur de politique d'exécution, exécuter:
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Étape 3: Installer les dépendances
```powershell
# Installer les dépendances principales
pip install -r requirements.txt

# Installer les dépendances des modules (optionnel)
pip install -r queue/requirements.txt
pip install -r ai/requirements.txt
pip install -r analytics/requirements.txt
# etc.
```

### Étape 4: Configurer les variables d'environnement
```powershell
# Copier le fichier .env.example
copy .env.example .env

# Éditer .env avec vos valeurs
notepad .env
```

**Configuration minimale pour démarrer:**
```env
FLASK_SECRET_KEY=dev-secret-key-change-in-production
FLASK_DEBUG=True
PORT=8080

# Database (optionnel - peut être désactivé pour test)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=arcode_db
DB_USER=postgres
DB_PASSWORD=postgres

# Redis (optionnel - peut être désactivé pour test)
REDIS_HOST=localhost
REDIS_PORT=6379
```

### Étape 5: Démarrer le serveur
```powershell
# Depuis le dossier backend/
python api/app.py

# Ou avec Flask CLI
set FLASK_APP=api/app.py
flask run --host=0.0.0.0 --port=8080
```

Le serveur devrait démarrer sur: **http://localhost:8080**

## ✅ Vérification

### Tester l'API
```powershell
# Health check
curl http://localhost:8080/health

# Ou avec PowerShell
Invoke-WebRequest -Uri http://localhost:8080/health
```

### Endpoints disponibles
- `GET /health` - Health check
- `GET /health/live` - Liveness probe
- `GET /health/ready` - Readiness probe
- `GET /api/v1/cta-links/{ar_code_id}` - CTA Links
- `GET /api/v1/workspaces` - Workspaces
- etc.

## 🔧 Configuration Avancée

### Mode Développement (sans base de données)
Pour tester l'API sans PostgreSQL/Redis:

```python
# Modifier api/health_check.py pour rendre DB/Redis optionnels
# L'API fonctionnera avec des warnings si services absents
```

### Variables d'environnement importantes
- `FLASK_DEBUG=True` - Mode debug (rechargement auto)
- `PORT=8080` - Port du serveur
- `DB_HOST`, `DB_PORT`, etc. - Configuration base de données
- `REDIS_HOST`, `REDIS_PORT` - Configuration Redis

## 🐛 Dépannage

### Erreur: "No module named 'flask'"
```powershell
# Vérifier que l'environnement virtuel est activé
# Réinstaller les dépendances
pip install -r requirements.txt
```

### Erreur: "Cannot connect to database"
- Vérifier que PostgreSQL est démarré
- Vérifier les credentials dans `.env`
- Ou désactiver les checks DB pour test

### Erreur: "Port already in use"
```powershell
# Changer le port dans .env
PORT=8081
```

### Erreur: "Redis connection failed"
- Redis est optionnel pour développement
- L'API fonctionnera avec des warnings

## 📝 Scripts Utiles

### Script de démarrage rapide (start.bat)
```batch
@echo off
cd /d %~dp0
call venv\Scripts\activate.bat
python api/app.py
pause
```

### Script avec environnement (start_env.bat)
```batch
@echo off
cd /d %~dp0
call venv\Scripts\activate.bat
set FLASK_APP=api/app.py
set FLASK_DEBUG=True
set PORT=8080
python api/app.py
pause
```

## 🔗 Documentation

- [API Documentation](../docs/API_DOCUMENTATION.md)
- [Architecture](../docs/ARCHITECTURE.md)
- [Developer Guide](../docs/DEVELOPER_GUIDE.md)

## 📞 Support

Pour problèmes:
- Vérifier les logs dans la console
- Vérifier les variables d'environnement
- Consulter la documentation


