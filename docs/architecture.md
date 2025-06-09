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

## 🎯 Development Progress

This project follows Test-Driven Development (TDD). Each checkbox represents a feature with corresponding test coverage. Check off items as tests pass and features are implemented.

### 🚀 Core Infrastructure

- [ ] **Project Setup & Dependencies**
  - [ ] Umbrella application structure with proper supervision trees
  - [ ] Database connectivity and migrations (PostgreSQL)
  - [ ] Inter-service communication via message passing
  - [ ] Configuration management across environments
  - [ ] Logging and observability setup

- [ ] **Security Foundation (AriaSecurity)**
  - [x] OpenBao integration for secrets management
  - [x] Vaultex client configuration and API integration  
  - [ ] JWT token generation and validation
  - [ ] Role-based access control (RBAC)
  - [ ] API authentication middleware
  - [ ] Zero-trust security policies

### 🧠 AI & Machine Learning Core

- [ ] **Character AI Planning (AriaPlanning)**
  - [ ] Goal-oriented action planning (GOAP) engine
  - [ ] Behavior tree execution
  - [ ] State management for character decisions
  - [ ] Action cost calculation and optimization
  - [ ] Multi-character coordination algorithms

- [ ] **Neural Network Integration (AriaNeuralNetwork)**
  - [ ] PyTorch model loading and inference
  - [ ] GRPO (Goal-Relabeled Policy Optimization) training pipeline
  - [ ] Model versioning and A/B testing
  - [ ] GPU acceleration support
  - [ ] Distributed training coordination

- [ ] **Recommendation System (AriaRecommendation)**
  - [ ] DIN (Deep Interest Network) integration from LibRecommender
  - [ ] Character trait and behavior pattern analysis
  - [ ] Content-based character attribute recommendations
  - [ ] Collaborative filtering for character generation
  - [ ] Real-time recommendation serving via API

### 🎮 Character Generation

- [ ] **Character Creation (AriaCharacter)**
  - [ ] Character template system
  - [ ] Trait and attribute generation
  - [ ] Personality modeling
  - [ ] Character validation and constraints
  - [ ] Character evolution over time

- [ ] **Asset Management (AriaAssets)**
  - [ ] Content-addressed storage (CAS) implementation
  - [ ] Asset deduplication and compression
  - [ ] Version control for character assets
  - [ ] Distributed asset synchronization
  - [ ] Asset garbage collection

### 🌐 Coordination & Communication

- [ ] **Service Coordination (AriaCoordinate)**
  - [ ] Service discovery and registration
  - [ ] Health check monitoring
  - [ ] Load balancing algorithms
  - [ ] Circuit breaker patterns
  - [ ] Graceful degradation handling

- [ ] **External Interfaces (AriaInterface)**
  - [ ] REST API endpoints
  - [ ] WebSocket real-time communication
  - [ ] WebRTC peer-to-peer connections
  - [ ] Rate limiting and throttling
  - [ ] API documentation generation

### 📊 Data & Analytics

- [ ] **Database Layer (AriaDatabase)**
  - [ ] Schema design and migrations
  - [ ] Query optimization
  - [ ] Connection pooling
  - [ ] Backup and recovery procedures
  - [ ] Data archival strategies

- [ ] **Analytics & Metrics**
  - [ ] Performance monitoring
  - [ ] Business metrics collection
  - [ ] Error tracking and alerting
  - [ ] Usage analytics
  - [ ] Cost optimization insights

### 🛠️ Development Tooling

- [ ] **Quality Assurance**
  - [x] Pre-commit hooks for code quality
  - [ ] Automated testing pipeline
  - [ ] Code coverage reporting
  - [ ] Performance benchmarking
  - [ ] Security vulnerability scanning

- [ ] **Deployment & Operations**
  - [x] Native systemd service deployment
  - [x] Production setup automation scripts
  - [ ] CI/CD pipeline configuration
  - [ ] Environment-specific configurations
  - [ ] Monitoring and alerting setup

## 📈 Testing Strategy

Each feature is developed using TDD:

1. **Write failing tests** that define the expected behavior
2. **Implement minimal code** to make tests pass
3. **Refactor** while keeping tests green
4. **Check off the task** when tests provide adequate coverage

```bash
# Run all tests
mix test.all

# Run tests for specific service
mix test apps/aria_security

# Run tests with coverage
mix test --cover

# Quality checks
mix quality
