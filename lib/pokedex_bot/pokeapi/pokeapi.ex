defmodule PokedexBot.PokeApi do
  use HTTPoison.Base

  alias PokedexBot.PokeApi.Cache

  @type pokemon :: %{
          abilities: list,
          artwork: String.t(),
          color: any,
          held_items: list,
          id: any,
          name: binary,
          sprite: any,
          shiny_sprite: any,
          stats: any,
          types: list
        }

  @url Application.fetch_env!(:pokedex_bot, :pokeapi_url)
  @expected_fields ~w(
    results
    id name abilities held_items types stats sprites
    color
  )

  def get_pokemon() do
    get!("/pokemon?limit=898").body[:results]
    |> Enum.with_index()
    |> Enum.map(fn {el, i} -> %{id: i + 1, name: Map.get(el, "name")} end)
  end

  @spec get_pokemon(String.t() | integer()) :: {integer, pokemon}
  def get_pokemon(pokemon) do
    pokemon_str = if is_integer(pokemon), do: Integer.to_string(pokemon), else: pokemon

    uri = "/pokemon/" <> pokemon_str
    res = get!(uri)

    body = res.body

    parsed_body = %{
      id: body[:id],
      name: String.capitalize(body[:name])
    }

    parsed_body =
      body[:abilities]
      |> Enum.map(fn el ->
        if(el["is_hidden"],
          do: "||`" <> el["ability"]["name"] <> "`||",
          else: "`#{el["ability"]["name"]}`"
        )
      end)
      |> (&Map.put(parsed_body, :abilities, &1)).()

    parsed_body =
      body[:held_items]
      |> Enum.map(fn el -> "`#{el["item"]["name"]}`" end)
      |> (&Map.put(parsed_body, :held_items, &1)).()

    parsed_body =
      body[:types]
      |> Enum.map(fn el -> "`#{el["type"]["name"]}`" end)
      |> (&Map.put(parsed_body, :types, &1)).()

    parsed_body =
      parsed_body
      |> Map.put(:sprite, body[:sprites]["front_default"])
      |> Map.put(:shiny_sprite, body[:sprites]["front_shiny"])

    parsed_body =
      Map.put(
        parsed_body,
        :artwork,
        body[:sprites]["other"]["official-artwork"]["front_default"]
      )

    stats_atoms = %{
      "hp" => :hp,
      "attack" => :atk,
      "defense" => :def,
      "special-attack" => :sp_atk,
      "special-defense" => :sp_def,
      "speed" => :spd
    }

    parsed_body =
      body[:stats]
      |> Enum.map(fn el -> {stats_atoms[el["stat"]["name"]], el["base_stat"]} end)
      |> Enum.into(%{})
      |> (&Map.put(parsed_body, :stats, &1)).()

    parsed_body =
      Map.put(
        parsed_body,
        :color,
        Cache.get(PokedexBot.PokeApi, :get_species_color, [parsed_body[:id]])
      )

    {res.status_code, parsed_body}
  end

  def get_species_color(id) do
    uri = "/pokemon-species/" <> Integer.to_string(id)

    get!(uri).body[:color]["name"]
  end

  def process_request_url(uri) do
    @url <> uri
  end

  def process_response_body(body) do
    unless body == "Not Found" do
      body
      |> Poison.decode!()
      |> Map.take(@expected_fields)
      |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    else
      %{}
    end
  end
end
