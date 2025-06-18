# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Print only warnings and errors during test
config :logger, level: :debug

# Set a higher stacktrace limit for more detailed errors
config :phoenix, :stacktrace_depth, 20
