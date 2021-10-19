defmodule PokedexBot.Commands.Help do
  @prefix Application.fetch_env!(:pokedex_bot, :prefix)

  alias Nostrum.Api

  alias PokedexBot.Commands.{
    Pokemon
  }

  @spec handle(list(String.t()), Nostrum.Snowflake.t()) ::
          Api.error() | {:ok, Nostrum.Struct.Message.t()}
  def handle(args, channel_id) do
    available_commands = [
      "help",
      "pokemon"
    ]

    if Enum.empty?(args) do
      message = "Available commands:\n"

      commands = Enum.map(available_commands, fn el -> "\t**`#{el}`**" end)

      message = message <> Enum.join(commands, "\n")

      message =
        message <> "\nUse **`#{@prefix}help command`** to get help about a specific command"

      Api.create_message(channel_id, message)
    else
      command = Enum.fetch!(args, 0)

      case command do
        "help" ->
          help(channel_id)

        "pokemon" ->
          Pokemon.help(channel_id)

        _ ->
          Api.create_message(
            channel_id,
            "Command `#{command}` not found.\nUse **`#{@prefix}help`** to list all available commands."
          )
      end
    end
  end

  @spec usage :: String.t()
  def usage do
    """
    Usage:
        **`#{@prefix}help`**
        **`#{@prefix}help command`**
    """
  end

  @spec help(Nostrum.Snowflake.t()) :: Api.Error.t() | {:ok, Nostrum.Struct.Message.t()}
  def help(channel_id) do
    message = """
    #{usage()}
    If called without any argument lists all available commands.
    If passed a `command` argument shows help for the specified command.
    """

    Api.create_message(channel_id, message)
  end
end
