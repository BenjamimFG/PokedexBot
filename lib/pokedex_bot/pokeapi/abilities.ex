defmodule PokedexBot.PokeApi.Abilities do
  alias PokedexBot.PokeApi

  @base_url "/ability"

  @type ability :: %{
          id: integer(),
          name: String.t(),
          flavor_text: String.t(),
          effect: String.t(),
          pokemons: list(String.t())
        }

  @spec get_ability :: list(%{id: integer, name: String.t()})
  def get_ability() do
    PokeApi.get!(@base_url <> "?limit=9999").body[:results]
    |> Enum.map(fn el ->
      %{
        id: String.to_integer(List.last(String.split(el["url"], "/", trim: true))),
        name: el["name"]
      }
    end)
  end

  def get_ability(ability) do
    ability_str = if is_integer(ability), do: Integer.to_string(ability), else: ability

    uri = @base_url <> "/" <> ability_str
    %{status_code: status_code, body: body} = PokeApi.get!(uri)

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
      |> Map.get("flavor_text")
      |> String.replace(~r/\s+/, " ")
      |> (&Map.put(parsed_body, :flavor_text, &1)).()

    parsed_body =
      body[:effect_entries]
      |> Enum.filter(fn el -> el["language"]["name"] == "en" end)
      |> Enum.fetch!(0)
      |> Map.get("effect")
      |> (&Map.put(parsed_body, :effect, &1)).()

    parsed_body =
      body[:pokemon]
      |> Enum.map(fn el ->
        if el["is_hidden"],
          do: "||`#{el["pokemon"]["name"]}`||",
          else: "`#{el["pokemon"]["name"]}`"
      end)
      |> (&Map.put(parsed_body, :pokemons, &1)).()

    {status_code, parsed_body}
  end
end
