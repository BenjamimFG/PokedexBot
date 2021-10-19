defmodule PokedexBot.Commands do
  alias Nostrum.Api

  alias PokedexBot.Commands.{
    Help,
    Pokemon,
    Item
  }

  @prefix Application.fetch_env!(:pokedex_bot, :prefix)

  @spec handle(String.t(), list(String.t()), Nostrum.Struct.Message.t()) ::
          :ok | Api.error() | {:ok, Nostrum.Struct.Message.t()}
  def handle(command, args, msg) do
    case command do
      "help" ->
        Help.handle(args, msg.channel_id)

      "pokemon" ->
        Pokemon.handle(args, msg)

      "item" ->
        Item.handle(args, msg)

      _ ->
        Api.create_message(msg.channel_id, not_found(command))
    end
  end

  @spec not_found(String.t()) :: String.t()
  def not_found(command) do
    """
    Command `#{command}` not found.
    Use **`#{@prefix}help`** to list all available commands.
    """
  end
end
