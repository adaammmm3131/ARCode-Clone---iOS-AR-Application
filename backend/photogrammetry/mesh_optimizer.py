#!/usr/bin/env python3
"""
Mesh Optimizer avec Blender
Cleanup, retopology, LOD generation, compression Draco
"""

import bpy
import sys
import os
import subprocess
from pathlib import Path
import argparse
from typing import Dict, Optional

# Nettoyer la scène Blender au démarrage
def clear_scene():
    """Nettoie la scène Blender"""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    
    # Supprimer matériaux et textures
    for material in bpy.data.materials:
        bpy.data.materials.remove(material)
    for texture in bpy.data.textures:
        bpy.data.textures.remove(texture)

class BlenderMeshOptimizer:
    def __init__(self, mesh_path: str, output_dir: str):
        """
        Initialise l'optimiseur Blender
        
        Args:
            mesh_path: Chemin vers le mesh (.ply, .obj, .fbx)
            output_dir: Dossier de sortie
        """
        self.mesh_path = Path(mesh_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        if not self.mesh_path.exists():
            raise ValueError(f"Mesh non trouvé: {mesh_path}")
        
        # Nettoyer scène
        clear_scene()
        
    def import_mesh(self) -> str:
        """
        Importe le mesh dans Blender
        
        Returns:
            Nom de l'objet importé
        """
        print(f"Import mesh: {self.mesh_path}")
        
        mesh_ext = self.mesh_path.suffix.lower()
        
        if mesh_ext == '.ply':
            bpy.ops.import_mesh.ply(filepath=str(self.mesh_path))
        elif mesh_ext == '.obj':
            bpy.ops.wm.obj_import(filepath=str(self.mesh_path))
        elif mesh_ext == '.fbx':
            bpy.ops.import_scene.fbx(filepath=str(self.mesh_path))
        else:
            raise ValueError(f"Format non supporté: {mesh_ext}")
        
        # Obtenir objet importé
        obj = bpy.context.selected_objects[0]
        obj.name = "mesh_source"
        
        print(f"Mesh importé: {len(obj.data.vertices)} vertices, {len(obj.data.polygons)} faces")
        return obj.name
    
    def cleanup_mesh(self, obj_name: str) -> Dict:
        """
        Nettoie le mesh (remove doubles, fill holes, etc.)
        
        Args:
            obj_name: Nom de l'objet
            
        Returns:
            Dict avec résultats
        """
        print("Nettoyage mesh...")
        
        obj = bpy.data.objects[obj_name]
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        
        # Mode Edit
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        
        # Remove doubles
        bpy.ops.mesh.remove_doubles(threshold=0.0001)
        
        # Fill holes
        bpy.ops.mesh.fill_holes(sides=0)
        
        # Recalculate normals
        bpy.ops.mesh.normals_make_consistent(inside=False)
        
        # Mode Object
        bpy.ops.object.mode_set(mode='OBJECT')
        
        print(f"Mesh nettoyé: {len(obj.data.vertices)} vertices, {len(obj.data.polygons)} faces")
        
        return {
            'vertices': len(obj.data.vertices),
            'faces': len(obj.data.polygons)
        }
    
    def retopology(self, obj_name: str, target_faces: int = 50000) -> Dict:
        """
        Retopology automatique (simplification intelligente)
        
        Args:
            obj_name: Nom de l'objet
            target_faces: Nombre cible de faces
            
        Returns:
            Dict avec résultats
        """
        print(f"Retopology: {target_faces} faces cibles...")
        
        obj = bpy.data.objects[obj_name]
        bpy.context.view_layer.objects.active = obj
        
        # Decimate modifier (ratio-based)
        current_faces = len(obj.data.polygons)
        ratio = target_faces / current_faces if current_faces > 0 else 0.5
        
        modifier = obj.modifiers.new(name="Decimate", type='DECIMATE')
        modifier.decimate_type = 'COLLAPSE'
        modifier.ratio = ratio
        
        # Appliquer modifier
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier="Decimate")
        
        print(f"Retopology terminé: {len(obj.data.polygons)} faces")
        
        return {
            'faces': len(obj.data.polygons),
            'ratio': ratio
        }
    
    def generate_lod_levels(self, obj_name: str) -> Dict:
        """
        Génère 3 niveaux de LOD (High/Medium/Low)
        
        Args:
            obj_name: Nom de l'objet source
            
        Returns:
            Dict avec chemins des LOD
        """
        print("Génération LOD levels...")
        
        obj = bpy.data.objects[obj_name]
        current_faces = len(obj.data.polygons)
        
        lod_configs = [
            {'name': 'high', 'ratio': 1.0},
            {'name': 'medium', 'ratio': 0.5},
            {'name': 'low', 'ratio': 0.2}
        ]
        
        lod_results = {}
        
        for lod in lod_configs:
            # Dupliquer objet
            obj_dup = obj.copy()
            obj_dup.data = obj.data.copy()
            obj_dup.name = f"mesh_{lod['name']}"
            bpy.context.collection.objects.link(obj_dup)
            
            # Sélectionner duplicate
            bpy.context.view_layer.objects.active = obj_dup
            obj_dup.select_set(True)
            
            # Appliquer decimation si nécessaire
            if lod['ratio'] < 1.0:
                modifier = obj_dup.modifiers.new(name="Decimate", type='DECIMATE')
                modifier.decimate_type = 'COLLAPSE'
                modifier.ratio = lod['ratio']
                bpy.ops.object.modifier_apply(modifier="Decimate")
            
            # Export PLY
            output_path = self.output_dir / f"mesh_{lod['name']}.ply"
            bpy.ops.wm.ply_export(
                filepath=str(output_path),
                export_selected_objects=True
            )
            
            lod_results[lod['name']] = {
                'path': str(output_path),
                'faces': len(obj_dup.data.polygons)
            }
            
            # Supprimer duplicate
            bpy.data.objects.remove(obj_dup)
            obj_dup.select_set(False)
        
        print(f"✅ LOD générés: {len(lod_results)} niveaux")
        return lod_results
    
    def export_glb(self, obj_name: str, output_path: str, compress_draco: bool = True) -> Dict:
        """
        Exporte en GLB avec compression Draco optionnelle
        
        Args:
            obj_name: Nom de l'objet
            output_path: Chemin de sortie .glb
            compress_draco: Utiliser compression Draco
            
        Returns:
            Dict avec résultats
        """
        print(f"Export GLB: {output_path}")
        
        obj = bpy.data.objects[obj_name]
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        
        # Configurer export glTF
        bpy.ops.export_scene.gltf(
            filepath=output_path,
            export_format='GLB',
            export_selected=True,
            export_draco_mesh_compression_enable=compress_draco,
            export_draco_mesh_compression_level=6,
            export_draco_position_quantization=14,
            export_draco_normal_quantization=10,
            export_draco_texcoord_quantization=12,
            export_apply=True
        )
        
        file_size = Path(output_path).stat().st_size / (1024 * 1024)  # MB
        
        print(f"✅ GLB exporté: {file_size:.2f} MB")
        
        return {
            'success': True,
            'path': output_path,
            'size_mb': file_size,
            'draco_compression': compress_draco
        }

