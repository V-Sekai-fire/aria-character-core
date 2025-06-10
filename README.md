# Aria Character Core

A distributed character generation and AI planning system built with Elixir umbrella applications.

## 🏗️ Architecture & Development

For detailed system architecture, service dependencies, and development progress tracking, see the [**Architecture Documentation**](docs/architecture.md).

**Key Features:**
- **14 specialized Elixir services** organized in dependency-aware boot layers
- **Test-Driven Development (TDD)** with comprehensive progress tracking
- **HSM-secured secrets management** via OpenBao
- **Native systemd deployment** for production environments

**Production Components:**
- **CockroachDB**: Distributed SQL database
- **OpenBao**: Secrets management (HSM-enabled)
- **SeaweedFS**: Distributed file storage
- **Aria Application**: Main Elixir umbrella app

---

Built with ❤️ by [Chibifire](https://chibifire.com) • Powered by Elixir & OTP
