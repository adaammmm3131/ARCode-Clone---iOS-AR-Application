#!/usr/bin/env python3
"""
Format Converter pour Photogrammétrie
Conversion PLY/OBJ → GLB/USDZ pour AR
"""

import sys
import subprocess
from pathlib import Path
import argparse
import json
from typing import Dict, Optional

try:
    import trimesh
except ImportError:
    print("⚠️  Trimesh non installé: pip install trimesh")
    trimesh = None

class FormatConverter:
    def __init__(self, input_path: str, output_dir: str):
        """
        Initialise le convertisseur
        
        Args:
            input_path: Chemin vers mesh source
            output_dir: Dossier de sortie
        """
        self.input_path = Path(input_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        if not self.input_path.exists():
            raise ValueError(f"Fichier non trouvé: {input_path}")
    
    def convert_to_glb(self, draco: bool = True) -> Dict:
        """
        Convertit mesh en GLB (glTF 2.0 binary)
        
        Args:
            draco: Utiliser compression Draco
            
        Returns:
            Dict avec résultats
        """
        print(f"Conversion GLB: {self.input_path}")
        
        output_path = self.output_dir / f"{self.input_path.stem}.glb"
        
        if trimesh:
            try:
                # Charger mesh avec trimesh
                mesh = trimesh.load(str(self.input_path))
                
                # Export GLB
                if draco:
                    # TODO: Compression Draco avec gltf-transform ou gltfpack
                    # Pour l'instant, export standard
                    mesh.export(str(output_path), file_type='glb')
                else:
                    mesh.export(str(output_path), file_type='glb')
                
                file_size = output_path.stat().st_size / (1024 * 1024)
                
                return {
                    'success': True,
                    'path': str(output_path),
                    'size_mb': file_size,
                    'format': 'GLB'
                }
            except Exception as e:
                return {'success': False, 'error': str(e)}
        else:
            # Utiliser Blender via command line
            return self.convert_with_blender('glb', output_path, draco)
    
    def convert_to_usdz(self) -> Dict:
        """
        Convertit mesh en USDZ (Apple AR Quick Look)
        
        Returns:
            Dict avec résultats
        """
        print(f"Conversion USDZ: {self.input_path}")
        
        # USDZ nécessite usdzip tool (Xcode Command Line Tools)
        # Alternative: utiliser Reality Converter ou usd-core
        
        output_path = self.output_dir / f"{self.input_path.stem}.usdz"
        
        # Méthode 1: Utiliser usdzip (macOS seulement)
        try:
            # Convertir d'abord en USD
            usd_path = self.convert_to_usd()
            if not usd_path.get('success'):
                return usd_path
            
            # Créer USDZ avec usdzip
            usdzip_cmd = ['usdzip', usd_path['path'], str(output_path)]
            result = subprocess.run(usdzip_cmd, capture_output=True, text=True, check=True)
            
            file_size = output_path.stat().st_size / (1024 * 1024)
            
            return {
                'success': True,
                'path': str(output_path),
                'size_mb': file_size,
                'format': 'USDZ'
            }
            
        except FileNotFoundError:
            return {
                'success': False,
                'error': 'usdzip tool non trouvé (nécessite Xcode Command Line Tools)'
            }
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def convert_to_usd(self) -> Dict:
        """
        Convertit en USD (intermédiaire pour USDZ)
        
        Returns:
            Dict avec résultats
        """
        output_path = self.output_dir / f"{self.input_path.stem}.usd"
        
        # TODO: Utiliser usd-core ou Blender pour conversion
        # Pour l'instant, retourner erreur
        return {
            'success': False,
            'error': 'Conversion USD non implémentée (nécessite usd-core)'
        }
    
    def convert_with_blender(self, format: str, output_path: Path, draco: bool = False) -> Dict:
        """
        Utilise Blender pour conversion
        
        Args:
            format: Format cible (glb, usdz)
            output_path: Chemin sortie
            draco: Compression Draco
            
        Returns:
            Dict avec résultats
        """
        # Créer script Blender temporaire
        script = self.output_dir / "blender_convert.py"
        script.write_text(f"""
import bpy
import sys

# Nettoyer scène
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# Importer mesh
mesh_path = "{self.input_path}"
if mesh_path.endswith('.ply'):
    bpy.ops.import_mesh.ply(filepath=mesh_path)
elif mesh_path.endswith('.obj'):
    bpy.ops.wm.obj_import(filepath=mesh_path)

obj = bpy.context.selected_objects[0]

# Export
output_path = "{output_path}"
if output_path.endswith('.glb'):
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        export_format='GLB',
        export_selected=True,
        export_draco_mesh_compression_enable={str(draco).lower()}
    )
""")
        
        try:
            blender_cmd = [
                'blender',
                '--background',
                '--python', str(script),
                '--quiet'
            ]
            
            result = subprocess.run(
                blender_cmd,
                capture_output=True,
                text=True,
                check=True
            )
            
            if output_path.exists():
                file_size = output_path.stat().st_size / (1024 * 1024)
                return {
                    'success': True,
                    'path': str(output_path),
                    'size_mb': file_size
                }
            else:
                return {'success': False, 'error': 'Export échoué'}
                
        except subprocess.CalledProcessError as e:
            return {'success': False, 'error': e.stderr}
        finally:
            if script.exists():
                script.unlink()
    
    def validate_glb(self, glb_path: str) -> Dict:
        """
        Valide fichier GLB
        
        Args:
            glb_path: Chemin GLB
            
        Returns:
            Dict avec résultats validation
        """
        print(f"Validation GLB: {glb_path}")
        
        # TODO: Utiliser gltf-validator ou pygltf
        # Vérifications basiques
        glb_file = Path(glb_path)
        
        if not glb_file.exists():
            return {'valid': False, 'error': 'Fichier non trouvé'}
        
        if glb_file.suffix != '.glb':
            return {'valid': False, 'error': 'Extension incorrecte'}
        
        # Vérifier taille
        size_mb = glb_file.stat().st_size / (1024 * 1024)
        if size_mb > 50:  # Max 50MB pour AR
            return {'valid': False, 'error': f'Taille trop grande: {size_mb:.2f}MB'}
        
        # TODO: Vérifier structure GLB (magic number, chunks, etc.)
        
        return {
            'valid': True,
            'size_mb': size_mb,
            'path': str(glb_path)
        }

def main():
    parser = argparse.ArgumentParser(description='Convertit mesh vers formats AR')
    parser.add_argument('input', help='Chemin mesh source (.ply, .obj)')
    parser.add_argument('-o', '--output', default='converted', help='Dossier sortie')
    parser.add_argument('--glb', action='store_true', help='Convertir en GLB')
    parser.add_argument('--usdz', action='store_true', help='Convertir en USDZ')
    parser.add_argument('--validate', action='store_true', help='Valider fichiers générés')
    parser.add_argument('--no-draco', action='store_true', help='Désactiver compression Draco')
    
    args = parser.parse_args()
    
    converter = FormatConverter(args.input, args.output)
    results = {}
    
    try:
        if args.glb:
            glb_result = converter.convert_to_glb(draco=not args.no_draco)
            results['glb'] = glb_result
            
            if args.validate and glb_result.get('success'):
                validation = converter.validate_glb(glb_result['path'])
                results['glb_validation'] = validation
        
        if args.usdz:
            usdz_result = converter.convert_to_usdz()
            results['usdz'] = usdz_result
        
        print("\n📊 Résultats:")
        print(json.dumps(results, indent=2))
        
        return 0
    except Exception as e:
        print(f"❌ Erreur: {e}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())










