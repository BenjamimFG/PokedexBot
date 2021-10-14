defmodule PokedexBot.Commands.Pokemon do
  @prefix Application.fetch_env!(:pokedex_bot, :prefix)
  @color_map %{
    "red" => 15_158_332,
    "blue" => 3_447_003,
    "yellow" => 16_776_960,
    "green" => 3_066_993,
    "black" => 2_303_786,
    "brown" => 11_027_200,
    "purple" => 10_181_046,
    "gray" => 9_807_270,
    "white" => 16_777_215,
    "pink" => 15_277_667
  }

  import Nostrum.Struct.Embed
  alias Nostrum.Api
  alias PokedexBot.PokeApi
  alias PokedexBot.PokeApi.Cache
  alias PokedexBot.EmbedPaginator

  def handle(args, msg) do
    if Enum.empty?(args) do
      pokemons = Cache.get(PokeApi, :get_pokemon, [])

      user_name = if msg.member.nick, do: msg.member.nick, else: msg.author.username

      user = %{
        id: msg.author.id,
        avatar: Nostrum.Struct.User.avatar_url(msg.author),
        name: user_name
      }

      EmbedPaginator.init_user_pagination(
        :pokemon_paginator,
        user,
        pokemons,
        18,
        msg.channel_id,
        0
      )
    else
      opts = Enum.filter(args, fn a -> String.starts_with?(a, "-") end)
      args = Enum.filter(args, fn a -> not String.starts_with?(a, "-") end)

      cond do
        "-shiny" in opts and "-sprite" in opts ->
          Api.create_message!(
            msg.channel_id,
            "Options `-sprite` and `-shiny` are mutually exclusive.\n#{usage()}"
          )

        true ->
          pokemon = Enum.fetch!(args, 0)
          {status, body} = Cache.get(PokeApi, :get_pokemon, [pokemon])

          if status != 200 do
            Api.create_message!(
              msg.channel_id,
              "Pokemon with name or id `#{pokemon}` not found.\n#{usage()}"
            )
          else
            bulbapedia_url = Application.fetch_env!(:pokedex_bot, :bulbapedia_url)
            pokedex_picture = Application.fetch_env!(:pokedex_bot, :pokedex_picture)

            held_items_str =
              if Enum.empty?(body[:held_items]),
                do: "\u200B",
                else: Enum.join(body[:held_items], "\n")

            image =
              cond do
                "-sprite" in opts ->
                  body[:sprite]

                "-shiny" in opts ->
                  body[:shiny_sprite]

                true ->
                  body[:artwork]
              end

            embed =
              %Nostrum.Struct.Embed{}
              |> put_color(@color_map[body[:color]])
              |> put_author("Pokédex", "", pokedex_picture)
              |> put_title(body[:name])
              |> put_url(bulbapedia_url <> "/" <> body[:name] <> "_(Pokémon)")
              |> put_description(
                "#" <> (body[:id] |> Integer.to_string() |> String.pad_leading(3, "0"))
              )
              |> put_field("Types", Enum.join(body[:types], "\n"), true)
              |> put_field("Abilities", Enum.join(body[:abilities], "\n"), true)
              |> put_field("Held Items", held_items_str, true)
              |> put_field("\u200B", "\u200B")
              |> put_field("Base Stats:", "\u200B")
              |> put_field("HP", body[:stats][:hp], true)
              |> put_field("ATK", body[:stats][:atk], true)
              |> put_field("DEF", body[:stats][:def], true)
              |> put_field("SP. ATK", body[:stats][:sp_atk], true)
              |> put_field("SP. DEF", body[:stats][:sp_def], true)
              |> put_field("SPD", body[:stats][:spd], true)
              |> put_image(image)

            Api.create_message!(msg.channel_id, embed: embed)
          end
      end
    end
  end

  def usage do
    """
    Usage:
        **`#{@prefix}pokemon`**
        **`#{@prefix}pokemon pokemon_name_or_id [opts]`**
    """
  end

  def help(channel_id) do
    message = """
    #{usage()}
    If no argument is given returns a list of pokemons.
    If argument pokemon_name_or_id is not present returns info about specific pokemon.

    opts:
        `-sprite`: Show pokemon sprite instead of official artwork.
        `-shiny`: Show pokemon shiny sprite instead of official artwork.
    """

    Api.create_message!(channel_id, message)
  end
end
