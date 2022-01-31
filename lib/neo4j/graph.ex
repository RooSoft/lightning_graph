defmodule LightningGraph.Neo4j.Graph do
  require Logger

  def create(conn, graph_name) do
    Logger.info("Creating Data Analysis graph")

    query = """
    CALL gds.graph.create('#{graph_name}', 'node',
      { CHANNEL: { } },
      {
        nodeProperties: ['is_local', 'channel_count'],
        relationshipProperties: ['capacity', 'fee_rate', 'base_fee', 'is_disabled', 'is_failing']
      }
    )
    """

    %Bolt.Sips.Response{} = Bolt.Sips.query!(conn, query)

    conn
  end

  def delete(conn, graph_name) do
    Logger.info("Destroying previous Data Analysis graph")

    query = """
      CALL gds.graph.drop('#{graph_name}')
    """

    {_, _} = Bolt.Sips.query(conn, query)

    conn
  end
end
