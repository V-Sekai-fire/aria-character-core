import Config

# Production configuration
config :elixir_png,
  default_output_dir: "priv/images"

# Reduce log noise in production
config :logger, level: :info
