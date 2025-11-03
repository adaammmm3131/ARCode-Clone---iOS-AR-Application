/**
 * SLAM Performance Optimizer
 * Adapte la qualité du SLAM selon performance device
 */

class SLAMPerformanceOptimizer {
    constructor(slamEngine) {
        this.slamEngine = slamEngine;
        this.performanceMonitor = new PerformanceMonitor();
        
        // Quality levels
        this.qualityLevels = {
            high: {
                maxFeatures: 8000,
                gridSize: 15,
                keyframeInterval: 30,
                useWASM: true,
                workerCount: 2
            },
            medium: {
                maxFeatures: 4000,
                gridSize: 20,
                keyframeInterval: 45,
                useWASM: true,
                workerCount: 1
            },
            low: {
                maxFeatures: 2000,
                gridSize: 30,
                keyframeInterval: 60,
                useWASM: false,
                workerCount: 1
            }
        };
        
        this.currentQuality = 'high';
        this.adaptiveQualityEnabled = true;
        
        // Setup performance callback
        this.performanceMonitor.onPerformanceUpdate = (metrics) => {
            this.adaptQuality(metrics);
        };
    }
    
    /**
     * Adapte la qualité selon performance
     */
    adaptQuality(metrics) {
        if (!this.adaptiveQualityEnabled) return;
        
        const { fps, latency } = metrics;
        let newQuality = this.currentQuality;
        
        // Détecter performance dégradée
        if (fps < 30 || latency > 32) {
            // Performance très dégradée -> low quality
            newQuality = 'low';
        } else if (fps < 45 || latency > 20) {
            // Performance modérée -> medium quality
            newQuality = 'medium';
        } else if (fps >= 50 && latency < 16) {
            // Bonne performance -> high quality
            newQuality = 'high';
        }
        
        // Appliquer changement si nécessaire
        if (newQuality !== this.currentQuality) {
            this.setQuality(newQuality);
        }
    }
    
    /**
     * Définit niveau de qualité
     */
    setQuality(quality) {
        if (!this.qualityLevels[quality]) {
            console.warn(`Quality level "${quality}" not found`);
            return;
        }
        
        this.currentQuality = quality;
        const config = this.qualityLevels[quality];
        
        // Appliquer configuration
        if (this.slamEngine.featureTracking) {
            this.slamEngine.featureTracking.maxFeatures = config.maxFeatures;
            this.slamEngine.featureTracking.gridSize = config.gridSize;
        }
        
        if (this.slamEngine.map) {
            // Ajuster intervalle keyframes
            this.slamEngine.map.keyframeInterval = config.keyframeInterval;
        }
        
        console.log(`Quality level changed to: ${quality} (${config.maxFeatures} features, ${config.workerCount} workers)`);
    }
    
    /**
     * Enregistre temps de frame pour monitoring
     */
    recordFrame(frameTime) {
        this.performanceMonitor.recordFrame(frameTime);
    }
    
    /**
     * Obtient rapport de performance
     */
    getPerformanceReport() {
        return this.performanceMonitor.getReport();
    }
    
    /**
     * Active/désactive qualité adaptative
     */
    setAdaptiveQuality(enabled) {
        this.adaptiveQualityEnabled = enabled;
    }
    
    /**
     * Détecte capacités device
     */
    detectDeviceCapabilities() {
        const capabilities = {
            webgl2: this.checkWebGL2(),
            wasm: this.checkWebAssembly(),
            workers: this.checkWorkers(),
            memory: this.checkMemory(),
            gpu: this.checkGPU()
        };
        
        // Déterminer qualité initiale
        if (capabilities.webgl2 && capabilities.wasm && capabilities.workers && capabilities.memory > 2) {
            this.setQuality('high');
        } else if (capabilities.webgl2 && capabilities.memory > 1) {
            this.setQuality('medium');
        } else {
            this.setQuality('low');
        }
        
        return capabilities;
    }
    
    checkWebGL2() {
        const canvas = document.createElement('canvas');
        return !!canvas.getContext('webgl2');
    }
    
    checkWebAssembly() {
        return typeof WebAssembly !== 'undefined';
    }
    
    checkWorkers() {
        return typeof Worker !== 'undefined';
    }
    
    checkMemory() {
        if (performance.memory) {
            return performance.memory.jsHeapSizeLimit / (1024 * 1024 * 1024); // GB
        }
        return 0; // Unknown
    }
    
    checkGPU() {
        // Détecter GPU via WebGL
        const canvas = document.createElement('canvas');
        const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
        if (!gl) return null;
        
        const debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
        if (debugInfo) {
            const renderer = gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL);
            return renderer;
        }
        return null;
    }
}










