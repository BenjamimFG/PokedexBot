defmodule PokedexBot.PokeApi.Moves do
  alias PokedexBot.PokeApi

  @base_url "/move"

  @type move :: %{
          id: integer(),
          accuracy: integer,
          power: integer,
          pp: integer,
          priority: integer,
          name: String.t(),
          flavor_text: String.t(),
          effect: String.t(),
          damage_class: String.t(),
          type: String.t(),
          machine: String.t(),
          learned_by: list(String.t())
        }

  @spec get_move :: list(%{id: integer, name: String.t()})
  def get_move() do
    PokeApi.get!(@base_url <> "?limit=9999").body[:results]
    |> Enum.map(fn el ->
      %{
        id: String.to_integer(List.last(String.split(el["url"], "/", trim: true))),
        name: el["name"]
      }
    end)
  end

  @spec get_move(integer | String.t()) :: {integer, %{} | move()}
  def get_move(move) do
    move_str = if is_integer(move), do: Integer.to_string(move), else: move

    uri = @base_url <> "/" <> move_str
    %{status_code: status_code, body: body} = PokeApi.get!(uri)

    case status_code do
      200 ->
        parsed_body = %{
          id: body[:id],
          accuracy: body[:accuracy],
          power: body[:power],
          pp: body[:pp],
          priority: body[:priority]
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

        parsed_body = Map.put(parsed_body, :damage_class, body[:damage_class]["name"])

        %{body: type_body} = PokeApi.get!(body[:type]["url"])

        move_type =
          type_body[:names]
          |> Enum.filter(fn el -> el["language"]["name"] == "en" end)
          |> Enum.fetch!(0)
          |> Map.get("name")

        parsed_body = Map.put(parsed_body, :type, move_type)

        machine_name =
          if Enum.empty?(body[:machines]) do
            nil
          else
            url =
              body[:machines]
              |> List.last()
              |> Map.get("machine")
              |> Map.get("url")

            %{body: machine_body} = PokeApi.get!(url)
            machine_body[:item]["name"]
          end

        # Cache.get(PokeApi, :get!, [List.last(body[:machines]["machine"]["url"])])

        parsed_body = Map.put(parsed_body, :machine, machine_name)

        parsed_body =
          body[:learned_by_pokemon]
          |> Enum.map(fn el -> "`#{el["name"]}`" end)
          |> (&Map.put(parsed_body, :learned_by, &1)).()

        # parsed_body = Map.put(parsed_body, :learned_by, [])

        {status_code, parsed_body}

      _ ->
        {status_code, body}
    end
  end
end
