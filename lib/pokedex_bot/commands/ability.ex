defmodule PokedexBot.Commands.Ability do
  @prefix Application.fetch_env!(:pokedex_bot, :prefix)

  import Nostrum.Struct.Embed
  alias Nostrum.Api
  alias PokedexBot.PokeApi.Abilities
  alias PokedexBot.PokeApi.Cache
  alias PokedexBot.EmbedPaginator

  def handle(args, msg) do
    if Enum.empty?(args) do
      abilities = Cache.get(Abilities, :get_ability, [])

      user_name = if msg.member.nick, do: msg.member.nick, else: msg.author.username

      user = %{
        id: msg.author.id,
        avatar: Nostrum.Struct.User.avatar_url(msg.author),
        name: user_name
      }

      EmbedPaginator.init_user_pagination(
        :ability_paginator,
        user,
        abilities,
        18,
        msg.channel_id,
        0
      )
    else
      ability = Enum.fetch!(args, 0)
      {status, body} = Cache.get(Abilities, :get_ability, [ability])

      if status != 200 do
        Api.create_message!(
          msg.channel_id,
          "Item with name or id `#{ability}` not found.\n#{usage()}"
        )
      else
        bulbapedia_url = Application.fetch_env!(:pokedex_bot, :bulbapedia_url)
        pokedex_picture = Application.fetch_env!(:pokedex_bot, :pokedex_picture)

        pokemons_str =
          if Enum.empty?(body[:pokemons]),
            do: "\u200B",
            else: Enum.join(body[:pokemons], "\n")

        embed =
          %Nostrum.Struct.Embed{}
          |> put_color(1_752_220)
          |> put_author("Pokédex", "", pokedex_picture)
          |> put_title(body[:name])
          |> put_url(bulbapedia_url <> "/" <> String.replace(body[:name], " ", "_"))
          |> put_description(
            "#" <>
              (body[:id] |> Integer.to_string() |> String.pad_leading(3, "0")) <>
              "\n" <> body[:flavor_text]
          )
          |> put_field("Effect", body[:effect], false)
          |> put_field("Pokemons:", pokemons_str, false)

        Api.create_message!(msg.channel_id, embed: embed)
      end
    end
  end

  def usage do
    """
    Usage:
        **`#{@prefix}ability`**
        **`#{@prefix}ability ability_name_or_id`**
    """
  end

  def help do
    """
    #{usage()}
    If no argument is given returns a list of abilities.
    If argument ability_name_or_id is present returns info about specific ability.
    """
  end
end
