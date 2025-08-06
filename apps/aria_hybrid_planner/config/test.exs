# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config

# Enable debug logs for trace mode debugging
# This allows Logger.debug/1 calls to work when running mix test --trace
# Normal test runs remain silent due to TestOutput module conditional logging
config :logger, level: :debug

# Exclude integration tests by default
# Run integration tests with: mix test --include integration
config :ex_unit, exclude: [:integration]
