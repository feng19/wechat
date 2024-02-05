import Config

config :logger, level: :debug
config :logger, :console, format: "$time $metadata[$level] $message\n"

if Mix.env() == :test do
  import_config "test.exs"
end
