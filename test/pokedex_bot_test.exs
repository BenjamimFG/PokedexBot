defmodule PokedexBotTest do
  use ExUnit.Case
  doctest PokedexBot

  test "greets the world" do
    assert PokedexBot.hello() == :world
  end
end
