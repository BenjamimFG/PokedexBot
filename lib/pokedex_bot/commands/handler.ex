defmodule PokedexBot.Commands do
  alias Nostrum.Api

  alias PokedexBot.Commands.{
    Help
  }

  def handle(command, args, channel_id) do
    case command do
      "help" ->
        Help.handle(args, channel_id)

      _ ->
        prefix = Application.fetch_env!(:pokedex_bot, :prefix)

        Api.create_message(
          channel_id,
          "Command `#{command}` not found.\nUse **`#{prefix}help`** to list all available commands."
        )
    end
  end
end
