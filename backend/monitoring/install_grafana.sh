#!/bin/bash
# Grafana Installation Script for Oracle Cloud Ubuntu 22.04

set -e

echo "Installing Grafana..."

# Add Grafana repository
sudo apt-get update
sudo apt-get install -y software-properties-common wget

wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

# Install Grafana
sudo apt-get update
sudo apt-get install -y grafana

# Enable and start Grafana service
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# Configure Grafana to listen on all interfaces (for reverse proxy)
sudo sed -i "s/;http_addr = localhost/http_addr = 0.0.0.0/" /etc/grafana/grafana.ini

# Restart Grafana
sudo systemctl restart grafana-server

echo "Grafana installed successfully!"
echo "Default credentials: admin/admin (change on first login)"
echo "Access Grafana at: http://your-server-ip:3000"







