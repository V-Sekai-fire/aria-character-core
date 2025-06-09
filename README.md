# Aria Character Core

A distributed character generation and AI planning system built with Elixir umbrella applications.

## 🏗️ Architecture & Development

For detailed system architecture, service dependencies, and development progress tracking, see the [**Architecture Documentation**](docs/architecture.md).

**Key Features:**
- **14 specialized Elixir services** organized in dependency-aware boot layers
- **Test-Driven Development (TDD)** with comprehensive progress tracking
- **HSM-secured secrets management** via OpenBao
- **Native systemd deployment** for production environments

## 🔧 Quick Start

**Prerequisites:** This project uses `asdf-vm` for version management and `just` for task automation.

### Development Setup

```bash
# Install dependencies
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf install

# Project setup
mix deps.get
mix ecto.setup

# Run tests to check progress
mix test.all

# Start development server
mix phx.server
```

### Production Deployment

The project uses native systemd services for production deployment:

```bash
# Automated production setup (recommended)
just setup-production

# Manual setup if needed
sudo ./scripts/setup-production.sh

# Production service management
just start-production     # Start all services
just stop-production      # Stop all services
just status-production    # Check service status
just logs-production      # View application logs
just restart-production   # Restart all services
```

**Production Components:**
- **CockroachDB**: Distributed SQL database
- **OpenBao**: Secrets management (HSM-enabled)
- **SeaweedFS**: Distributed file storage
- **Aria Application**: Main Elixir umbrella app

All services run as systemd units under the `aria` user with proper security isolation.

---

Built with ❤️ by [Chibifire](https://chibifire.com) • Powered by Elixir & OTP
