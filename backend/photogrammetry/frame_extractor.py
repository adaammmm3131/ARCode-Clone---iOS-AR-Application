#!/usr/bin/env python3
"""
Frame Extractor pour Photogrammétrie
Extrait automatiquement les frames d'une vidéo à 30fps pour COLMAP
"""

import cv2
import os
import argparse
import sys
from pathlib import Path
from typing import List, Tuple

class FrameExtractor:
    def __init__(self, video_path: str, output_dir: str, fps: int = 30):
        """
        Initialise l'extracteur de frames
        
        Args:
            video_path: Chemin vers la vidéo
            output_dir: Dossier de sortie pour les frames
            fps: FPS d'extraction (défaut: 30)
        """
        self.video_path = video_path
        self.output_dir = Path(output_dir)
        self.fps = fps
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
    def extract_frames(self) -> List[str]:
        """
        Extrait les frames de la vidéo
        
        Returns:
            Liste des chemins des frames extraites
        """
        print(f"Extraction des frames de {self.video_path} à {self.fps} fps...")
        
        cap = cv2.VideoCapture(self.video_path)
        if not cap.isOpened():
            raise ValueError(f"Impossible d'ouvrir la vidéo: {self.video_path}")
        
        # Obtenir les propriétés de la vidéo
        video_fps = cap.get(cv2.CAP_PROP_FPS)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        duration = total_frames / video_fps
        
        print(f"Vidéo: {total_frames} frames à {video_fps} fps ({duration:.2f}s)")
        
        # Calculer intervalle d'extraction
        frame_interval = max(1, int(video_fps / self.fps))
        
        extracted_frames = []
        frame_count = 0
        extracted_count = 0
        
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            
            # Extraire frame si c'est le bon intervalle
            if frame_count % frame_interval == 0:
                frame_filename = f"frame_{extracted_count:06d}.jpg"
                frame_path = self.output_dir / frame_filename
                
                # Sauvegarder frame
                cv2.imwrite(str(frame_path), frame, [cv2.IMWRITE_JPEG_QUALITY, 95])
                extracted_frames.append(str(frame_path))
                extracted_count += 1
                
                if extracted_count % 10 == 0:
                    print(f"Extrait {extracted_count} frames...")
            
            frame_count += 1
        
        cap.release()
        print(f"Extraction terminée: {extracted_count} frames extraites")
        
        return extracted_frames
    
    def get_video_info(self) -> dict:
        """
        Obtient les informations de la vidéo
        
        Returns:
            Dict avec infos vidéo
        """
        cap = cv2.VideoCapture(self.video_path)
        if not cap.isOpened():
            return {}
        
        info = {
            'fps': cap.get(cv2.CAP_PROP_FPS),
            'frame_count': int(cap.get(cv2.CAP_PROP_FRAME_COUNT)),
            'width': int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)),
            'height': int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)),
            'duration': cap.get(cv2.CAP_PROP_FRAME_COUNT) / cap.get(cv2.CAP_PROP_FPS)
        }
        
        cap.release()
        return info

def main():
    parser = argparse.ArgumentParser(description='Extrait les frames d\'une vidéo pour photogrammétrie')
    parser.add_argument('video', help='Chemin vers la vidéo')
    parser.add_argument('-o', '--output', default='frames', help='Dossier de sortie')
    parser.add_argument('--fps', type=int, default=30, help='FPS d\'extraction (défaut: 30)')
    
    args = parser.parse_args()
    
    extractor = FrameExtractor(args.video, args.output, args.fps)
    
    try:
        frames = extractor.extract_frames()
        print(f"\n✅ Succès: {len(frames)} frames extraites dans {args.output}")
        return 0
    except Exception as e:
        print(f"❌ Erreur: {e}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())










