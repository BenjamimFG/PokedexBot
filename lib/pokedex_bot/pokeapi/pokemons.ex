defmodule PokedexBot.PokeApi.Pokemons do
  alias PokedexBot.PokeApi.Cache
  alias PokedexBot.PokeApi

  @base_url "/pokemon"

  @type pokemon :: %{
          id: integer,
          name: String.t(),
          variation: String.t(),
          color: String.t(),
          types: list(String.t()),
          abilities: list(String.t()),
          held_items: list(String.t()),
          stats: any,
          artwork: String.t(),
          sprite: String.t(),
          shiny_sprite: String.t()
        }

  @spec get_pokemon :: list(%{id: integer, name: String.t()})
  def get_pokemon() do
    PokeApi.get!(@base_url <> "?limit=9999").body[:results]
    |> Enum.map(fn el ->
      %{
        id: String.to_integer(List.last(String.split(el["url"], "/", trim: true))),
        name: el["name"]
      }
    end)
  end

  @spec get_pokemon(String.t() | integer()) :: {integer, pokemon}
  def get_pokemon(pokemon) do
    pokemon_str = if is_integer(pokemon), do: Integer.to_string(pokemon), else: pokemon

    uri = @base_url <> "/" <> pokemon_str
    %{status_code: status_code, body: body} = PokeApi.get!(uri)

    case status_code do
      200 ->
        %{body: species_body} = PokeApi.get!(body[:species]["url"])

        name =
          species_body[:names]
          |> Enum.filter(fn el -> el["language"]["name"] == "en" end)
          |> Enum.fetch!(0)
          |> Map.get("name")

        variation = String.split(body[:name], species_body[:name], parts: 2, trim: true)

        variation =
          if length(variation) != 0 do
            tmp =
              Enum.fetch!(variation, 0)
              |> String.split("-", trim: true)
              |> Enum.map(fn el -> String.capitalize(el) end)
              |> Enum.join(" ")

            "(" <> tmp <> ")"
          else
            ""
          end

        parsed_body = %{
          id: body[:id],
          name: name,
          variation: variation
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
            Cache.get(__MODULE__, :get_species_color, [parsed_body[:id]])
          )

        {status_code, parsed_body}

      _ ->
        {status_code, body}
    end
  end

  @spec get_species_color(integer) :: String.t()
  def get_species_color(id) do
    uri = "/pokemon-species/" <> Integer.to_string(id)

    PokeApi.get!(uri).body[:color]["name"]
  end
end
