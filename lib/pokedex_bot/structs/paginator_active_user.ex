defmodule PokedexBot.EmbedPaginator.ActiveUser do
  @enforce_keys [:user, :channel_id, :message_id, :paginator, :page]
  defstruct [:user, :channel_id, :message_id, :paginator, :page]

  @type user :: %{id: Nostrum.Snowflake.t(), name: String.t(), avatar: String.t()}
  @type channel_id :: Nostrum.Snowflake.t()
  @type message_id :: Nostrum.Snowflake.t()
  @type paginator :: atom
  @type page :: integer
end
