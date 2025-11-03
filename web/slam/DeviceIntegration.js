/**
 * Device Integration pour SLAM
 * Gère DeviceMotion API (gyroscope/accéléromètre) et calibration caméra
 */

class DeviceIntegration {
    constructor() {
        this.deviceMotionSupported = false;
        this.deviceOrientationSupported = false;
        
        // Sensors data
        this.gyroscopeData = { x: 0, y: 0, z: 0 };
        this.accelerometerData = { x: 0, y: 0, z: 0 };
        this.magnetometerData = { x: 0, y: 0, z: 0 };
        
        // Camera calibration
        this.cameraMatrix = null;
        this.distortionCoeffs = null;
        this.cameraCalibrated = false;
        
        // Fusion sensors
        this.sensorFusionEnabled = true;
    }
    
    /**
     * Initialise l'intégration des capteurs
     */
    async init() {
        await this.initDeviceMotion();
        await this.initCameraCalibration();
    }
    
    /**
     * Initialise DeviceMotion API
     */
    async initDeviceMotion() {
        if (typeof DeviceMotionEvent === 'undefined') {
            console.warn('DeviceMotionEvent not supported');
            return;
        }
        
        // Demander permission (iOS 13+)
        if (typeof DeviceMotionEvent.requestPermission === 'function') {
            try {
                const permission = await DeviceMotionEvent.requestPermission();
                if (permission !== 'granted') {
                    console.warn('DeviceMotion permission denied');
                    return;
                }
            } catch (error) {
                console.error('Error requesting DeviceMotion permission:', error);
                return;
            }
        }
        
        // Écouter événements DeviceMotion
        window.addEventListener('devicemotion', (event) => {
            this.handleDeviceMotion(event);
        });
        
        // Écouter événements DeviceOrientation
        window.addEventListener('deviceorientation', (event) => {
            this.handleDeviceOrientation(event);
        });
        
        this.deviceMotionSupported = true;
        console.log('DeviceMotion API initialized');
    }
    
    /**
     * Gère événements DeviceMotion
     */
    handleDeviceMotion(event) {
        if (event.accelerationIncludingGravity) {
            this.accelerometerData = {
                x: event.accelerationIncludingGravity.x || 0,
                y: event.accelerationIncludingGravity.y || 0,
                z: event.accelerationIncludingGravity.z || 0
            };
        }
        
        if (event.rotationRate) {
            this.gyroscopeData = {
                x: event.rotationRate.alpha || 0,
                y: event.rotationRate.beta || 0,
                z: event.rotationRate.gamma || 0
            };
        }
    }
    
    /**
     * Gère événements DeviceOrientation
     */
    handleDeviceOrientation(event) {
        // Orientation absolue (compass)
        if (event.absolute !== undefined) {
            this.absoluteOrientation = event.absolute;
        }
        
        // Angles Euler
        this.orientationEuler = {
            alpha: event.alpha || 0, // Z-axis (compass)
            beta: event.beta || 0,  // X-axis (tilt front/back)
            gamma: event.gamma || 0 // Y-axis (tilt left/right)
        };
    }
    
    /**
     * Initialise calibration caméra
     */
    async initCameraCalibration() {
        // Charger paramètres caméra depuis localStorage ou utiliser defaults
        const savedCalibration = this.loadCameraCalibration();
        
        if (savedCalibration) {
            this.cameraMatrix = savedCalibration.cameraMatrix;
            this.distortionCoeffs = savedCalibration.distortionCoeffs;
            this.cameraCalibrated = true;
            console.log('Camera calibration loaded from storage');
        } else {
            // Utiliser calibration par défaut (approximative)
            this.setDefaultCameraCalibration();
            console.log('Using default camera calibration');
        }
    }
    
    /**
     * Calibration par défaut (à remplacer par vraie calibration)
     */
    setDefaultCameraCalibration() {
        // Matrice intrinsèque approximative
        // À calibrer avec chessboard ou charuco pattern
        const width = 640;  // Résolution caméra
        const height = 480;
        
        const fx = width * 1.2;  // Focal length X (approximatif)
        const fy = height * 1.2; // Focal length Y
        const cx = width / 2;    // Principal point X
        const cy = height / 2;   // Principal point Y
        
        this.cameraMatrix = [
            [fx, 0, cx],
            [0, fy, cy],
            [0, 0, 1]
        ];
        
        // Coefficients de distorsion (k1, k2, p1, p2, k3)
        // Généralement proches de zéro pour caméras modernes
        this.distortionCoeffs = [0, 0, 0, 0, 0];
        
        this.cameraCalibrated = true;
    }
    
