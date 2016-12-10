use Mix.Config

# Base config
config :servus,
  backends: [:connect_four],
  modules: [Player_Self, Player_Only, HiScore, Player_FB]

# Configuration for a connect-four game
config :servus,
connect_four: %{
  adapters: [
    tcp: 3334,
    web: 3335
  ],
  players_per_game: 2, 
  implementation: ConnectFour
}

config :servus,
database: %{
  rootpath: "./db",
  testmode: ""
}
# JUST TEST Credentials!!!! NO Real Key or Application
config :servus,
facebook: %{
  app_token: "1216077065136886|yaVQhGi9fzy_N5YchZBH2xQwvzk",
  app_id: "1216077065136886",
  app_secret: "0b2b0ff3fde4bbe08fe58cd012904427"
}


import_config "#{Mix.env}.exs"
