# Aria Character Core

A distributed character generation and AI planning system built with Elixir umbrella applications.

## 🏗️ Architecture Overview

Aria Character Core is organized as an Elixir umbrella application with 14 specialized services:

### **Security & Foundation Services**
- **[aria_security](apps/aria_security/)** - OpenBao secrets management
- **[aria_auth](apps/aria_auth/)** - Authentication & authorization (JWT, OAuth2, WebRTC)
- **[aria_data](apps/aria_data/)** - System data persistence (CockroachDB/Ecto)
- **[aria_storage](apps/aria_storage/)** - Bulk asset storage (S3, SFTP, CDN)
- **[aria_queue](apps/aria_queue/)** - Background job processing (Oban)

### **Data & Intelligence Services**
- **[aria_shape](apps/aria_shape/)** - Character generation & shaping (Qwen3/GRPO)
- **[aria_engine](apps/aria_engine/)** - Planning algorithm (ported from C++)
- **[aria_interpret](apps/aria_interpret/)** - Data interpretation & analysis
- **[aria_workflow](apps/aria_workflow/)** - SOP management & execution

### **Interface & Coordination Services**
- **[aria_interface](apps/aria_interface/)** - Data ingestion & web UI (Phoenix)
- **[aria_coordinate](apps/aria_coordinate/)** - API gateway & routing
- **[aria_monitor](apps/aria_monitor/)** - System observability (Prometheus, LiveDashboard)
- **[aria_debugger](apps/aria_debugger/)** - System inspection & configuration
- **[aria_tune](apps/aria_tune/)** - Performance optimization & ML tuning

## 🚀 Quick Start

```bash
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

---

Built with ❤️ by [Chibifire](https://chibifire.com) • Powered by Elixir & OTP
