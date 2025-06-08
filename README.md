# Aria Character Core

A distributed character generation and AI planning system built with Elixir umbrella applications.

## 🚀 Quick Start

> ⚠️ **Nothing works yet!** These commands will fail until services are implemented.

**Platform Recommendation:**
*   **Linux/macOS:** The instructions below are primarily tailored for Linux-based environments (including macOS).
*   **Windows Users:** It is **highly recommended to use Windows Subsystem for Linux (WSL) 2**. See platform details below.

This project uses `asdf-vm` to manage Erlang and Elixir versions. 

**Step 1: Install `asdf-vm`**
   - If you don't have `asdf-vm` installed, follow our **[asdf-vm Installation Guide](docs/SETUP_ASDF.md)**.
   - Ensure `asdf` is active in your current terminal session (you may need to open a new terminal or source your shell config).

**Step 2: Add Erlang & Elixir Plugins**
```bash
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
```

**Step 3: Install Project Versions**
   (Ensure you are in the project root directory)
```bash
asdf install
```

**Step 4: Project Setup**
   (Run after `asdf install` is complete)
```bash
# If you haven't cloned the project yet:
# git clone https://github.com/V-Sekai-fire/aria-character-core.git aria-character-core
# cd aria-character-core

mix deps.get
mix ecto.setup
mix phx.server
```

> ⚠️ **Work in Progress**: This project is in early development. Nothing is functional yet - we're building from the ground up using TDD principles.

### Detailed Platform Recommendations

*   **Linux/macOS:** The instructions are primarily tailored for these environments, which generally offer the smoothest experience for Elixir development and the tooling used in this project.
*   **Windows Users (WSL2 Recommended):** 
    *   **Why WSL2 over Native Windows for this project?**
        *   **`asdf-vm` Compatibility:** `asdf-vm` is primarily designed for Unix-like systems. Native Windows support can be less straightforward.
        *   **Tooling & Scripting:** Many development tools and scripts assume a Unix-like environment.
        *   **Dependency Compilation:** Some Elixir dependencies compile more reliably in a Linux environment.
        *   **Community & Support:** More community examples are geared towards Linux/macOS.
        *   **Consistency:** WSL2 provides a consistent Linux environment for all contributors.
    *   **Setup:** Install WSL2 and a Linux distribution (e.g., Ubuntu) from the Microsoft Store, then follow the Linux instructions within your WSL2 terminal.

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
- **AI-Core**: Key features are designed with AI/ML models (For example: GRPO for training) at their heart, enabling sophisticated and dynamic capabilities.
- **Microservices**: Independent development, testing, and deployment
- **Observability**: Comprehensive monitoring and debugging tools
- **Content-Addressed Storage**: Efficient asset management with deduplication
- **OTP-Native Process Management for Elixir Services**: Leveraging Elixir/OTP's supervisor trees for the lifecycle and fault tolerance of processes _within each Elixir application_. This provides highly efficient, built-in mechanisms for managing these internal processes. For managing external standalone services (like databases or OpenBao if run independently) or containerized workloads (like Python ML tasks), other tools (e.g., systemd, Docker, Kubernetes, as outlined in the Deployment section) are typically used in conjunction with the Elixir applications.

---

Built with ❤️ by [Chibifire](https://chibifire.com) • Powered by Elixir & OTP
