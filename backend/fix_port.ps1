# Script pour libérer le port 8080 ou utiliser un autre port

Write-Host "🔧 Correction du problème de port..." -ForegroundColor Green
Write-Host ""

$port = 8080

# Vérifier si le port est utilisé
$portInUse = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue

if ($portInUse) {
    Write-Host "⚠️  Port $port déjà utilisé par PID: $($portInUse.OwningProcess)" -ForegroundColor Yellow
    
    # Essayer le port 8081
    $newPort = 8081
    $port8081InUse = Get-NetTCPConnection -LocalPort $newPort -ErrorAction SilentlyContinue
    
    if (-not $port8081InUse) {
        Write-Host "✅ Port $newPort disponible" -ForegroundColor Green
        Write-Host ""
        Write-Host "🚀 Démarrage du serveur sur le port $newPort..." -ForegroundColor Cyan
        Write-Host ""
        
        $env:PORT = $newPort
        python api/app_simple.py
    } else {
        Write-Host "⚠️  Port $newPort aussi utilisé" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Options:" -ForegroundColor Yellow
        Write-Host "1. Tuer le processus utilisant le port 8080:" -ForegroundColor White
        Write-Host "   Stop-Process -Id $($portInUse.OwningProcess) -Force" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "2. Utiliser un autre port:" -ForegroundColor White
        Write-Host "   \$env:PORT = 8082; python api/app_simple.py" -ForegroundColor Cyan
    }
} else {
    Write-Host "✅ Port $port disponible" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Démarrage du serveur sur le port $port..." -ForegroundColor Cyan
    Write-Host ""
    
    python api/app_simple.py
}