def run_blender_script(script_path: str, mesh_path: str, output_dir: str):
    """
    Exécute script Blender en mode headless
    
    Args:
        script_path: Chemin vers script Python
        mesh_path: Chemin mesh
        output_dir: Dossier sortie
    """
    blender_cmd = [
        'blender',
        '--background',
        '--python', script_path,
        '--',
        mesh_path,
        output_dir
    ]
    
    subprocess.run(blender_cmd, check=True)

def main():
    """
    Point d'entrée pour exécution standalone
    Nécessite Blender en mode script
    """
    # Parser arguments depuis Blender
    if '--' in sys.argv:
        argv = sys.argv[sys.argv.index('--') + 1:]
    else:
        argv = sys.argv[1:]
    
    parser = argparse.ArgumentParser(description='Optimise mesh avec Blender')
    parser.add_argument('mesh', help='Chemin mesh')
    parser.add_argument('-o', '--output', default='optimized', help='Dossier sortie')
    parser.add_argument('--lod', action='store_true', help='Générer LOD levels')
    parser.add_argument('--glb', help='Export GLB avec chemin')
    parser.add_argument('--no-draco', action='store_true', help='Désactiver compression Draco')
    
    args = parser.parse_args(argv)
    
    optimizer = BlenderMeshOptimizer(args.mesh, args.output)
    
    try:
        # Import
        obj_name = optimizer.import_mesh()
        
        # Cleanup
        cleanup_result = optimizer.cleanup_mesh(obj_name)
        
        # Retopology optionnel
        if args.lod:
            lod_results = optimizer.generate_lod_levels(obj_name)
            print(f"LOD générés: {lod_results}")
        
        # Export GLB
        if args.glb:
            glb_result = optimizer.export_glb(
                obj_name,
                args.glb,
                compress_draco=not args.no_draco
            )
            print(f"GLB exporté: {glb_result}")
        
        print("\n✅ Optimisation terminée!")
        return 0
    except Exception as e:
        print(f"❌ Erreur: {e}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    main()










