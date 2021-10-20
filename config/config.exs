import Config

config :pokedex_bot,
  prefix: "p!",
  pokeapi_url: "https://pokeapi.co/api/v2",
  bulbapedia_url: "https://bulbapedia.bulbagarden.net/wiki",
  pokedex_picture: "https://i.imgur.com/b9hwqWV.png"

config :nostrum,
  token: System.get_env("POKEDEX_TOKEN")

config :porcelain,
  goon_warn_if_missing: false

config :logger,
  level: :warn,
  trucate: :infinity
