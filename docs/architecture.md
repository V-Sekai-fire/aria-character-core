# 🏗️ Architecture & Development Progress

Aria Character Core is organized as an Elixir umbrella application with 14 specialized services.

Each service's role and dependencies are documented in their respective README files in the `apps/` directory.

- [ ] **Demo Implementation Options**:
  - [ ] **Option A: Livebook + Kino Components** (Recommended for rapid prototyping)
    - [ ] Create Livebook notebook with Kino.Input components (sliders, selects, checkboxes)
    - [ ] Use `Kino.Input.range/2` for numeric attributes
    - [ ] Use `Kino.Input.select/3` for categorical choices
    - [ ] Use `Kino.Input.checkbox/2` for boolean options and feature toggles
    - [ ] Implement real-time character preview with `Kino.listen/2` for live updates
    - [ ] Render character sheets with `Kino.Markdown.new/1` for rich formatting
    - [ ] Use `Kino.Layout` for organizing input components and output display
    - [ ] Create shareable `.livemd` notebooks for easy distribution and collaboration
    - [ ] **OAuth Integration**: GitHub OAuth for user authentication and favorites storage
- [ ] **Character Generator Features**
  - [ ] Interactive controls for all character attributes
  - [ ] Real-time character preview with live updates
  - [ ] Character configuration export/import capabilities
  - [ ] Generated character prompt display and formatting
  - [ ] **Macaroon Cookie Authentication**
  - [ ] Configure HTTP-only secure cookie handling for macaroon tokens
  - [ ] Create Phoenix plug for automatic macaroon token verification from cookies
  - [ ] Implement GitHub OAuth callback to generate and set macaroon cookies
  - [ ] Add cookie-based user identification for LiveView sessions
  - [ ] **Character Generator Storage Strategy**
    - [ ] **Authenticated Users**: Database storage with OAuth user favorites via single-tier aria_storage backend
    - [ ] **Unauthenticated Users**: Browser `localStorage` with macaroon-signed checksums (character config ~6-12KB exceeds 4KB cookie limit)
    - [ ] **Preset References**: Compressed cookie storage for preset IDs (~50-100 bytes) with server-side expansion
  - [ ] Configure cookie security settings (HTTP-only, Secure, SameSite protection)
  - [ ] Test macaroon cookie authentication flow with character generator demo
  - [ ] **User Favorites System**
  - [ ] Save/load user favorite character configurations (authenticated users only)
  - [ ] Character gallery view for saved favorites with thumbnails
  - [ ] Share character configurations via URL parameters (public/private toggle)
- [ ] **Demo Features for Feedback & Sponsorship**
  - [ ] Export generated character configurations
  - [ ] Share generated characters via URL parameters
  - [ ] GitHub Sponsors integration and course promotion
  - [ ] Feedback collection system for community input
  - [ ] Performance metrics display (generation time, complexity)
- [ ] **Deployment Options**
  - [ ] **Livebook Deployment**: Deploy shareable notebooks via Livebook Cloud or GitHub
  - [ ] Social sharing features for character creations
