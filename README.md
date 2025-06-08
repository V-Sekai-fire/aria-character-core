# Aria Character Core

A distributed character generation and AI planning system built with Elixir umbrella applications.

> ⚠️ **Work in Progress**: This project is in early development. Nothing is functional yet - we're building from the ground up using TDD principles.

## 🚀 Quick Start

> ⚠️ **Nothing works yet!** These commands will fail until services are implemented.

```bash
# This project uses asdf-vm to manage Erlang and Elixir versions.
# Follow these steps carefully to set up your environment.

# --- Step 1: Install asdf-vm (version manager) ---
# Prerequisite: Ensure 'git' is installed on your system.

# Clone the asdf-vm repository (v0.14.0 specific to these instructions).
# If you have asdf already installed, you might skip this or see an error if the directory exists.
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0

# Add asdf to your shell. Execute the commands for YOUR shell.
# After this, you MUST open a new terminal or source your shell config file (e.g., source ~/.bashrc).

# For Bash users (append to ~/.bashrc):
echo '' >> ~/.bashrc # Adds a newline for better separation
echo '# Initialize asdf version manager' >> ~/.bashrc
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc

# For Zsh users (append to ~/.zshrc - uncomment and run):
# echo '' >> ~/.zshrc
# echo '# Initialize asdf version manager' >> ~/.zshrc
# echo '. "$HOME/.asdf/asdf.sh"' >> ~/.zshrc

# For Fish users (create a symlink - uncomment and run):
# mkdir -p ~/.config/fish/completions
# ln -s ~/.asdf/completions/asdf.fish ~/.config/fish/completions

# --- Step 2: Activate asdf in your CURRENT terminal session ---
# If you haven't already, open a NEW terminal window/tab,
# OR source your shell's configuration file in the CURRENT terminal.
# Example for Bash:
#   source ~/.bashrc
# Example for Zsh:
#   source ~/.zshrc
# The 'asdf' command should now be recognized.

# --- Step 3: Add asdf plugins for Erlang & Elixir ---
# (Requires 'asdf' command to be active from Step 2).
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git

# --- Step 4: Install Erlang & Elixir versions ---
# This command uses asdf to install the specific versions listed in the
# '.tool-versions' file located in the project root.
# Ensure you are in the project root directory before running this.
asdf install

# --- Setup Complete ---
# Your environment should now be set up with the correct Erlang and Elixir versions.
# You can now proceed with project-specific commands.

# Project setup commands (run after asdf setup is complete and you are in the project directory):
git clone https://github.com/V-Sekai-fire/aria-character-core.git aria-character-core
cd aria-character-core
mix deps.get
mix ecto.setup
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
- **OTP-Native Process Management for Elixir Services**: Leveraging Elixir/OTP's supervisor trees for the lifecycle and fault tolerance of processes _within each Elixir application_. This provides highly efficient, built-in mechanisms for managing these internal processes. For managing external standalone services (like databases or OpenBao if run independently) or containerized workloads (like Python ML tasks), other tools (e.g., systemd, Docker, Kubernetes, as outlined in the Deployment section) are typically used in conjunction with the Elixir applications.

---

Built with ❤️ by [Chibifire](https://chibifire.com) • Powered by Elixir & OTP
