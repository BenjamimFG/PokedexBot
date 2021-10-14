defmodule PokedexBot.EmbedPaginator do
  import Nostrum.Struct.Embed
  import PokedexBot.EmbedPaginator.ActiveUser

  alias PokedexBot.EmbedPaginator.ActiveUser
  alias Nostrum.Api
  alias Nostrum.Struct.Emoji

  @type item :: %{
          id: integer(),
          name: String.t()
        }

  @spec new_paginator(atom, String.t(), integer) :: true
  def new_paginator(key, title, color) do
    :ets.new(key, [:named_table, :public])
    :ets.insert(key, {:title, title})
    :ets.insert(key, {:color, color})
  end

  @spec init_user_pagination(
          atom,
          ActiveUser.user(),
          list(item()),
          integer,
          Nostrum.Snowflake.t(),
          integer
        ) :: :ok
  def init_user_pagination(key, user, items, items_per_page, channel_id, initial_page) do
    remove_active_user(user.id)

    total_pages = trunc(Float.floor(length(items) / items_per_page))

    :ets.insert(key, {:items, items})
    :ets.insert(key, {:items_per_page, items_per_page})
    :ets.insert(key, {:total_pages, total_pages})

    bot_msg = Api.create_message!(channel_id, embed: get_page(key, initial_page, user))

    create_multiple_reactions(bot_msg.channel_id, bot_msg.id, [
      %Emoji{name: "◀️"},
      %Emoji{name: "▶️"},
      %Emoji{name: "🗑️"}
    ])

    active_user = %ActiveUser{
      user: user,
      channel_id: bot_msg.channel_id,
      message_id: bot_msg.id,
      paginator: key,
      page: initial_page
    }

    [{_, active_users}] = :ets.lookup(:active_users, :list)
    new_active_users = [active_user | active_users]

    :ets.insert(:active_users, {:list, new_active_users})

    Task.async(fn ->
      :timer.sleep(5 * 60 * 1000)
      remove_active_user(user.id)
    end)

    :ok
  end

  @spec remove_active_user(Nostrum.Snowflake.t()) :: true
  defp remove_active_user(author_id) do
    active_user = get_active_user(author_id)

    if active_user != nil do
      Api.delete_message(active_user.channel_id, active_user.message_id)

      [{_, active_users}] = :ets.lookup(:active_users, :list)

      new_active_users =
        active_users
        |> Enum.filter(fn u -> u.user.id != author_id end)

      :ets.insert(:active_users, {:list, new_active_users})
    end
  end

  @spec get_active_user(Nostrum.Snowflake.t()) :: %ActiveUser{} | nil
  defp get_active_user(author_id) do
    [{_, active_users}] = :ets.lookup(:active_users, :list)

    Enum.find(active_users, fn user -> user.user.id == author_id end)
  end

  @spec change_page(atom, atom, ActiveUser.user()) :: nil | :ok
  def change_page(key, action, user) do
    active_user = get_active_user(user.id)
    current_page = active_user.page
    [{_, total_pages}] = :ets.lookup(key, :total_pages)

    case action do
      :next ->
        page = current_page + 1
        page = if page > total_pages, do: 0, else: page

        Api.delete_user_reaction!(
          active_user.channel_id,
          active_user.message_id,
          %Emoji{name: "▶️"},
          user.id
        )

        Api.edit_message!(active_user.channel_id, active_user.message_id,
          embed: get_page(key, page, user)
        )

      :prev ->
        page = current_page - 1
        page = if page < 0, do: total_pages, else: page

        Api.delete_user_reaction(
          active_user.channel_id,
          active_user.message_id,
          %Emoji{name: "◀️"},
          user.id
        )

        Api.edit_message!(active_user.channel_id, active_user.message_id,
          embed: get_page(key, page, user)
        )

      :del ->
        remove_active_user(user.id)
        :ok

      _ ->
        nil
    end
  end

  @spec get_page(atom, integer, ActiveUser.user()) :: %Nostrum.Struct.Embed{}
  defp get_page(key, page, user) do
    [{_, items_per_page}] = :ets.lookup(key, :items_per_page)
    [{_, items}] = :ets.lookup(key, :items)

    items = Enum.slice(items, page * items_per_page, items_per_page)

    [{_, active_users}] = :ets.lookup(:active_users, :list)

    case get_active_user(user.id) do
      nil ->
        nil

      active_user ->
        updated_active_user = %{active_user | page: page}

        active_users = Enum.filter(active_users, fn u -> u.user.id != user.id end)
        updated_active_users = [updated_active_user | active_users]

        :ets.insert(:active_users, {:list, updated_active_users})
    end

    make_embed(key, items, page, user)
  end

  @spec make_embed(atom, list(item()), integer, ActiveUser.user()) :: %Nostrum.Struct.Embed{}
  defp make_embed(key, items, page, user) do
    [{_, color}] = :ets.lookup(key, :color)
    [{_, title}] = :ets.lookup(key, :title)
    [{_, total_pages}] = :ets.lookup(key, :total_pages)

    embed =
      %Nostrum.Struct.Embed{}
      |> put_color(color)
      |> put_author("Requested by: " <> user.name, "", user.avatar)
      |> put_title(title)
      |> put_footer("Page: #{page + 1}/#{total_pages + 1}")

    embed =
      Enum.reduce(items, embed, fn item, acc ->
        id_str = "#" <> (item.id |> Integer.to_string() |> String.pad_leading(3, "0"))
        put_field(acc, id_str, item.name, true)
      end)

    embed
  end

  @spec create_multiple_reactions(
          Nostrum.Snowflake.t(),
          Nostrum.Snowflake.t(),
          list(%Emoji{})
        ) :: Task.t()
  defp create_multiple_reactions(channel_id, message_id, emoji_list) do
    Task.async(fn ->
      emoji_list
      |> Enum.each(fn emoji ->
        :timer.sleep(100)
        Api.create_reaction!(channel_id, message_id, emoji)
      end)
    end)
  end
end
