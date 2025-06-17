use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :aria_engine, AriaEngineWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :debug

# Initialize and configure
config :aria_engine, :ecto_repos, []

# Set a higher stacktrace limit for more detailed errors
config :phoenix, :stacktrace_depth, 20

# Configure parameters for
# the `mix test --cover` command.
config :excoveralls,
  tool: ExCoveralls.LCOV,
  inputs: ["lib", "apps/aria_engine/lib", "apps/aria_auth/lib", "apps/aria_workflow/lib", "apps/aria_file_management/lib", "apps/aria_storage/lib"],
  excluded: [
    ~r"test",
    ~r"mix.exs",
    ~r"lib/aria_engine/application.ex",
    ~r"lib/aria_engine/release.ex",
    ~r"lib/aria_engine_web/",
    ~r"lib/aria_engine/domains/"
  ]
