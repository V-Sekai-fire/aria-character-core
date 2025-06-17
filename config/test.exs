import Config

# We don't want to configure the logger in tests, but we do want to suppress
# the ipyhop_loop messages.
config :logger,
  backends: [:console],
  level: :info, # Set default level to info to hide debug messages
  # compile_time_purge_matching: [
  #   [module: AriaEngine.IpyhopLoop, level: :info] # Suppress ipyhop_loop messages
  # ],
  # metadata: [:file, :line, :function, :module, :pid, :level, :node], # This line is correct, the error was elsewhere.
  format: "$time $metadata[$level] $message\n",
  utc_log: true,
  sync_threshold: 1000,
  discard_threshold: 5000,
  truncate: 8000,
  handle_otp_reports: true,
  handle_sasl_reports: true


# Configure AriaAuth.Repo for testing
config :aria_auth, AriaAuth.Repo,
  adapter: Ecto.Adapters.SQLite3,
  database: ":memory:", # In-memory database for testing
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1

# We don't run a server during test. If one is required,
# you can enable the server option below.
# config :aria_character_core, AriaCharacterCoreWeb.Endpoint,
#   http: [port: 4002],
#   server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
