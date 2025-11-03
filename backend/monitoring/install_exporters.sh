#!/bin/bash
# Install Prometheus Exporters
# Node, PostgreSQL, Redis, Nginx

set -e

echo "Installing Prometheus Exporters..."

# Node Exporter (system metrics)
echo "Installing Node Exporter..."
NODE_VERSION="1.7.0"
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_VERSION}/node_exporter-${NODE_VERSION}.linux-arm64.tar.gz
tar xvf node_exporter-${NODE_VERSION}.linux-arm64.tar.gz
sudo cp node_exporter-${NODE_VERSION}.linux-arm64/node_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/node_exporter

# Create systemd service for Node Exporter
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nobody
Group=nogroup
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# PostgreSQL Exporter
echo "Installing PostgreSQL Exporter..."
sudo apt-get install -y postgresql-client

POSTGRES_VERSION="0.15.0"
cd /tmp
wget https://github.com/prometheus-community/postgres_exporter/releases/download/v${POSTGRES_VERSION}/postgres_exporter-${POSTGRES_VERSION}.linux-arm64.tar.gz
tar xvf postgres_exporter-${POSTGRES_VERSION}.linux-arm64.tar.gz
sudo cp postgres_exporter-${POSTGRES_VERSION}.linux-arm64/postgres_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/postgres_exporter

# PostgreSQL exporter needs connection string
sudo tee /etc/postgres_exporter.env > /dev/null <<EOF
DATA_SOURCE_NAME=postgresql://arcode_user:${DB_PASSWORD}@localhost:5432/arcode_db?sslmode=disable
EOF

# Create systemd service for PostgreSQL Exporter
sudo tee /etc/systemd/system/postgres_exporter.service > /dev/null <<EOF
[Unit]
Description=PostgreSQL Exporter
After=network.target postgresql.service

[Service]
User=nobody
Group=nogroup
EnvironmentFile=/etc/postgres_exporter.env
Type=simple
ExecStart=/usr/local/bin/postgres_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable postgres_exporter
sudo systemctl start postgres_exporter

# Redis Exporter
echo "Installing Redis Exporter..."
REDIS_VERSION="1.56.0"
cd /tmp
wget https://github.com/oliver006/redis_exporter/releases/download/v${REDIS_VERSION}/redis_exporter-v${REDIS_VERSION}.linux-arm64.tar.gz
tar xvf redis_exporter-v${REDIS_VERSION}.linux-arm64.tar.gz
sudo cp redis_exporter-v${REDIS_VERSION}.linux-arm64/redis_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/redis_exporter

# Create systemd service for Redis Exporter
sudo tee /etc/systemd/system/redis_exporter.service > /dev/null <<EOF
[Unit]
Description=Redis Exporter
After=network.target redis.service

[Service]
User=nobody
Group=nogroup
Type=simple
ExecStart=/usr/local/bin/redis_exporter --redis.addr=redis://localhost:6379

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable redis_exporter
sudo systemctl start redis_exporter

# Nginx Exporter (requires nginx-module-vts)
echo "Installing Nginx Exporter..."
NGINX_VERSION="0.11.1"
cd /tmp
wget https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v${NGINX_VERSION}/nginx-prometheus-exporter_${NGINX_VERSION}_linux_arm64.tar.gz
tar xvf nginx-prometheus-exporter_${NGINX_VERSION}_linux_arm64.tar.gz
sudo cp nginx-prometheus-exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/nginx-prometheus-exporter

# Create systemd service for Nginx Exporter
sudo tee /etc/systemd/system/nginx_exporter.service > /dev/null <<EOF
[Unit]
Description=Nginx Exporter
After=network.target nginx.service

[Service]
User=nobody
Group=nogroup
Type=simple
ExecStart=/usr/local/bin/nginx-prometheus-exporter -nginx.scrape-uri=http://localhost:8080/stub_status

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable nginx_exporter
sudo systemctl start nginx_exporter

echo "All exporters installed successfully!"







