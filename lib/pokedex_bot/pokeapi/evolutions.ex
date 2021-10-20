defmodule PokedexBot.PokeApi.Evolutions do
  alias PokedexBot.PokeApi
  require Logger

  @type evolution :: %{
          id: integer,
          name: String.t(),
          trees: list
        }

  @spec get_tree(integer | String.t()) :: {integer, %{} | evolution()}
  def get_tree(pokemon) do
    pokemon_str = if is_integer(pokemon), do: Integer.to_string(pokemon), else: pokemon

    uri = "/pokemon-species" <> "/" <> pokemon_str
    %{status_code: status_code, body: body} = PokeApi.get!(uri)

    case status_code do
      200 ->
        name =
          body[:names]
          |> Enum.filter(fn el -> el["language"]["name"] == "en" end)
          |> Enum.fetch!(0)
          |> Map.get("name")

        evolution_url = body[:evolution_chain]["url"]
        %{status_code: _, body: evolution_body} = PokeApi.get!(evolution_url)

        {status_code, %{id: body[:id], name: name, trees: get_trees(evolution_body[:chain])}}

      _ ->
        {status_code, body}
    end
  end

  defp get_trees(chain, trees \\ []) do
    trees = List.insert_at(trees, -1, chain["species"]["name"])
    chains = chain["evolves_to"]

    case length(chains) do
      0 ->
        trees

      1 ->
        get_trees(Enum.fetch!(chains, 0), trees)

      _ ->
        Enum.map(chains, fn ch -> get_trees(ch, trees) end)
    end
  end
end
