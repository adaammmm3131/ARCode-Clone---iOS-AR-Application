# Pipeline Photogrammétrie COLMAP

Pipeline complet pour reconstruction 3D depuis vidéos.

## Installation

### Prérequis

1. **COLMAP** (Structure-from-Motion)
   ```bash
   # Ubuntu/Debian
   sudo apt-get install colmap
   
   # Ou compiler depuis source
   git clone https://github.com/colmap/colmap.git
   cd colmap
   mkdir build && cd build
   cmake .. -DCMAKE_BUILD_TYPE=Release
   make -j4
   sudo make install
   ```

2. **Python dependencies**
   ```bash
   pip install -r requirements.txt
   ```

## Usage

### Pipeline complet (recommandé)

```bash
python pipeline.py video.mp4 -w workspace/ --fps 30 -o results.json
```

### Étapes individuelles

1. **Extraction frames**
   ```bash
   python frame_extractor.py video.mp4 -o frames/ --fps 30
   ```

2. **Preprocessing**
   ```bash
   python preprocessor.py frames/ -o preprocessed/
   ```

3. **COLMAP SfM**
   ```bash
   python colmap_pipeline.py workspace/ images/ --sfm
   ```

4. **COLMAP Dense**
   ```bash
   python colmap_pipeline.py workspace/ images/ --dense --model workspace/sparse/0
   ```

5. **Génération Mesh**
   ```bash
   python mesh_generator.py dense/fused.ply -o mesh/ --poisson-depth 9 --simplify 50000
   ```

## Workflow

```
Vidéo MP4
    ↓
[1] Frame Extraction (30fps)
    ↓
[2] Preprocessing (denoising, contrast)
    ↓
[3] COLMAP Feature Extraction
    ↓
[4] COLMAP Feature Matching
    ↓
[5] COLMAP Sparse Reconstruction
    ↓
[6] COLMAP Bundle Adjustment
    ↓
[7] COLMAP Image Undistorter
    ↓
[8] COLMAP Patch Match Stereo
    ↓
[9] COLMAP Stereo Fusion → Point Cloud
    ↓
[10] Poisson Surface Reconstruction → Mesh
    ↓
[11] Mesh Simplification (LOD)
    ↓
Mesh final (.ply)
```

## Structure Workspace

```
workspace/
├── frames/              # Frames extraites
├── preprocessed/        # Images préprocessées
├── colmap/
│   ├── database.db      # Base COLMAP
│   ├── sparse/          # Modèles sparse
│   └── dense/           # Reconstruction dense
├── mesh/                # Meshes générés
└── export/              # Exports finaux
```

## Performance

- **Temps estimé** (vidéo 1-1.5min, 750+ frames):
  - Frame extraction: ~2 min
  - Preprocessing: ~5 min
  - COLMAP SfM: ~15-30 min
  - COLMAP Dense: ~30-60 min
  - Mesh generation: ~5-10 min
  
  **Total: ~1-2 heures** selon hardware

## Notes

- COLMAP nécessite GPU pour meilleures performances
- Point cloud dense peut être volumineux (plusieurs GB)
- Mesh simplification recommandée pour export AR










