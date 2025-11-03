# Phase 28 - Features - Guide Complet

## Vue d'ensemble

Phase 28 implémente trois fonctionnalités majeures: Custom Links (CTA), Collaboration (Workspaces), et White Label.

## Phase 28.1 - Custom Links (CTA)

### Fonctionnalités

1. **Boutons CTA dans AR**
   - Boutons configurables dans expérience AR
   - Positions multiples (top, bottom, center, floating)
   - Styles variés (primary, secondary, outline, text, icon)
   - Redirections vers différents types de destinations

2. **Types de Destinations**
   - Product page
   - Landing page
   - App download (App Store)
   - Social media
   - Website
   - Deep link
   - Email (mailto:)
   - Phone (tel:)

3. **A/B Testing**
   - Variants multiples (A, B, C, etc.)
   - Distribution par poids
   - Tracking conversions
   - Résultats en temps réel
   - Conclure test et définir gagnant

### Architecture

**iOS:**
- `ARCodeCTALink` - Modèle
- `CTALinkService` - Service CRUD et tracking
- `ABTestingService` - Service A/B testing
- `ARCTALinkButton` - Composant UI bouton
- `ARCTALinkOverlay` - Overlay dans AR
- `CTALinkViewModel` - ViewModel gestion

**Backend:**
- `cta_links_api.py` - Endpoints CTA links
- `ab_testing_api.py` - Endpoints A/B testing
- Tables: `cta_links`, `ab_tests`, `ab_test_results`

### Intégration AR

Les CTA links sont chargés automatiquement dans `ARExperienceViewModel` et affichés dans `AROverlayView`.

## Phase 28.2 - Collaboration (Workspaces)

### Fonctionnalités

1. **Workspaces Multi-utilisateurs**
   - Création workspaces
   - Gestion membres
   - Rôles: Owner, Admin, Editor, Viewer
   - Permissions granulaires

2. **Rôles et Permissions**
   - **Owner**: Contrôle total
   - **Admin**: Gestion workspace, inviter membres
   - **Editor**: Créer/modifier AR Codes
   - **Viewer**: Lecture seule

3. **Comments**
   - Commentaires sur AR Codes
   - Résolution comments
   - Threading

4. **Version History**
   - Historique versions AR Codes
   - Changelog
   - Restauration version précédente

### Architecture

**iOS:**
- `Workspace` - Modèle workspace
- `WorkspaceMember` - Modèle membre
- `WorkspaceComment` - Modèle commentaire
- `ARCodeVersion` - Modèle version
- `WorkspaceService` - Service CRUD
- `WorkspaceViewModel` - ViewModel

**Backend:**
- `workspaces_api.py` - Endpoints workspaces
- Tables: `workspaces`, `workspace_members`, `workspace_comments`, `ar_code_versions`

## Phase 28.3 - White Label

### Fonctionnalités

1. **Custom Domain**
   - Domaine personnalisé (ex: ar.votresite.com)
   - Validation DNS
   - Configuration Nginx

2. **Branding**
   - Logo personnalisé
   - Couleurs custom (primary, secondary, accent)
   - Nom entreprise
   - Email support

3. **Loading Screens**
   - Écran de chargement personnalisé
   - URL personnalisée

4. **Email Templates**
   - Templates email brandés
   - Customisation HTML

### Architecture

**iOS:**
- `WhiteLabelSettings` - Modèle settings
- `WhiteLabelConfig` - Modèle config
- `WhiteLabelService` - Service gestion
- `WhiteLabelSettingsView` - Interface configuration

**Backend:**
- `white_label_api.py` - Endpoints white label
- Tables: `white_label_configs`, `email_templates_custom`

## Migrations Base de Données

### CTA Links
```sql
-- cta_links table
-- ab_tests table
-- ab_test_results table
```

### Workspaces
```sql
-- workspaces table
-- workspace_members table
-- workspace_comments table
-- ar_code_versions table
-- Add workspace_id to ar_codes
```

### White Label
```sql
-- white_label_configs table
-- email_templates_custom table
```

## Endpoints API

### CTA Links
- `GET /api/v1/cta-links/{ar_code_id}` - Get CTA links
- `POST /api/v1/cta-links` - Create CTA link
- `PUT /api/v1/cta-links/{id}` - Update CTA link
- `DELETE /api/v1/cta-links/{id}` - Delete CTA link
- `POST /api/v1/analytics/cta-click` - Track click

### A/B Testing
- `GET /api/v1/ab-tests/{ar_code_id}` - Get AB test
- `POST /api/v1/ab-tests` - Create AB test
- `GET /api/v1/ab-tests/{test_id}/results` - Get results
- `POST /api/v1/analytics/ab-test-conversion` - Track conversion
- `POST /api/v1/ab-tests/{test_id}/conclude` - Conclude test

### Workspaces
- `GET /api/v1/workspaces` - Get workspaces
- `POST /api/v1/workspaces` - Create workspace
- `GET /api/v1/workspaces/{id}` - Get workspace
- `PUT /api/v1/workspaces/{id}` - Update workspace
- `DELETE /api/v1/workspaces/{id}` - Delete workspace
- `GET /api/v1/workspaces/{workspace_id}/members` - Get members
- `POST /api/v1/workspaces/{workspace_id}/members/invite` - Invite member
- `POST /api/v1/workspaces/comments` - Create comment
- `GET /api/v1/ar-codes/{ar_code_id}/versions` - Get versions

### White Label
- `GET /api/v1/white-label/config` - Get config
- `PUT /api/v1/white-label/config/{id}` - Update config
- `POST /api/v1/white-label/validate-domain` - Validate domain

## Checklist Phase 28

- [x] Phase 28.1 - Custom Links (CTA)
  - [x] Modèles CTA links
  - [x] Service CTA links
  - [x] A/B testing service
  - [x] Composants UI AR
  - [x] Backend API endpoints
  - [x] Database migrations

- [x] Phase 28.2 - Collaboration
  - [x] Modèles workspaces
  - [x] Service workspaces
  - [x] Comments système
  - [x] Version history
  - [x] Backend API endpoints
  - [x] Database migrations

- [x] Phase 28.3 - White Label
  - [x] Modèles white label
  - [x] Service white label
  - [x] Interface configuration
  - [x] Backend API endpoints
  - [x] Database migrations

## Prochaines étapes

Voir Phase 29 - Accessibility & Localization pour:
- WCAG 2.1 AA compliance
- VoiceOver support
- Multi-langue (27+)
- Dark mode







