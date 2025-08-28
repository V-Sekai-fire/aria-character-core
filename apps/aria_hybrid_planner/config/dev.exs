# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config

# Development environment configuration
config :logger, level: :debug

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"
