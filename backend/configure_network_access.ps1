# Script pour configurer l'accès réseau au backend depuis iPhone
# Exécuter en tant qu'Administrateur

Write-Host "🔧 Configuration de l'accès réseau pour ARCode Backend" -ForegroundColor Green
Write-Host ""

# Obtenir l'IP locale
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254.*"}).IPAddress | Select-Object -First 1

Write-Host "📍 Votre adresse IP: $ipAddress" -ForegroundColor Cyan
Write-Host ""

# Port du serveur
$port = 8080

# Vérifier si la règle existe déjà
$existingRule = Get-NetFirewallRule -DisplayName "ARCode Backend" -ErrorAction SilentlyContinue

if ($existingRule) {
    Write-Host "✅ Règle firewall déjà existante" -ForegroundColor Green
} else {
    Write-Host "🔐 Création de la règle firewall..." -ForegroundColor Yellow
    
    # Créer la règle firewall (nécessite droits admin)
    try {
        New-NetFirewallRule -DisplayName "ARCode Backend" `
            -Direction Inbound `
            -LocalPort $port `
            -Protocol TCP `
            -Action Allow `
            -Profile Private,Public | Out-Null
        
        Write-Host "✅ Règle firewall créée avec succès!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Erreur lors de la création de la règle firewall" -ForegroundColor Red
        Write-Host "   Assurez-vous d'exécuter PowerShell en tant qu'Administrateur" -ForegroundColor Yellow
        Write-Host "   Erreur: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📱 Informations pour votre iPhone:" -ForegroundColor Cyan
Write-Host "   URL Backend: http://$ipAddress:$port" -ForegroundColor White
Write-Host "   Health Check: http://$ipAddress:$port/health" -ForegroundColor White
Write-Host ""
Write-Host "✅ Configuration terminée!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Pour tester depuis votre iPhone:" -ForegroundColor Yellow
Write-Host "   1. Connectez votre iPhone au même WiFi que ce PC" -ForegroundColor White
Write-Host "   2. Ouvrez Safari sur iPhone" -ForegroundColor White
Write-Host "   3. Allez à: http://$ipAddress:$port/health" -ForegroundColor White
Write-Host ""

