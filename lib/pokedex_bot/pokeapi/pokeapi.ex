defmodule PokedexBot.PokeApi do
  use HTTPoison.Base

  @url Application.fetch_env!(:pokedex_bot, :pokeapi_url)
  @expected_fields ~w(
    results
    id name abilities held_items types stats sprites
    color
    attributes effect_entries flavor_text_entries held_by_pokemon names
    pokemon
  )

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
