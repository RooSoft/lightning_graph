defmodule LightningGraph.Neo4j.DataAnalyzer do
  require Logger

  @default_graph_name "myGraph"
  @default_subgraph_name "mySubGraph"

  def create_is_local conn, alias do
    Logger.info("Adding is_local property to #{alias}")

    query = """
      MATCH (n)
      SET n.is_local = (CASE WHEN n.alias='#{alias}' THEN 1 ELSE 0 END)
      RETURN n.alias, n.is_local
    """

    { _, _ } = Bolt.Sips.query(conn, query)

    conn
  end

  def add_is_failing conn do
    Logger.info("Adding is_failing = 0 property to all channels")

    query = """
      MATCH ()-[c:CHANNEL]-()
      SET c.is_failing = 0
    """

    { _, _ } = Bolt.Sips.query(conn, query)

    conn
  end

  def delete_graph conn, graph_name \\ @default_graph_name do
    Logger.info("Destroying previous Data Analysis graph")

    query = """
      CALL gds.graph.drop('#{graph_name}')
    """

    { _, _ } = Bolt.Sips.query(conn, query)

    conn
  end

  def create_graph conn, graph_name \\ @default_graph_name do
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

  def create_subgraph conn, graph_name \\ @default_graph_name, subgraph_name \\ @default_subgraph_name do
    Logger.info("Creating Data Analysis graph")

    query = """
    CALL gds.beta.graph.create.subgraph(
      '#{subgraph_name}',
      '#{graph_name}',
      'n.is_local = 0 AND n.channel_count > 1',
      'r.capacity >= 2000000 AND r.fee_rate < 50 AND r.base_fee <= 1000 AND r.is_disabled = 0 AND r.is_failing = 0'
    )
    YIELD graphName, fromGraphName, nodeCount, relationshipCount
    """

    %Bolt.Sips.Response{} = Bolt.Sips.query!(conn, query)

    conn
  end

  def add_community_ids conn, graph_name \\ @default_graph_name do
    Logger.info("Adding community ids to nodes")

    query = """
    CALL gds.louvain.write('#{graph_name}', {
      writeProperty: 'community',
      relationshipWeightProperty: 'capacity'
    })
    """

    %Bolt.Sips.Response{} = Bolt.Sips.query!(conn, query)

    conn
  end

  def add_betweenness_score conn, graph_name \\ @default_graph_name do
    Logger.info("Adding betweenness scores to nodes")

    query = """
    CALL gds.betweenness.write('#{graph_name}', { writeProperty: 'betweenness' })
    YIELD centralityDistribution, nodePropertiesWritten
    RETURN
      centralityDistribution.min AS minimumScore,
      centralityDistribution.mean AS meanScore,
      nodePropertiesWritten
    """

    %Bolt.Sips.Response{} = Bolt.Sips.query!(conn, query)

    conn
  end
end
