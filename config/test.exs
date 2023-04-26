import Config

config :ecto_querify, ecto_repos: [TestRepo]
config :ecto_querify, TestRepo, url: "ecto://perun:perun@localhost:5432/perun"
config :ecto_querify, TestRepo, pool: Ecto.Adapters.SQL.Sandbox
