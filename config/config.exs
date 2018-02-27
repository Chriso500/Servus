use Mix.Config

# Base config
config :servus,
  backends: [:connect_four],
  #backends: [:testModule_1P],
  modules: [Player_Self, Player_Only, Player_FB,Player_Userdata]

#Ecto DB
config :servus, ecto_repos: [Servus.Repo]

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
#Configuration for a Testmodule
config :servus,
testModule_1P: %{
  adapters: [
    tcp: 3334,
    web: 3335
  ],
  players_per_game: 1, 
  implementation: TestModule_1P
}
# JUST TEST Credentials!!!! NO Real Key or Application
config :servus,
facebook: %{
  app_token: "1216077065136886|yaVQhGi9fzy_N5YchZBH2xQwvzk",
  app_id: "1216077065136886",
  app_secret: "0b2b0ff3fde4bbe08fe58cd012904427"
}


config :servus,
player_userdata: %{
  picturepath: "./save/picture",
  profilepath: "./save/profiles"
}

import_config "#{Mix.env}.exs"
