#!/usr/bin/env bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Working in project directory: $PROJECT_DIR"
cd "$PROJECT_DIR"

echo "Installing asdf in the project root..."

if [ ! -d "./.asdf" ]; then
    echo "Cloning asdf into ./.asdf..."
    git clone https://github.com/asdf-vm/asdf.git ./.asdf --branch v0.14.0
else
    echo ".asdf already exists in the project root"
fi

echo "Setting up project-local asdf environment..."
# Unset any global asdf environment to avoid conflicts
unset ASDF_DIR ASDF_DATA_DIR || true

# Set project-local asdf environment
export ASDF_DIR="$(pwd)/.asdf"
export ASDF_DATA_DIR="$(pwd)/.asdf"
export PATH="$(pwd)/.asdf/bin:$(pwd)/.asdf/shims:${PATH}"

echo "Sourcing asdf from project directory: $ASDF_DIR"
. ./.asdf/asdf.sh

echo "Adding asdf plugins..."
asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git || true
asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git || true

# Verify .tool-versions exists
if [ ! -f ".tool-versions" ]; then
    echo "❌ Error: .tool-versions file not found in $(pwd)"
    echo "Current directory contents:"
    ls -la
    exit 1
fi

echo "Found .tool-versions file:"
cat .tool-versions

# Check if versions are already installed
if asdf current erlang 2>/dev/null && asdf current elixir 2>/dev/null; then
    echo "✅ Erlang and Elixir are already installed!"
    asdf current
else
    echo "Installing Erlang and Elixir versions (as per .tool-versions)..."
    asdf install
    echo "✅ Installation complete!"
    asdf current
fi
