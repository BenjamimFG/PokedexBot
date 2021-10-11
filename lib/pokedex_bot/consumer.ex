defmodule PokedexBot.Consumer do
  use Nostrum.Consumer

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    unless msg.author.bot do
      prefix = Application.fetch_env!(:pokedex_bot, :prefix)

      if String.starts_with?(msg.content, prefix) do
        message =
          String.trim(msg.content)
          |> String.slice(String.length(prefix)..-1)
          |> String.split()

        args = List.delete_at(message, 0)
        command = Enum.fetch!(message, 0)

        # IO.puts("command: #{command}")
        # IO.puts("args: #{Enum.join(args, ", ")}")

        PokedexBot.Commands.handle(command, args, msg.channel_id)
      end
    end
  end

  def handle_event(_event) do
    :noop
  end
end
