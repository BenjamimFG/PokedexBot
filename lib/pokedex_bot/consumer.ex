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
        command = String.downcase(Enum.fetch!(message, 0))

        PokedexBot.Commands.handle(command, args, msg)
      end
    end
  end

  def handle_event({:MESSAGE_REACTION_ADD, msg, _ws_state}) do
    unless Map.has_key?(msg.member.user, :bot) and msg.member.user.bot do
      [{_, active_users}] = :ets.lookup(:active_users, :list)

      case Enum.find(active_users, fn u -> u.user.id == msg.member.user.id end) do
        nil ->
          :noop

        active_user ->
          emoji_action_map = %{
            "▶️" => :next,
            "◀️" => :prev,
            "🗑️" => :del
          }

          if msg.emoji.name in Map.keys(emoji_action_map) do
            PokedexBot.EmbedPaginator.change_page(
              active_user.paginator,
              emoji_action_map[msg.emoji.name],
              active_user.user
            )
          end
      end
    end
  end

  def handle_event(_event) do
    :noop
  end
end
