/**
 * Sparse Map System pour SLAM
 * Gère keyframes, loop closure detection, bundle adjustment
 */

class SparseMap {
    constructor() {
        this.keyframes = [];
        this.mapPoints = []; // Points 3D de la map
        this.covisibilityGraph = new Map(); // Graphe de covisibilité
        this.lastKeyframeId = 0;
        this.loopClosureCandidates = [];
    }
    
    /**
     * Ajoute un keyframe à la map
     */
    addKeyframe(frame, features, pose) {
        const keyframe = {
            id: this.lastKeyframeId++,
            timestamp: Date.now(),
            frame: frame,
            features: features,
            pose: pose,
            mapPointIds: [] // IDs des map points observés
        };
        
        this.keyframes.push(keyframe);
        
        // Créer map points depuis nouvelles features
        this.createMapPoints(keyframe, features);
        
        // Mettre à jour graphe de covisibilité
        this.updateCovisibilityGraph(keyframe);
        
        // Vérifier loop closure
        this.checkLoopClosure(keyframe);
        
        return keyframe;
    }
    
    /**
     * Crée des map points 3D depuis features d'un keyframe
     */
    createMapPoints(keyframe, features) {
        // TODO: Triangulation pour créer points 3D
        // Pour l'instant, créer points simulés
        for (const feature of features) {
            if (feature.trackId === undefined) {
                // Nouvelle feature, créer map point
                const mapPoint = {
                    id: this.mapPoints.length,
                    position: this.triangulatePoint(keyframe, feature),
                    observations: [{
                        keyframeId: keyframe.id,
                        featureId: feature.id
                    }],
                    descriptor: feature.descriptor,
                    firstObserved: keyframe.id
                };
                
                this.mapPoints.push(mapPoint);
                keyframe.mapPointIds.push(mapPoint.id);
                feature.trackId = mapPoint.id;
            } else {
                // Feature déjà trackée, ajouter observation
                const mapPoint = this.mapPoints[feature.trackId];
                if (mapPoint) {
                    mapPoint.observations.push({
                        keyframeId: keyframe.id,
                        featureId: feature.id
                    });
                    keyframe.mapPointIds.push(mapPoint.id);
                }
            }
        }
    }
    
    /**
     * Triangule un point 3D depuis plusieurs vues
     */
    triangulatePoint(keyframe, feature) {
        // TODO: Implémenter triangulation DLT (Direct Linear Transform)
        // Pour l'instant, retourner position 3D simulée
        // Basée sur pose et feature 2D
        const depth = 1.0; // Profondeur estimée
        const fx = 800; // Focal length X
        const fy = 800; // Focal length Y
        const cx = 320; // Principal point X
        const cy = 240; // Principal point Y
        
        const x = (feature.x - cx) / fx;
        const y = (feature.y - cy) / fy;
        
        // Transform selon pose
        const point3D = [
            x * depth,
            y * depth,
            depth
        ];
        
        return point3D;
    }
    
    /**
     * Met à jour le graphe de covisibilité
     */
    updateCovisibilityGraph(newKeyframe) {
        // Pour chaque keyframe existant, calculer nombre de map points partagés
        for (const keyframe of this.keyframes) {
            if (keyframe.id === newKeyframe.id) continue;
            
            const sharedPoints = this.countSharedMapPoints(keyframe, newKeyframe);
            
            if (sharedPoints > 15) { // Seuil minimum pour covisibilité
                const key = `${Math.min(keyframe.id, newKeyframe.id)}-${Math.max(keyframe.id, newKeyframe.id)}`;
                this.covisibilityGraph.set(key, sharedPoints);
            }
        }
    }
    
    /**
     * Compte les map points partagés entre deux keyframes
     */
    countSharedMapPoints(kf1, kf2) {
        const set1 = new Set(kf1.mapPointIds);
        const set2 = new Set(kf2.mapPointIds);
        let count = 0;
        
        for (const id of set1) {
            if (set2.has(id)) {
                count++;
            }
        }
        
        return count;
    }
    
    /**
     * Détecte loop closure
     */
    checkLoopClosure(currentKeyframe) {
        // Chercher keyframes similaires (pas voisins)
        const neighbors = this.getNeighborKeyframes(currentKeyframe, 5);
        const neighborIds = new Set(neighbors.map(kf => kf.id));
        
        // Chercher dans keyframes plus anciens
        for (const keyframe of this.keyframes) {
            if (keyframe.id === currentKeyframe.id || neighborIds.has(keyframe.id)) {
                continue;
            }
            
            // Comparer avec BoW (Bag of Words) ou descripteurs
            const similarity = this.computeKeyframeSimilarity(currentKeyframe, keyframe);
            
            if (similarity > 0.7) { // Seuil de similarité
                this.loopClosureCandidates.push({
                    currentKeyframe: currentKeyframe.id,
                    candidateKeyframe: keyframe.id,
                    similarity: similarity,
                    timestamp: Date.now()
                });
                
                // Si plusieurs candidats trouvés, déclencher optimisation
                if (this.loopClosureCandidates.length > 0) {
                    this.optimizeBundle();
                }
            }
        }
    }
    
    /**
     * Obtient les keyframes voisins (covisibles)
     */
    getNeighborKeyframes(keyframe, maxNeighbors) {
        const neighbors = [];
        
        for (const otherKeyframe of this.keyframes) {
            if (otherKeyframe.id === keyframe.id) continue;
            
            const sharedPoints = this.countSharedMapPoints(keyframe, otherKeyframe);
            if (sharedPoints > 10) {
                neighbors.push({ keyframe: otherKeyframe, score: sharedPoints });
            }
        }
        
        neighbors.sort((a, b) => b.score - a.score);
        return neighbors.slice(0, maxNeighbors).map(n => n.keyframe);
    }
    
