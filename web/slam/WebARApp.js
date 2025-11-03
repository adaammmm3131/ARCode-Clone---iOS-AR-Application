/**
 * Application WebAR principale
 * Gère l'accès caméra, permissions, et orchestre SLAM
 */

class WebARApp {
    constructor() {
        this.canvas = document.getElementById('ar-canvas');
        this.video = null;
        this.slamEngine = null;
        this.isRunning = false;
        
        // Setup canvas size
        this.resizeCanvas();
        window.addEventListener('resize', () => this.resizeCanvas());
        
        // Initialize
        this.init();
    }
    
    resizeCanvas() {
        this.canvas.width = window.innerWidth;
        this.canvas.height = window.innerHeight;
    }
    
    async init() {
        try {
            // 1. Demander permission caméra
            const stream = await this.requestCameraAccess();
            
            // 2. Créer élément vidéo
            this.video = document.createElement('video');
            this.video.srcObject = stream;
            this.video.play();
            this.video.setAttribute('playsinline', 'true');
            this.video.setAttribute('webkit-playsinline', 'true');
            
            // 3. Initialiser SLAM engine
            this.slamEngine = new WebARSlamEngine(this.canvas);
            
            // 4. Masquer loading
            document.getElementById('loading').style.display = 'none';
            document.getElementById('controls').style.display = 'flex';
            
            // 5. Démarrer la boucle AR
            this.startAR();
            
        } catch (error) {
            console.error('Erreur initialisation WebAR:', error);
            this.showError(error.message);
        }
    }
    
    /**
     * Demande l'accès à la caméra via WebRTC
     */
    async requestCameraAccess() {
        const constraints = {
            video: {
                width: { ideal: 1920 },
                height: { ideal: 1080 },
                facingMode: 'environment' // Camera arrière si disponible
            }
        };
        
        try {
            const stream = await navigator.mediaDevices.getUserMedia(constraints);
            return stream;
        } catch (error) {
            throw new Error('Accès caméra refusé: ' + error.message);
        }
    }
    
    /**
     * Démarre la boucle AR
     */
    startAR() {
        this.isRunning = true;
        this.arLoop();
    }
    
    /**
     * Boucle principale AR
     */
    arLoop() {
        if (!this.isRunning) return;
        
        // Traiter frame vidéo avec SLAM
        if (this.video && this.video.readyState === this.video.HAVE_ENOUGH_DATA) {
            this.slamEngine.processFrame(this.video);
        }
        
        // Prochaine frame (target 60fps)
        requestAnimationFrame(() => this.arLoop());
    }
    
    /**
     * Arrête l'expérience AR
     */
    stopAR() {
        this.isRunning = false;
        
        if (this.video && this.video.srcObject) {
            const tracks = this.video.srcObject.getTracks();
            tracks.forEach(track => track.stop());
        }
        
        if (this.slamEngine) {
            this.slamEngine.cleanup();
        }
    }
    
    /**
     * Affiche une erreur
     */
    showError(message) {
        const loading = document.getElementById('loading');
        loading.innerHTML = `
            <div style="color: #ff7675;">Erreur</div>
            <div style="margin-top: 10px; font-size: 14px;">${message}</div>
        `;
    }
}

// Initialize app when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        const app = new WebARApp();
        
        // Setup controls
        document.getElementById('close-btn').addEventListener('click', () => {
            app.stopAR();
            window.close();
        });
        
        document.getElementById('screenshot-btn').addEventListener('click', () => {
            app.takeScreenshot();
        });
    });
} else {
    const app = new WebARApp();
}












