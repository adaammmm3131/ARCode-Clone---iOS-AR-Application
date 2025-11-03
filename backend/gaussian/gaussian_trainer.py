#!/usr/bin/env python3
"""
Gaussian Splatting Trainer
Wrapper autour de Nerfstudio pour training automatique
"""

import subprocess
import sys
import os
import json
import time
from pathlib import Path
from typing import Dict, Optional
import argparse
from datetime import datetime

class GaussianSplattingTrainer:
    def __init__(self, dataset_path: str, output_dir: str):
        """
        Initialise le trainer
        
        Args:
            dataset_path: Chemin vers dataset images
            output_dir: Dossier de sortie pour checkpoints/results
        """
        self.dataset_path = Path(dataset_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        if not self.dataset_path.exists():
            raise ValueError(f"Dataset non trouvé: {dataset_path}")
        
        # Vérifier nombre d'images
        image_extensions = {'.jpg', '.jpeg', '.png', '.JPG', '.JPEG', '.PNG'}
        self.images = [f for f in self.dataset_path.iterdir() 
                      if f.suffix in image_extensions]
        
        if len(self.images) < 100:
            raise ValueError(f"Pas assez d'images: {len(self.images)}/100 minimum requis")
        
        print(f"Dataset: {len(self.images)} images trouvées")
    
    def prepare_dataset(self) -> Path:
        """
        Prépare dataset au format Nerfstudio
        
        Returns:
            Chemin dataset préparé
        """
        print("Préparation dataset pour Nerfstudio...")
        
        # Nerfstudio attend structure spécifique
        ns_dataset = self.output_dir / "dataset"
        ns_dataset.mkdir(parents=True, exist_ok=True)
        
        images_dir = ns_dataset / "images"
        images_dir.mkdir(exist_ok=True)
        
        # Copier images
        import shutil
        for i, img in enumerate(sorted(self.images)):
            shutil.copy(img, images_dir / f"{i:06d}{img.suffix}")
        
        print(f"Dataset préparé: {images_dir}")
        return ns_dataset
    
    def train(self, max_steps: int = 30000, checkpoint_interval: int = 5000) -> Dict:
        """
        Lance training Gaussian Splatting
        
        Args:
            max_steps: Nombre max d'itérations
            checkpoint_interval: Intervalle checkpoints
            
        Returns:
            Dict avec résultats training
        """
        print("=" * 60)
        print("TRAINING GAUSSIAN SPLATTING")
        print("=" * 60)
        
        # Préparer dataset
        dataset = self.prepare_dataset()
        
        # Configurer training
        config_path = self.output_dir / "config.json"
        config = {
            "method_name": "gaussian-splatting",
            "steps_per_eval_image": 100,
            "steps_per_eval_batch": 100,
            "steps_per_save": checkpoint_interval,
            "steps_per_eval_all_images": 1000,
            "max_num_iterations": max_steps,
            "save_only_latest_checkpoint": False,
            "log_gradients": False,
            "model": {
                "num_random": 50000,
                "sh_degree": 3
            }
        }
        
        with open(config_path, 'w') as f:
            json.dump(config, f, indent=2)
        
        # Commande training
        cmd = [
            'ns-train',
            'gaussian-splatting',
            '--data', str(dataset),
            '--output-dir', str(self.output_dir),
            '--max-num-iterations', str(max_steps),
            '--steps-per-save', str(checkpoint_interval),
            '--viewer.quit-on-train-completion', 'True'
        ]
        
        print(f"Lancement training: {' '.join(cmd)}")
        
        start_time = time.time()
        
        try:
            # Exécuter training
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=False
            )
            
            training_time = time.time() - start_time
            
            # Chercher checkpoints
            checkpoints = list(self.output_dir.glob("**/checkpoints/*.ckpt"))
            
            # Trouver meilleur checkpoint (dernier par défaut)
            latest_checkpoint = max(checkpoints, key=lambda p: p.stat().st_mtime) if checkpoints else None
            
            return {
                'success': result.returncode == 0,
                'training_time': training_time,
                'checkpoints': [str(c) for c in checkpoints],
                'latest_checkpoint': str(latest_checkpoint) if latest_checkpoint else None,
                'stdout': result.stdout,
                'stderr': result.stderr,
                'return_code': result.returncode
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'training_time': time.time() - start_time
            }
    
    def get_training_logs(self) -> Dict:
        """
        Lit logs de training
        
        Returns:
            Dict avec métriques training
        """
        # Chercher fichier logs
        log_files = list(self.output_dir.glob("**/*.log"))
        
        if not log_files:
            return {'error': 'Aucun log trouvé'}
        
        latest_log = max(log_files, key=lambda p: p.stat().st_mtime)
        
        # TODO: Parser logs pour extraire métriques (loss, PSNR, etc.)
        with open(latest_log, 'r') as f:
            log_content = f.read()
        
        return {
            'log_file': str(latest_log),
            'content': log_content[:1000]  # Premiers 1000 chars
        }

def main():
    parser = argparse.ArgumentParser(description='Train Gaussian Splatting model')
    parser.add_argument('dataset', help='Chemin dataset images')
    parser.add_argument('-o', '--output', default='./gaussian_output', help='Dossier sortie')
    parser.add_argument('--max-steps', type=int, default=30000, help='Max iterations')
    parser.add_argument('--checkpoint-interval', type=int, default=5000, help='Intervalle checkpoints')
    
    args = parser.parse_args()
    
    trainer = GaussianSplattingTrainer(args.dataset, args.output)
    
    try:
        results = trainer.train(
            max_steps=args.max_steps,
            checkpoint_interval=args.checkpoint_interval
        )
        
        print("\n📊 Résultats Training:")
        print(json.dumps(results, indent=2))
        
        if results['success']:
            print(f"\n✅ Training terminé!")
            if results['latest_checkpoint']:
                print(f"   Checkpoint: {results['latest_checkpoint']}")
            return 0
        else:
            print(f"\n❌ Erreur training: {results.get('error')}")
            return 1
            
    except Exception as e:
        print(f"❌ Erreur: {e}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())










