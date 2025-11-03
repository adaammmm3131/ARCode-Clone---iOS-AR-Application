#!/bin/bash
# Script de configuration Nginx pour ARCode API Gateway

set -e

echo "🚀 Configuration Nginx pour ARCode API Gateway..."

# Vérifier si Nginx est installé
if ! command -v nginx &> /dev/null; then
    echo "📦 Installation de Nginx..."
    sudo apt update
    sudo apt install -y nginx
fi

# Créer dossiers nécessaires
echo "📁 Création des dossiers..."
sudo mkdir -p /var/www/static
sudo mkdir -p /var/log/nginx
sudo chown -R www-data:www-data /var/www/static

# Copier configuration
echo "⚙️  Copie de la configuration..."
sudo cp nginx.conf /etc/nginx/sites-available/ar-code-api
sudo ln -sf /etc/nginx/sites-available/ar-code-api /etc/nginx/sites-enabled/

# Supprimer configuration par défaut
sudo rm -f /etc/nginx/sites-enabled/default

# Tester configuration
echo "🧪 Test de la configuration..."
sudo nginx -t

# Redémarrer Nginx
echo "🔄 Redémarrage de Nginx..."
sudo systemctl restart nginx
sudo systemctl enable nginx

# Vérifier status
sudo systemctl status nginx --no-pager

echo "✅ Nginx configuré avec succès!"
echo "📝 Configuration: /etc/nginx/sites-available/ar-code-api"
echo "📊 Logs: /var/log/nginx/api_*.log"









