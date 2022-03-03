defmodule LightningGraph.Neo4j.Query do
  require Logger

  def get_number_of_nodes(conn) do
    query = """
    MATCH (n:node)
    RETURN count(n);
    """

    %Bolt.Sips.Response{results: results} = Bolt.Sips.query!(conn, query)

    results
    |> List.first()
    |> Map.get("count(n)")
  end

  def get_node_by_alias(conn, node_alias) do
    query = """
    MATCH (n:node {alias: "#{node_alias}"})
    RETURN n
    """

    %Bolt.Sips.Response{results: results} = Bolt.Sips.query!(conn, query)

    results
    |> Enum.map(fn result ->
      result["n"].properties
    end)
    |> List.first()
  end

  def get_community_members(conn, community_id) do
    query = """
    MATCH (n:node {community: #{community_id}})
    RETURN n
    """

    %Bolt.Sips.Response{results: results} = Bolt.Sips.query!(conn, query)

    results
    |> Enum.map(fn result ->
      result["n"].properties
    end)
  end

  def get_longest_paths(conn, graph, pub_key) do
    Logger.info("Getting longest paths to #{pub_key}")

    query = """
    CALL {
      MATCH (nice:node)
      WHERE nice.total_capacity > 100000000
      RETURN nice
    }
    MATCH (source:node {pub_key: '#{pub_key}'}), (nice)
    CALL gds.shortestPath.dijkstra.stream('#{graph}', {
        sourceNode: source,
        targetNode: nice
    })
    YIELD index, sourceNode, targetNode, totalCost, nodeIds, costs, path
    WHERE totalCost >= 3.0
    RETURN
        gds.util.asNode(sourceNode).alias AS sourceNodeName,
        gds.util.asNode(targetNode).alias AS targetNodeName,
        gds.util.asNode(targetNode).pub_key AS targetNodePubKey,
        gds.util.asNode(targetNode).betweenness AS targetNodeBetweenness,
        gds.util.asNode(targetNode).community AS targetNodeCommunity,
        totalCost,
        [nodeId IN nodeIds | gds.util.asNode(nodeId).alias] AS nodeNames,
        costs
    ORDER BY totalCost, gds.util.asNode(targetNode).betweenness DESC
    """

    %Bolt.Sips.Response{results: results} = Bolt.Sips.query!(conn, query)

    results
  end

  @doc """
  Find node that have channel to both node1 and node2

  Examples

  iex> LightningGraph.Neo4j.get_connection |> LightningGraph.Neo4j.Query.get_common_peers("WalletOfSatoshi.com", "BCash_Is_Trash")
  """
  def get_common_peers(conn, node1_alias, node2_alias) do
    query = """
    MATCH (r:node {alias: '#{node1_alias}'})-[]-(x:node)-[]-(node {alias:'#{node2_alias}'})
    RETURN DISTINCT x
    """

    %Bolt.Sips.Response{results: results} = Bolt.Sips.query!(conn, query)

    results
    |> Enum.map(fn result ->
      result["x"].properties
    end)
  end

  def get_cheapest_routes(conn, graph, route_count, node1_pub_key, node2_pub_key) do
    query = """
        MATCH   (source:node {pub_key: "#{node1_pub_key}"}),
                (target:node {pub_key: "#{node2_pub_key}"})
        CALL gds.shortestPath.yens.stream('#{graph}', {
            sourceNode: source,
            targetNode: target,
            k: #{route_count + 1},
            relationshipWeightProperty: "fee_rate"
        })
        YIELD index, totalCost, nodeIds, costs, path
        RETURN
            index,
            totalCost,
            [nodeId IN nodeIds | gds.util.asNode(nodeId).pub_key] AS pubKeys,
            costs
        ORDER BY index
        SKIP 1
    """

    %Bolt.Sips.Response{results: results} = Bolt.Sips.query!(conn, query)

    results
    |> Enum.map(fn result ->
      %{
        index: result["index"],
        total_cost: result["totalCost"],
        costs: result["costs"],
        pub_keys: result["pubKeys"]
      }
    end)
  end
end
