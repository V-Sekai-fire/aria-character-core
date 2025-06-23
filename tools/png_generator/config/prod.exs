import Config

# Production configuration
config :png_generator,
  default_output_dir: "priv/images"

# Reduce log noise in production
config :logger, level: :info
