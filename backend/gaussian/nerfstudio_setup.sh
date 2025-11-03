#!/bin/bash
# Setup script pour Nerfstudio sur Oracle Cloud ARM VM
# Nécessite: Ubuntu 22.04, Python 3.10+

set -e

echo "=========================================="
echo "Setup Nerfstudio pour Gaussian Splatting"
echo "=========================================="

# Vérifier Python
if ! command -v python3 &> /dev/null; then
    echo "Python 3 non trouvé. Installation..."
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip python3-venv
fi

# Créer environnement virtuel
if [ ! -d "venv" ]; then
    echo "Création environnement virtuel..."
    python3 -m venv venv
fi

source venv/bin/activate

# Upgrade pip
pip install --upgrade pip setuptools wheel

# Installer PyTorch (CPU par défaut, GPU si CUDA disponible)
if command -v nvidia-smi &> /dev/null; then
    echo "CUDA détecté, installation PyTorch avec support GPU..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
else
    echo "Installation PyTorch CPU-only..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
fi

# Installer Nerfstudio
echo "Installation Nerfstudio..."
pip install nerfstudio[all]

# Installer diff-gaussian-rasterization
echo "Installation diff-gaussian-rasterization..."
pip install diff-gaussian-rasterization

# Installer additional dependencies
pip install imageio imageio-ffmpeg
pip install plyfile
pip install opencv-python

echo ""
echo "✅ Setup terminé!"
echo ""
echo "Pour activer l'environnement:"
echo "  source venv/bin/activate"
echo ""
echo "Pour vérifier installation:"
echo "  ns-train --help"










