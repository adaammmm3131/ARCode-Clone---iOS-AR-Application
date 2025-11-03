# Phase 18.1 - Oracle Cloud Free Tier Setup

Guide complet pour configurer l'infrastructure Oracle Cloud Free Tier.

## Prérequis

1. Créer un compte Oracle Cloud Free Tier
2. Accès à la console Oracle Cloud

## Étape 1: Créer Instance VM ARM

### 1.1. Naviguer vers Compute

1. Se connecter à [Oracle Cloud Console](https://cloud.oracle.com/)
2. Menu → Compute → Instances
3. Cliquer "Create Instance"

### 1.2. Configuration Instance

**Nom:** `ar-code-backend`

**Image:**
- Image: Canonical Ubuntu 22.04
- Architecture: ARM64 (pour Free Tier)

**Shape:**
- Shape: VM.Standard.A1.Flex
- OCPUs: 4
- Memory (GB): 24
- Boot Volume: 100 GB

**Réseau:**
- Virtual Cloud Network: Créer nouveau VCN
- Subnet: Public subnet
- Assign public IP: Oui
- Security List: Créer avec règles suivantes:
  - SSH (port 22) depuis 0.0.0.0/0
  - HTTP (port 80) depuis 0.0.0.0/0
  - HTTPS (port 443) depuis 0.0.0.0/0

**SSH Keys:**
- Upload public key ou générer nouvelle paire

### 1.3. Créer Instance

Cliquer "Create" et attendre provisionnement (~5 minutes)

## Étape 2: Configurer Firewall

### 2.1. Security List Rules

Dans VCN → Security Lists → Default Security List:

**Inbound Rules:**
```
Type    Source              Destination Port
SSH     0.0.0.0/0          22
HTTP    0.0.0.0/0          80
HTTPS   0.0.0.0.0/0        443
Custom  Cloudflare IPs     8080 (pour API backend)
```

### 2.2. Firewall Ubuntu (UFW)

Une fois connecté en SSH:

```bash
# Activer firewall
sudo ufw enable

# Autoriser SSH
sudo ufw allow 22/tcp

# Autoriser HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Autoriser port API (si nécessaire)
sudo ufw allow 8080/tcp

# Vérifier status
sudo ufw status
```

## Étape 3: Setup SSH Keys

### 3.1. Générer clé SSH locale

```bash
ssh-keygen -t ed25519 -C "ar-code-backend" -f ~/.ssh/ar-code-oracle
```

### 3.2. Upload clé publique

Dans Oracle Console → Instance → Console Connection → Upload SSH Key

Ou via CLI:

```bash
# Copier clé publique
cat ~/.ssh/ar-code-oracle.pub

# Coller dans Oracle Console lors création instance
```

### 3.3. Se connecter

```bash
ssh -i ~/.ssh/ar-code-oracle ubuntu@<IP_PUBLIC_INSTANCE>
```

## Étape 4: Configuration Ubuntu 22.04

### 4.1. Mise à jour système

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release
```

### 4.2. Créer utilisateur app

```bash
# Créer utilisateur non-root pour application
sudo adduser --disabled-password --gecos "" appuser
sudo usermod -aG sudo appuser
sudo su - appuser
```

### 4.3. Configuration locale

```bash
# Timezone
sudo timedatectl set-timezone UTC

# Hostname
sudo hostnamectl set-hostname ar-code-backend

# Locale
sudo locale-gen en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

## Étape 5: Configurer Domain DNS

### 5.1. Obtenir IP publique

```bash
curl ifconfig.me
# Noter l'IP publique
```

### 5.2. Configurer DNS (Cloudflare)

1. Se connecter à Cloudflare Dashboard
2. Sélectionner domaine `ar-code.com`
3. DNS → Records → Add record

**Type A Record:**
```
Type: A
Name: @ (ou api)
IPv4: <IP_PUBLIQUE_INSTANCE>
Proxy: DNS only (désactiver proxy pour IP directe)
TTL: Auto
```

**Type A Record pour API:**
```
Type: A
Name: api
IPv4: <IP_PUBLIQUE_INSTANCE>
Proxy: Proxied (activer proxy Cloudflare)
TTL: Auto
```

### 5.3. Vérifier DNS

```bash
# Vérifier résolution DNS
nslookup api.ar-code.com
dig api.ar-code.com
```

## Étape 6: Configuration sécurité supplémentaire

### 6.1. Fail2ban (protection brute force)

```bash
sudo apt install fail2ban -y

# Configuration
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Éditer /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local

# Démarrer
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 6.2. Auto-updates sécurité

```bash
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

## Étape 7: Monitoring basique

### 7.1. Installer monitoring tools

```bash
sudo apt install htop iotop nethogs -y
```

### 7.2. Vérifier ressources

```bash
# CPU, RAM, Disk
htop
df -h
free -h
```

## Checklist

- [ ] Instance VM ARM créée (4 CPUs, 24GB RAM)
- [ ] Firewall configuré (ports 22, 80, 443)
- [ ] SSH keys configurées
- [ ] Ubuntu 22.04 mis à jour
- [ ] Utilisateur app créé
- [ ] DNS configuré (api.ar-code.com)
- [ ] Fail2ban installé
- [ ] Auto-updates activés
- [ ] Monitoring basique installé

## Prochaines étapes

Voir `PHASE_18_API_GATEWAY.md` pour configuration Nginx.









