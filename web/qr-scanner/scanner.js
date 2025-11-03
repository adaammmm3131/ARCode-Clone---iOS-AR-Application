/**
 * QR Code Scanner Web (jsQR)
 * Détection QR code depuis web browser avec redirection automatique
 */

import jsQR from 'https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.js';

class QRCodeWebScanner {
    constructor() {
        this.video = document.getElementById('video');
        this.canvas = document.createElement('canvas');
        this.context = this.canvas.getContext('2d');
        this.stream = null;
        this.isScanning = false;
        this.scanningInterval = null;
    }
    
    /**
     * Démarrer scanning
     */
    async startScanning() {
        try {
            // Demander accès caméra
            this.stream = await navigator.mediaDevices.getUserMedia({
                video: {
                    facingMode: 'environment' // Camera arrière
                }
            });
            
            this.video.srcObject = this.stream;
            await this.video.play();
            
            // Ajuster canvas à taille vidéo
            this.video.addEventListener('loadedmetadata', () => {
                this.canvas.width = this.video.videoWidth;
                this.canvas.height = this.video.videoHeight;
                this.updateStatus('Prêt à scanner');
                this.startScanningLoop();
            });
            
        } catch (error) {
            console.error('Erreur accès caméra:', error);
            this.updateStatus('Erreur: Accès caméra refusé');
        }
    }
    
    /**
     * Boucle de scanning
     */
    startScanningLoop() {
        if (this.isScanning) return;
        
        this.isScanning = true;
        
        this.scanningInterval = setInterval(() => {
            if (this.video.readyState === this.video.HAVE_ENOUGH_DATA) {
                this.scanFrame();
            }
        }, 100); // 10 FPS scanning
    }
    
    /**
     * Scanner frame actuelle
     */
    scanFrame() {
        // Dessiner frame vidéo sur canvas
        this.context.drawImage(this.video, 0, 0, this.canvas.width, this.canvas.height);
        
        // Extraire image data
        const imageData = this.context.getImageData(0, 0, this.canvas.width, this.canvas.height);
        
        // Détecter QR code avec jsQR
        const code = jsQR(imageData.data, imageData.width, imageData.height, {
            inversionAttempts: 'dontInvert'
        });
        
        if (code) {
            // QR code détecté!
            this.handleQRCodeDetected(code.data);
        }
    }
    
    /**
     * Gérer QR code détecté
     */
    handleQRCodeDetected(url) {
        console.log('QR Code détecté:', url);
        
        // Arrêter scanning
        this.stopScanning();
        
        // Afficher loading
        this.showLoading();
        
        // Vérifier si URL est AR Code
        if (url.includes('ar-code.com') || url.includes('/a/')) {
            // Parser metadata et charger AR content
            this.loadARContent(url);
        } else {
            // Rediriger vers URL
            window.location.href = url;
        }
    }
    
    /**
     * Charger contenu AR
     */
    async loadARContent(url) {
        // Extraire ID depuis URL
        const urlObj = new URL(url);
        const pathParts = urlObj.pathname.split('/');
        const arCodeId = pathParts[pathParts.length - 1];
        
        // Parser query params
        const params = new URLSearchParams(urlObj.search);
        const contentType = params.get('type') || 'object_capture';
        
        this.updateLoadingMessage('Chargement AR Code...', 0.3);
        
        // Simuler chargement (en production, charger depuis API)
        setTimeout(() => {
            this.updateLoadingMessage('Chargement assets...', 0.6);
            
            setTimeout(() => {
                this.updateLoadingMessage('Prêt!', 1.0);
                
                // Rediriger vers AR view
                setTimeout(() => {
                    // Deep link vers app iOS si disponible
                    const appURL = `ar-code://ar/${arCodeId}?type=${contentType}`;
                    
                    // Essayer ouvrir dans app
                    window.location.href = appURL;
                    
                    // Fallback: ouvrir dans web AR viewer
                    setTimeout(() => {
                        window.location.href = `/ar-viewer.html?id=${arCodeId}&type=${contentType}`;
                    }, 1000);
                }, 500);
            }, 1000);
        }, 500);
    }
    
    /**
     * Arrêter scanning
     */
    stopScanning() {
        this.isScanning = false;
        
        if (this.scanningInterval) {
            clearInterval(this.scanningInterval);
            this.scanningInterval = null;
        }
        
        if (this.stream) {
            this.stream.getTracks().forEach(track => track.stop());
            this.stream = null;
        }
        
        if (this.video) {
            this.video.srcObject = null;
        }
    }
    
    /**
     * Afficher loading
     */
    showLoading() {
        const loading = document.getElementById('loading');
        loading.classList.add('active');
    }
    
    /**
     * Mettre à jour message loading
     */
    updateLoadingMessage(message, progress) {
        const loadingMessage = document.getElementById('loading-message');
        const progressFill = document.getElementById('progress-fill');
        
        if (loadingMessage) {
            loadingMessage.textContent = message + ` (${Math.round(progress * 100)}%)`;
        }
        
        if (progressFill) {
            progressFill.style.width = `${progress * 100}%`;
        }
    }
    
    /**
     * Mettre à jour status
     */
    updateStatus(message) {
        const status = document.getElementById('status');
        if (status) {
            status.textContent = message;
        }
    }
}

// Initialiser scanner au chargement
document.addEventListener('DOMContentLoaded', () => {
    const scanner = new QRCodeWebScanner();
    scanner.startScanning();
    
    // Exposer globalement pour debugging
    window.qrScanner = scanner;
});









