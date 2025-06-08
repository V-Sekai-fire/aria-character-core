# asdf-vm Installation Guide

This guide provides detailed steps for installing `asdf-vm` and configuring it for your shell. `asdf-vm` is used by Aria Character Core to manage Erlang and Elixir versions.

**Prerequisite:** Ensure 'git' is installed on your system.

## Step 1: Clone asdf-vm

Clone the `asdf-vm` repository (v0.14.0 specific to these instructions). If you have `asdf` already installed, you might skip this or see an error if the directory exists.

```bash
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
```

## Step 2: Add asdf to your Shell

Execute the commands appropriate for YOUR shell. After this, you **MUST open a new terminal window/tab OR source your shell's configuration file** (e.g., `source ~/.bashrc` for Bash).

### For Bash users:
Append the following to your `~/.bashrc` file:

```bash
echo '' >> ~/.bashrc # Adds a newline for better separation
echo '# Initialize asdf version manager' >> ~/.bashrc
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc
```
Then, source your `.bashrc` or open a new terminal:
```bash
source ~/.bashrc
```

### For Zsh users:
Append the following to your `~/.zshrc` file:

```bash
# echo '' >> ~/.zshrc
# echo '# Initialize asdf version manager' >> ~/.zshrc
# echo '. "$HOME/.asdf/asdf.sh"' >> ~/.zshrc
```
Then, source your `.zshrc` or open a new terminal:
```bash
# source ~/.zshrc
```
*(Uncomment the lines above to run them)*

### For Fish users:
Create a symlink:

```bash
# mkdir -p ~/.config/fish/completions
# ln -s ~/.asdf/completions/asdf.fish ~/.config/fish/completions
```
*(Uncomment the lines above to run them)*

## Step 3: Verify Installation

After sourcing your shell configuration or opening a new terminal, the `asdf` command should be recognized. You can verify this by typing:

```bash
asdf --version
```

You should see the version number of `asdf` printed. You can now return to the main project README's Quick Start section to continue with adding plugins and installing project versions.
