#!/usr/bin/env python3
"""
Pipeline COLMAP pour Photogrammétrie
Structure-from-Motion (SfM) et reconstruction dense
"""

import subprocess
import os
import sys
from pathlib import Path
from typing import Optional, Dict
import json

class COLMAPPipeline:
    def __init__(self, workspace_path: str):
        """
        Initialise le pipeline COLMAP
        
        Args:
            workspace_path: Chemin vers le workspace COLMAP
        """
        self.workspace_path = Path(workspace_path)
        self.workspace_path.mkdir(parents=True, exist_ok=True)
        
        # Dossiers COLMAP
        self.images_dir = self.workspace_path / "images"
        self.database_path = self.workspace_path / "database.db"
        self.sparse_dir = self.workspace_path / "sparse"
        self.dense_dir = self.workspace_path / "dense"
        
    def run_sfm_pipeline(self, images_dir: str) -> Dict:
        """
        Exécute le pipeline SfM complet
        
        Args:
            images_dir: Dossier contenant les images
            
        Returns:
            Dict avec résultats et statistiques
        """
        print("=" * 60)
        print("Pipeline COLMAP SfM")
        print("=" * 60)
        
        self.images_dir = Path(images_dir)
        self.sparse_dir.mkdir(parents=True, exist_ok=True)
        
        results = {
            'feature_extraction': None,
            'feature_matching': None,
            'sparse_reconstruction': None,
            'bundle_adjustment': None
        }
        
        # 1. Feature extraction
        print("\n[1/4] Extraction des features...")
        results['feature_extraction'] = self.feature_extraction()
        
        # 2. Feature matching
        print("\n[2/4] Matching des features...")
        results['feature_matching'] = self.feature_matching()
        
        # 3. Sparse reconstruction
        print("\n[3/4] Reconstruction sparse...")
        results['sparse_reconstruction'] = self.sparse_reconstruction()
        
        # 4. Bundle adjustment
        print("\n[4/4] Bundle adjustment...")
        results['bundle_adjustment'] = self.bundle_adjustment()
        
        print("\n✅ Pipeline SfM terminé!")
        return results
    
    def feature_extraction(self) -> Dict:
        """Extrait les features avec COLMAP"""
        cmd = [
            'colmap', 'feature_extractor',
            '--database_path', str(self.database_path),
            '--image_path', str(self.images_dir),
            '--ImageReader.camera_model', 'PINHOLE',
            '--ImageReader.single_camera', '1',
            '--SiftExtraction.use_gpu', '1'
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return {'success': True, 'output': result.stdout}
        except subprocess.CalledProcessError as e:
            return {'success': False, 'error': e.stderr}
    
    def feature_matching(self) -> Dict:
        """Match les features entre images"""
        cmd = [
            'colmap', 'exhaustive_matcher',
            '--database_path', str(self.database_path),
            '--SiftMatching.use_gpu', '1'
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return {'success': True, 'output': result.stdout}
        except subprocess.CalledProcessError as e:
            return {'success': False, 'error': e.stderr}
    
    def sparse_reconstruction(self) -> Dict:
        """Reconstruction sparse"""
        sparse_model_dir = self.sparse_dir / "0"
        sparse_model_dir.mkdir(parents=True, exist_ok=True)
        
        cmd = [
            'colmap', 'mapper',
            '--database_path', str(self.database_path),
            '--image_path', str(self.images_dir),
            '--output_path', str(self.sparse_dir)
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return {'success': True, 'model_path': str(sparse_model_dir)}
        except subprocess.CalledProcessError as e:
            return {'success': False, 'error': e.stderr}
    
    def bundle_adjustment(self, model_path: Optional[str] = None) -> Dict:
        """Bundle adjustment pour optimisation"""
        if model_path is None:
            model_path = self.sparse_dir / "0"
        else:
            model_path = Path(model_path)
        
        cmd = [
            'colmap', 'bundle_adjuster',
            '--input_path', str(model_path),
            '--output_path', str(model_path),
            '--BundleAdjustment.refine_focal_length', '1',
            '--BundleAdjustment.refine_principal_point', '0',
            '--BundleAdjustment.refine_extra_params', '1'
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return {'success': True, 'output': result.stdout}
        except subprocess.CalledProcessError as e:
            return {'success': False, 'error': e.stderr}
    
    def run_dense_reconstruction(self, model_path: Optional[str] = None) -> Dict:
        """
        Reconstruction dense (point cloud)
        
        Args:
            model_path: Chemin vers le modèle sparse
            
        Returns:
            Dict avec résultats
        """
        print("=" * 60)
        print("Pipeline COLMAP Dense Reconstruction")
        print("=" * 60)
        
        if model_path is None:
            model_path = self.sparse_dir / "0"
        else:
            model_path = Path(model_path)
        
        self.dense_dir.mkdir(parents=True, exist_ok=True)
        
        results = {
            'image_undistorter': None,
            'patch_match_stereo': None,
            'stereo_fusion': None
        }
        
        # 1. Image undistorter
        print("\n[1/3] Undistortion des images...")
        results['image_undistorter'] = self.image_undistorter(model_path)
        
        # 2. Patch Match Stereo
        print("\n[2/3] Patch Match Stereo...")
        results['patch_match_stereo'] = self.patch_match_stereo()
        
        # 3. Stereo Fusion
        print("\n[3/3] Stereo Fusion...")
        results['stereo_fusion'] = self.stereo_fusion()
        
        print("\n✅ Reconstruction dense terminée!")
        return results
    
    def image_undistorter(self, model_path: Path) -> Dict:
        """Undistort images"""
        dense_images_dir = self.dense_dir / "images"
        
        cmd = [
            'colmap', 'image_undistorter',
            '--image_path', str(self.images_dir),
            '--input_path', str(model_path),
            '--output_path', str(self.dense_dir),
            '--output_type', 'COLMAP'
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return {'success': True, 'undistorted_images': str(dense_images_dir)}
        except subprocess.CalledProcessError as e:
            return {'success': False, 'error': e.stderr}
    
    def patch_match_stereo(self) -> Dict:
        """Patch Match Stereo pour depth maps"""
        cmd = [
            'colmap', 'patch_match_stereo',
            '--workspace_path', str(self.dense_dir),
            '--workspace_format', 'COLMAP',
            '--PatchMatchStereo.geom_consistency', '1'
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return {'success': True, 'output': result.stdout}
        except subprocess.CalledProcessError as e:
            return {'success': False, 'error': e.stderr}
    
    def stereo_fusion(self, output_ply: Optional[str] = None) -> Dict:
        """Fusion stereo pour point cloud dense"""
        if output_ply is None:
            output_ply = self.dense_dir / "fused.ply"
        else:
            output_ply = Path(output_ply)
        
        cmd = [
            'colmap', 'stereo_fusion',
            '--workspace_path', str(self.dense_dir),
            '--workspace_format', 'COLMAP',
            '--input_type', 'geometric',
            '--output_path', str(output_ply)
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return {'success': True, 'point_cloud': str(output_ply)}
        except subprocess.CalledProcessError as e:
            return {'success': False, 'error': e.stderr}

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Pipeline COLMAP pour photogrammétrie')
    parser.add_argument('workspace', help='Chemin workspace COLMAP')
    parser.add_argument('images', help='Dossier contenant les images')
    parser.add_argument('--sfm', action='store_true', help='Exécuter pipeline SfM')
    parser.add_argument('--dense', action='store_true', help='Exécuter reconstruction dense')
    parser.add_argument('--model', help='Chemin modèle sparse (pour dense reconstruction)')
    
    args = parser.parse_args()
    
    pipeline = COLMAPPipeline(args.workspace)
    
    try:
        if args.sfm:
            results = pipeline.run_sfm_pipeline(args.images)
            print("\n📊 Résultats SfM:")
            print(json.dumps(results, indent=2))
        
        if args.dense:
            results = pipeline.run_dense_reconstruction(args.model)
            print("\n📊 Résultats Dense:")
            print(json.dumps(results, indent=2))
        
        return 0
    except Exception as e:
        print(f"❌ Erreur: {e}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())










