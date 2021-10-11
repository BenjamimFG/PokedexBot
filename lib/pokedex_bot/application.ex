defmodule PokedexBot.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PokedexBot.ConsumerSupervisor
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: PokedexBot.Supervisor)
  end
end
