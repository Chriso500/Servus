use Mix.Config

config :logger,
  level: :info

config :servus, Servus.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "app",
  username: "db",
  password: "test1234",
  hostname: "localhost",
  port: "5532"