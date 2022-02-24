defmodule LightningGraph.Neo4j.Subgraph do
  require Logger

  @default_capacity 2_000_000
  @default_base_fee 50
  @default_fee_rate 1000
  @default_is_disabled false
  @default_is_failing false

  def create(conn, graph_name, subgraph_name, options \\ []) do
    Logger.info("Creating Data Analysis graph")

    capacity = Keyword.get(options, :capacity, @default_capacity)
    base_fee = Keyword.get(options, :base_fee, @default_base_fee)
    fee_rate = Keyword.get(options, :fee_rate, @default_fee_rate)
    is_disabled = convert_boolean(Keyword.get(options, :is_disabled, @default_is_disabled))
    is_failing = convert_boolean(Keyword.get(options, :is_failing, @default_is_failing))

    query = """
    CALL gds.beta.graph.create.subgraph(
      '#{subgraph_name}',
      '#{graph_name}',
      'n.is_local = 0 AND n.channel_count > 1',
      'r.capacity >= #{capacity} AND r.base_fee <= #{base_fee} AND r.fee_rate < #{fee_rate} AND r.is_disabled = #{is_disabled} AND r.is_failing = #{is_failing}'
    )
    YIELD graphName, fromGraphName, nodeCount, relationshipCount
    """

    IO.puts("CREATE SUB GRAPH")
    IO.inspect(query)

    %Bolt.Sips.Response{} = Bolt.Sips.query!(conn, query)

    conn
  end

  defp convert_boolean(true) do
    1
  end

  defp convert_boolean(false) do
    0
  end
end
