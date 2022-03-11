defmodule LightningGraph.Neo4j.Lnd.Mutations.Node do
  require Logger

  def update(conn, node_update) do
    query = """
    MATCH (n:node {pub_key:"#{node_update.identity_key}"})
    SET n += { alias: "#{node_update.alias}", color: "#{node_update.color}" }
    RETURN n;
    """

    Logger.info("Updated the #{node_update.identity_key} node (#{node_update.alias})")

    Bolt.Sips.query!(conn, query)
  end
end
