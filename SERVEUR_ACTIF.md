# ✅ Serveur ARCode Backend - ACTIF

## 🎉 Statut: Serveur Lancé!

Le serveur Flask ARCode est maintenant en cours d'exécution.

## 📡 Informations du Serveur

- **URL**: http://localhost:8081
- **Status**: ✅ ACTIF
- **Mode**: Debug (app_simple.py)

## 🔗 Endpoints Disponibles

### 1. Health Check
```
GET http://localhost:8081/health
```
Réponse:
```json
{
  "status": "ok",
  "message": "ARCode API is running",
  "version": "1.0.0"
}
```

### 2. Test Endpoint
```
GET http://localhost:8081/api/v1/test
```
Réponse:
```json
{
  "message": "API is working!",
  "platform": "Windows",
  "python_version": "..."
}
```

### 3. Root
```
GET http://localhost:8081/
```
Réponse: Informations sur l'API

## 🧪 Tester l'API

### Avec PowerShell
```powershell
# Health check
Invoke-WebRequest -Uri http://localhost:8081/health

# Test endpoint
Invoke-WebRequest -Uri http://localhost:8081/api/v1/test
```

### Avec Navigateur
- Ouvrir: http://localhost:8081/health
- Ouvrir: http://localhost:8081/api/v1/test

### Avec curl (si installé)
```bash
curl http://localhost:8081/health
curl http://localhost:8081/api/v1/test
```

## 📝 Notes

- Le serveur tourne en mode **simple** (sans base de données)
- Parfait pour tester l'API et le développement
- Pour fonctionnalités complètes, installer PostgreSQL/Redis

## 🛑 Arrêter le Serveur

Appuyez sur **Ctrl+C** dans le terminal où le serveur tourne.

## 🔄 Redémarrer

```powershell
cd backend
$env:PORT=8081
python api/app_simple.py
```

---

**Serveur opérationnel! Vous pouvez maintenant tester l'API.** 🚀


