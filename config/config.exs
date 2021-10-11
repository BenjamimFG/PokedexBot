import Config

config :pokedex_bot,
  prefix: "p!"

config :nostrum,
  token: System.get_env("POKEDEX_TOKEN")

config :porcelain,
  goon_warn_if_missing: false

config :logger,
  level: :warn
