# 🏗️ Architecture Overview

Aria Character Core is organized as an Elixir umbrella application with 14 specialized services in **cold boot order**:

### **1. Foundation Layer** (Boot First)

1.  - [ ] **[aria_security](../apps/aria_security/)** - OpenBao secrets management
    - Dependencies: (Core infrastructure, provides secrets to others); External: OpenBao (bundled)
2.  - [ ] **[aria_data](../apps/aria_data/)** - System data persistence (PostgreSQL/Ecto)
    - Dependencies: `aria_security` (for DB credentials); External: CockroachDB 22.1 (or PostgreSQL)

### **2. Core Services Layer** (Boot Second)

3.  - [ ] **[aria_auth](../apps/aria_auth/)** - Authentication & authorization (JWT, OAuth2, WebRTC)
    - Dependencies: `aria_security` (for secrets/certs), `aria_data` (for user/token storage)
4.  - [ ] **[aria_storage](../apps/aria_storage/)** - Bulk asset storage (S3, SFTP, CDN)
    - Dependencies: `aria_security` (for storage credentials), `aria_auth` (for access authorization); External: Desync, S3/SFTP/CDN backends
5.  - [ ] **[aria_queue](../apps/aria_queue/)** - Background job processing (Oban)
    - Dependencies: `aria_data` (for Oban persistence), `aria_security` (for Oban's DB credentials)

### **3. Intelligence Layer** (Boot Third)

6.  - [ ] **[aria_shape](../apps/aria_shape/)** - Character generation & shaping (Qwen3/GRPO)
    - Dependencies: `aria_security` (for model/API credentials), `aria_data` (for templates/results), `aria_storage` (for assets), `aria_queue` (for async tasks); External: Python, PyTorch, Qwen3/GRPO models
7.  - [ ] **[aria_engine](../apps/aria_engine/)** - Classical AI planning & GTPyhop (hierarchical task planner)
    - Dependencies: `aria_security` (for secure config), `aria_data` (for state/plans), `aria_queue` (for async tasks)
    - Note: Incorporates GTPyhop port for predicate-based planning with goals, tasks, and actions
8.  - [ ] **[aria_interpret](../apps/aria_interpret/)** - Data interpretation & analysis
    - Dependencies: `aria_security` (for model/API credentials), `aria_data` (for data/results), `aria_storage` (for large datasets), `aria_queue` (for async tasks); External: Python, PyTorch

### **4. Orchestration Layer** (Boot Fourth)

9.  - [ ] **[aria_workflow](../apps/aria_workflow/)** - SOP management & execution
    - Dependencies: `aria_security`, `aria_data` (for definitions/state), `aria_queue`, and various services it orchestrates (e.g., `aria_shape`, `aria_engine`).
10. - [ ] **[aria_interface](../apps/aria_interface/)** - Data ingestion & web UI (Phoenix)
    - Dependencies: `aria_security`, `aria_auth`, `aria_data`, `aria_storage`, `aria_queue`, `aria_workflow`, and other intelligence/engine services for UI interaction.

### **5. Gateway & Ops Layer** (Boot Last)

11. - [ ] **[aria_coordinate](../apps/aria_coordinate/)** - API gateway & routing
    - Dependencies: `aria_security` (for certs/config), `aria_auth` (for route protection); Routes to most other services.
12. - [ ] **[aria_monitor](../apps/aria_monitor/)** - System observability (Prometheus, LiveDashboard)
    - Dependencies: `aria_security` (for secure scraping if needed); Connects to most services for metrics; External: Prometheus.
13. - [ ] **[aria_debugger](../apps/aria_debugger/)** - System inspection & configuration
    - Dependencies: `aria_security` (for access credentials), `aria_auth` (to secure debugger access); Interacts with most services.
14. - [ ] **[aria_tune](../apps/aria_tune/)** - Performance optimization & ML tuning
    - Dependencies: `aria_security`, `aria_data`, `aria_monitor`, `aria_queue`, and potentially AI services like `aria_shape` for model tuning.
