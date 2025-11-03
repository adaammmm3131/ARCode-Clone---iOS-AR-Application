# ARCode Backend Infrastructure

Documentation complète pour l'infrastructure backend ARCode.

## Architecture

- **Oracle Cloud Free Tier**: VM ARM (4 CPUs, 24GB RAM)
- **Nginx**: Reverse proxy / API Gateway
- **Flask**: API REST Python
- **PostgreSQL**: Base de données principale
- **Redis**: Cache et sessions
- **Cloudflare R2**: Stockage objets
- **Supabase Auth**: Authentification OAuth 2.0

## Structure

```
backend/
├── api/              # API REST Flask
├── ai/              # Services AI (Ollama, Stable Diffusion)
├── photogrammetry/  # Pipeline COLMAP
├── gaussian/        # Gaussian Splatting
├── config/          # Configuration Nginx, etc.
├── scripts/         # Scripts deployment
└── docs/            # Documentation
```









