/**
 * WebAR SLAM Engine
 * Système de SLAM propriétaire pour navigateur web
 * Technologie signature d'AR Code
 */

class WebARSlamEngine {
    constructor(canvas) {
        this.canvas = canvas;
        this.gl = null;
        this.renderer = null;
        this.scene = null;
        this.camera = null;
        
        // SLAM state
        this.currentFrame = null;
        this.previousFrame = null;
        this.features = [];
        this.map = new SparseMap();
        this.pose = {
            translation: [0, 0, 0],
            rotation: [0, 0, 0, 1]
        };
        
        // Performance targets
        this.targetFPS = 60;
        this.targetLatency = 16; // ms
        
        // Workers pour parallélisation
        this.featureWorker = null;
        this.workerReady = false;
        
        // Performance optimizer
        this.performanceOptimizer = null;
        
        // Device integration
        this.deviceIntegration = null;
        
        // Initialize
        this.initWebGL();
        this.initSLAM();
        this.initWorkers();
        this.initPerformanceOptimizer();
        this.initDeviceIntegration();
    }
    
    /**
     * Initialise le contexte WebGL 2.0
     */
    initWebGL() {
        const gl = this.canvas.getContext('webgl2');
        if (!gl) {
            throw new Error('WebGL 2.0 not supported');
        }
        
        this.gl = gl;
        
        // Configuration WebGL
        gl.enable(gl.DEPTH_TEST);
        gl.enable(gl.CULL_FACE);
        gl.viewport(0, 0, this.canvas.width, this.canvas.height);
        
        // Initialiser Three.js ou renderer custom
        // TODO: Setup Three.js scene
    }
    
    /**
     * Initialise le système SLAM
     */
    initSLAM() {
        this.featureTracking = new FeatureTracking();
        this.poseEstimator = new PnPPoseEstimator();
        this.ransacFilter = new RANSACFilter();
    }
    
    /**
     * Détection de features avec ORB
     */
    detectFeatures(frame) {
        // Convertir frame vidéo en ImageData
        const imageData = this.frameToImageData(frame);
        
        // Détection ORB
        const features = this.featureTracking.detectORB(imageData);
        
        return features;
    }
    
    /**
     * Convertit une frame vidéo en ImageData
     */
    frameToImageData(videoFrame) {
        // Créer canvas temporaire pour extraction
        const canvas = document.createElement('canvas');
        canvas.width = videoFrame.videoWidth || 640;
        canvas.height = videoFrame.videoHeight || 480;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(videoFrame, 0, 0);
        
        return ctx.getImageData(0, 0, canvas.width, canvas.height);
    }
    
    /**
     * Tracking de features entre frames
     */
    trackFeatures(features) {
        if (!this.previousFrame) {
            return features;
        }
        
        const prevImageData = this.frameToImageData(this.previousFrame);
        const currImageData = this.frameToImageData(this.currentFrame);
        
        return this.featureTracking.trackFeatures(prevImageData, currImageData, features);
    }
    
    /**
     * Estimation de pose avec PnP
     */
    estimatePose(features) {
        // Convertir features 2D en correspondances 3D-2D
        const imagePoints = features.map(f => [f.x, f.y]);
        const objectPoints = this.getObjectPoints3D(features); // Points 3D depuis map
        
        const pose = this.poseEstimator.estimatePose(imagePoints, objectPoints);
        
        if (!pose) {
            return null;
        }
        
        // RANSAC pour outlier rejection
        const filtered = this.ransacFilter.filter(features, pose);
        
        // Fusionner avec données capteurs (IMU)
        let finalPose = filtered.model;
        if (this.deviceIntegration && this.deviceIntegration.sensorFusionEnabled) {
            finalPose = this.deviceIntegration.fuseSensors(finalPose);
        }
        
        return finalPose;
    }
    
    /**
     * Obtient les points 3D correspondants depuis la map
     */
    getObjectPoints3D(features) {
        // TODO: Retrouver correspondances 3D depuis sparse map
        // Pour l'instant, retourner points simulés
        return features.map(() => [0, 0, 0]);
    }
    
