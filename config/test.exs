# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Set a higher stacktrace limit for more detailed errors
config :phoenix, :stacktrace_depth, 20

# Enable debug logs for trace mode debugging
# This allows Logger.debug/1 calls to work when running mix test --trace
# Normal test runs remain silent due to TestOutput module conditional logging
config :logger, level: :debug

# Exclude integration tests by default
# Run integration tests with: mix test --include integration
config :ex_unit, exclude: [:integration]
