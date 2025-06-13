# 🏗️ Architecture & Development Progress

Aria Character Core is organized as an Elixir umbrella application with 14 specialized services in **cold boot order**.

Each service's role and dependencies are documented in their respective README files in the `apps/` directory.

## 📋 Queued Work

- [ ] **Character Generator LiveView Demo**: Create interactive demo for community feedback and GitHub sponsorship
  - [ ] **Minimal UI for character generator demo** (`aria_interface`): 
    - [ ] Basic Phoenix LiveView application with routing and layout
    - [ ] Create real-time character generation interface with sliders and controls
    - [ ] Live preview of generated character parameters and prompt text
    - [ ] **OAuth Integration**: GitHub OAuth for user authentication and favorites storage
  - [ ] **Macaroon Cookie Authentication**: Implement stateless authentication for character demo
    - [ ] Configure HTTP-only secure cookie handling for macaroon tokens
    - [ ] Create Phoenix plug for automatic macaroon token verification from cookies
    - [ ] Implement GitHub OAuth callback to generate and set macaroon cookies
    - [ ] Add cookie-based user identification for LiveView sessions
    - [ ] **Character Generator Storage Strategy**: 
      - [ ] **Authenticated Users**: Database storage with OAuth user favorites via single-tier aria_storage backend
      - [ ] **Unauthenticated Users**: Browser `localStorage` with macaroon-signed checksums (character config ~6-12KB exceeds 4KB cookie limit)
      - [ ] **Preset References**: Compressed cookie storage for preset IDs (~50-100 bytes) with server-side expansion
    - [ ] Configure cookie security settings (HTTP-only, Secure, SameSite protection)
    - [ ] Test macaroon cookie authentication flow with character generator demo
  - [ ] **Interactive Slider Controls**: Port test sliders to LiveView components
    - [ ] Sliders with live updates
    - [ ] Categorical sliders
    - [ ] Boolean toggles
    - [ ] Numeric range sliders with real-time feedback
    - [ ] Character configuration preview panel with generated prompt display
  - [ ] **User Favorites System**: Implement OAuth user character storage via single-tier architecture
    - [ ] Save/load user favorite character configurations (authenticated users only)
    - [ ] Character gallery view for saved favorites with thumbnails
    - [ ] Share character configurations via URL parameters (public/private toggle)
  - [ ] **Demo Features for Feedback & Sponsorship**
    - [ ] Export generated character configurations
    - [ ] Share generated characters via URL parameters
    - [ ] GitHub Sponsors integration and course promotion
    - [ ] Feedback collection system for community input
    - [ ] Performance metrics display (generation time, complexity)
  - [ ] **Deployment for Public Demo**
    - [ ] Configure public access to demo
    - [ ] Simple authentication (optional GitHub OAuth for sponsors)
    - [ ] Mobile-responsive design for broader accessibility
    - [ ] Social sharing features for character creations
