#!/usr/bin/env python3
"""
Preprocessor pour Photogrammétrie
Prétraitement des images: denoising, contrast enhancement
"""

import cv2
import numpy as np
from pathlib import Path
import argparse
import sys
from typing import List

class ImagePreprocessor:
    def __init__(self, input_dir: str, output_dir: str):
        """
        Initialise le préprocesseur
        
        Args:
            input_dir: Dossier contenant les images brutes
            output_dir: Dossier de sortie pour images préprocessées
        """
        self.input_dir = Path(input_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
    def preprocess_images(self, denoise: bool = True, enhance_contrast: bool = True) -> List[str]:
        """
        Prétraite toutes les images du dossier
        
        Args:
            denoise: Activer débruitage
            enhance_contrast: Améliorer contraste
            
        Returns:
            Liste des chemins des images préprocessées
        """
        print(f"Prétraitement des images de {self.input_dir}...")
        
        # Obtenir toutes les images
        image_extensions = {'.jpg', '.jpeg', '.png', '.JPG', '.JPEG', '.PNG'}
        image_files = [f for f in self.input_dir.iterdir() 
                      if f.suffix in image_extensions]
        
        if not image_files:
            raise ValueError(f"Aucune image trouvée dans {self.input_dir}")
        
        print(f"{len(image_files)} images à traiter...")
        
        processed_images = []
        
        for i, image_file in enumerate(sorted(image_files)):
            try:
                # Charger image
                img = cv2.imread(str(image_file))
                if img is None:
                    print(f"⚠️  Impossible de charger {image_file}")
                    continue
                
                # Preprocessing
                processed_img = self.process_image(img, denoise, enhance_contrast)
                
                # Sauvegarder
                output_path = self.output_dir / image_file.name
                cv2.imwrite(str(output_path), processed_img, 
                           [cv2.IMWRITE_JPEG_QUALITY, 95])
                processed_images.append(str(output_path))
                
                if (i + 1) % 10 == 0:
                    print(f"Traité {i + 1}/{len(image_files)} images...")
                    
            except Exception as e:
                print(f"⚠️  Erreur lors du traitement de {image_file}: {e}")
                continue
        
        print(f"✅ Prétraitement terminé: {len(processed_images)} images")
        return processed_images
    
    def process_image(self, img: np.ndarray, denoise: bool, enhance_contrast: bool) -> np.ndarray:
        """
        Prétraite une image
        
        Args:
            img: Image BGR
            denoise: Débruiter
            enhance_contrast: Améliorer contraste
            
        Returns:
            Image préprocessée
        """
        processed = img.copy()
        
        # Débruitage (Non-local Means Denoising)
        if denoise:
            processed = cv2.fastNlMeansDenoisingColored(processed, None, 3, 3, 7, 21)
        
        # Amélioration du contraste (CLAHE - Contrast Limited Adaptive Histogram Equalization)
        if enhance_contrast:
            # Convertir en LAB
            lab = cv2.cvtColor(processed, cv2.COLOR_BGR2LAB)
            l, a, b = cv2.split(lab)
            
            # Appliquer CLAHE sur le canal L
            clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
            l_enhanced = clahe.apply(l)
            
            # Fusionner canaux
            lab_enhanced = cv2.merge([l_enhanced, a, b])
            processed = cv2.cvtColor(lab_enhanced, cv2.COLOR_LAB2BGR)
        
        return processed

def main():
    parser = argparse.ArgumentParser(description='Prétraite les images pour photogrammétrie')
    parser.add_argument('input', help='Dossier contenant les images brutes')
    parser.add_argument('-o', '--output', default='preprocessed', help='Dossier de sortie')
    parser.add_argument('--no-denoise', action='store_true', help='Désactiver débruitage')
    parser.add_argument('--no-contrast', action='store_true', help='Désactiver amélioration contraste')
    
    args = parser.parse_args()
    
    preprocessor = ImagePreprocessor(args.input, args.output)
    
    try:
        images = preprocessor.preprocess_images(
            denoise=not args.no_denoise,
            enhance_contrast=not args.no_contrast
        )
        print(f"\n✅ Succès: {len(images)} images préprocessées")
        return 0
    except Exception as e:
        print(f"❌ Erreur: {e}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())










