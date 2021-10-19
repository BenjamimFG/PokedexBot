defmodule PokedexBot.PokeApi.Items do
  alias PokedexBot.PokeApi

  @base_url "/item"

  @type item :: %{
          id: integer(),
          name: String.t(),
          flavor_text: String.t(),
          effects: list(String.t()),
          held_by_pokemons: list(String.t()),
          sprite: String.t()
        }

  @spec get_item :: list(%{id: integer, name: String.t()})
  def get_item() do
    PokeApi.get!(@base_url <> "?limit=954").body[:results]
    |> Enum.map(fn el ->
      %{
        id: String.to_integer(List.last(String.split(el["url"], "/", trim: true))),
        name: el["name"]
      }
    end)
  end

  @spec get_item(String.t() | integer()) :: {integer, item()}
  def get_item(item) do
    item_str = if is_integer(item), do: Integer.to_string(item), else: item

    uri = @base_url <> "/" <> item_str
    res = PokeApi.get!(uri)

    body = res.body

    parsed_body = %{
      id: body[:id]
    }

    parsed_body =
      body[:names]
      |> Enum.filter(fn el -> el["language"]["name"] == "en" end)
      |> Enum.fetch!(0)
      |> Map.get("name")
      |> (&Map.put(parsed_body, :name, &1)).()

    parsed_body =
      body[:flavor_text_entries]
      |> Enum.filter(fn el -> el["language"]["name"] == "en" end)
      |> Enum.fetch!(0)
      |> Map.get("text")
      |> (&Map.put(parsed_body, :flavor_text, &1)).()

    parsed_body =
      body[:effect_entries]
      |> Enum.filter(fn el -> el["language"]["name"] == "en" end)
      |> Enum.map(fn el -> el["effect"] end)
      |> (&Map.put(parsed_body, :effects, &1)).()

    parsed_body =
      body[:held_by_pokemon]
      |> Enum.map(fn el -> "`#{el["pokemon"]["name"]}`" end)
      |> (&Map.put(parsed_body, :held_by_pokemons, &1)).()

    parsed_body = Map.put(parsed_body, :sprite, body[:sprites]["default"])

    {res.status_code, parsed_body}
  end
end
