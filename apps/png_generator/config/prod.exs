# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Production configuration
config :png_generator,
  default_output_dir: "priv/images"

# Reduce log noise in production
config :logger, level: :info
