# ARCode Backend - PowerShell Startup Script
# Script pour lancer le serveur Flask

Write-Host "🚀 Démarrage du serveur ARCode Backend..." -ForegroundColor Green

# Aller dans le dossier backend
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# Vérifier si Python est installé
try {
    $pythonVersion = python --version
    Write-Host "✅ Python détecté: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python non trouvé! Veuillez installer Python 3.9+" -ForegroundColor Red
    exit 1
}

# Vérifier si le fichier existe
if (-Not (Test-Path "api/app_simple.py")) {
    Write-Host "❌ Fichier api/app_simple.py non trouvé!" -ForegroundColor Red
    exit 1
}

# Essayer le port 8080, sinon 8081
$port = 8080
$portInUse = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue

if ($portInUse) {
    Write-Host "⚠️  Port 8080 déjà utilisé, utilisation du port 8081" -ForegroundColor Yellow
    $port = 8081
}

# Définir les variables d'environnement
$env:FLASK_APP = "api/app_simple.py"
$env:FLASK_DEBUG = "True"
$env:PORT = $port

Write-Host "📡 Démarrage du serveur sur http://localhost:$port" -ForegroundColor Cyan
Write-Host "📋 Endpoints disponibles:" -ForegroundColor Cyan
Write-Host "   - Health: http://localhost:$port/health" -ForegroundColor White
Write-Host "   - Test: http://localhost:$port/api/v1/test" -ForegroundColor White
Write-Host ""
Write-Host "Appuyez sur Ctrl+C pour arrêter le serveur" -ForegroundColor Yellow
Write-Host ""

# Lancer le serveur
python api/app_simple.py


