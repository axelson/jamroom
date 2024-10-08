# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :jamroom,
  ecto_repos: [Jamroom.Repo]

# Configures the endpoint
config :jamroom, JamroomWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "RwSstVPCy1KxJRqo05QuOP8T9CgTomCQmtNPrghMeXLAz178WohZbXhrj7skm0zI",
  render_errors: [view: JamroomWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Jamroom.InternalPubSub,

  live_view: [
    signing_salt: "pls.pls.poogy123"
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :phoenix,
  template_engines: [leex: Phoenix.LiveView.Engine]

config :esbuild,
  version: "0.14.41",
  default: [
    args:
      ~w(js/app.js --bundle --minify --sourcemap=external --target=es2020 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :dart_sass,
  version: "1.61.0",
  default: [
    args:
      ~w(--load-path=node_modules --no-source-map css/app.scss ../priv/static/assets/app.css),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
