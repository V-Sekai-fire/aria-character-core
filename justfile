# Main justfile for Aria Character Core
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Import all modular justfiles
import 'justfiles/install'
import 'justfiles/services'
import 'justfiles/test'
import 'justfiles/dev'
import 'justfiles/production'
import 'justfiles/security'

default: 
    @just --list

# Quick access aliases to commonly used recipes
alias deps := install-deps
alias start := start-all
alias stop := stop-all-services
alias status := show-services-status
alias logs := show-all-logs
alias health := check-all-health
alias compile := test-elixir-compile
alias unit := test-elixir-unit
alias setup := dev-setup