    /**
     * Calibre la caméra avec pattern (chessboard ou charuco)
     */
    async calibrateCamera(images) {
        // TODO: Implémenter calibration avec OpenCV.js
        // Processus:
        // 1. Détecter corners dans chaque image
        // 2. Calculer matrices intrinsiques/extrinsiques
        // 3. Optimiser avec bundle adjustment
        
        console.log(`Calibrating camera with ${images.length} images...`);
        
        // Pour l'instant, utiliser calibration par défaut améliorée
        this.improveCameraCalibration(images);
    }
    
    /**
     * Améliore calibration avec images
     */
    improveCameraCalibration(images) {
        // TODO: Analyser images pour estimer meilleure calibration
        // Pour l'instant, garder calibration par défaut
        this.saveCameraCalibration();
    }
    
    /**
     * Sauvegarde calibration caméra
     */
    saveCameraCalibration() {
        const calibration = {
            cameraMatrix: this.cameraMatrix,
            distortionCoeffs: this.distortionCoeffs,
            timestamp: Date.now()
        };
        
        localStorage.setItem('camera_calibration', JSON.stringify(calibration));
    }
    
    /**
     * Charge calibration caméra
     */
    loadCameraCalibration() {
        const saved = localStorage.getItem('camera_calibration');
        if (!saved) return null;
        
        try {
            return JSON.parse(saved);
        } catch (error) {
            console.error('Error loading camera calibration:', error);
            return null;
        }
    }
    
    /**
     * Obtient matrice caméra (intrinsics)
     */
    getCameraMatrix() {
        return this.cameraMatrix;
    }
    
    /**
     * Obtient coefficients de distorsion
     */
    getDistortionCoeffs() {
        return this.distortionCoeffs;
    }
    
    /**
     * Fusionne données capteurs pour améliorer pose estimation
     */
    fuseSensors(visualPose) {
        if (!this.sensorFusionEnabled || !this.deviceMotionSupported) {
            return visualPose;
        }
        
        // Fusion visuelle + IMU (Inertial Measurement Unit)
        // Utiliser filtres complémentaires ou Kalman filter
        
        const fusedPose = {
            translation: [...visualPose.translation],
            rotation: this.fuseRotation(visualPose.rotation, this.orientationEuler)
        };
        
        return fusedPose;
    }
    
    /**
     * Fusion rotation visuelle + gyroscope
     */
    fuseRotation(visualRotation, gyroOrientation) {
        // TODO: Implémenter vrai filtrage (complementary filter ou Kalman)
        // Pour l'instant, moyenne pondérée simple
        
        if (!gyroOrientation) {
            return visualRotation;
        }
        
        // Convertir orientation gyro en quaternion
        const gyroQuat = this.eulerToQuaternion(
            gyroOrientation.alpha,
            gyroOrientation.beta,
            gyroOrientation.gamma
        );
        
        // Interpoler entre rotation visuelle et gyro
        const alpha = 0.7; // Poids rotation visuelle
        return this.slerpQuaternion(visualRotation, gyroQuat, 1 - alpha);
    }
    
    /**
     * Convertit angles Euler en quaternion
     */
    eulerToQuaternion(alpha, beta, gamma) {
        // Convertir degrés en radians
        const a = alpha * Math.PI / 180;
        const b = beta * Math.PI / 180;
        const g = gamma * Math.PI / 180;
        
        const cy = Math.cos(g * 0.5);
        const sy = Math.sin(g * 0.5);
        const cp = Math.cos(b * 0.5);
        const sp = Math.sin(b * 0.5);
        const cr = Math.cos(a * 0.5);
        const sr = Math.sin(a * 0.5);
        
        return [
            cy * cp * cr + sy * sp * sr,
            cy * cp * sr - sy * sp * cr,
            sy * cp * sr + cy * sp * cr,
            sy * cp * cr - cy * sp * sr
        ];
    }
    
    /**
     * Spherical Linear Interpolation entre quaternions
     */
    slerpQuaternion(q1, q2, t) {
        // TODO: Implémenter vraie SLERP
        // Pour l'instant, interpolation linéaire simple
        return [
            q1[0] * (1 - t) + q2[0] * t,
            q1[1] * (1 - t) + q2[1] * t,
            q1[2] * (1 - t) + q2[2] * t,
            q1[3] * (1 - t) + q2[3] * t
        ];
    }
    
    /**
     * Obtient données capteurs actuelles
     */
    getSensorData() {
        return {
            gyroscope: this.gyroscopeData,
            accelerometer: this.accelerometerData,
            orientation: this.orientationEuler,
            absolute: this.absoluteOrientation
        };
    }
}










