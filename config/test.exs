# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Silent tests by default, use --trace for verbose output
config :logger, level: :warning

# Set a higher stacktrace limit for more detailed errors
config :phoenix, :stacktrace_depth, 20
