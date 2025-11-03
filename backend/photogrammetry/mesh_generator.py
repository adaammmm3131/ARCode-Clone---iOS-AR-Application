#!/usr/bin/env python3
"""
Mesh Generator pour Photogrammétrie
Génère mesh depuis point cloud avec Poisson reconstruction
"""

import numpy as np
import subprocess
import sys
from pathlib import Path
from typing import Optional, Dict
import json

try:
    import open3d as o3d
except ImportError:
    print("⚠️  Open3D non installé. Installation requise: pip install open3d")
    o3d = None

class MeshGenerator:
    def __init__(self, point_cloud_path: str, output_dir: str):
        """
        Initialise le générateur de mesh
        
        Args:
            point_cloud_path: Chemin vers le point cloud (.ply)
            output_dir: Dossier de sortie
        """
        self.point_cloud_path = Path(point_cloud_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        if not self.point_cloud_path.exists():
            raise ValueError(f"Point cloud non trouvé: {point_cloud_path}")
    
    def generate_mesh_poisson(self, depth: int = 9, scale: float = 1.1) -> Dict:
        """
        Génère mesh avec Poisson surface reconstruction
        
        Args:
            depth: Profondeur de l'octree
            scale: Scale pour Poisson
            
        Returns:
            Dict avec résultats
        """
        if o3d is None:
            return {'success': False, 'error': 'Open3D non disponible'}
        
        print(f"Génération mesh Poisson depuis {self.point_cloud_path}...")
        
        try:
            # Charger point cloud
            pcd = o3d.io.read_point_cloud(str(self.point_cloud_path))
            
            if len(pcd.points) == 0:
                return {'success': False, 'error': 'Point cloud vide'}
            
            print(f"Point cloud chargé: {len(pcd.points)} points")
            
            # Estimer normales si absentes
            if not pcd.has_normals():
                print("Estimation des normales...")
                pcd.estimate_normals()
                pcd.orient_normals_consistent_tangent_plane(100)
            
            # Poisson reconstruction
            print(f"Reconstruction Poisson (depth={depth})...")
            mesh, densities = o3d.geometry.TriangleMesh.create_from_point_cloud_poisson(
                pcd, depth=depth, scale=scale, linear_fit=False
            )
            
            # Filtrer mesh selon densité
            vertices_to_remove = densities < np.quantile(densities, 0.01)
            mesh.remove_vertices_by_mask(vertices_to_remove)
            
            print(f"Mesh généré: {len(mesh.vertices)} vertices, {len(mesh.triangles)} triangles")
            
            # Sauvegarder mesh
            output_mesh = self.output_dir / "mesh_poisson.ply"
            o3d.io.write_triangle_mesh(str(output_mesh), mesh)
            
            return {
                'success': True,
                'mesh_path': str(output_mesh),
                'vertices': len(mesh.vertices),
                'triangles': len(mesh.triangles)
            }
            
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def simplify_mesh(self, mesh_path: str, target_triangles: int = 50000) -> Dict:
        """
        Simplifie le mesh (decimation)
        
        Args:
            mesh_path: Chemin vers le mesh
            target_triangles: Nombre cible de triangles
            
        Returns:
            Dict avec résultats
        """
        if o3d is None:
            return {'success': False, 'error': 'Open3D non disponible'}
        
        print(f"Simplification mesh: {target_triangles} triangles cibles...")
        
        try:
            mesh = o3d.io.read_triangle_mesh(mesh_path)
            original_triangles = len(mesh.triangles)
            
            # Quadric decimation
            mesh = mesh.simplify_quadric_decimation(target_number_of_triangles=target_triangles)
            
            print(f"Simplifié: {original_triangles} → {len(mesh.triangles)} triangles")
            
            # Sauvegarder
            output_mesh = self.output_dir / "mesh_simplified.ply"
            o3d.io.write_triangle_mesh(str(output_mesh), mesh)
            
            return {
                'success': True,
                'mesh_path': str(output_mesh),
                'triangles': len(mesh.triangles)
            }
            
        except Exception as e:
            return {'success': False, 'error': str(e)}

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Génère mesh depuis point cloud')
    parser.add_argument('point_cloud', help='Chemin vers point cloud .ply')
    parser.add_argument('-o', '--output', default='mesh', help='Dossier de sortie')
    parser.add_argument('--poisson-depth', type=int, default=9, help='Profondeur Poisson')
    parser.add_argument('--simplify', type=int, help='Simplifier à N triangles')
    
    args = parser.parse_args()
    
    generator = MeshGenerator(args.point_cloud, args.output)
    
    try:
        # Génération mesh
        result = generator.generate_mesh_poisson(depth=args.poisson_depth)
        
        if not result['success']:
            print(f"❌ Erreur: {result.get('error')}", file=sys.stderr)
            return 1
        
        print(f"✅ Mesh généré: {result['mesh_path']}")
        
        # Simplification optionnelle
        if args.simplify:
            simplify_result = generator.simplify_mesh(result['mesh_path'], args.simplify)
            if simplify_result['success']:
                print(f"✅ Mesh simplifié: {simplify_result['mesh_path']}")
        
        return 0
    except Exception as e:
        print(f"❌ Erreur: {e}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())










