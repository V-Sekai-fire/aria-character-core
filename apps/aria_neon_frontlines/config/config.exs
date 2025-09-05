import Config

# Configure the endpoint
config :aria_viewer, AriaViewerWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: AriaViewerWeb.ErrorHTML, json: AriaViewerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AriaViewer.PubSub,
  live_view: [signing_salt: "your_live_view_signing_salt"]

# Configure the mailer
config :aria_viewer, AriaViewer.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.7",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
