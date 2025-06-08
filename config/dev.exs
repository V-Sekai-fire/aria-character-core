import Config

# Development environment configuration
config :logger, level: :debug

# Configure development database (PostgreSQL adapter, CockroachDB compatible)
config :aria_data, AriaData.Repo,
  username: "postgres",
  password: "postgres", 
  hostname: "localhost",
  database: "aria_character_core_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  adapter: Ecto.Adapters.Postgres

# Development Phoenix configuration for coordinate service
config :aria_coordinate, AriaCoordinateWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "development_secret_key_base_replace_in_production",
  watchers: []

# Configure Oban for development (used by queue service)
config :aria_queue, Oban,
  repo: AriaData.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [
    ai_generation: 5,
    planning: 10,
    storage_sync: 3,
    monitoring: 2
  ]

# OpenBao development configuration (security service)
config :aria_security,
  openbao_url: "http://localhost:8200",
  openbao_token: System.get_env("OPENBAO_DEV_TOKEN") || "dev-token"

# AI Service development configuration
config :aria_interpret,
  qwen_model_path: "/models/qwen3.onnx",
  gpu_enabled: System.get_env("ARIA_GPU_ENABLED") == "true",
  batch_size: 1

# Shape Service development configuration  
config :aria_shape,
  qwen_model_path: "/models/qwen3.onnx",
  gpu_enabled: System.get_env("ARIA_GPU_ENABLED") == "true",
  batch_size: 1,
  grpo_enabled: true

# Storage Service development configuration
config :aria_storage,
  backend: :local,
  local_path: "tmp/storage",
  chunk_size: 64 * 1024,
  cdn_enabled: false

# Authentication Service development configuration
config :aria_auth,
  jwt_secret: "development_jwt_secret_key",
  session_ttl: 3600,
  webrtc_enabled: false

# Interface Service development configuration
config :aria_interface, AriaInterfaceWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4001],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "development_interface_secret_key_base"

# Monitor Service development configuration
config :aria_monitor,
  prometheus_enabled: false,
  live_dashboard_enabled: true