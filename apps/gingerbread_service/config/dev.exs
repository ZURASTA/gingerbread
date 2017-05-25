use Mix.Config

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Configure database
config :gingerbread_service, Gingerbread.Service.Repo,
    adapter: Ecto.Adapters.Postgres,
    username: "postgres",
    password: "postgres",
    database: "gingerbread_service_dev",
    hostname: "localhost",
    pool_size: 10