    /**
     * Initialise les Workers pour parallélisation
     */
    initWorkers() {
        if (typeof Worker === 'undefined') {
            console.warn('Web Workers not supported, using main thread');
            return;
        }
        
        try {
            this.featureWorker = new Worker('workers/FeatureDetectionWorker.js');
            this.featureWorker.name = 'feature-detection';
            
            this.featureWorker.onmessage = (e) => {
                const { type, data } = e.data;
                
                switch (type) {
                    case 'FEATURES_DETECTED':
                        this.onFeaturesDetected(data);
                        break;
                    case 'FEATURES_TRACKED':
                        this.onFeaturesTracked(data);
                        break;
                    case 'WASM_LOADED':
                        if (data.success) {
                            this.workerReady = true;
                            console.log('Feature detection worker ready');
                        } else {
                            console.error('Failed to load WASM in worker:', data.error);
                        }
                        break;
                }
            };
            
            this.featureWorker.onerror = (error) => {
                console.error('Worker error:', error);
            };
            
            // Charger WASM dans worker si disponible
            this.loadWASMInWorker();
            
        } catch (error) {
            console.error('Failed to initialize workers:', error);
        }
    }
    
    /**
     * Charge WASM dans worker
     */
    loadWASMInWorker() {
        // TODO: Charger OpenCV.js WASM
        // this.featureWorker.postMessage({
        //     type: 'LOAD_WASM',
        //     data: { wasmPath: 'opencv/opencv.wasm' }
        // });
    }
    
    /**
     * Initialise l'optimiseur de performance
     */
    initPerformanceOptimizer() {
        this.performanceOptimizer = new SLAMPerformanceOptimizer(this);
        this.performanceOptimizer.detectDeviceCapabilities();
    }
    
    /**
     * Initialise intégration device (DeviceMotion, calibration)
     */
    async initDeviceIntegration() {
        this.deviceIntegration = new DeviceIntegration();
        await this.deviceIntegration.init();
        
        // Utiliser calibration caméra pour pose estimation
        if (this.poseEstimator && this.deviceIntegration.getCameraMatrix()) {
            this.poseEstimator.cameraMatrix = this.deviceIntegration.getCameraMatrix();
        }
    }
    
    /**
     * Traite une nouvelle frame vidéo
     */
    processFrame(videoFrame) {
        const startTime = performance.now();
        
        this.previousFrame = this.currentFrame;
        this.currentFrame = videoFrame;
        
        // Utiliser worker si disponible, sinon thread principal
        if (this.workerReady && this.featureWorker) {
            this.processFrameWithWorker(videoFrame);
        } else {
            this.processFrameMainThread(videoFrame);
        }
        
        const processTime = performance.now() - startTime;
        
        // Enregistrer pour monitoring
        if (this.performanceOptimizer) {
            this.performanceOptimizer.recordFrame(processTime);
        }
        
        // Vérifier performance
        if (processTime > this.targetLatency) {
            console.warn(`SLAM latency: ${processTime.toFixed(2)}ms (target: ${this.targetLatency}ms)`);
        }
    }
    
    /**
     * Traitement avec Worker (parallélisé)
     */
    processFrameWithWorker(videoFrame) {
        // Convertir frame en ImageData
        const imageData = this.frameToImageData(videoFrame);
        
        // Envoyer à worker pour traitement
        this.featureWorker.postMessage({
            type: 'DETECT_FEATURES',
            data: imageData
        }, [imageData.data.buffer]); // Transfer ownership
        
        // TODO: Gérer réponse asynchrone
        // Pour l'instant, fallback sur main thread
        this.processFrameMainThread(videoFrame);
    }
    
    /**
     * Traitement sur thread principal
     */
    processFrameMainThread(videoFrame) {
        // 1. Feature detection
        const features = this.detectFeatures(videoFrame);
        
        // 2. Feature tracking
        const trackedFeatures = this.trackFeatures(features);
        
        // 3. Pose estimation
        const pose = this.estimatePose(trackedFeatures);
        
        // 4. Map update
        this.updateMap(trackedFeatures, pose);
        
        // 5. Render
        this.render();
    }
    
    /**
     * Callback quand features détectées par worker
     */
    onFeaturesDetected(result) {
        this.features = result.features;
        // Continuer pipeline...
    }
    
    /**
     * Callback quand features trackées par worker
     */
    onFeaturesTracked(result) {
        const trackedFeatures = result.features;
        const pose = this.estimatePose(trackedFeatures);
        this.updateMap(trackedFeatures, pose);
        this.render();
    }
    
