defmodule LightningGraph.Neo4j.Lnd.Mutations.Channel do
  require Logger

  def update(conn, channel_edge_update) do
    routing_policy = channel_edge_update.routing_policy

    set_statement =
      []
      |> maybe_add(channel_edge_update.capacity, "capacity")
      |> maybe_add(routing_policy.fee_base_msat, "base_fee")
      |> maybe_add(routing_policy.fee_rate_milli_msat, "fee_rate")
      |> maybe_add(routing_policy.disabled, "disabled")
      |> Enum.join(", ")

    query = """
    MATCH (node)-[c:CHANNEL {lnd_id: "#{channel_edge_update.chan_id}"}]-(node)
    SET c += { #{set_statement} }
    RETURN c;
    """

    now = DateTime.utc_now() |> DateTime.to_string()

    Logger.info("#{now} Updated the #{channel_edge_update.chan_id} channel")

    Bolt.Sips.query!(conn, query)
  end

  defp maybe_add(statement, nil, _field) do
    statement
  end

  defp maybe_add(statement, value, field) do
    ["#{field}: \"#{value}\"" | statement]
  end
end
