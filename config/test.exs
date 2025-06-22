# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Set a higher stacktrace limit for more detailed errors
config :phoenix, :stacktrace_depth, 20

# Exclude integration tests by default
# Run integration tests with: mix test --include integration
config :ex_unit, exclude: [:integration]
