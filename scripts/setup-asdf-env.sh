#!/usr/bin/env bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

set -euo pipefail

echo "Setting up asdf environment..."

# Add asdf to PATH if not already available
if ! command -v asdf &> /dev/null; then
    if [ -f "$HOME/.asdf/bin/asdf" ]; then
        export PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH"
        # Source asdf.sh if available
        [ -f "$HOME/.asdf/asdf.sh" ] && source "$HOME/.asdf/asdf.sh"
    else
        echo "Error: asdf not found. Please install asdf first."
        exit 1
    fi
fi

echo "Installing Erlang and Elixir using asdf..."

# Add plugins (ignore errors if already added)
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git || echo "Erlang plugin already added or command failed."
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git || echo "Elixir plugin already added or command failed."

echo "Installing Erlang, this may take a while..."
asdf install erlang

echo "Installing Elixir..."
asdf install elixir

echo "Setting global Erlang and Elixir versions..."
asdf global erlang $(asdf current erlang | awk '{print $2}')
asdf global elixir $(asdf current elixir | awk '{print $2}')

echo "Updating local Hex and Rebar..."
mix local.hex --force
mix local.rebar --force

echo "Erlang and Elixir environment setup complete."