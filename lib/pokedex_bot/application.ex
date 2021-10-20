defmodule PokedexBot.Application do
  use Application

  @impl true
  def start(_type, _args) do
    # init pokeapi cache on ets
    :ets.new(:pokeapi_cache, [:named_table, :public])
    :ets.new(:active_users, [:named_table, :public])
    :ets.insert(:active_users, {:list, []})

    PokedexBot.EmbedPaginator.new_paginator(:pokemon_paginator, "Pokémons", 15_158_332)
    PokedexBot.EmbedPaginator.new_paginator(:item_paginator, "Items", 3_447_003)
    PokedexBot.EmbedPaginator.new_paginator(:ability_paginator, "Abilities", 1_752_220)
    PokedexBot.EmbedPaginator.new_paginator(:move_paginator, "Moves", 3_066_993)

    children = [
      PokedexBot.ConsumerSupervisor
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: PokedexBot.Supervisor)
  end
end
