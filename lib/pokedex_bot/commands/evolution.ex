defmodule PokedexBot.Commands.Evolution do
  @prefix Application.fetch_env!(:pokedex_bot, :prefix)

  import Nostrum.Struct.Embed
  alias Nostrum.Api
  alias PokedexBot.PokeApi.Evolutions
  alias PokedexBot.PokeApi.Cache

  def handle(args, msg) do
    if Enum.empty?(args) do
      Api.create_message!(msg.channel_id, "Argument pokemon_name_or_id required.\n#{usage()}")
    else
      pokemon = Enum.fetch!(args, 0)
      {status, body} = Cache.get(Evolutions, :get_tree, [pokemon])

      if status != 200 do
        Api.create_message!(
          msg.channel_id,
          "Pokemon with name or id `#{pokemon}` not found.\n#{usage()}"
        )
      else
        bulbapedia_url = Application.fetch_env!(:pokedex_bot, :bulbapedia_url)
        pokedex_picture = Application.fetch_env!(:pokedex_bot, :pokedex_picture)

        tree_strs =
          if is_list(Enum.fetch!(body[:trees], 0)) do
            Enum.map(body[:trees], fn el -> Enum.join(el, " -> ") end)
          else
            if length(body[:trees]) == 1 do
              ["This pokemon does not evolve"]
            else
              [Enum.join(body[:trees], " -> ")]
            end
          end

        embed =
          %Nostrum.Struct.Embed{}
          |> put_color(12_745_742)
          |> put_author("Pokédex", "", pokedex_picture)
          |> put_title(body[:name] <> " Evolution Tree")
          |> put_url(
            bulbapedia_url <> "/" <> String.replace(body[:name], " ", "_") <> "#Evolution"
          )
          |> put_description(
            "#" <> (body[:id] |> Integer.to_string() |> String.pad_leading(3, "0"))
          )

        embed = add_trees_to_embed(embed, tree_strs)

        Api.create_message!(msg.channel_id, embed: embed)
      end
    end
  end

  @spec usage :: String.t()
  def usage do
    """
    Usage:
        **`#{@prefix}evolution pokemon_name_or_id`**
    """
  end

  @spec help :: String.t()
  def help do
    """
    #{usage()}
    Show information about a pokemon evolution tree.
    """
  end

  defp add_trees_to_embed(embed, trees) do
    if length(trees) == 0 do
      embed
    else
      embed = put_field(embed, "Tree:", Enum.fetch!(trees, 0))
      trees = List.delete_at(trees, 0)
      add_trees_to_embed(embed, trees)
    end
  end
end
