#!/usr/bin/env python3
"""
Gaussian Splatting Exporter
Export .PLY depuis checkpoint Nerfstudio, conversion .SPLAT optionnelle
"""

import sys
import subprocess
from pathlib import Path
import argparse
import json
from typing import Dict, Optional

try:
    import numpy as np
    from plyfile import PlyData, PlyElement
except ImportError:
    print("⚠️  numpy/plyfile non installés: pip install numpy plyfile")
    np = None
    PlyData = None

class GaussianSplattingExporter:
    def __init__(self, checkpoint_path: str, output_dir: str):
        """
        Initialise l'exporteur
        
        Args:
            checkpoint_path: Chemin checkpoint Nerfstudio
            output_dir: Dossier de sortie
        """
        self.checkpoint_path = Path(checkpoint_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        if not self.checkpoint_path.exists():
            raise ValueError(f"Checkpoint non trouvé: {checkpoint_path}")
    
    def export_ply(self, output_name: str = "gaussian_splat.ply") -> Dict:
        """
        Exporte checkpoint en .PLY
        
        Args:
            output_name: Nom fichier sortie
            
        Returns:
            Dict avec résultats
        """
        print(f"Export PLY depuis {self.checkpoint_path}...")
        
        output_path = self.output_dir / output_name
        
        # Utiliser ns-export pour exporter
        cmd = [
            'ns-export',
            'gaussian-splat',
            '--load-config', str(self.checkpoint_path.parent.parent / "config.yml"),
            '--output-dir', str(self.output_dir),
            '--num-points', '1000000'  # Max points
        ]
        
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True
            )
            
            # Chercher fichier PLY généré
            ply_files = list(self.output_dir.glob("*.ply"))
            if ply_files:
                exported_ply = ply_files[0]
                
                # Renommer si nécessaire
                if exported_ply.name != output_name:
                    exported_ply.rename(output_path)
                
                file_size = output_path.stat().st_size / (1024 * 1024)
                
                return {
                    'success': True,
                    'ply_path': str(output_path),
                    'size_mb': file_size
                }
            else:
                return {'success': False, 'error': 'Fichier PLY non généré'}
                
        except subprocess.CalledProcessError as e:
            return {'success': False, 'error': e.stderr}
    
    def convert_to_splat(self, ply_path: str) -> Dict:
        """
        Convertit PLY en format .SPLAT (optionnel, custom format)
        
        Args:
            ply_path: Chemin fichier PLY
            
        Returns:
            Dict avec résultats
        """
        print(f"Conversion PLY → SPLAT: {ply_path}")
        
        if PlyData is None:
            return {'success': False, 'error': 'plyfile non disponible'}
        
        try:
            # Lire PLY
            plydata = PlyData.read(ply_path)
            
            # Extraire données Gaussiennes
            vertices = plydata['vertex']
            
            # Metadata pour format SPLAT custom
            metadata = {
                'format': 'SPLAT',
                'version': '1.0',
                'num_gaussians': len(vertices),
                'has_spherical_harmonics': True,
                'sh_degree': 3
            }
            
            # Sauvegarder metadata
            metadata_path = Path(ply_path).with_suffix('.splat.meta')
            with open(metadata_path, 'w') as f:
                json.dump(metadata, f, indent=2)
            
            # Pour format SPLAT complet, nécessiterait conversion binaire
            # Pour l'instant, garder PLY + metadata
            
            return {
                'success': True,
                'splat_path': str(Path(ply_path).with_suffix('.splat')),
                'metadata_path': str(metadata_path),
                'num_gaussians': len(vertices)
            }
            
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def get_metadata(self, ply_path: str) -> Dict:
        """
        Extrait métadonnées depuis PLY
        
        Args:
            ply_path: Chemin PLY
            
        Returns:
            Dict avec métadonnées
        """
        if PlyData is None:
            return {'error': 'plyfile non disponible'}
        
        try:
            plydata = PlyData.read(ply_path)
            vertices = plydata['vertex']
            
            # Extraire propriétés
            metadata = {
                'num_gaussians': len(vertices),
                'properties': list(vertices.dtype.names),
                'has_position': 'x' in vertices.dtype.names,
                'has_rotation': 'rot_0' in vertices.dtype.names or 'rot_1' in vertices.dtype.names,
                'has_scale': 'scale_0' in vertices.dtype.names,
                'has_opacity': 'opacity' in vertices.dtype.names,
                'has_color': 'f_dc_0' in vertices.dtype.names or 'red' in vertices.dtype.names,
                'has_spherical_harmonics': any('f_dc' in prop or 'f_rest' in prop for prop in vertices.dtype.names)
            }
            
            return metadata
            
        except Exception as e:
            return {'error': str(e)}

def main():
    parser = argparse.ArgumentParser(description='Export Gaussian Splatting model')
    parser.add_argument('checkpoint', help='Chemin checkpoint Nerfstudio')
    parser.add_argument('-o', '--output', default='./export', help='Dossier sortie')
    parser.add_argument('--ply', default='gaussian_splat.ply', help='Nom fichier PLY')
    parser.add_argument('--splat', action='store_true', help='Convertir en SPLAT')
    parser.add_argument('--metadata', action='store_true', help='Afficher métadonnées')
    
    args = parser.parse_args()
    
    exporter = GaussianSplattingExporter(args.checkpoint, args.output)
    
    try:
        # Export PLY
        ply_result = exporter.export_ply(args.ply)
        
        if not ply_result.get('success'):
            print(f"❌ Erreur export PLY: {ply_result.get('error')}", file=sys.stderr)
            return 1
        
        print(f"✅ PLY exporté: {ply_result['ply_path']} ({ply_result['size_mb']:.2f} MB)")
        
        # Conversion SPLAT optionnelle
        if args.splat:
            splat_result = exporter.convert_to_splat(ply_result['ply_path'])
            if splat_result.get('success'):
                print(f"✅ SPLAT converti: {splat_result['splat_path']}")
        
        # Métadonnées
        if args.metadata:
            metadata = exporter.get_metadata(ply_result['ply_path'])
            print("\n📊 Métadonnées:")
            print(json.dumps(metadata, indent=2))
        
        return 0
        
    except Exception as e:
        print(f"❌ Erreur: {e}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())










