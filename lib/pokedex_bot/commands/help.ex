defmodule PokedexBot.Commands.Help do
  @prefix Application.fetch_env!(:pokedex_bot, :prefix)

  alias Nostrum.Api

  alias PokedexBot.Commands.{
    Pokemon,
    Item,
    Ability
  }

  @spec handle(list(String.t()), Nostrum.Struct.Message.t()) ::
          Api.error() | {:ok, Nostrum.Struct.Message.t()}
  def handle(args, msg) do
    commands = %{
      help: __MODULE__,
      pokemon: Pokemon,
      item: Item,
      ability: Ability
    }

    available_commands =
      Map.keys(commands)
      |> Enum.map(fn el -> Atom.to_string(el) end)

    if Enum.empty?(args) do
      message = "Available commands:\n"

      commands = Enum.map(available_commands, fn el -> "\t**`#{el}`**" end)

      message = message <> Enum.join(commands, "\n")

      message =
        message <> "\nUse **`#{@prefix}help command`** to get help about a specific command"

      Api.create_message(msg.channel_id, message)
    else
      command = Enum.fetch!(args, 0)

      help_msg =
        if command in available_commands do
          commands[String.to_existing_atom(command)].help()
        else
          "Command `#{command}` not found.\nUse **`#{@prefix}help`** to list all available commands."
        end

      Api.create_message(msg.channel_id, help_msg)
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

  @spec help :: String.t()
  def help do
    """
    #{usage()}
    If called without any argument lists all available commands.
    If passed a `command` argument shows help for the specified command.
    """
  end
end
