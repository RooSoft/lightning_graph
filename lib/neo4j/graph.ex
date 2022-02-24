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

  def list(conn) do
    Logger.info("List graphs")

    query = """
      CALL gds.graph.list();
    """

    %Bolt.Sips.Response{results: results} = Bolt.Sips.query!(conn, query)

    results
    |> Enum.map(&convert_graph/1)
  end

  defp convert_graph(neo4j_graph) do
    %{
      name: neo4j_graph["graphName"],
      database: neo4j_graph["database"],
      memory_usage: neo4j_graph["memoryUsage"],
      size: neo4j_graph["sizeInBytes"],
      creation_time: neo4j_graph["creationTime"],
      modification_time: neo4j_graph["modificationTime"],
      node_count: neo4j_graph["nodeCount"],
      relationship_count: neo4j_graph["relationshipCount"]
    }
  end
end
