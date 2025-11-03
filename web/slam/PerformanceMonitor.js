/**
 * Performance Monitor pour SLAM
 * Surveille FPS, latency, memory usage
 */

class PerformanceMonitor {
    constructor() {
        this.frameTimes = [];
        this.maxSamples = 60; // 1 seconde à 60fps
        this.targetFPS = 60;
        this.targetLatency = 16; // ms
        
        // Metrics
        this.currentFPS = 0;
        this.averageLatency = 0;
        this.maxLatency = 0;
        
        // Memory tracking
        this.memoryUsage = {
            heapUsed: 0,
            heapTotal: 0
        };
        
        // Performance callbacks
        this.onPerformanceUpdate = null;
    }
    
    /**
     * Enregistre le temps de traitement d'une frame
     */
    recordFrame(frameTime) {
        this.frameTimes.push(frameTime);
        
        // Garder seulement les N dernières
        if (this.frameTimes.length > this.maxSamples) {
            this.frameTimes.shift();
        }
        
        // Calculer FPS
        this.calculateFPS();
        this.calculateLatency();
        this.updateMemoryUsage();
        
        // Notifier si callback défini
        if (this.onPerformanceUpdate) {
            this.onPerformanceUpdate({
                fps: this.currentFPS,
                latency: this.averageLatency,
                maxLatency: this.maxLatency,
                memory: this.memoryUsage
            });
        }
        
        // Avertir si performance dégradée
        if (this.currentFPS < this.targetFPS * 0.8) {
            this.warnPerformanceDegradation();
        }
    }
    
    /**
     * Calcule FPS actuel
     */
    calculateFPS() {
        if (this.frameTimes.length < 2) {
            this.currentFPS = 0;
            return;
        }
        
        const avgFrameTime = this.frameTimes.reduce((a, b) => a + b, 0) / this.frameTimes.length;
        this.currentFPS = 1000 / avgFrameTime;
    }
    
    /**
     * Calcule latence moyenne
     */
    calculateLatency() {
        if (this.frameTimes.length === 0) {
            this.averageLatency = 0;
            this.maxLatency = 0;
            return;
        }
        
        this.averageLatency = this.frameTimes.reduce((a, b) => a + b, 0) / this.frameTimes.length;
        this.maxLatency = Math.max(...this.frameTimes);
    }
    
    /**
     * Met à jour usage mémoire
     */
    updateMemoryUsage() {
        if (performance.memory) {
            this.memoryUsage = {
                heapUsed: performance.memory.usedJSHeapSize,
                heapTotal: performance.memory.totalJSHeapSize,
                heapLimit: performance.memory.jsHeapSizeLimit
            };
        }
    }
    
    /**
     * Avertit si performance dégradée
     */
    warnPerformanceDegradation() {
        console.warn(`Performance dégradée: ${this.currentFPS.toFixed(1)} FPS (target: ${this.targetFPS})`);
        console.warn(`Latency: ${this.averageLatency.toFixed(2)}ms (target: <${this.targetLatency}ms)`);
    }
    
    /**
     * Obtenir rapport de performance
     */
    getReport() {
        return {
            fps: {
                current: this.currentFPS,
                target: this.targetFPS,
                status: this.currentFPS >= this.targetFPS * 0.9 ? 'good' : 'degraded'
            },
            latency: {
                average: this.averageLatency,
                max: this.maxLatency,
                target: this.targetLatency,
                status: this.averageLatency < this.targetLatency ? 'good' : 'degraded'
            },
            memory: this.memoryUsage,
            frameCount: this.frameTimes.length
        };
    }
    
    /**
     * Reset les métriques
     */
    reset() {
        this.frameTimes = [];
        this.currentFPS = 0;
        this.averageLatency = 0;
        this.maxLatency = 0;
    }
}











