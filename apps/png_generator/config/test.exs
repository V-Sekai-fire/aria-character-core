# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import Config

# Test configuration
config :png_generator,
  default_output_dir: "tmp/test_images"

# Reduce log noise during tests
config :logger, level: :warning
