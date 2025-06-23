import Config

# Test configuration
config :elixir_png,
  default_output_dir: "tmp/test_images"

# Reduce log noise during tests
config :logger, level: :warning
