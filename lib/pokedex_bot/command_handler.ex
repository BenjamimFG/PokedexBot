defmodule PokedexBot.Commands do
  alias Nostrum.Api

  alias PokedexBot.Commands.{
    Help,
    Pokemon
  }

  @prefix Application.fetch_env!(:pokedex_bot, :prefix)

  def handle(command, args, msg) do
    case command do
      "help" ->
        Help.handle(args, msg.channel_id)

      "pokemon" ->
        Pokemon.handle(args, msg)

      _ ->
        Api.create_message(msg.channel_id, not_found(command))
    end
  end

  def not_found(command) do
    """
    Command `#{command}` not found.
    Use **`#{@prefix}help`** to list all available commands.
    """
  end
end
