defmodule PokedexBot.Commands.Item do
  @prefix Application.fetch_env!(:pokedex_bot, :prefix)

  import Nostrum.Struct.Embed
  alias Nostrum.Api
  alias PokedexBot.PokeApi.Items
  alias PokedexBot.PokeApi.Cache
  alias PokedexBot.EmbedPaginator

  def handle(args, msg) do
    if Enum.empty?(args) do
      items = Cache.get(Items, :get_item, [])

      user_name = if msg.member.nick, do: msg.member.nick, else: msg.author.username

      user = %{
        id: msg.author.id,
        avatar: Nostrum.Struct.User.avatar_url(msg.author),
        name: user_name
      }

      EmbedPaginator.init_user_pagination(
        :item_paginator,
        user,
        items,
        18,
        msg.channel_id,
        0
      )
    else
      item = Enum.fetch!(args, 0)
      {status, body} = Cache.get(Items, :get_item, [item])

      if status != 200 do
        Api.create_message!(
          msg.channel_id,
          "Item with name or id `#{item}` not found.\n#{usage()}"
        )
      else
        bulbapedia_url = Application.fetch_env!(:pokedex_bot, :bulbapedia_url)
        pokedex_picture = Application.fetch_env!(:pokedex_bot, :pokedex_picture)

        effects_str =
          body[:effects]
          |> Enum.map(fn el -> String.replace(el, ~r/\s+/, " ") end)
          |> Enum.map(fn el ->
            case String.split(el, ": ", parts: 2, trim: true) do
              [title, effect] ->
                "**#{title}:**\n\t#{effect}"

              _ ->
                el
            end
          end)
          |> Enum.join("\n\n")

        held_by_str =
          if Enum.empty?(body[:held_by_pokemons]),
            do: "\u200B",
            else: Enum.join(body[:held_by_pokemons], "\n")

        embed =
          %Nostrum.Struct.Embed{}
          |> put_color(3_447_003)
          |> put_thumbnail(body[:sprite])
          |> put_author("Pokédex", "", pokedex_picture)
          |> put_title(body[:name])
          |> put_url(bulbapedia_url <> "/" <> String.replace(body[:name], " ", "_"))
          |> put_description(
            "#" <>
              (body[:id] |> Integer.to_string() |> String.pad_leading(3, "0")) <>
              "\n" <> String.replace(body[:flavor_text], ~r/\s+/, " ")
          )
          |> put_field("Effects", effects_str, false)
          |> put_field("Held by:", held_by_str, false)

        Api.create_message!(msg.channel_id, embed: embed)
      end
    end
  end

  def usage do
    """
    Usage:
        **`#{@prefix}item`**
        **`#{@prefix}item item_name_or_id`**
    """
  end

  def help do
    """
    #{usage()}
    If no argument is given returns a list of items.
    If argument item_name_or_id is present returns info about specific item.
    """
  end
end
