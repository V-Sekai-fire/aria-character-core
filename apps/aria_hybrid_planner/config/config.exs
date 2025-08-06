# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config

# Shared configuration for all apps
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :app]

# Suppress Porcelain goon executable warning
config :porcelain, goon_warn_if_missing: false

# Import environment specific config files
import_config "#{config_env()}.exs"
