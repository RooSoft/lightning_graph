defmodule LightningGraph.Neo4j.Lnd.Mutations.Channel do
  require Logger

  def update(conn, channel_edge_update) do
    channel_fields = convert(channel_edge_update)

    set_statement =
      []
      |> maybe_add(channel_fields.capacity, "capacity")
      |> maybe_add(channel_fields.base_fee, "base_fee")
      |> maybe_add(channel_fields.fee_rate, "fee_rate")
      |> maybe_add(channel_fields.disabled, "disabled")
      |> add_current_date
      |> Enum.join(", ")

    query = """
    MATCH (:node)-[c:CHANNEL {lnd_id: #{channel_edge_update.chan_id}}]-(:node)
    SET c += { #{set_statement} };
    """

    Bolt.Sips.query!(conn, query)

    channel_fields
  end

  def delete(conn, lnd_id) do
    query = """
    MATCH (:node)-[c:CHANNEL {lnd_id: #{lnd_id}}]-(:node)
    DELETE c;
    """

    Bolt.Sips.query!(conn, query)

    lnd_id
  end

  defp maybe_add(statement, nil, _field) do
    statement
  end

  defp maybe_add(statement, value, field) do
    ["#{field}: \"#{value}\"" | statement]
  end

  defp add_current_date(statement) do
    ["updated: datetime(\"#{DateTime.utc_now() |> DateTime.to_iso8601()}\")" | statement]
  end

  defp convert(channel_edge_update) do
    routing_policy = channel_edge_update.routing_policy

    %{
      lnd_id: channel_edge_update.chan_id,
      capacity: channel_edge_update.capacity,
      base_fee: routing_policy.fee_base_msat,
      fee_rate: routing_policy.fee_rate_milli_msat,
      disabled: routing_policy.disabled
    }
  end
end
