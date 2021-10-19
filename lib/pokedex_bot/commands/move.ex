defmodule PokedexBot.Commands.Move do
  @prefix Application.fetch_env!(:pokedex_bot, :prefix)

  import Nostrum.Struct.Embed
  alias Nostrum.Api
  alias PokedexBot.PokeApi.Moves
  alias PokedexBot.PokeApi.Cache
  alias PokedexBot.EmbedPaginator

  def handle(args, msg) do
    if Enum.empty?(args) do
      moves = Cache.get(Moves, :get_move, [])

      user_name = if msg.member.nick, do: msg.member.nick, else: msg.author.username

      user = %{
        id: msg.author.id,
        avatar: Nostrum.Struct.User.avatar_url(msg.author),
        name: user_name
      }

      EmbedPaginator.init_user_pagination(
        :move_paginator,
        user,
        moves,
        18,
        msg.channel_id,
        0
      )
    else
      move = Enum.fetch!(args, 0)
      {status, body} = Cache.get(Moves, :get_move, [move])

      if status != 200 do
        Api.create_message!(
          msg.channel_id,
          "Move with name or id `#{move}` not found.\n#{usage()}"
        )
      else
        bulbapedia_url = Application.fetch_env!(:pokedex_bot, :bulbapedia_url)
        pokedex_picture = Application.fetch_env!(:pokedex_bot, :pokedex_picture)

        learned_by =
          if length(body[:learned_by]) > 80 do
            body[:learned_by]
            |> Enum.slice(0, 80)
            |> List.insert_at(81, "`...`")
          else
            body[:learned_by]
          end

        learned_by_str =
          if Enum.empty?(learned_by),
            do: "\u200B",
            else: Enum.join(learned_by, " ")

        embed =
          %Nostrum.Struct.Embed{}
          |> put_color(
            case body[:damage_class] do
              "physical" ->
                11_027_200

              "special" ->
                10_181_046

              _ ->
                9_807_270
            end
          )
          |> put_author("Pokédex", "", pokedex_picture)
          |> put_title(body[:name])
          |> put_url(bulbapedia_url <> "/" <> String.replace(body[:name], " ", "_"))
          |> put_description(
            "#" <>
              (body[:id] |> Integer.to_string() |> String.pad_leading(3, "0")) <>
              "#{if body[:machine] == nil, do: "", else: " - #{body[:machine]}"}" <>
              "\n" <> body[:flavor_text]
          )
          |> put_field("Effect:", body[:effect], false)
          |> put_field("Type", body[:type], true)
          |> put_field("Category", String.capitalize(body[:damage_class]), true)
          |> put_field("PP", body[:pp], true)
          |> put_field("Power", body[:power], true)
          |> put_field("Accuracy", Integer.to_string(body[:accuracy]) <> "%", true)
          |> put_field("Priority", body[:priority], true)
          |> put_field("Learned by:", learned_by_str, true)

        Api.create_message!(msg.channel_id, embed: embed)
      end
    end
  end

  @spec usage :: String.t()
  def usage do
    """
    Usage:
        **`#{@prefix}move`**
        **`#{@prefix}move move_name_or_id`**
    """
  end

  @spec help :: String.t()
  def help do
    """
    #{usage()}
    If no argument is given returns a list of moves.
    If argument move_name_or_id is present returns info about specific move.
    """
  end
end
