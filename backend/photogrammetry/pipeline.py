#!/usr/bin/env python3
"""
Pipeline Photogrammétrie Complet
Orchestre toutes les étapes: extraction → preprocessing → COLMAP → mesh → export
"""

import sys
from pathlib import Path
import argparse
import json
from datetime import datetime

from frame_extractor import FrameExtractor
from preprocessor import ImagePreprocessor
from colmap_pipeline import COLMAPPipeline
from mesh_generator import MeshGenerator

class PhotogrammetryPipeline:
    def __init__(self, workspace_path: str):
        """
        Initialise le pipeline complet
        
        Args:
            workspace_path: Chemin workspace principal
        """
        self.workspace = Path(workspace_path)
        self.workspace.mkdir(parents=True, exist_ok=True)
        
        # Dossiers de travail
        self.frames_dir = self.workspace / "frames"
        self.preprocessed_dir = self.workspace / "preprocessed"
        self.colmap_workspace = self.workspace / "colmap"
        self.mesh_dir = self.workspace / "mesh"
        self.export_dir = self.workspace / "export"
        
    def run_full_pipeline(self, video_path: str, extract_fps: int = 30) -> dict:
        """
        Exécute le pipeline complet
        
        Args:
            video_path: Chemin vers la vidéo
            extract_fps: FPS pour extraction frames
            
        Returns:
            Dict avec résultats de toutes les étapes
        """
        print("=" * 60)
        print("PIPELINE PHOTOGRAMMÉTRIE COMPLET")
        print("=" * 60)
        print(f"Workspace: {self.workspace}")
        print(f"Vidéo: {video_path}\n")
        
        results = {
            'timestamp': datetime.now().isoformat(),
            'video_path': video_path,
            'workspace': str(self.workspace),
            'stages': {}
        }
        
        try:
            # Étape 1: Extraction frames
            print("\n" + "=" * 60)
            print("ÉTAPE 1: EXTRACTION FRAMES")
            print("=" * 60)
            extractor = FrameExtractor(video_path, str(self.frames_dir), extract_fps)
            frames = extractor.extract_frames()
            results['stages']['frame_extraction'] = {
                'success': True,
                'frames_count': len(frames),
                'frames_dir': str(self.frames_dir)
            }
            
            # Étape 2: Preprocessing
            print("\n" + "=" * 60)
            print("ÉTAPE 2: PRÉTRAITEMENT")
            print("=" * 60)
            preprocessor = ImagePreprocessor(str(self.frames_dir), str(self.preprocessed_dir))
            preprocessed = preprocessor.preprocess_images()
            results['stages']['preprocessing'] = {
                'success': True,
                'images_count': len(preprocessed),
                'output_dir': str(self.preprocessed_dir)
            }
            
            # Étape 3: COLMAP SfM
            print("\n" + "=" * 60)
            print("ÉTAPE 3: COLMAP STRUCTURE-FROM-MOTION")
            print("=" * 60)
            colmap = COLMAPPipeline(str(self.colmap_workspace))
            sfm_results = colmap.run_sfm_pipeline(str(self.preprocessed_dir))
            results['stages']['colmap_sfm'] = sfm_results
            
            if not all(r.get('success') for r in sfm_results.values() if isinstance(r, dict)):
                raise Exception("Échec pipeline COLMAP SfM")
            
            # Étape 4: COLMAP Dense
            print("\n" + "=" * 60)
            print("ÉTAPE 4: COLMAP RECONSTRUCTION DENSE")
            print("=" * 60)
            dense_results = colmap.run_dense_reconstruction()
            results['stages']['colmap_dense'] = dense_results
            
            if not dense_results['stereo_fusion'].get('success'):
                raise Exception("Échec reconstruction dense")
            
            point_cloud_path = dense_results['stereo_fusion'].get('point_cloud')
            
            # Étape 5: Génération Mesh
            print("\n" + "=" * 60)
            print("ÉTAPE 5: GÉNÉRATION MESH")
            print("=" * 60)
            mesh_gen = MeshGenerator(point_cloud_path, str(self.mesh_dir))
            mesh_results = mesh_gen.generate_mesh_poisson(depth=9)
            results['stages']['mesh_generation'] = mesh_results
            
            if not mesh_results.get('success'):
                raise Exception("Échec génération mesh")
            
            # Étape 6: Simplification mesh (LOD)
            print("\n" + "=" * 60)
            print("ÉTAPE 6: SIMPLIFICATION MESH (LOD)")
            print("=" * 60)
            
            lod_levels = [
                {'name': 'high', 'triangles': 100000},
                {'name': 'medium', 'triangles': 50000},
                {'name': 'low', 'triangles': 10000}
            ]
            
            lod_results = {}
            for lod in lod_levels:
                result = mesh_gen.simplify_mesh(mesh_results['mesh_path'], lod['triangles'])
                lod_results[lod['name']] = result
            
            results['stages']['mesh_lod'] = lod_results
            
            # Résumé final
            print("\n" + "=" * 60)
            print("✅ PIPELINE TERMINÉ AVEC SUCCÈS!")
            print("=" * 60)
            print(f"Frames extraites: {len(frames)}")
            print(f"Point cloud: {point_cloud_path}")
            print(f"Mesh principal: {mesh_results['mesh_path']}")
            print(f"LOD générés: {len(lod_results)} niveaux")
            
            results['success'] = True
            return results
            
        except Exception as e:
            print(f"\n❌ ERREUR: {e}", file=sys.stderr)
            results['success'] = False
            results['error'] = str(e)
            return results

def main():
    parser = argparse.ArgumentParser(description='Pipeline photogrammétrie complet')
    parser.add_argument('video', help='Chemin vers la vidéo')
    parser.add_argument('-w', '--workspace', required=True, help='Workspace de travail')
    parser.add_argument('--fps', type=int, default=30, help='FPS extraction (défaut: 30)')
    parser.add_argument('-o', '--output', help='Fichier JSON de sortie avec résultats')
    
    args = parser.parse_args()
    
    pipeline = PhotogrammetryPipeline(args.workspace)
    
    results = pipeline.run_full_pipeline(args.video, args.fps)
    
    # Sauvegarder résultats
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(results, f, indent=2)
        print(f"\n📄 Résultats sauvegardés: {args.output}")
    
    return 0 if results['success'] else 1

if __name__ == '__main__':
    sys.exit(main())