    /**
     * Calcule la similarité entre deux keyframes
     */
    computeKeyframeSimilarity(kf1, kf2) {
        // TODO: Implémenter BoW (Bag of Words) ou comparaison de descripteurs
        // Pour l'instant, basé sur nombre de map points partagés
        const sharedPoints = this.countSharedMapPoints(kf1, kf2);
        const totalPoints = Math.max(kf1.mapPointIds.length, kf2.mapPointIds.length);
        
        return totalPoints > 0 ? sharedPoints / totalPoints : 0;
    }
    
    /**
     * Détection de loop closure (appelée depuis SLAM engine)
     */
    detectLoopClosure(currentPose) {
        if (this.loopClosureCandidates.length === 0) {
            return null;
        }
        
        // Prendre le candidat le plus récent
        const candidate = this.loopClosureCandidates[this.loopClosureCandidates.length - 1];
        
        // Vérifier que le loop closure est toujours valide
        const candidateKeyframe = this.keyframes.find(kf => kf.id === candidate.candidateKeyframe);
        if (!candidateKeyframe) {
            return null;
        }
        
        return {
            detected: true,
            currentKeyframeId: candidate.currentKeyframe,
            loopKeyframeId: candidate.candidateKeyframe,
            transform: this.computeLoopTransform(candidateKeyframe, currentPose)
        };
    }
    
    /**
     * Calcule la transformation entre current pose et loop keyframe
     */
    computeLoopTransform(loopKeyframe, currentPose) {
        // TODO: Estimer transformation rigide entre poses
        // Pour l'instant, retourner transformation identité
        return {
            rotation: [0, 0, 0, 1], // quaternion
            translation: [0, 0, 0]
        };
    }
    
    /**
     * Bundle Adjustment - Optimise poses et map points
     */
    optimizeBundle() {
        console.log('Optimisation Bundle Adjustment...');
        
        // TODO: Implémenter Bundle Adjustment complet
        // Utiliser Levenberg-Marquardt ou Ceres Solver (WebAssembly)
        
        // Pour l'instant, optimisation simplifiée
        this.bundleAdjustmentIteration();
    }
    
    /**
     * Une itération de Bundle Adjustment
     */
    bundleAdjustmentIteration() {
        // Minimiser erreur de reprojection
        // min Σ ||π(P_i, X_j) - x_ij||²
        
        // 1. Calculer erreurs de reprojection
        const reprojectionErrors = this.computeReprojectionErrors();
        
        // 2. Calculer gradients
        const gradients = this.computeGradients(reprojectionErrors);
        
        // 3. Mettre à jour poses et map points
        this.updatePosesAndPoints(gradients);
    }
    
    /**
     * Calcule erreurs de reprojection
     */
    computeReprojectionErrors() {
        const errors = [];
        
        for (const mapPoint of this.mapPoints) {
            for (const obs of mapPoint.observations) {
                const keyframe = this.keyframes.find(kf => kf.id === obs.keyframeId);
                if (!keyframe) continue;
                
                // Reprojecter point 3D dans image
                const projected = this.projectPoint3D(mapPoint.position, keyframe.pose);
                
                // Trouver feature correspondante
                const feature = keyframe.features.find(f => f.id === obs.featureId);
                if (!feature) continue;
                
                // Calculer erreur
                const error = [
                    projected[0] - feature.x,
                    projected[1] - feature.y
                ];
                
                errors.push({
                    mapPointId: mapPoint.id,
                    keyframeId: keyframe.id,
                    error: error,
                    errorNorm: Math.sqrt(error[0] * error[0] + error[1] * error[1])
                });
            }
        }
        
        return errors;
    }
    
    /**
     * Projette un point 3D dans l'image
     */
    projectPoint3D(point3D, pose) {
        // TODO: Appliquer transformation de pose puis projection caméra
        const fx = 800, fy = 800, cx = 320, cy = 240;
        
        // Pour simplifier, projection directe (sans transformation de pose)
        const x = (point3D[0] / point3D[2]) * fx + cx;
        const y = (point3D[1] / point3D[2]) * fy + cy;
        
        return [x, y];
    }
    
    /**
     * Calcule gradients pour optimisation
     */
    computeGradients(reprojectionErrors) {
        // TODO: Implémenter calcul gradients (dérivées partielles)
        // Pour l'instant, retourner gradients simulés
        return {
            poseGradients: {},
            pointGradients: {}
        };
    }
    
    /**
     * Met à jour poses et map points selon gradients
     */
    updatePosesAndPoints(gradients) {
        // TODO: Mise à jour selon algorithme Levenberg-Marquardt
        // Pour l'instant, pas de mise à jour
    }
    
    /**
     * Gère la persistance de la map
     */
    saveMap() {
        // TODO: Sauvegarder map dans localStorage ou IndexedDB
        const mapData = {
            keyframes: this.keyframes.map(kf => ({
                id: kf.id,
                pose: kf.pose,
                mapPointIds: kf.mapPointIds,
                timestamp: kf.timestamp
            })),
            mapPoints: this.mapPoints.map(mp => ({
                id: mp.id,
                position: mp.position,
                descriptor: mp.descriptor
            }))
        };
        
        localStorage.setItem('slam_map', JSON.stringify(mapData));
    }
    
    /**
     * Charge la map depuis le stockage
     */
    loadMap() {
        // TODO: Charger map depuis localStorage ou IndexedDB
        const mapDataStr = localStorage.getItem('slam_map');
        if (!mapDataStr) return;
        
        const mapData = JSON.parse(mapDataStr);
        // Restaurer keyframes et map points
    }
}











