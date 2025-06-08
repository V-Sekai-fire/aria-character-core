# Aria Character Core

A distributed character generation and AI planning system built with Elixir umbrella applications.

> ⚠️ **Work in Progress**: This project is in early development. Nothing is functional yet - we're building from the ground up using TDD principles.

## 🏗️ Architecture Overview

Aria Character Core is organized as an Elixir umbrella application with 14 specialized services in **cold boot order**:

### **1. Foundation Layer** (Boot First)
1. - [ ] **[aria_security](apps/aria_security/)** - OpenBao secrets management
2. - [ ] **[aria_data](apps/aria_data/)** - System data persistence (PostgreSQL/Ecto)

### **2. Core Services Layer** (Boot Second)
3. - [ ] **[aria_auth](apps/aria_auth/)** - Authentication & authorization (JWT, OAuth2, WebRTC)
4. - [ ] **[aria_storage](apps/aria_storage/)** - Bulk asset storage (S3, SFTP, CDN)
5. - [ ] **[aria_queue](apps/aria_queue/)** - Background job processing (Oban)

### **3. Intelligence Layer** (Boot Third)
6. - [ ] **[aria_shape](apps/aria_shape/)** - Character generation & shaping (Qwen3/GRPO)
7. - [ ] **[aria_engine](apps/aria_engine/)** - Planning algorithm (ported from C++)
8. - [ ] **[aria_interpret](apps/aria_interpret/)** - Data interpretation & analysis

### **4. Orchestration Layer** (Boot Fourth)
9. - [ ] **[aria_workflow](apps/aria_workflow/)** - SOP management & execution
10. - [ ] **[aria_interface](apps/aria_interface/)** - Data ingestion & web UI (Phoenix)

### **5. Gateway & Ops Layer** (Boot Last)
11. - [ ] **[aria_coordinate](apps/aria_coordinate/)** - API gateway & routing
12. - [ ] **[aria_monitor](apps/aria_monitor/)** - System observability (Prometheus, LiveDashboard)
13. - [ ] **[aria_debugger](apps/aria_debugger/)** - System inspection & configuration
14. - [ ] **[aria_tune](apps/aria_tune/)** - Performance optimization & ML tuning

## 🚀 Quick Start

> ⚠️ **Nothing works yet!** These commands will fail until services are implemented.

```bash
# For Debian/Ubuntu (using apt):
sudo apt-get install erlang-dev

# For Fedora/CentOS/RHEL (using dnf or yum):
sudo dnf install erlang-devel

# Clone and setup
git clone <repo-url> aria-character-core
cd aria-character-core

# Install dependencies
mix deps.get

# Setup database
mix ecto.setup

# Start all services
mix phx.server
```

## 🔧 Development

> ⚠️ **TDD in Progress** - Most commands will fail until core functionality is implemented.

```bash
# Run tests across all apps
mix test.all

# Format code across all apps  
mix format

# Quality checks
mix quality

# Start with specific services only
mix run --no-halt -e "Application.ensure_all_started([:aria_coordinate, :aria_interface])"
```

## 📖 Documentation

Each service has detailed documentation in its respective `apps/*/README.md` file. See the individual service READMEs for:

- Service-specific responsibilities
- Technology stack details
- Inter-service interactions
- Deployment considerations

## 🏛️ System Principles

- **Zero Trust Architecture**: Every request authenticated and authorized
- **AI-First Design**: Centralized character generation with GRPO training
- **Microservices**: Independent development, testing, and deployment
- **Observability**: Comprehensive monitoring and debugging tools
- **Content-Addressed Storage**: Efficient asset management with deduplication
- **OTP-Native Process Management**: Utilizing Elixir/OTP's supervisor trees for service lifecycle and fault tolerance. This approach provides lightweight, built-in mechanisms for managing processes within the application, which can simplify deployment and reduce the need for external orchestration tools for these specific concerns. This is favored for in-application process orchestration due to its efficiency and integration with the Erlang VM's capabilities.

---

Built with ❤️ by [Chibifire](https://chibifire.com) • Powered by Elixir & OTP
