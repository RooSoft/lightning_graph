defmodule LightningGraph.Neo4j.DataAnalyzer do
  require Logger

  @graph_name "myGraph"

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

  def delete_graph conn do
    Logger.info("Destroying previous Data Analysis graph")

    query = """
      CALL gds.graph.drop('#{@graph_name}')
    """

    { _, _ } = Bolt.Sips.query(conn, query)

    conn
  end

  def create_graph conn do
    Logger.info("Creating Data Analysis graph")

    query = """
    CALL gds.graph.create('#{@graph_name}', 'node',
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

  def add_community_ids conn do
    Logger.info("Adding community ids to nodes")

    query = """
    CALL gds.louvain.write('#{@graph_name}', {
      writeProperty: 'community',
      relationshipWeightProperty: 'capacity'
    })
    """

    %Bolt.Sips.Response{} = Bolt.Sips.query!(conn, query)

    conn
  end

  def add_betweenness_score conn do
    Logger.info("Adding betweenness scores to nodes")

    query = """
    CALL gds.betweenness.write('#{@graph_name}', { writeProperty: 'betweenness' })
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
