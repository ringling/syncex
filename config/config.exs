use Mix.Config

config :raven,
  dsn: System.get_env["SENTRY_DSN"],
  tags: %{
    env: "production"
  }

config :logger,
  backends: [
      {LoggerFileBackend, :error_log},
      {LoggerFileBackend, :info_log},
      {Raven, :error_log},
      :console
    ],
  level: :debug,
  format: "$time $metadata[$level] $message\n"

config :logger, :error_log,
  level: :warn,
  path: "logs/error.log",
  format: "$date $time [$level] $metadata$message\n"

config :logger, :info_log,
  level: :info,
  path: "logs/info.log",
  format: "$date $time [$level] $metadata$message\n"

config :logger, :console,
  level: :debug,
  format: "$date $time [$level] $metadata$message\n"

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

