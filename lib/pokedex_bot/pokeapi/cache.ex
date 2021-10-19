defmodule PokedexBot.PokeApi.Cache do
  @spec get(module(), atom(), list(String.t()), list(String.t())) :: any
  def get(mod, fun, args, opts \\ []) do
    case lookup(mod, fun, args) do
      nil ->
        ttl = Keyword.get(opts, :ttl, 3600)
        cache_apply(mod, fun, args, ttl)

      result ->
        IO.puts("Retrieving #{mod}.#{fun}(#{Enum.join(args, ",")}) from cache")
        result
    end
  end

  @spec lookup(module(), atom(), list(String.t())) :: any
  defp lookup(mod, fun, args) do
    case :ets.lookup(:pokeapi_cache, [mod, fun, args]) do
      [result | _] -> check_freshness(result)
      [] -> nil
    end
  end

  defp check_freshness({_mfa, result, expiration}) do
    cond do
      expiration > :os.system_time(:seconds) -> result
      :else -> nil
    end
  end

  @spec cache_apply(module(), atom(), list(String.t()), integer()) :: any()
  defp cache_apply(mod, fun, args, ttl) do
    result = apply(mod, fun, args)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(:pokeapi_cache, {[mod, fun, args], result, expiration})
    result
  end
end