    /**
     * Détection de features avec pipeline GLSL
     */
    detectFeatures(frame) {
        // Utiliser shader GLSL pour feature extraction
        const shaderProgram = this.createFeatureExtractionShader();
        const features = this.featureDetector.detect(frame, shaderProgram);
        
        // Support 8K features points
        return features.slice(0, 8000);
    }
    
    /**
     * Crée le shader GLSL pour feature extraction
     */
    createFeatureExtractionShader() {
        const vertexShader = `
            #version 300 es
            in vec2 a_position;
            in vec2 a_texCoord;
            out vec2 v_texCoord;
            
            void main() {
                gl_Position = vec4(a_position, 0.0, 1.0);
                v_texCoord = a_texCoord;
            }
        `;
        
        const fragmentShader = `
            #version 300 es
            precision highp float;
            
            uniform sampler2D u_image;
            in vec2 v_texCoord;
            out vec4 fragColor;
            
            void main() {
                // Feature extraction algorithm (simplified)
                vec4 color = texture(u_image, v_texCoord);
                float intensity = dot(color.rgb, vec3(0.299, 0.587, 0.114));
                
                // Edge detection pour features
                // TODO: Implémenter algorithme ORB/SIFT complet
                
                fragColor = vec4(intensity);
            }
        `;
        
        return { vertexShader, fragmentShader };
    }
    
    /**
     * Tracking de features entre frames
     */
    trackFeatures(features) {
        if (!this.previousFrame) {
            return features;
        }
        
        return this.tracker.track(this.previousFrame, this.currentFrame, features);
    }
    
    /**
     * Estimation de pose avec PnP
     */
    estimatePose(features) {
        const pose = this.poseEstimator.estimate(features);
        
        // RANSAC pour outlier rejection
        const filteredPose = this.ransacFilter.filter(pose, features);
        
        return filteredPose;
    }
    
    /**
     * Met à jour la map sparse
     */
    updateMap(features, pose) {
        this.pose = pose;
        
        // Ajouter keyframe si conditions remplies
        if (this.shouldAddKeyframe(features, pose)) {
            const keyframe = this.map.addKeyframe(this.currentFrame, features, pose);
            
            // Loop closure detection
            const loopClosure = this.map.detectLoopClosure(pose);
            if (loopClosure) {
                console.log('Loop closure détecté! Optimisation...');
                this.map.optimizeBundle();
            }
        }
    }
    
    /**
     * Détermine si on doit ajouter un keyframe
     */
    shouldAddKeyframe(features, pose) {
        // Ajouter keyframe si:
        // - Pas de keyframe récent (toutes les 30 frames ~= 1 seconde à 30fps)
        if (this.map.keyframes.length === 0) {
            return true;
        }
        
        const lastKeyframe = this.map.keyframes[this.map.keyframes.length - 1];
        const framesSinceLastKeyframe = this.map.keyframes.length;
        
        // Minimum 30 frames entre keyframes
        if (framesSinceLastKeyframe < 30) {
            return false;
        }
        
        // Vérifier mouvement significatif
        const translationChange = this.computeTranslationChange(pose, lastKeyframe.pose);
        if (translationChange > 0.1) { // 10cm
            return true;
        }
        
        // Vérifier rotation significative
        const rotationChange = this.computeRotationChange(pose, lastKeyframe.pose);
        if (rotationChange > 0.2) { // ~11 degrés
            return true;
        }
        
        return false;
    }
    
    computeTranslationChange(pose1, pose2) {
        const dx = pose1.translation[0] - pose2.translation[0];
        const dy = pose1.translation[1] - pose2.translation[1];
        const dz = pose1.translation[2] - pose2.translation[2];
        return Math.sqrt(dx * dx + dy * dy + dz * dz);
    }
    
    computeRotationChange(pose1, pose2) {
        // Calculer différence entre quaternions
        // Pour simplifier, retourner valeur simulée
        return 0;
    }
    
    /**
     * Render la scène AR
     */
    render() {
        // TODO: Render 3D models avec pose estimée
        if (this.renderer) {
            this.renderer.render(this.scene, this.camera);
        }
    }
    
    /**
     * Nettoie les ressources
     */
    cleanup() {
        // Cleanup WebGL resources
        if (this.gl) {
            const loseContext = this.gl.getExtension('WEBGL_lose_context');
            if (loseContext) {
                loseContext.loseContext();
            }
        }
    }
}

// Les classes détaillées sont dans FeatureTracking.js

// La classe SparseMap complète est dans SparseMap.js

