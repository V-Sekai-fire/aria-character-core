import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
Config.config :aria_engine, AriaEngineWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
Config.config :logger, level: :debug

# Initialize and configure
Config.config :aria_engine, :ecto_repos, []

# Set a higher stacktrace limit for more detailed errors
Config.config :phoenix, :stacktrace_depth, 20
